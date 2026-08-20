import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/themes/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/services/app_feedback.dart';
import '../../l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';
import 'location_picker_screen.dart'; // sesuaikan path
import '../../repositories/subscription_repository.dart';
import '../../services/subscription_service.dart';

/// Hasil evaluasi dua lapis gate saat menambah cabang baru: status
/// subscription (blockedByStatus) dan kuota (quotaAvailable). Kalau
/// blockedByStatus true, quotaAvailable tidak relevan (sudah gagal lebih
/// awal dari status, jadi kuota tidak perlu dicek) - sama seperti
/// _EmployeeGateResult di CreateEmployeeScreen.
class _LaundryGateResult {
  final bool blockedByStatus;
  final bool quotaAvailable;
  final int? graceDaysRemaining;

  const _LaundryGateResult({
    required this.blockedByStatus,
    required this.quotaAvailable,
    this.graceDaysRemaining,
  });
}

/// Local design tokens matching the new "NetWash Utility System" design
/// (samain persis dengan CreateEmployeeScreen: canvas abu kebiruan, kartu
/// putih shadow lembut, Be Vietnam Pro, warna primary #0061A4). Sengaja
/// TIDAK menyentuh AppTheme global, biar layar lain gak ikut berubah.
class _DS {
  static const canvas = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const onSurface = Color(0xFF1B1C1C);
  static const onSurfaceVariant = Color(0xFF404752);
  static const outline = Color(0xFF707883);
  static const outlineVariant = Color(0xFFBFC7D4);

  static const primary = Color(0xFF0061A4);
  static const primaryFixed = Color(0xFFD1E4FF);

  static const tertiary = Color(0xFF526069);
  static const tertiaryFixed = Color(0xFFD6E5EF);

  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);

  static const secondaryContainer = Color(0xFFE0E3E6);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static TextStyle headlineMd({Color? color}) => GoogleFonts.beVietnamPro(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color ?? onSurface,
        letterSpacing: -0.1,
      );

  static TextStyle labelBold({Color? color}) => GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color ?? onSurfaceVariant,
        letterSpacing: 0.3,
      );
}

const _kFieldFill = Color(0xFFF7F8FA);

class CreateLaundryScreen extends ConsumerStatefulWidget {
  final String? laundryId;

  const CreateLaundryScreen({Key? key, this.laundryId}) : super(key: key);

  @override
  ConsumerState<CreateLaundryScreen> createState() => _CreateLaundryScreenState();
}

class _CreateLaundryScreenState extends ConsumerState<CreateLaundryScreen> {
  final _formKey = GlobalKey<FormState>();

  bool get isEditMode => widget.laundryId != null;

  // Controller input form - field dasar sesuai skema laundries (§3.2.3)
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _capacityController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  String? _selectedCompanyId;
  bool _isActive = true;
  bool _isLoading = false;

  // Loading khusus saat mengambil data existing di mode edit
  bool _isLoadingInitialData = false;

  /// Alert error - disamakan persis dengan CreateOrderScreen: pakai
  /// AppSnackbar (bukan SnackBar bawaan) + getar & suara error lewat
  /// AppFeedback, supaya rasanya konsisten di seluruh form "Tambah"/"Edit"
  /// (dipakai baik untuk mode create maupun edit cabang, karena keduanya
  /// lewat layar & method yang sama).
  void _showError(String message) {
    AppFeedback.haptic(ref, type: HapticFeedbackType.heavy);
    AppFeedback.playSound(ref, AppSound.error);
    AppSnackbar.error(context, message);
  }

  // List Perusahaan (untuk dropdown company_id)
  List<Map<String, dynamic>> _companiesList = [];

  // Hari operasional sesuai skema operating_hours (§3.2.3): key harus persis
  // "monday".."sunday" agar konsisten dengan blueprint. Label ditampilkan
  // sesuai bahasa aktif lewat _dayLabel().
  final List<Map<String, String>> _days = const [
    {'key': 'monday'},
    {'key': 'tuesday'},
    {'key': 'wednesday'},
    {'key': 'thursday'},
    {'key': 'friday'},
    {'key': 'saturday'},
    {'key': 'sunday'},
  ];

  /// Mengembalikan label hari sesuai locale aktif berdasarkan key hari.
  String _dayLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'monday':
        return l10n.monday;
      case 'tuesday':
        return l10n.tuesday;
      case 'wednesday':
        return l10n.wednesday;
      case 'thursday':
        return l10n.thursday;
      case 'friday':
        return l10n.friday;
      case 'saturday':
        return l10n.saturday;
      case 'sunday':
      default:
        return l10n.sunday;
    }
  }

  // Default jam operasional per hari
  late Map<String, Map<String, String>> _operatingHours;

  // Status buka/tutup per hari (switch di tiap baris). Tidak ada field
  // eksplisit untuk ini di skema Firestore - dipakai murni sebagai kontrol
  // UI untuk menonaktifkan input jam hari tertentu, sesuai mockup.
  late Map<String, bool> _dayEnabled;

  @override
  void initState() {
    super.initState();
    _operatingHours = {
      for (final d in _days) d['key']!: {'open': '08:00', 'close': '20:00'},
    };
    _dayEnabled = {
      for (final d in _days) d['key']!: true,
    };
    _fetchCompaniesData();
    if (isEditMode) {
      _loadExistingLaundry();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _capacityController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  /// MODE EDIT: Ambil data cabang existing dari Firestore dan prefill semua
  /// controller/state form, termasuk operating_hours dan lokasi (jika ada).
  Future<void> _loadExistingLaundry() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoadingInitialData = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('laundries')
          .doc(widget.laundryId)
          .get();

      final data = doc.data();
      if (data == null) {
        if (mounted) {
          _showError(AppLocalizations.of(context)!.branchDataNotFoundError);
          context.pop();
        }
        return;
      }

      _nameController.text = (data['name'] ?? '') as String;
      _codeController.text = (data['code'] ?? '') as String;
      _addressController.text = (data['address'] ?? '') as String;
      _cityController.text = (data['city'] ?? '') as String;
      _provinceController.text = (data['province'] ?? '') as String;
      _phoneController.text = (data['phone'] ?? '') as String;
      _emailController.text = (data['email'] ?? '') as String;
      _capacityController.text = (data['capacity']?.toString() ?? '');
      _selectedCompanyId = data['company_id'] as String?;
      _isActive = (data['is_active'] as bool?) ?? true;

      final location = data['location'] as Map<String, dynamic>?;
      if (location != null) {
        _latController.text = (location['lat']?.toString() ?? '');
        _lngController.text = (location['lng']?.toString() ?? '');
      }

      final rawHours = data['operating_hours'] as Map<String, dynamic>?;
      if (rawHours != null) {
        final loadedHours = {
          for (final d in _days)
            d['key']!: {
              'open': (rawHours[d['key']]?['open'] ?? '08:00') as String,
              'close': (rawHours[d['key']]?['close'] ?? '20:00') as String,
            },
        };
        final loadedEnabled = {
          for (final d in _days)
            d['key']!: (rawHours[d['key']]?['is_open'] ?? true) as bool,
        };
        setState(() {
          _operatingHours = loadedHours;
          _dayEnabled = loadedEnabled;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError(AppLocalizations.of(context)!.loadBranchDataError(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isLoadingInitialData = false);
    }
  }

  /// MIGRASI DATA LAMA: sebelum fix, AuthRepository.saveCompanyData()
  /// hanya menulis data perusahaan ke field `company` di users/{uid},
  /// bukan ke subcollection users/{uid}/companies yang dibaca layar ini.
  /// Akun yang sempat menyelesaikan Setup Company SEBELUM fix tersebut
  /// jadi tidak punya dokumen apa pun di subcollection `companies`,
  /// meskipun sudah pernah mengisi data perusahaan.
  ///
  /// Method ini mengecek kondisi itu dan otomatis menyalin data lama ke
  /// subcollection, sekali saja, supaya dropdown perusahaan di bawah
  /// tidak kosong tanpa perlu user mengulang proses onboarding (yang
  /// sudah tidak bisa diakses lagi karena companyCompleted sudah true).
  /// Aman dipanggil berkali-kali — no-op kalau subcollection sudah terisi
  /// atau memang tidak ada data lama untuk dimigrasikan.
  Future<void> _migrateLegacyCompanyIfNeeded(String userId) async {
    final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final companiesRef = userDocRef.collection('companies');

    try {
      final existing = await companiesRef.limit(1).get();
      if (existing.docs.isNotEmpty) return; // Sudah ada, tidak perlu migrasi

      final userDoc = await userDocRef.get();
      final legacyCompany = userDoc.data()?['company'] as Map<String, dynamic>?;

      // Tidak ada data lama untuk dimigrasikan (mis. akun baru yang memang
      // belum pernah mengisi Setup Company sama sekali).
      if (legacyCompany == null || legacyCompany['name'] == null) return;

      await companiesRef.add({
        ...legacyCompany,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Gagal migrasi data perusahaan lama: $e");
    }
  }

  /// Mengambil data perusahaan milik user, untuk relasi company_id
  /// (relasi laundries.company_id sesuai Blueprint §3.2.3)
  Future<void> _fetchCompaniesData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Jalankan migrasi data lama dulu (lihat dokumentasi method di atas)
      // sebelum query, supaya akun lama juga langsung dapat datanya.
      await _migrateLegacyCompanyIfNeeded(user.uid);

      final companySnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('companies')
          .get();

      setState(() {
        _companiesList = companySnap.docs.map((doc) => {
          'id': doc.id,
          'name': doc.data()['name'] ?? AppLocalizations.of(context)!.defaultCompanyName,
        }).toList();

        // Di mode create, auto-pilih perusahaan pertama sebagai default.
        // Di mode edit, JANGAN override _selectedCompanyId yang sudah/akan
        // di-load dari data existing lewat _loadExistingLaundry().
        if (!isEditMode && _companiesList.isNotEmpty && _selectedCompanyId == null) {
          _selectedCompanyId = _companiesList.first['id'];
        }
      });
    } catch (e) {
      debugPrint("Gagal memuat data perusahaan: $e");
    }
  }

  /// FEATURE GATING: dua lapis pengecekan sebelum menambah cabang baru
  /// (menambah cabang = aksi administrative). HANYA dipanggil di mode
  /// CREATE — edit tidak menambah jumlah cabang.
  ///
  /// Lapis 1 - status: SubscriptionService.checkAccess(administrative)
  /// menentukan boleh/tidak berdasarkan status subscription (aktif, masih
  /// grace period, atau sudah benar-benar expired).
  /// Lapis 2 - kuota: SubscriptionService.canAddLaundry() membandingkan
  /// jumlah cabang saat ini dengan limits.max_laundries plan yang berlaku.
  ///
  /// FIX: sebelumnya kalau tidak ada dokumen subscription sama sekali,
  /// fallback ke limit 1 di-hardcode langsung di screen ini. Sekarang
  /// didelegasikan ke SubscriptionService (currentSubscription: null tetap
  /// fallback ke limit Starter, tapi didefinisikan SEKALI di service, bukan
  /// diduplikasi di tiap screen — sama seperti CreateEmployeeScreen).
  ///
  /// Pakai streamSubscriptionForCompany() (BUKAN streamActiveSubscription())
  /// karena guard di sini butuh tahu status apa pun dokumennya (termasuk
  /// past_due), bukan cuma "null vs aktif".
  Future<_LaundryGateResult> _evaluateLaundryGate(String userId, String companyId) async {
    final subscriptionRepo = SubscriptionRepository(userId: userId);
    final subscription =
        await subscriptionRepo.streamSubscriptionForCompany(companyId).first;
    final service = SubscriptionService(currentSubscription: subscription);

    final access = service.checkAccess(SubscriptionActionType.administrative);
    if (!access.allowed) {
      return const _LaundryGateResult(blockedByStatus: true, quotaAvailable: false);
    }

    final currentCount = await _getCurrentLaundryCount(userId);
    return _LaundryGateResult(
      blockedByStatus: false,
      quotaAvailable: service.canAddLaundry(currentCount),
      graceDaysRemaining: access.isInGracePeriod ? access.graceDaysRemaining : null,
    );
  }

  /// Helper hitung total dokumen cabang dengan agregasi hemat cost
  Future<int> _getCurrentLaundryCount(String userId) async {
    final laundryCountSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('laundries')
        .count()
        .get();
    return laundryCountSnap.count ?? 0;
  }

  /// Buka time picker dan kembalikan string "HH:mm"
  Future<void> _pickTime({
    required String initialValue,
    required void Function(String) onPicked,
  }) async {
    final parts = initialValue.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: _DS.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      onPicked('$h:$m');
    }
  }

  /// Menyimpan data cabang ke Firestore (create dokumen baru ATAU update
  /// dokumen existing, tergantung isEditMode).
  Future<void> _saveLaundry() async {
    if (!_formKey.currentState!.validate()) {
      // Selain teks merah kecil di bawah tiap field, sekarang juga
      // munculin alert (snackbar merah + getar + suara error) - disamakan
      // dengan CreateDeliveryScreen/CreateCustomerScreen. Berlaku untuk
      // mode create MAUPUN edit karena keduanya lewat method ini.
      _showError('Lengkapi data yang wajib diisi terlebih dahulu');
      return;
    }
    if (_selectedCompanyId == null) {
      _showError(AppLocalizations.of(context)!.companyNotSelectedWarning);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception(AppLocalizations.of(context)!.userSessionExpiredError);

      final currentUserId = user.uid;

            // UPDATE: checkAccess (status subscription) sekarang dicek untuk
      // create MAUPUN edit - subscription expired harus tetap ngeblok
      // edit cabang juga, bukan cuma nambah baru. Kuota (canAddLaundry,
      // Blueprint §3.6.3) tetap CUMA relevan saat menambah cabang baru,
      // karena edit tidak menambah jumlah cabang - makanya quotaAvailable
      // dipaksa true saat edit supaya tidak ikut nge-block gara-gara
      // kuota yang memang tidak relevan di mode ini.
      final rawGate = await _evaluateLaundryGate(currentUserId, _selectedCompanyId!);
      final gate = isEditMode
          ? _LaundryGateResult(
              blockedByStatus: rawGate.blockedByStatus,
              quotaAvailable: true,
              graceDaysRemaining: rawGate.graceDaysRemaining,
            )
          : rawGate;

      if (gate.blockedByStatus || !gate.quotaAvailable) {
        if (mounted) {
          _showQuotaReachedDialog(blockedByStatus: gate.blockedByStatus);
          setState(() => _isLoading = false);
        }
        return;
      }
      // Boleh lanjut, tapi kalau lagi dalam grace period tetap kasih tahu
      // sisa harinya - tidak menghalangi, cuma peringatan.
      if (gate.graceDaysRemaining != null && mounted) {
        AppSnackbar.info(context, AppLocalizations.of(context)!.gracePeriodWarning(gate.graceDaysRemaining!));
      }

      // Susun operating_hours sesuai skema §3.2.3 (per hari, key monday..sunday)
      // + is_open (status switch "libur" per hari) - sebelumnya cuma
      // dipakai sebagai kontrol UI dan hilang begitu disimpan, sekarang
      // ikut ditulis ke Firestore supaya toggle libur beneran nyantol.
      final Map<String, dynamic> operatingHoursData = {
        for (final d in _days)
          d['key']!: {
            'open': _operatingHours[d['key']]!['open'],
            'close': _operatingHours[d['key']]!['close'],
            'is_open': _dayEnabled[d['key']] ?? true,
          },
      };

      // location bersifat opsional; hanya disertakan bila diisi
      Map<String, dynamic>? locationData;
      final latText = _latController.text.trim();
      final lngText = _lngController.text.trim();
      if (latText.isNotEmpty && lngText.isNotEmpty) {
        locationData = {
          'lat': double.tryParse(latText) ?? 0.0,
          'lng': double.tryParse(lngText) ?? 0.0,
        };
      }

      // Mapping data model presisi sesuai skema Blueprint §3.2.3 & Lampiran A
      final Map<String, dynamic> laundryData = {
        'company_id': _selectedCompanyId,
        'name': _nameController.text.trim(),
        'code': _codeController.text.trim().toUpperCase(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'province': _provinceController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'operating_hours': operatingHoursData,
        'capacity': int.tryParse(_capacityController.text.trim()) ?? 0,
        'is_active': _isActive,
        if (locationData != null) 'location': locationData,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (isEditMode) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('laundries')
            .doc(widget.laundryId)
            .update(laundryData);
      } else {
        final laundryRef = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('laundries')
            .doc();
        await laundryRef.set({
          ...laundryData,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        AppFeedback.haptic(ref);
        AppFeedback.playSound(ref, AppSound.success);
        AppSnackbar.success(context, isEditMode ? l10n.branchUpdateSuccess : l10n.branchAddSuccess);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        _showError(AppLocalizations.of(context)!.saveBranchError(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Menonaktifkan cabang langsung dari layar edit (tombol "Nonaktifkan
  /// Cabang" di bagian bawah, sesuai mockup). Menampilkan konfirmasi
  /// sebelum menyimpan status is_active = false.
  Future<void> _confirmDeactivate() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _DS.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.pause_circle_outline, color: Colors.redAccent, size: 26),
              ),
              const SizedBox(height: AppTheme.lg),
              Text(
                l10n.deactivateBranchTitle,
                style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.w700, color: _DS.onSurface),
              ),
              const SizedBox(height: AppTheme.sm),
              Text(
                l10n.deactivateBranchContent,
                style: GoogleFonts.beVietnamPro(fontSize: 13, color: _DS.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: AppTheme.xl),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => ctx.pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, color: _DS.onSurfaceVariant, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.md),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                      ),
                      onPressed: () => ctx.pop(true),
                      child: Text(
                        l10n.deactivateMenuItem,
                        style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      setState(() => _isActive = false);
      await _saveLaundry();
    }
  }

  /// Dialog "kuota cabang habis". Direstyle mengikuti AppTheme (Poppins,
  /// radius, warna primary) supaya konsisten dengan tampilan card & tombol
  /// di layar lain, bukan AlertDialog default yang polos.
  /// [blockedByStatus] pilih pasangan title/content: quota habis (default,
  /// dipakai juga oleh kode lama yang manggil tanpa argumen) vs subscription
  /// benar-benar expired (grace period sudah lewat). Tombol aksinya sama
  /// persis di kedua kasus - sama-sama mengarah ke halaman upgrade.
  void _showQuotaReachedDialog({bool blockedByStatus = false}) {
    showDialog(
      context: context,
      builder: (ctx) {
        final dialogL10n = AppLocalizations.of(ctx)!;
        return Dialog(
          backgroundColor: _DS.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _DS.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.workspace_premium_outlined, color: _DS.primary, size: 26),
                ),
                const SizedBox(height: AppTheme.lg),
                Text(
                  blockedByStatus ? dialogL10n.subscriptionExpiredTitle : dialogL10n.quotaReachedTitle,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _DS.onSurface,
                  ),
                ),
                const SizedBox(height: AppTheme.sm),
                Text(
                  blockedByStatus ? dialogL10n.subscriptionExpiredWarning : dialogL10n.quotaReachedContent,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    color: _DS.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppTheme.xl),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => ctx.pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                        ),
                        child: Text(
                          dialogL10n.cancel,
                          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, color: _DS.onSurfaceVariant, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.md),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _DS.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                        ),
                        onPressed: () {
                          ctx.pop();
                          context.push('/settings/subscription');
                        },
                        child: Text(
                          dialogL10n.upgradePlanButton,
                          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      // Disamakan dengan CreateEmployeeScreen: canvas abu kebiruan (#F5F7FA)
      backgroundColor: _DS.canvas,
      body: SafeArea(
        child: (_isLoading || _isLoadingInitialData)
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(_DS.primary),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 800;
                  final horizontalPadding = isMobile ? 16.0 : 24.0;

                  return Column(
                    children: [
                      // ==== Top bar TETAP (pinned) saat form di-scroll ====
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Container(
                            color: _DS.canvas,
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              isMobile ? 16 : 24,
                              horizontalPadding,
                              0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTopBar(context, l10n),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // ==== Isi form yang bisa di-scroll ====
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 480),
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  horizontalPadding,
                                  0,
                                  horizontalPadding,
                                  32,
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildStatusSwitchCard(l10n),
                                      const SizedBox(height: 20),
                                      _buildGeneralInfoSection(l10n),
                                      const SizedBox(height: 20),
                                      _buildOperatingHoursSection(l10n),
                                      const SizedBox(height: 28),
                                      _buildPrimaryActions(l10n),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  /// Top bar - disamakan persis dengan pola CreateEmployeeScreen (bar putih,
  /// tombol back bulat, judul warna primary).
  Widget _buildTopBar(BuildContext context, AppLocalizations l10n) {
    final canGoBack = context.canPop();
    return Container(
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _DS.cardShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          if (canGoBack)
            InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_rounded, size: 22, color: _DS.primary),
              ),
            ),
          SizedBox(width: canGoBack ? 4 : 12),
          Expanded(
            child: Text(
              isEditMode ? l10n.editBranchTitle : l10n.addBranchTitle,
              style: _DS.headlineMd(color: _DS.primary),
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu "Cabang Aktif" dengan switch, persis mengikuti card status di
  /// bagian paling atas mockup (icon bulat + judul + subtitle + switch).
  Widget _buildStatusSwitchCard(AppLocalizations l10n) {
    return _cardContainer(
      padding: const EdgeInsets.all(AppTheme.lg),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _DS.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.storefront_rounded, color: _DS.primary, size: 20),
          ),
          const SizedBox(width: AppTheme.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.activeStatusLabel,
                  style: GoogleFonts.beVietnamPro(fontSize: 13.5, fontWeight: FontWeight.w600, color: _DS.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.activeStatusSubtitle,
                  style: GoogleFonts.beVietnamPro(fontSize: 11.5, color: _DS.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isActive,
            activeColor: _DS.primary,
            onChanged: (v) => setState(() => _isActive = v),
          ),
        ],
      ),
    );
  }

  /// Section "Informasi Umum": perusahaan, nama, kode+telepon, email,
  /// alamat, kota+provinsi, kapasitas, dan koordinat lokasi.
  Widget _buildGeneralInfoSection(AppLocalizations l10n) {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(l10n.generalInfoSection),

          _fieldLabel(l10n.ownerCompanyLabel),
          _companiesList.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => context.push('/companies/create'),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: Text(
                        l10n.registerCompanyFirst,
                        style: GoogleFonts.beVietnamPro(color: _DS.primary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                )
              : DropdownButtonFormField<String>(
                  value: _companiesList.any((c) => c['id'] == _selectedCompanyId) ? _selectedCompanyId : null,
                  items: _companiesList.map((c) {
                    return DropdownMenuItem<String>(
                      value: c['id'],
                      child: Text(c['name'], style: GoogleFonts.beVietnamPro(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCompanyId = val),
                  decoration: _buildInputDecoration(l10n.selectCompanyHint, null),
                  validator: (v) => v == null ? l10n.companyRequiredValidator : null,
                ),
          const SizedBox(height: AppTheme.md),

          _fieldLabel(l10n.branchNameLabel),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.beVietnamPro(fontSize: 13.5, color: _DS.onSurface),
            decoration: _buildInputDecoration(l10n.branchNameHint, null),
            validator: (v) => v == null || v.trim().isEmpty ? l10n.branchNameEmpty : null,
          ),
          const SizedBox(height: AppTheme.md),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel(l10n.branchCodeLabel),
                    TextFormField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      style: GoogleFonts.beVietnamPro(fontSize: 13.5, color: _DS.onSurface),
                      decoration: _buildInputDecoration(l10n.branchCodeHint, null),
                      validator: (v) => v == null || v.trim().isEmpty ? l10n.branchCodeEmpty : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel(l10n.branchPhoneLabel),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.beVietnamPro(fontSize: 13.5, color: _DS.onSurface),
                      decoration: _buildInputDecoration(l10n.branchPhoneHint, null),
                      validator: (v) => v == null || v.trim().isEmpty ? l10n.phoneEmpty : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.md),

          _fieldLabel(l10n.emailOptionalLabel),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.beVietnamPro(fontSize: 13.5, color: _DS.onSurface),
            decoration: _buildInputDecoration(l10n.branchEmailHint, null),
          ),
          const SizedBox(height: AppTheme.md),

          _fieldLabel(l10n.addressLabel),
          TextFormField(
            controller: _addressController,
            maxLines: 3,
            style: GoogleFonts.beVietnamPro(fontSize: 13.5, color: _DS.onSurface),
            decoration: _buildInputDecoration(l10n.addressHint, null),
            validator: (v) => v == null || v.trim().isEmpty ? l10n.addressEmpty : null,
          ),
          const SizedBox(height: AppTheme.md),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel(l10n.cityLabel),
                    TextFormField(
                      controller: _cityController,
                      textCapitalization: TextCapitalization.words,
                      style: GoogleFonts.beVietnamPro(fontSize: 13.5, color: _DS.onSurface),
                      decoration: _buildInputDecoration(l10n.cityHint, null),
                      validator: (v) => v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel(l10n.provinceLabel),
                    TextFormField(
                      controller: _provinceController,
                      textCapitalization: TextCapitalization.words,
                      style: GoogleFonts.beVietnamPro(fontSize: 13.5, color: _DS.onSurface),
                      decoration: _buildInputDecoration(l10n.provinceHint, null),
                      validator: (v) => v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.md),

          _fieldLabel(l10n.dailyCapacityLabel),
          TextFormField(
            controller: _capacityController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.beVietnamPro(fontSize: 13.5, color: _DS.onSurface),
            decoration: _buildInputDecoration(l10n.capacityHint, null),
            validator: (v) => v == null || v.trim().isEmpty ? l10n.capacityEmpty : null,
          ),
          const SizedBox(height: AppTheme.md),

          _fieldLabel(l10n.mapLocationLabel),
          FormField<String>(
            validator: (_) {
              if (_latController.text.trim().isEmpty || _lngController.text.trim().isEmpty) {
                return 'Tentukan lokasi cabang di peta terlebih dahulu';
              }
              return null;
            },
            builder: (field) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      LatLng? initial;
                      final lat = double.tryParse(_latController.text.trim());
                      final lng = double.tryParse(_lngController.text.trim());
                      if (lat != null && lng != null) initial = LatLng(lat, lng);
                      final result = await Navigator.push<LocationPickResult>(
                        context,
                        MaterialPageRoute(builder: (_) => LocationPickerScreen(initialLocation: initial)),
                      );
                      if (result != null) {
                        setState(() {
                          _latController.text = result.point.latitude.toString();
                          _lngController.text = result.point.longitude.toString();
                          if (result.address != null && result.address!.trim().isNotEmpty) {
                            _addressController.text = result.address!;
                          }
                          if (result.city != null && result.city!.trim().isNotEmpty) {
                            _cityController.text = result.city!;
                          }
                          if (result.province != null && result.province!.trim().isNotEmpty) {
                            _provinceController.text = result.province!;
                          }
                        });
                        field.didChange(_latController.text);
                        field.validate();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: _kFieldFill,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: field.hasError ? _DS.error : _DS.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.map_outlined, size: 18, color: _DS.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              (_latController.text.isNotEmpty && _lngController.text.isNotEmpty)
                                  ? '${_latController.text}, ${_lngController.text}'
                                  : 'Ketuk untuk pilih lokasi di peta',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12.5,
                                color: (_latController.text.isNotEmpty) ? _DS.onSurface : _DS.outline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 18, color: _DS.outline),
                        ],
                      ),
                    ),
                  ),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        field.errorText!,
                        style: GoogleFonts.beVietnamPro(fontSize: 11, color: _DS.error),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Section "Jam Operasional": header + tombol pill "Samakan untuk semua
  /// hari" (aksi sekali klik yang menyalin jam Senin ke semua hari lain),
  /// lalu daftar 7 hari yang SELALU tampil, masing-masing dengan switch
  /// aktif/nonaktif sendiri - persis mengikuti mockup.
  ///
  /// FIX OVERFLOW: header sebelumnya pakai `Row(spaceBetween)`, yang tidak
  /// bisa membungkus ke baris baru. Di layar sempit (mis. 360px), judul
  /// "JAM OPERASIONAL" + tombol pill "Gunakan jam yang sama untuk semua
  /// hari" jadi lebih lebar dari layar dan overflow ke kanan. Diganti ke
  /// `Wrap(alignment: WrapAlignment.spaceBetween)`: kalau keduanya masih
  /// muat sebaris (layar lebar/tablet), tampilannya identik dengan Row.
  /// Kalau tidak muat, tombol pill otomatis turun ke baris kedua alih-alih
  /// overflow.
  Widget _buildOperatingHoursSection(AppLocalizations l10n) {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              Text(
                l10n.operatingHoursLabel.toUpperCase(),
                style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: _DS.outline),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _applySameHoursToAllDays(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _DS.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.useSameHoursLabel,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.beVietnamPro(fontSize: 10.5, fontWeight: FontWeight.w700, color: _DS.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Column(
            children: _days.map((d) {
              final key = d['key']!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildDayRow(key, l10n),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Menyalin jam Senin ke semua hari lain (aksi tombol "Samakan untuk
  /// semua hari"). Hari yang sedang nonaktif tetap ikut disamakan jamnya,
  /// tapi tetap nonaktif sampai switch-nya dinyalakan lagi.
  void _applySameHoursToAllDays() {
    final firstKey = _days.first['key']!;
    final open = _operatingHours[firstKey]!['open']!;
    final close = _operatingHours[firstKey]!['close']!;
    setState(() {
      for (final d in _days) {
        _operatingHours[d['key']!] = {'open': open, 'close': close};
      }
    });
  }

  /// Satu baris hari: switch aktif/nonaktif + label hari + dua chip jam.
  /// Saat switch dimatikan, chip jam ikut dinonaktifkan (tidak bisa ditekan)
  /// sesuai perilaku pada mockup.
  Widget _buildDayRow(String key, AppLocalizations l10n) {
    final enabled = _dayEnabled[key] ?? true;
    return Row(
      children: [
        Transform.scale(
          scale: 0.75,
          child: Switch.adaptive(
            value: enabled,
            activeColor: _DS.primary,
            onChanged: (v) => setState(() => _dayEnabled[key] = v),
          ),
        ),
        SizedBox(
          width: 58,
          child: Text(
            _dayLabel(l10n, key),
            style: GoogleFonts.beVietnamPro(fontSize: 12.5, fontWeight: FontWeight.w500, color: _DS.onSurface),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _timeChip(
            _operatingHours[key]!['open']!,
            enabled
                ? () => _pickTime(
                      initialValue: _operatingHours[key]!['open']!,
                      onPicked: (v) => setState(() => _operatingHours[key]!['open'] = v),
                    )
                : null,
            enabled: enabled,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('—', style: GoogleFonts.beVietnamPro(color: _DS.outline)),
        ),
        Expanded(
          child: _timeChip(
            _operatingHours[key]!['close']!,
            enabled
                ? () => _pickTime(
                      initialValue: _operatingHours[key]!['close']!,
                      onPicked: (v) => setState(() => _operatingHours[key]!['close'] = v),
                    )
                : null,
            enabled: enabled,
          ),
        ),
      ],
    );
  }

  /// Tombol simpan (full width, rounded besar) + tombol teks "Nonaktifkan
  /// Cabang" berwarna merah di bawahnya (hanya muncul di mode edit),
  /// sesuai mockup.
  Widget _buildPrimaryActions(AppLocalizations l10n) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _saveLaundry,
            style: ElevatedButton.styleFrom(
              backgroundColor: _DS.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              isEditMode ? l10n.updateBranchButton : l10n.saveBranchButton,
              style: GoogleFonts.beVietnamPro(fontSize: 14.5, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        if (isEditMode) ...[
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: _confirmDeactivate,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: 10),
              ),
              child: Text(
                l10n.deactivateBranchButton,
                style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.redAccent),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================
  // HELPER STYLING
  // ============================================

  /// Kartu section dengan shadow tipis & radius besar, konsisten dipakai
  /// untuk status card & tiap section form.
  Widget _cardContainer({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(AppTheme.xl),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Judul section uppercase kecil (mis. "INFORMASI UMUM").
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: _DS.outline),
      ),
    );
  }

  /// Label kecil di atas tiap input field.
  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.beVietnamPro(fontSize: 11.5, fontWeight: FontWeight.w600, color: _DS.onSurfaceVariant),
      ),
    );
  }

  /// Chip jam ringkas (kotak, tanpa ikon), mengikuti input time polos
  /// di mockup. [onTap] null berarti chip nonaktif (hari sedang tutup),
  /// tampilannya dibuat pudar dan tidak bisa ditekan.
  Widget _timeChip(String value, VoidCallback? onTap, {bool enabled = true}) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: _kFieldFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _DS.outlineVariant),
        ),
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Text(value, style: GoogleFonts.beVietnamPro(fontSize: 11.5, color: _DS.onSurface)),
        ),
      ),
    );
  }

  /// Dekorasi input polos (tanpa border membulat penuh, fill abu muda),
  /// mengikuti gaya input pada mockup. Ikon bersifat opsional.
  InputDecoration _buildInputDecoration(String hint, IconData? icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.beVietnamPro(fontSize: 12.5, color: _DS.outline),
      prefixIcon: icon != null ? Icon(icon, color: _DS.outline, size: 18) : null,
      isDense: true,
      filled: true,
      fillColor: _kFieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _DS.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _DS.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _DS.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
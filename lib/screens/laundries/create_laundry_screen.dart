import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/themes/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../repositories/subscription_repository.dart';

/// Create / Edit Laundry (Cabang) Screen - NetWash
/// Skema data & feature gating mengikuti Blueprint §3.2.3 (Manajemen Cabang)
/// dan §3.6.3 (Feature Gating - canAddLaundry).
///
/// Dual-mode:
/// - laundryId == null  -> mode CREATE (form kosong, quota dicek sebelum simpan)
/// - laundryId != null  -> mode EDIT (data existing di-load & di-prefill,
///   quota TIDAK dicek ulang karena tidak menambah cabang baru)
///
/// Styling disamakan dengan mockup referensi "Tambah Cabang": top bar
/// sederhana (back + judul), kartu "Cabang Aktif" dengan switch di atas,
/// lalu section-section bercard terpisah (Informasi Umum, Jam Operasional,
/// Manajemen) dengan header label uppercase kecil, input polos tanpa ikon,
/// dan tombol pill "Samakan untuk semua hari".
const _kFieldFill = Color(0xFFF7F8FA);

class CreateLaundryScreen extends StatefulWidget {
  final String? laundryId;

  const CreateLaundryScreen({Key? key, this.laundryId}) : super(key: key);

  @override
  State<CreateLaundryScreen> createState() => _CreateLaundryScreenState();
}

class _CreateLaundryScreenState extends State<CreateLaundryScreen> {
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
  String? _selectedManagerId;
  bool _isActive = true;
  bool _isLoading = false;

  // Loading khusus saat mengambil data existing di mode edit
  bool _isLoadingInitialData = false;

  // List Perusahaan & Karyawan (untuk dropdown company_id & manager_id)
  List<Map<String, dynamic>> _companiesList = [];
  List<Map<String, dynamic>> _employeesList = [];

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
    _fetchEmployeesData();
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.branchDataNotFoundError), backgroundColor: Colors.redAccent),
          );
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
      _selectedManagerId = data['manager_id'] as String?;
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
        setState(() {
          _operatingHours = loadedHours;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.loadBranchDataError(e.toString())), backgroundColor: Colors.redAccent),
        );
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

  /// Mengambil data karyawan aktif, untuk opsi manager_id (opsional,
  /// bisa kosong bila cabang baru dibuat sebelum ada karyawan)
  Future<void> _fetchEmployeesData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final employeeSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('employees')
          .where('is_active', isEqualTo: true)
          .get();

      setState(() {
        _employeesList = employeeSnap.docs.map((doc) => {
          'id': doc.id,
          'name': (doc.data()['full_name'] as String?)?.isNotEmpty == true
              ? doc.data()['full_name']
              : (doc.data()['employee_code'] ?? AppLocalizations.of(context)!.defaultEmployeeName),
        }).toList();
      });
    } catch (e) {
      debugPrint("Gagal memuat data karyawan: $e");
    }
  }

  /// FEATURE GATING: Validasi sisa kuota cabang berdasarkan plan aktif
  /// Persis mengikuti SubscriptionService.canAddLaundry (Blueprint §3.6.3):
  /// baca `limits.max_laundries` dari dokumen subscription, -1 = unlimited.
  /// HANYA dipanggil di mode CREATE — edit tidak menambah jumlah cabang.
  ///
  /// FIX: sebelumnya query manual `.where('status','active').limit(1)`
  /// tanpa sorting bisa mengambil dokumen subscription yang SALAH kalau
  /// ada lebih dari satu dokumen berstatus 'active' untuk company yang
  /// sama (mis. sisa dokumen lama yang belum dinonaktifkan saat upgrade
  /// paket - lihat kasus yang sama yang sudah diperbaiki di
  /// CreateEmployeeScreen._checkEmployeeLimit). Sekarang pakai
  /// SubscriptionRepository.streamActiveSubscription(), yang sudah
  /// mengurutkan berdasarkan createdAt descending dan selalu memilih
  /// dokumen aktif/trialing yang PALING BARU - jadi konsisten dengan
  /// pola yang dipakai di layar employee.
  Future<bool> _checkLaundryLimit(String userId, String companyId) async {
    final subscriptionRepo = SubscriptionRepository(userId: userId);
    final activeSubscription =
        await subscriptionRepo.streamActiveSubscription(companyId).first;

    if (activeSubscription == null) {
      // Jika tidak ada data langganan, default kembali ke batasan Starter (maks 1)
      final currentCount = await _getCurrentLaundryCount(userId);
      return currentCount < 1;
    }

    // Sesuai Blueprint §3.6.3 (SubscriptionService.canAddLaundry):
    // batas kuota dibaca langsung dari `limits.max_laundries` pada
    // dokumen subscription, BUKAN hardcode per plan_id.
    // Nilai -1 pada limits berarti unlimited (khusus paket Enterprise).
    final int maxLaundries = activeSubscription.limits.maxLaundries;
    if (maxLaundries == -1) return true; // Unlimited

    final currentCount = await _getCurrentLaundryCount(userId);
    return currentCount < maxLaundries;
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
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppTheme.primaryColor),
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
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCompanyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.companyNotSelectedWarning), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception(AppLocalizations.of(context)!.userSessionExpiredError);

      final currentUserId = user.uid;

      // Pengecekan kuota (Blueprint §3.6.3) hanya relevan saat menambah
      // cabang baru. Saat edit, jumlah cabang tidak bertambah jadi dilewati.
      if (!isEditMode) {
        final isQuotaAvailable = await _checkLaundryLimit(currentUserId, _selectedCompanyId!);
        if (!isQuotaAvailable) {
          if (mounted) {
            _showQuotaReachedDialog();
            setState(() => _isLoading = false);
          }
          return;
        }
      }

      // Susun operating_hours sesuai skema §3.2.3 (per hari, key monday..sunday)
      final Map<String, dynamic> operatingHoursData = {
        for (final d in _days)
          d['key']!: {
            'open': _operatingHours[d['key']]!['open'],
            'close': _operatingHours[d['key']]!['close'],
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
        'manager_id': _selectedManagerId,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode ? l10n.branchUpdateSuccess : l10n.branchAddSuccess),
            backgroundColor: const Color(0xFF51CF66),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.saveBranchError(e.toString())), backgroundColor: Colors.redAccent),
        );
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
        backgroundColor: AppTheme.cardColor,
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
                'Nonaktifkan Cabang?',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: AppTheme.sm),
              Text(
                'Cabang ini akan ditandai tutup sementara dan tidak menerima pesanan baru.',
                style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
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
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13),
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
                        'Nonaktifkan',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
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
  void _showQuotaReachedDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final dialogL10n = AppLocalizations.of(ctx)!;
        return Dialog(
          backgroundColor: AppTheme.cardColor,
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
                    color: AppTheme.primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.workspace_premium_outlined, color: AppTheme.primaryColor, size: 26),
                ),
                const SizedBox(height: AppTheme.lg),
                Text(
                  dialogL10n.quotaReachedTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.sm),
                Text(
                  dialogL10n.quotaReachedContent,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
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
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.md),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
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
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
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
      // Disamakan dengan mockup: background abu kebiruan lembut (#F5F7FA)
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: (_isLoading || _isLoadingInitialData)
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 800;
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            isMobile ? 16 : 24,
                            isMobile ? 16 : 24,
                            isMobile ? 16 : 24,
                            32,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTopBar(context, l10n),
                                const SizedBox(height: 20),
                                _buildStatusSwitchCard(l10n),
                                const SizedBox(height: 20),
                                _buildGeneralInfoSection(l10n),
                                const SizedBox(height: 20),
                                _buildOperatingHoursSection(l10n),
                                const SizedBox(height: 20),
                                _buildManagementSection(l10n),
                                const SizedBox(height: 28),
                                _buildPrimaryActions(l10n),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  /// Top bar sederhana: tombol back + judul, tanpa icon-box atau subtitle,
  /// mengikuti mockup ("Tambah Cabang" / "Edit Cabang").
  Widget _buildTopBar(BuildContext context, AppLocalizations l10n) {
    final canGoBack = context.canPop();
    return Row(
      children: [
        if (canGoBack)
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.arrow_back_rounded, size: 24, color: AppTheme.textPrimary),
            ),
          ),
        SizedBox(width: canGoBack ? 8 : 0),
        Text(
          isEditMode ? l10n.editBranchTitle : l10n.addBranchTitle,
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
      ],
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
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.storefront_rounded, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: AppTheme.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.activeStatusLabel,
                  style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Nonaktifkan untuk tutup sementara',
                  style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isActive,
            activeColor: AppTheme.primaryColor,
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
          _sectionTitle('Informasi Umum'),

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
                        style: GoogleFonts.poppins(color: AppTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                )
              : DropdownButtonFormField<String>(
                  value: _companiesList.any((c) => c['id'] == _selectedCompanyId) ? _selectedCompanyId : null,
                  items: _companiesList.map((c) {
                    return DropdownMenuItem<String>(
                      value: c['id'],
                      child: Text(c['name'], style: GoogleFonts.poppins(fontSize: 13)),
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
            style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
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
                      style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
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
                      style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
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
            style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
            decoration: _buildInputDecoration(l10n.branchEmailHint, null),
          ),
          const SizedBox(height: AppTheme.md),

          _fieldLabel(l10n.addressLabel),
          TextFormField(
            controller: _addressController,
            maxLines: 3,
            style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
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
                      style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
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
                      style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
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
            style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
            decoration: _buildInputDecoration(l10n.capacityHint, null),
            validator: (v) => v == null || v.trim().isEmpty ? l10n.capacityEmpty : null,
          ),
          const SizedBox(height: AppTheme.md),

          _fieldLabel(l10n.mapLocationLabel),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _latController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
                  decoration: _buildInputDecoration(l10n.latitudeHint, null),
                ),
              ),
              const SizedBox(width: AppTheme.md),
              Expanded(
                child: TextFormField(
                  controller: _lngController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
                  decoration: _buildInputDecoration(l10n.longitudeHint, null),
                ),
              ),
            ],
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
                'Jam Operasional'.toUpperCase(),
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppTheme.textTertiary),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _applySameHoursToAllDays(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.useSameHoursLabel,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
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
            activeColor: AppTheme.primaryColor,
            onChanged: (v) => setState(() => _dayEnabled[key] = v),
          ),
        ),
        SizedBox(
          width: 58,
          child: Text(
            _dayLabel(l10n, key),
            style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
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
          child: Text('—', style: GoogleFonts.poppins(color: AppTheme.textTertiary)),
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

  /// Section "Manajemen": pilih manajer cabang (opsional).
  Widget _buildManagementSection(AppLocalizations l10n) {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Manajemen'),
          _fieldLabel(l10n.managerOptionalLabel),
          _employeesList.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(AppTheme.md),
                  decoration: BoxDecoration(
                    color: _kFieldFill,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Text(
                    l10n.noEmployeeDataInfo,
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                )
              : DropdownButtonFormField<String>(
                  value: _employeesList.any((e) => e['id'] == _selectedManagerId) ? _selectedManagerId : null,
                  items: _employeesList.map((e) {
                    return DropdownMenuItem<String>(
                      value: e['id'],
                      child: Text(e['name'], style: GoogleFonts.poppins(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedManagerId = val),
                  decoration: _buildInputDecoration(l10n.selectManagerHint, null),
                ),
        ],
      ),
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
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              isEditMode ? l10n.updateBranchButton : l10n.saveBranchButton,
              style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w700),
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
                'Nonaktifkan Cabang',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.redAccent),
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
        color: AppTheme.cardColor,
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
        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppTheme.textTertiary),
      ),
    );
  }

  /// Label kecil di atas tiap input field.
  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
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
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Text(value, style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.textPrimary)),
        ),
      ),
    );
  }

  /// Dekorasi input polos (tanpa border membulat penuh, fill abu muda),
  /// mengikuti gaya input pada mockup. Ikon bersifat opsional.
  InputDecoration _buildInputDecoration(String hint, IconData? icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textTertiary),
      prefixIcon: icon != null ? Icon(icon, color: AppTheme.textTertiary, size: 18) : null,
      isDense: true,
      filled: true,
      fillColor: _kFieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
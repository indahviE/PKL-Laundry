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
/// Styling disamakan dengan LaundriesListScreen: memakai AppTheme design
/// system (warna, radius, spacing, Poppins) alih-alih warna hardcoded lokal,
/// serta header custom (icon box + back button) & max-width layout yang sama.
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

  // Toggle: pakai jam yang sama untuk semua hari (simplifikasi UX,
  // datanya tetap disimpan penuh per hari sesuai skema blueprint)
  bool _useSameHoursForAllDays = true;
  String _uniformOpen = '08:00';
  String _uniformClose = '20:00';

  @override
  void initState() {
    super.initState();
    _operatingHours = {
      for (final d in _days) d['key']!: {'open': '08:00', 'close': '20:00'},
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
        // Cek apakah semua hari punya jam yang sama -> pakai toggle uniform
        final firstOpen = loadedHours[_days.first['key']]!['open'];
        final firstClose = loadedHours[_days.first['key']]!['close'];
        final allSame = loadedHours.values.every(
          (h) => h['open'] == firstOpen && h['close'] == firstClose,
        );

        setState(() {
          _operatingHours = loadedHours;
          _useSameHoursForAllDays = allSame;
          if (allSame) {
            _uniformOpen = firstOpen!;
            _uniformClose = firstClose!;
          }
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
      final Map<String, dynamic> operatingHoursData = _useSameHoursForAllDays
          ? {
              for (final d in _days)
                d['key']!: {'open': _uniformOpen, 'close': _uniformClose},
            }
          : {
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
      backgroundColor: AppTheme.backgroundColor,
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
                        constraints: const BoxConstraints(maxWidth: 900),
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
                                _buildHeader(context, l10n),
                                const SizedBox(height: 22),
                                _buildInfoBanner(l10n),
                                const SizedBox(height: AppTheme.xl),

                                _sectionLabel(l10n.ownerCompanyLabel),
                                const SizedBox(height: 8),
                                _companiesList.isEmpty
                                    ? TextButton(
                                        onPressed: () => context.push('/companies/create'),
                                        child: Text(
                                          l10n.registerCompanyFirst,
                                          style: GoogleFonts.poppins(color: AppTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.w600),
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
                                        decoration: _buildInputDecoration(l10n.selectCompanyHint, Icons.apartment_outlined),
                                        validator: (v) => v == null ? l10n.companyRequiredValidator : null,
                                      ),
                                const SizedBox(height: AppTheme.lg),

                                _sectionLabel(l10n.branchNameLabel),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _nameController,
                                  textCapitalization: TextCapitalization.words,
                                  style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
                                  decoration: _buildInputDecoration(l10n.branchNameHint, Icons.storefront_outlined),
                                  validator: (v) => v == null || v.trim().isEmpty ? l10n.branchNameEmpty : null,
                                ),
                                const SizedBox(height: AppTheme.lg),

                                _sectionLabel(l10n.branchCodeLabel),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _codeController,
                                  textCapitalization: TextCapitalization.characters,
                                  style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
                                  decoration: _buildInputDecoration(l10n.branchCodeHint, Icons.qr_code_outlined),
                                  validator: (v) => v == null || v.trim().isEmpty ? l10n.branchCodeEmpty : null,
                                ),
                                const SizedBox(height: AppTheme.lg),

                                _sectionLabel(l10n.addressLabel),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _addressController,
                                  maxLines: 2,
                                  style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
                                  decoration: _buildInputDecoration(l10n.addressHint, Icons.location_on_outlined),
                                  validator: (v) => v == null || v.trim().isEmpty ? l10n.addressEmpty : null,
                                ),
                                const SizedBox(height: AppTheme.lg),

                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _sectionLabel(l10n.cityLabel),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: _cityController,
                                            textCapitalization: TextCapitalization.words,
                                            style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
                                            decoration: _buildInputDecoration(l10n.cityHint, Icons.location_city_outlined),
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
                                          _sectionLabel(l10n.provinceLabel),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            controller: _provinceController,
                                            textCapitalization: TextCapitalization.words,
                                            style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
                                            decoration: _buildInputDecoration(l10n.provinceHint, Icons.map_outlined),
                                            validator: (v) => v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.lg),

                                _sectionLabel(l10n.branchPhoneLabel),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
                                  decoration: _buildInputDecoration(l10n.branchPhoneHint, Icons.phone_outlined),
                                  validator: (v) => v == null || v.trim().isEmpty ? l10n.phoneEmpty : null,
                                ),
                                const SizedBox(height: AppTheme.lg),

                                _sectionLabel(l10n.emailOptionalLabel),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
                                  decoration: _buildInputDecoration(l10n.branchEmailHint, Icons.email_outlined),
                                ),
                                const SizedBox(height: AppTheme.lg),

                                _sectionLabel(l10n.managerOptionalLabel),
                                const SizedBox(height: 8),
                                _employeesList.isEmpty
                                    ? Container(
                                        padding: const EdgeInsets.all(AppTheme.md),
                                        decoration: BoxDecoration(
                                          color: AppTheme.cardColor,
                                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
                                        decoration: _buildInputDecoration(l10n.selectManagerHint, Icons.badge_outlined),
                                      ),
                                const SizedBox(height: AppTheme.lg),

                                _sectionLabel(l10n.dailyCapacityLabel),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _capacityController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
                                  decoration: _buildInputDecoration(l10n.capacityHint, Icons.local_shipping_outlined),
                                  validator: (v) => v == null || v.trim().isEmpty ? l10n.capacityEmpty : null,
                                ),
                                const SizedBox(height: AppTheme.lg),

                                _sectionLabel(l10n.mapLocationLabel),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _latController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                        style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
                                        decoration: _buildInputDecoration(l10n.latitudeHint, Icons.my_location_outlined),
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.md),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _lngController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                        style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
                                        decoration: _buildInputDecoration(l10n.longitudeHint, Icons.my_location_outlined),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.lg),

                                _sectionLabel(l10n.operatingHoursLabel),
                                const SizedBox(height: 10),
                                _buildToggleCard(
                                  label: l10n.useSameHoursLabel,
                                  value: _useSameHoursForAllDays,
                                  onChanged: (v) => setState(() => _useSameHoursForAllDays = v),
                                ),
                                const SizedBox(height: AppTheme.md),

                                _useSameHoursForAllDays
                                    ? _buildHourPickerRow(
                                        label: l10n.everyDayLabel,
                                        openValue: _uniformOpen,
                                        closeValue: _uniformClose,
                                        onOpenTap: () => _pickTime(
                                          initialValue: _uniformOpen,
                                          onPicked: (v) => setState(() => _uniformOpen = v),
                                        ),
                                        onCloseTap: () => _pickTime(
                                          initialValue: _uniformClose,
                                          onPicked: (v) => setState(() => _uniformClose = v),
                                        ),
                                      )
                                    : Column(
                                        children: _days.map((d) {
                                          final key = d['key']!;
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 8.0),
                                            child: _buildHourPickerRow(
                                              label: _dayLabel(l10n, key),
                                              openValue: _operatingHours[key]!['open']!,
                                              closeValue: _operatingHours[key]!['close']!,
                                              onOpenTap: () => _pickTime(
                                                initialValue: _operatingHours[key]!['open']!,
                                                onPicked: (v) => setState(() => _operatingHours[key]!['open'] = v),
                                              ),
                                              onCloseTap: () => _pickTime(
                                                initialValue: _operatingHours[key]!['close']!,
                                                onPicked: (v) => setState(() => _operatingHours[key]!['close'] = v),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                const SizedBox(height: AppTheme.lg),

                                _buildToggleCard(
                                  label: l10n.activeStatusLabel,
                                  value: _isActive,
                                  boldLabel: true,
                                  onChanged: (v) => setState(() => _isActive = v),
                                ),
                                const SizedBox(height: AppTheme.xxl),

                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _saveLaundry,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                                    ),
                                    child: Text(
                                      isEditMode ? l10n.updateBranchButton : l10n.saveBranchButton,
                                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
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

  /// Header custom (icon box + judul + tombol back), mengikuti pola persis
  /// di LaundriesListScreen._buildHeader agar kedua layar terasa satu tema.
  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final canGoBack = context.canPop();

    return Row(
      children: [
        if (canGoBack) ...[
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: AppTheme.md),
        ],
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            isEditMode ? Icons.edit_outlined : Icons.storefront_rounded,
            color: AppTheme.primaryColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditMode ? l10n.editBranchTitle : l10n.addBranchTitle,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isEditMode ? l10n.editBranchInfo : l10n.addBranchInfo,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Banner info kecil di bawah header, memakai kartu AppTheme (bukan lagi
  /// warna biru lokal) supaya senada dengan card lain di layar list.
  Widget _buildInfoBanner(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Icon(
            isEditMode ? Icons.edit_outlined : Icons.storefront_outlined,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: AppTheme.md),
          Expanded(
            child: Text(
              isEditMode ? l10n.editBranchInfo : l10n.addBranchInfo,
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
    );
  }

  /// Card toggle (switch) bergaya sama dengan card lain (shadow tipis,
  /// radius AppTheme), dipakai untuk "jam sama tiap hari" & "status aktif".
  Widget _buildToggleCard({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool boldLabel = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: boldLabel ? FontWeight.w600 : FontWeight.w400,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: AppTheme.primaryColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildHourPickerRow({
    required String label,
    required String openValue,
    required String closeValue,
    required VoidCallback onOpenTap,
    required VoidCallback onCloseTap,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textPrimary)),
        ),
        const SizedBox(width: 8.0),
        Expanded(child: _timeChip(openValue, onOpenTap)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('—', style: GoogleFonts.poppins(color: AppTheme.textTertiary)),
        ),
        Expanded(child: _timeChip(closeValue, onCloseTap)),
      ],
    );
  }

  Widget _timeChip(String value, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, color: AppTheme.textTertiary, size: 16),
            const SizedBox(width: 6),
            Text(value, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textTertiary),
      prefixIcon: Icon(icon, color: AppTheme.textTertiary, size: 20),
      filled: true,
      fillColor: AppTheme.cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: BorderSide(color: AppTheme.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: BorderSide(color: AppTheme.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
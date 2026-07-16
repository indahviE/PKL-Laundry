import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/themes/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Create / Edit Laundry (Cabang) Screen - NetWash
/// Skema data & feature gating mengikuti Blueprint §3.2.3 (Manajemen Cabang)
/// dan §3.6.3 (Feature Gating - canAddLaundry).
///
/// Dual-mode:
/// - laundryId == null  -> mode CREATE (form kosong, quota dicek sebelum simpan)
/// - laundryId != null  -> mode EDIT (data existing di-load & di-prefill,
///   quota TIDAK dicek ulang karena tidak menambah cabang baru)
class CreateLaundryScreen extends StatefulWidget {
  final String? laundryId;

  const CreateLaundryScreen({Key? key, this.laundryId}) : super(key: key);

  @override
  State<CreateLaundryScreen> createState() => _CreateLaundryScreenState();
}

class _CreateLaundryScreenState extends State<CreateLaundryScreen> {
  final _formKey = GlobalKey<FormState>();

  static const Color textBlue = Color(0xFF0288D1);
  static const Color primaryBlue = Color(0xFF8ED8F5);

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
  Future<bool> _checkLaundryLimit(String userId) async {
    final firestore = FirebaseFirestore.instance;

    final subSnap = await firestore
        .collection('users')
        .doc(userId)
        .collection('subscriptions')
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (subSnap.docs.isEmpty) {
      // Tidak ada langganan aktif → default ke batasan Starter (maks 1 cabang)
      final currentCount = await _getCurrentLaundryCount(userId);
      return currentCount < 1;
    }

    final subData = subSnap.docs.first.data();
    final Map<String, dynamic> limits =
        (subData['limits'] as Map<String, dynamic>?) ?? const {'max_laundries': 1};
    final int maxLaundries = (limits['max_laundries'] as num?)?.toInt() ?? 1;

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

    final picked = await showTimePicker(context: context, initialTime: initial);
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
        final isQuotaAvailable = await _checkLaundryLimit(currentUserId);
        if (!isQuotaAvailable) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (ctx) {
                final dialogL10n = AppLocalizations.of(ctx)!;
                return AlertDialog(
                  title: Text(dialogL10n.quotaReachedTitle),
                  content: Text(dialogL10n.quotaReachedContent),
                  actions: [
                    TextButton(
                      onPressed: () => ctx.pop(),
                      child: Text(dialogL10n.cancel, style: const TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: textBlue),
                      onPressed: () {
                        ctx.pop();
                        context.push('/settings/subscription');
                      },
                      child: Text(dialogL10n.upgradePlanButton, style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                );
              },
            );
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
            backgroundColor: const Color(0xFF27AE60),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FB),
      appBar: AppBar(
        title: Text(
          isEditMode ? l10n.editBranchTitle : l10n.addBranchTitle,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: DefaultTextStyle.merge(
        style: GoogleFonts.plusJakartaSans(),
        child: (_isLoading || _isLoadingInitialData)
            ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(textBlue)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.md),
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isEditMode ? Icons.edit_outlined : Icons.storefront_outlined,
                              color: textBlue,
                              size: 20,
                            ),
                            const SizedBox(width: AppTheme.md),
                            Expanded(
                              child: Text(
                                isEditMode ? l10n.editBranchInfo : l10n.addBranchInfo,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.xl),

                      _sectionLabel(l10n.ownerCompanyLabel),
                      const SizedBox(height: 6),
                      _companiesList.isEmpty
                          ? TextButton(
                              onPressed: () => context.push('/companies/create'),
                              child: Text(l10n.registerCompanyFirst, style: const TextStyle(color: textBlue, fontSize: 13)),
                            )
                          : DropdownButtonFormField<String>(
                              value: _companiesList.any((c) => c['id'] == _selectedCompanyId) ? _selectedCompanyId : null,
                              items: _companiesList.map((c) {
                                return DropdownMenuItem<String>(
                                  value: c['id'],
                                  child: Text(c['name'], style: const TextStyle(fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedCompanyId = val),
                              decoration: _buildInputDecoration(l10n.selectCompanyHint, Icons.apartment_outlined),
                              validator: (v) => v == null ? l10n.companyRequiredValidator : null,
                            ),
                      const SizedBox(height: AppTheme.lg),

                      _sectionLabel(l10n.branchNameLabel),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _buildInputDecoration(l10n.branchNameHint, Icons.storefront_outlined),
                        validator: (v) => v == null || v.trim().isEmpty ? l10n.branchNameEmpty : null,
                      ),
                      const SizedBox(height: AppTheme.lg),

                      _sectionLabel(l10n.branchCodeLabel),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: _buildInputDecoration(l10n.branchCodeHint, Icons.qr_code_outlined),
                        validator: (v) => v == null || v.trim().isEmpty ? l10n.branchCodeEmpty : null,
                      ),
                      const SizedBox(height: AppTheme.lg),

                      _sectionLabel(l10n.addressLabel),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: _buildInputDecoration(l10n.addressHint, Icons.location_on_outlined),
                        validator: (v) => v == null || v.trim().isEmpty ? l10n.addressEmpty : null,
                      ),
                      const SizedBox(height: AppTheme.lg),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionLabel(l10n.cityLabel),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _cityController,
                                  textCapitalization: TextCapitalization.words,
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
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _provinceController,
                                  textCapitalization: TextCapitalization.words,
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
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _buildInputDecoration(l10n.branchPhoneHint, Icons.phone_outlined),
                        validator: (v) => v == null || v.trim().isEmpty ? l10n.phoneEmpty : null,
                      ),
                      const SizedBox(height: AppTheme.lg),

                      _sectionLabel(l10n.emailOptionalLabel),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _buildInputDecoration(l10n.branchEmailHint, Icons.email_outlined),
                      ),
                      const SizedBox(height: AppTheme.lg),

                      _sectionLabel(l10n.managerOptionalLabel),
                      const SizedBox(height: 6),
                      _employeesList.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(AppTheme.md),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Text(
                                l10n.noEmployeeDataInfo,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            )
                          : DropdownButtonFormField<String>(
                              value: _employeesList.any((e) => e['id'] == _selectedManagerId) ? _selectedManagerId : null,
                              items: _employeesList.map((e) {
                                return DropdownMenuItem<String>(
                                  value: e['id'],
                                  child: Text(e['name'], style: const TextStyle(fontSize: 13)),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedManagerId = val),
                              decoration: _buildInputDecoration(l10n.selectManagerHint, Icons.badge_outlined),
                            ),
                      const SizedBox(height: AppTheme.lg),

                      _sectionLabel(l10n.dailyCapacityLabel),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _capacityController,
                        keyboardType: TextInputType.number,
                        decoration: _buildInputDecoration(l10n.capacityHint, Icons.local_shipping_outlined),
                        validator: (v) => v == null || v.trim().isEmpty ? l10n.capacityEmpty : null,
                      ),
                      const SizedBox(height: AppTheme.lg),

                      _sectionLabel(l10n.mapLocationLabel),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: _buildInputDecoration(l10n.latitudeHint, Icons.my_location_outlined),
                            ),
                          ),
                          const SizedBox(width: AppTheme.md),
                          Expanded(
                            child: TextFormField(
                              controller: _lngController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: _buildInputDecoration(l10n.longitudeHint, Icons.my_location_outlined),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.lg),

                      _sectionLabel(l10n.operatingHoursLabel),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(l10n.useSameHoursLabel, style: const TextStyle(fontSize: 13)),
                            ),
                            Switch.adaptive(
                              value: _useSameHoursForAllDays,
                              activeColor: textBlue,
                              onChanged: (v) => setState(() => _useSameHoursForAllDays = v),
                            ),
                          ],
                        ),
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

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l10n.activeStatusLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                            Switch.adaptive(
                              value: _isActive,
                              activeColor: textBlue,
                              onChanged: (val) => setState(() => _isActive = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.xxl),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _saveLaundry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: textBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                            elevation: 0,
                          ),
                          child: Text(
                            isEditMode ? l10n.updateBranchButton : l10n.saveBranchButton,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87));
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
        SizedBox(width: 64, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87))),
        const SizedBox(width: 8.0),
        Expanded(child: _timeChip(openValue, onOpenTap)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text('—', style: TextStyle(color: Colors.grey)),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time, color: Colors.grey, size: 16),
            const SizedBox(width: 6),
            Text(value, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: Colors.grey, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: const BorderSide(color: textBlue, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: const BorderSide(color: Colors.redAccent)),
    );
  }
}
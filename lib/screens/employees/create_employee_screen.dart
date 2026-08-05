import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/themes/app_theme.dart';
import '../../repositories/subscription_repository.dart';
import '../../l10n/app_localizations.dart';

/// Local design tokens matching the new "NetWash Utility System" design
/// (samain persis dengan CreateServiceScreen: canvas abu kebiruan, kartu
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

  static TextStyle subtitleMd({Color? color}) => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color ?? onSurfaceVariant,
      );

  static TextStyle bodyMd({Color? color, FontWeight? weight}) => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: weight ?? FontWeight.w400,
        color: color ?? onSurface,
      );

  static TextStyle bodySm({Color? color, FontWeight? weight}) => GoogleFonts.beVietnamPro(
        fontSize: 13,
        fontWeight: weight ?? FontWeight.w400,
        color: color ?? onSurfaceVariant,
      );

  static TextStyle labelBold({Color? color}) => GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color ?? onSurfaceVariant,
        letterSpacing: 0.3,
      );
}

/// Create / Edit Employee Screen - NetWash
/// Dilengkapi dengan Feature Gating kuota karyawan berdasarkan paket langganan aktif.
///
/// Sekarang mendukung mode edit: kirim `employeeId` untuk membuka layar ini
/// dalam mode edit (data existing akan di-load & disimpan lewat update),
/// sama seperti pola CreateLaundryScreen yang dipakai `/laundries/:id/edit`.
///
/// UI di-restyle total mengikuti tema baru "NetWash Utility System" (samain
/// persis dengan CreateServiceScreen: _DS design tokens) - logic form,
/// fetch data, validasi kuota, dan save TIDAK berubah sama sekali.
class CreateEmployeeScreen extends ConsumerStatefulWidget {
  final String? employeeId;

  const CreateEmployeeScreen({Key? key, this.employeeId}) : super(key: key);

  @override
  ConsumerState<CreateEmployeeScreen> createState() => _CreateEmployeeScreenState();
}

class _CreateEmployeeScreenState extends ConsumerState<CreateEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();

  // Pilihan jabatan standar sesuai mockup (dropdown, bukan free text lagi).
  // Kalau data existing (mode edit) punya posisi custom yang tidak ada di
  // daftar ini, posisi itu tetap ditambahkan sebagai item tambahan di
  // dropdown supaya datanya tidak hilang/ke-reset.
  static const List<String> _positionOptions = [
  'Manajer',
  'Kasir',
  'Operator Cuci',
  'Operator Pengering',
  'Operator Setrika',
  'Quality Control',
  'Kurir',
  'Staff Gudang',
];

  // Controller input form
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _employeeCodeController = TextEditingController();
  final _positionController = TextEditingController();
  final _salaryController = TextEditingController();
  final _commissionController = TextEditingController();

  String? _selectedLaundryId;
  String? _selectedProfileId;
  DateTime _hireDate = DateTime.now();
  bool _isActive = true;
  bool _isLoading = false;

  // true saat data existing sedang di-fetch untuk mode edit
  bool _isFetchingEmployee = false;

  // List Cabang Laundry dari Firestore
  List<Map<String, dynamic>> _laundriesList = [];

  // Hak Akses (Permissions) sesuai Spesifikasi Blueprint
  bool _canCreateOrder = true;
  bool _canManageCustomer = true;
  bool _canViewReport = false;

  bool get _isEditMode => widget.employeeId != null;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _employeeCodeController.dispose();
    _positionController.dispose();
    _salaryController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  /// Urutan init: ambil daftar cabang dulu, baru (jika mode edit) ambil data
  /// karyawan existing - supaya dropdown cabang sudah terisi saat value di-set.
  Future<void> _initData() async {
    await _fetchLaundriesData();
    if (_isEditMode) {
      await _fetchEmployeeData();
    }
  }

  /// Mengambil data cabang laundry terdaftar milik user
  Future<void> _fetchLaundriesData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final laundrySnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('laundries')
          .where('is_active', isEqualTo: true)
          .get();

      setState(() {
        _laundriesList = laundrySnap.docs.map((doc) => {
          'id': doc.id,
          'name': doc.data()['name'] ?? AppLocalizations.of(context)!.unnamedBranchFallback,
          // company_id ikut disertakan agar saat karyawan disimpan,
          // company_id konsisten dengan cabang yang dipilih
          // (relasi laundries.company_id sesuai Blueprint §3.2.3)
          'company_id': doc.data()['company_id'],
        }).toList();

        if (_laundriesList.isNotEmpty && _selectedLaundryId == null) {
          _selectedLaundryId = _laundriesList.first['id'];
        }
      });
    } catch (e) {
      debugPrint("Gagal memuat data cabang: $e");
    }
  }

  /// Mode edit: ambil dokumen karyawan existing lalu isi seluruh form
  /// dengan data tersebut, sama seperti CreateLaundryScreen mem-prefill
  /// form-nya saat dibuka lewat `/laundries/:id/edit`.
  Future<void> _fetchEmployeeData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isFetchingEmployee = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('employees')
          .doc(widget.employeeId)
          .get();

      if (!doc.exists || doc.data() == null) {
        if (mounted) {
          _showSnack(AppLocalizations.of(context)!.employeeNotFoundError, isError: false, isWarning: true);
          context.pop();
        }
        return;
      }

      final data = doc.data()!;
      final permissions = (data['permissions'] as Map<String, dynamic>?) ?? {};
      final hireDateRaw = data['hire_date'];

      setState(() {
        _fullNameController.text = (data['full_name'] as String?) ?? '';
        _phoneController.text = (data['phone'] as String?) ?? '';
        _emailController.text = (data['email'] as String?) ?? '';
        _addressController.text = (data['address'] as String?) ?? '';
        _employeeCodeController.text = (data['employee_code'] as String?) ?? '';
        _positionController.text = (data['position'] as String?) ?? '';
        _salaryController.text = ((data['salary'] as num?) ?? 0).toString();
        _commissionController.text = ((data['commission_rate'] as num?) ?? 0).toString();
        _selectedLaundryId = (data['laundry_id'] as String?) ?? _selectedLaundryId;
        _selectedProfileId = data['profile_id'] as String?;
        _isActive = (data['is_active'] as bool?) ?? true;
        _canCreateOrder = (permissions['can_create_order'] as bool?) ?? true;
        _canManageCustomer = (permissions['can_manage_customer'] as bool?) ?? true;
        _canViewReport = (permissions['can_view_report'] as bool?) ?? false;
        _hireDate = _parseHireDate(hireDateRaw) ?? _hireDate;
      });
    } catch (e) {
      if (mounted) {
        _showSnack(AppLocalizations.of(context)!.employeeLoadError(e.toString()), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isFetchingEmployee = false);
    }
  }

  DateTime? _parseHireDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  /// FEATURE GATING: Validasi sisa kuota karyawan berdasarkan plan aktif.
  /// Hanya relevan saat menambah karyawan baru - saat edit, jumlah karyawan
  /// tidak bertambah sehingga pengecekan kuota dilewati.
  ///
  /// FIX: sebelumnya query manual `.where('status','active').limit(1)`
  /// tanpa sorting bisa mengambil dokumen subscription yang SALAH kalau ada
  /// lebih dari satu dokumen berstatus 'active' untuk company yang sama
  /// (mis. sisa dokumen lama yang belum di-nonaktifkan saat upgrade paket).
  /// Sekarang pakai SubscriptionRepository.streamActiveSubscription(), yang
  /// sudah mengurutkan berdasarkan createdAt descending dan selalu memilih
  /// dokumen aktif/trialing yang PALING BARU.
  Future<bool> _checkEmployeeLimit(String userId, String companyId) async {
    final subscriptionRepo = ref.read(subscriptionRepositoryProvider);
    final activeSubscription =
        await subscriptionRepo.streamActiveSubscription(companyId).first;

    if (activeSubscription == null) {
      // Jika tidak ada data langganan, default kembali ke batasan Starter (maks 5)
      final currentCount = await _getCurrentEmployeeCount(userId);
      return currentCount < 5;
    }

    // Sesuai Blueprint §3.6.3 (SubscriptionService.canAddEmployee):
    // batas kuota dibaca langsung dari `limits.max_employees` pada
    // dokumen subscription, BUKAN hardcode per plan_id.
    // Nilai -1 pada limits berarti unlimited (khusus paket Enterprise).
    final int maxEmployees = activeSubscription.limits.maxEmployees;
    if (maxEmployees == -1) return true; // Unlimited

    final currentCount = await _getCurrentEmployeeCount(userId);
    return currentCount < maxEmployees;
  }

  /// Helper hitung total dokumen karyawan dengan agregasi hemat cost
  Future<int> _getCurrentEmployeeCount(String userId) async {
    final employeeCountSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('employees')
        .count()
        .get();
    return employeeCountSnap.count ?? 0;
  }

  /// Menyimpan data karyawan ke Firestore - membuat dokumen baru saat mode
  /// tambah, atau meng-update dokumen existing saat mode edit (tanpa
  /// mengecek kuota lagi & tanpa menimpa created_at).
  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLaundryId == null) {
      _showSnack(AppLocalizations.of(context)!.branchNotSelectedWarning, isWarning: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception(AppLocalizations.of(context)!.sessionExpiredError);

      final currentUserId = user.uid;

      // Ambil company_id dari CABANG yang dipilih (relasi laundries.company_id
      // sesuai Blueprint §3.2.3), bukan mengambil perusahaan pertama secara acak.
      // Ini harus dilakukan SEBELUM pengecekan kuota, karena kuota sekarang
      // dibaca per-company lewat SubscriptionRepository (lihat _checkEmployeeLimit).
      final selectedLaundry = _laundriesList.firstWhere(
        (l) => l['id'] == _selectedLaundryId,
        orElse: () => {},
      );
      final String? companyIdRef = selectedLaundry['company_id'] as String?;

      if (companyIdRef == null || companyIdRef.isEmpty) {
        if (mounted) {
          _showSnack(
            AppLocalizations.of(context)!.branchNotLinkedWarning,
            isWarning: true,
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      // Pengecekan limitasi paket hanya berlaku saat menambah karyawan baru
      if (!_isEditMode) {
        final isQuotaAvailable = await _checkEmployeeLimit(currentUserId, companyIdRef);
        if (!isQuotaAvailable) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(AppLocalizations.of(context)!.quotaLimitReachedTitle, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700)),
                content: Text(
                  AppLocalizations.of(context)!.quotaLimitReachedContent,
                  style: GoogleFonts.beVietnamPro(fontSize: 13, color: _DS.onSurfaceVariant),
                ),
                actions: [
                  TextButton(
                    onPressed: () => ctx.pop(),
                    child: Text(AppLocalizations.of(context)!.cancel, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, color: _DS.onSurfaceVariant)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _DS.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      ctx.pop();
                      context.push('/settings/subscription');
                    },
                    child: Text(AppLocalizations.of(context)!.upgradePlanButton, style: GoogleFonts.beVietnamPro(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      final employeesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('employees');

      // Mapping data model presisi sesuai skema Blueprint §3.3.2 & Lampiran A
      final Map<String, dynamic> employeeData = {
        'profile_id': _selectedProfileId ?? currentUserId,
        'laundry_id': _selectedLaundryId,
        'company_id': companyIdRef,
        'employee_code': _employeeCodeController.text.trim().toUpperCase(),
        // full_name bukan bagian eksplisit skema `employees` di blueprint
        // (blueprint mereferensikan nama lewat profile_id), namun disertakan
        // di sini agar data karyawan tetap mudah diidentifikasi di UI.
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'position': _positionController.text.trim(),
        'salary': double.tryParse(_salaryController.text.trim()) ?? 0.0,
        'commission_rate': double.tryParse(_commissionController.text.trim()) ?? 0.0,
        'hire_date':
            '${_hireDate.year.toString().padLeft(4, '0')}-${_hireDate.month.toString().padLeft(2, '0')}-${_hireDate.day.toString().padLeft(2, '0')}',
        'is_active': _isActive,
        'permissions': {
          'can_create_order': _canCreateOrder,
          'can_manage_customer': _canManageCustomer,
          'can_view_report': _canViewReport,
        },
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (_isEditMode) {
        // Update dokumen existing - created_at & termination_date tidak disentuh
        // supaya riwayat lama tetap konsisten (selaras dengan
        // EmployeeRepository.updateEmployee).
        await employeesRef.doc(widget.employeeId).update(employeeData);
      } else {
        employeeData['termination_date'] = null;
        employeeData['created_at'] = FieldValue.serverTimestamp();
        await employeesRef.doc().set(employeeData);
      }

      if (mounted) {
        _showSnack(
          _isEditMode ? AppLocalizations.of(context)!.employeeUpdateSuccess : AppLocalizations.of(context)!.employeeAddSuccess,
          isSuccess: true,
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        _showSnack(AppLocalizations.of(context)!.employeeSaveError(e.toString()), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Dialog konfirmasi soft-terminate langsung dari layar edit, sesuai
  /// link "Nonaktifkan Karyawan" pada mockup - konsisten dengan
  /// EmployeeRepository.terminateEmployee (set is_active: false +
  /// termination_date, dokumen tidak dihapus).
  Future<void> _confirmTerminate() async {
    if (widget.employeeId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context)!.deactivateEmployeeTitle, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700)),
        content: Text(
          AppLocalizations.of(context)!.deactivateEmployeeConfirm,
          style: GoogleFonts.beVietnamPro(fontSize: 13, color: _DS.onSurfaceVariant),
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: Text(AppLocalizations.of(context)!.cancel, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, color: _DS.onSurfaceVariant))),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: Text(AppLocalizations.of(context)!.yesDeactivateButton, style: GoogleFonts.beVietnamPro(color: _DS.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('employees')
          .doc(widget.employeeId)
          .update({
        'is_active': false,
        'termination_date': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _showSnack(AppLocalizations.of(context)!.employeeDeactivatedSuccess, isWarning: true);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        _showSnack(AppLocalizations.of(context)!.employeeDeactivateError(e.toString()), isError: true);
      }
    }
  }

  void _showSnack(String message, {bool isError = false, bool isWarning = false, bool isSuccess = false}) {
    final color = isError
        ? _DS.error
        : isWarning
            ? const Color(0xFFE8590C)
            : isSuccess
                ? const Color(0xFF51CF66)
                : null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.beVietnamPro()),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DS.canvas,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: (_isLoading || _isFetchingEmployee)
                    ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: _DS.primary))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 500),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildInfoBanner(),
                                        const SizedBox(height: AppTheme.xl),
                                        _buildPersonalDataCard(),
                                        const SizedBox(height: AppTheme.xl),
                                        _buildAssignmentCard(),
                                        const SizedBox(height: AppTheme.xl),
                                        _buildAccessStatusToggle(),
                                        const SizedBox(height: AppTheme.md),
                                        _buildActiveStatusToggle(),
                                        const SizedBox(height: AppTheme.xl),
                                        Row(
                                          children: [
                                            Expanded(child: Divider(color: _DS.outlineVariant)),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: Text(
                                                AppLocalizations.of(context)!.additionalDetailsDivider,
                                                style: _DS.labelBold(),
                                              ),
                                            ),
                                            Expanded(child: Divider(color: _DS.outlineVariant)),
                                          ],
                                        ),
                                        const SizedBox(height: AppTheme.lg),
                                        _buildPayrollCard(),
                                        const SizedBox(height: AppTheme.xl),
                                        _buildPermissionsCard(),
                                        const SizedBox(height: AppTheme.xxl),
                                        if (_isEditMode && _isActive) _buildTerminateButton(),
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
              _buildSaveBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Top bar - samain persis pola CreateServiceScreen (back button bulat,
  // judul, warna primary), ditambah ikon "tambah karyawan baru" di kanan.
  // ---------------------------------------------------------------------
  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: _DS.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
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
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isEditMode ? AppLocalizations.of(context)!.editEmployeeTitle : AppLocalizations.of(context)!.addEmployeeTitle,
              style: _DS.headlineMd(color: _DS.primary),
            ),
          ),
          InkWell(
            onTap: () => context.push('/employees/create'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _DS.primaryFixed.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_add_alt_1_rounded, color: _DS.primary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Banner info - restyle dari kotak biru lama jadi versi _DS.primaryFixed,
  // konten pesan sama persis (kuota kalau tambah, info edit kalau edit).
  // ---------------------------------------------------------------------
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _DS.primaryFixed.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.badge_outlined, color: _DS.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isEditMode
                  ? AppLocalizations.of(context)!.editEmployeeInfoBanner
                  : AppLocalizations.of(context)!.addEmployeeInfoBanner,
              style: _DS.bodySm(color: _DS.onSurfaceVariant).copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Card: Data Pribadi (Nama, Telepon, Email, Alamat)
  // ---------------------------------------------------------------------
  Widget _buildPersonalDataCard() {
    return _sectionCard([
      _sectionColumn(
        label: AppLocalizations.of(context)!.fullNameLabel,
        child: TextFormField(
          controller: _fullNameController,
          textCapitalization: TextCapitalization.words,
          style: _DS.bodyMd(),
          decoration: _inputDecoration(hintText: AppLocalizations.of(context)!.fullNameHint, prefixIcon: Icons.person_outline),
          validator: (v) => v == null || v.trim().isEmpty ? AppLocalizations.of(context)!.employeeNameRequiredError : null,
        ),
      ),
      const SizedBox(height: AppTheme.lg),
      _sectionColumn(
        label: AppLocalizations.of(context)!.phoneNumberLabel,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _DS.canvas,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _DS.outlineVariant),
              ),
              child: Text('+62', style: _DS.bodyMd(weight: FontWeight.w600)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: _DS.bodyMd(),
                decoration: _inputDecoration(hintText: '8123456789', prefixIcon: Icons.phone_outlined),
                validator: (v) => v == null || v.trim().isEmpty ? AppLocalizations.of(context)!.phoneNumberRequiredError : null,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppTheme.lg),
      _sectionColumn(
        label: AppLocalizations.of(context)!.emailOptionalLabel,
        child: TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: _DS.bodyMd(),
          decoration: _inputDecoration(hintText: 'budi@netwash.com', prefixIcon: Icons.email_outlined),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null; // opsional
            final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$');
            return emailRegex.hasMatch(v.trim()) ? null : AppLocalizations.of(context)!.invalidEmailFormatError;
          },
        ),
      ),
      const SizedBox(height: AppTheme.lg),
      _sectionColumn(
        label: AppLocalizations.of(context)!.addressLabel,
        child: TextFormField(
          controller: _addressController,
          maxLines: 3,
          style: _DS.bodyMd(),
          decoration: _inputDecoration(hintText: AppLocalizations.of(context)!.addressHint, prefixIcon: Icons.home_outlined),
        ),
      ),
    ]);
  }

  // ---------------------------------------------------------------------
  // Card: Penempatan (Role, Cabang, Tanggal Bergabung)
  // ---------------------------------------------------------------------
  Widget _buildAssignmentCard() {
    return _sectionCard([
      _sectionColumn(
        label: AppLocalizations.of(context)!.roleLabel,
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          value: _positionController.text.isEmpty ? null : _positionController.text,
          items: [
            ..._positionOptions.map(
              (p) => DropdownMenuItem<String>(value: p, child: Text(p, style: _DS.bodyMd())),
            ),
            if (_positionController.text.isNotEmpty && !_positionOptions.contains(_positionController.text))
              DropdownMenuItem<String>(
                value: _positionController.text,
                child: Text(_positionController.text, style: _DS.bodyMd()),
              ),
          ],
          onChanged: (val) => setState(() => _positionController.text = val ?? ''),
          decoration: _inputDecoration(hintText: AppLocalizations.of(context)!.selectPositionHint, prefixIcon: Icons.assignment_ind_outlined),
          validator: (v) => v == null || v.isEmpty ? AppLocalizations.of(context)!.positionRequiredError : null,
        ),
      ),
      const SizedBox(height: AppTheme.lg),
      _sectionColumn(
        label: AppLocalizations.of(context)!.assignedBranchLabel,
        child: _laundriesList.isEmpty
            ? TextButton(
                onPressed: () => context.push('/laundries/create'),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                child: Text(
                  AppLocalizations.of(context)!.registerNewBranchFirstButton,
                  style: _DS.bodySm(color: _DS.primary, weight: FontWeight.w600),
                ),
              )
            : DropdownButtonFormField<String>(
                // isExpanded:true supaya field ikut lebar penuh dan nama
                // cabang yang panjang di-ellipsis, bukan overflow di
                // belakang ikon panah dropdown.
                isExpanded: true,
                value: _laundriesList.any((element) => element['id'] == _selectedLaundryId)
                    ? _selectedLaundryId
                    : null,
                items: _laundriesList.map((laundry) {
                  return DropdownMenuItem<String>(
                    value: laundry['id'],
                    child: Text(
                      laundry['name'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _DS.bodyMd(),
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedLaundryId = val),
                decoration: _inputDecoration(hintText: AppLocalizations.of(context)!.selectBranchHint, prefixIcon: Icons.storefront_outlined),
                validator: (v) => v == null ? AppLocalizations.of(context)!.branchRequiredError : null,
              ),
      ),
      const SizedBox(height: AppTheme.lg),
      _sectionColumn(
        label: AppLocalizations.of(context)!.hireDateLabel,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _hireDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => _hireDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: _DS.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _DS.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, color: _DS.outline, size: 20),
                const SizedBox(width: 12),
                Text(
                  '${_hireDate.day.toString().padLeft(2, '0')}/${_hireDate.month.toString().padLeft(2, '0')}/${_hireDate.year.toString().padLeft(4, '0')}',
                  style: _DS.bodyMd(),
                ),
              ],
            ),
          ),
        ),
      ),
    ]);
  }

  // ---------------------------------------------------------------------
  // Toggle: Akses Aplikasi & Status Karyawan - restyle mengikuti
  // _buildStatusToggle di CreateServiceScreen (kartu putih + Switch primary).
  // Keduanya sengaja tetap di-bind ke _isActive yang sama, sesuai keputusan
  // sebelumnya (tidak dipisah jadi field `canLogin` baru).
  // ---------------------------------------------------------------------
  Widget _buildAccessStatusToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _DS.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.appAccessTitle, style: _DS.subtitleMd(color: _DS.onSurface)),
                const SizedBox(height: 2),
                Text(AppLocalizations.of(context)!.appAccessSubtitle, style: _DS.bodySm()),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (val) => setState(() => _isActive = val),
            activeColor: _DS.surface,
            activeTrackColor: _DS.primary,
            inactiveThumbColor: _DS.surface,
            inactiveTrackColor: _DS.secondaryContainer,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveStatusToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _DS.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.employeeStatusTitle, style: _DS.subtitleMd(color: _DS.onSurface)),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context)!.employeeStatusCurrent(
                    _isActive ? AppLocalizations.of(context)!.statusActive : AppLocalizations.of(context)!.statusInactive,
                  ),
                  style: _DS.bodySm(),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (val) => setState(() => _isActive = val),
            activeColor: _DS.surface,
            activeTrackColor: _DS.primary,
            inactiveThumbColor: _DS.surface,
            inactiveTrackColor: _DS.secondaryContainer,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Card: Payroll (Kode Karyawan, Gaji, Komisi)
  // ---------------------------------------------------------------------
  Widget _buildPayrollCard() {
    return _sectionCard([
      _sectionColumn(
        label: AppLocalizations.of(context)!.employeeCodeLabel,
        child: TextFormField(
          controller: _employeeCodeController,
          textCapitalization: TextCapitalization.characters,
          style: _DS.bodyMd(),
          decoration: _inputDecoration(hintText: AppLocalizations.of(context)!.employeeCodeHint, prefixIcon: Icons.vpn_key_outlined),
          validator: (v) => v == null || v.trim().isEmpty ? AppLocalizations.of(context)!.employeeCodeRequiredError : null,
        ),
      ),
      const SizedBox(height: AppTheme.lg),
      _sectionColumn(
        label: AppLocalizations.of(context)!.baseSalaryLabel,
        child: TextFormField(
          controller: _salaryController,
          keyboardType: TextInputType.number,
          style: _DS.bodyMd(),
          decoration: _inputDecoration(hintText: '0', prefixText: 'Rp '),
          validator: (v) => v == null || v.trim().isEmpty ? AppLocalizations.of(context)!.baseSalaryRequiredError : null,
        ),
      ),
      const SizedBox(height: AppTheme.lg),
      _sectionColumn(
        label: AppLocalizations.of(context)!.commissionPerTransactionLabel,
        child: TextFormField(
          controller: _commissionController,
          keyboardType: TextInputType.number,
          style: _DS.bodyMd(),
          decoration: _inputDecoration(hintText: AppLocalizations.of(context)!.commissionHint),
        ),
      ),
    ]);
  }

  // ---------------------------------------------------------------------
  // Card: Hak Akses Fitur Karyawan (Permissions)
  // ---------------------------------------------------------------------
  Widget _buildPermissionsCard() {
    return _sectionCard([
      Text(AppLocalizations.of(context)!.employeePermissionsTitle, style: _DS.subtitleMd(color: _DS.onSurface)),
      const SizedBox(height: 2),
      Text(AppLocalizations.of(context)!.employeePermissionsSubtitle, style: _DS.bodySm()),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(
          color: _DS.canvas,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _DS.outlineVariant),
        ),
        child: Column(
          children: [
            _permissionTile(
              title: AppLocalizations.of(context)!.canCreateOrderPermission,
              value: _canCreateOrder,
              onChanged: (v) => setState(() => _canCreateOrder = v ?? false),
            ),
            Divider(height: 1, color: _DS.outlineVariant),
            _permissionTile(
              title: AppLocalizations.of(context)!.canManageCustomerPermission,
              value: _canManageCustomer,
              onChanged: (v) => setState(() => _canManageCustomer = v ?? false),
            ),
            Divider(height: 1, color: _DS.outlineVariant),
            _permissionTile(
              title: AppLocalizations.of(context)!.canViewReportPermission,
              value: _canViewReport,
              onChanged: (v) => setState(() => _canViewReport = v ?? false),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _permissionTile({required String title, required bool value, required ValueChanged<bool?> onChanged}) {
    return CheckboxListTile(
      title: Text(title, style: _DS.bodyMd()),
      value: value,
      activeColor: _DS.primary,
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: onChanged,
    );
  }

  // ---------------------------------------------------------------------
  // Tombol nonaktifkan karyawan (mode edit saja)
  // ---------------------------------------------------------------------
  Widget _buildTerminateButton() {
    return Center(
      child: TextButton.icon(
        onPressed: _confirmTerminate,
        icon: Icon(Icons.person_off_outlined, size: 18, color: _DS.error),
        label: Text(
          AppLocalizations.of(context)!.deactivateEmployeeTitle,
          style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w600, color: _DS.error),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Save bar (sticky bottom) - samain persis pola CreateServiceScreen
  // ---------------------------------------------------------------------
  Widget _buildSaveBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.surface,
        border: const Border(top: BorderSide(color: _DS.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: !_isLoading ? _saveEmployee : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _DS.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.7)),
                          ),
                        ),
                        const SizedBox(width: AppTheme.md),
                        Text(AppLocalizations.of(context)!.savingButton, style: _DS.headlineMd(color: Colors.white)),
                      ],
                    )
                  : Text(
                      _isEditMode ? AppLocalizations.of(context)!.saveChangesButton : AppLocalizations.of(context)!.saveEmployeeButton,
                      style: _DS.headlineMd(color: Colors.white),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Shared helpers - identik dengan CreateServiceScreen
  // ---------------------------------------------------------------------
  Widget _sectionCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _DS.cardShadow,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _sectionColumn({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _DS.subtitleMd()),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration({required String hintText, String? prefixText, IconData? prefixIcon}) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hintText,
      hintStyle: _DS.bodyMd(color: _DS.outline),
      prefixText: prefixText,
      prefixStyle: _DS.subtitleMd(),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: _DS.outline, size: 20) : null,
      filled: true,
      fillColor: _DS.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border(_DS.outlineVariant, 1),
      enabledBorder: border(_DS.outlineVariant, 1),
      focusedBorder: border(_DS.primary, 1.5),
      errorBorder: border(_DS.error, 1),
      focusedErrorBorder: border(_DS.error, 1.5),
      errorStyle: _DS.bodySm(color: _DS.error),
    );
  }
}
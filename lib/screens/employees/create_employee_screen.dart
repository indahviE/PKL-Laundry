import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/themes/app_theme.dart';
import '../../repositories/subscription_repository.dart';

/// Create / Edit Employee Screen - NetWash
/// Dilengkapi dengan Feature Gating kuota karyawan berdasarkan paket langganan aktif.
///
/// Sekarang mendukung mode edit: kirim `employeeId` untuk membuka layar ini
/// dalam mode edit (data existing akan di-load & disimpan lewat update),
/// sama seperti pola CreateLaundryScreen yang dipakai `/laundries/:id/edit`.
class CreateEmployeeScreen extends ConsumerStatefulWidget {
  final String? employeeId;

  const CreateEmployeeScreen({Key? key, this.employeeId}) : super(key: key);

  @override
  ConsumerState<CreateEmployeeScreen> createState() => _CreateEmployeeScreenState();
}

class _CreateEmployeeScreenState extends ConsumerState<CreateEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();

  // Definisi Warna di tingkat State agar bisa diakses oleh semua fungsi dan widget
  static const Color textBlue = Color(0xFF0288D1);
  static const Color primaryBlue = Color(0xFF8ED8F5);

  // Pilihan jabatan standar sesuai mockup (dropdown, bukan free text lagi).
  // Kalau data existing (mode edit) punya posisi custom yang tidak ada di
  // daftar ini, posisi itu tetap ditambahkan sebagai item tambahan di
  // dropdown supaya datanya tidak hilang/ke-reset.
  static const List<String> _positionOptions = [
    'Manajer',
    'Kasir',
    'Operator Cuci',
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
          'name': doc.data()['name'] ?? 'Cabang Tanpa Nama',
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data karyawan tidak ditemukan.'),
              backgroundColor: Colors.orangeAccent,
            ),
          );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data karyawan: $e'), backgroundColor: Colors.redAccent),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cabang laundry belum dipilih atau belum dibuat!'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Sesi user berakhir.");

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cabang terpilih belum terhubung dengan data perusahaan. Periksa kembali data cabang.'),
              backgroundColor: Colors.orangeAccent,
            ),
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
                title: const Text('Batas Kuota Tercapai'),
                content: const Text('Jumlah karyawan Anda telah mencapai batas maksimal kuota paket langganan saat ini. Silakan upgrade paket.'),
                actions: [
                  TextButton(
                    onPressed: () => ctx.pop(),
                    child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: textBlue),
                    onPressed: () {
                      ctx.pop();
                      context.push('/settings/subscription');
                    },
                    child: const Text('Upgrade Paket', style: TextStyle(color: Colors.white)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Data karyawan berhasil diperbarui!' : 'Staf karyawan berhasil ditambahkan!'),
            backgroundColor: const Color(0xFF27AE60),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data karyawan: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Bungkus sekelompok field ke dalam kartu putih membulat dengan shadow
  /// tipis, supaya form terlihat tersegmentasi rapi seperti pada mockup
  /// (Nama/Telepon/Email/Alamat dalam satu kartu, Role/Cabang/Tanggal/Toggle
  /// pada kartu berikutnya), tanpa mengubah/menghapus field apa pun.
  Widget _sectionCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd + 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Data Karyawan' : 'Tambah Karyawan',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Ikon dekoratif di kanan AppBar sesuai mockup - konsisten dengan
          // gaya header "tambah data" di layar lain. Tap membawa ke form
          // tambah karyawan baru yang bersih (berguna saat sedang di mode
          // edit dan ingin langsung menambah karyawan lain).
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.lg),
            child: Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context.push('/employees/create'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded, color: textBlue, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
      body: DefaultTextStyle.merge(
        style: GoogleFonts.plusJakartaSans(),
        child: (_isLoading || _isFetchingEmployee)
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
                            const Icon(Icons.badge_outlined, color: textBlue, size: 20),
                            const SizedBox(width: AppTheme.md),
                            Expanded(
                              child: Text(
                                _isEditMode
                                    ? 'Perubahan akan langsung tersimpan pada data karyawan ini.'
                                    : 'Sistem akan memvalidasi limitasi kuota paket langganan Anda secara otomatis sebelum menyimpan data karyawan.',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.xl),

                      _sectionCard([
                        const Text('Nama Lengkap', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _fullNameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _buildInputDecoration('Contoh: Siti Aminah', Icons.person_outline),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Nama karyawan wajib diisi' : null,
                        ),
                        const SizedBox(height: AppTheme.lg),

                        const Text('Nomor Telepon', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: AppTheme.md),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              ),
                              child: const Text('+62', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: AppTheme.md),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: _buildInputDecoration('8123456789', Icons.phone_outlined),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Nomor telepon wajib diisi' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.lg),

                        const Text('Email (Opsional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _buildInputDecoration('budi@netwash.com', Icons.email_outlined),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null; // opsional
                            final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$');
                            return emailRegex.hasMatch(v.trim()) ? null : 'Format email tidak valid';
                          },
                        ),
                        const SizedBox(height: AppTheme.lg),

                        const Text('Alamat', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _addressController,
                          maxLines: 3,
                          decoration: _buildInputDecoration('Masukkan alamat lengkap rumah', Icons.home_outlined),
                        ),
                      ]),
                      const SizedBox(height: AppTheme.xl),

                      _sectionCard([
                        const Text('Role / Jabatan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 6),
                        // Diubah dari text field bebas ketik jadi dropdown pilihan
                        // sesuai mockup. Kalau posisi existing (mode edit) tidak ada
                        // di _positionOptions, posisi itu ditambahkan sebagai item
                        // tambahan supaya data lama tidak hilang.
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _positionController.text.isEmpty ? null : _positionController.text,
                          items: [
                            ..._positionOptions.map(
                              (p) => DropdownMenuItem<String>(value: p, child: Text(p, style: const TextStyle(fontSize: 13))),
                            ),
                            if (_positionController.text.isNotEmpty && !_positionOptions.contains(_positionController.text))
                              DropdownMenuItem<String>(
                                value: _positionController.text,
                                child: Text(_positionController.text, style: const TextStyle(fontSize: 13)),
                              ),
                          ],
                          onChanged: (val) => setState(() => _positionController.text = val ?? ''),
                          decoration: _buildInputDecoration('Pilih Jabatan', Icons.assignment_ind_outlined),
                          validator: (v) => v == null || v.isEmpty ? 'Posisi atau jabatan wajib dipilih' : null,
                        ),
                        const SizedBox(height: AppTheme.lg),

                        const Text('Cabang Bertugas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 6),
                        _laundriesList.isEmpty
                            ? TextButton(
                                onPressed: () => context.push('/laundries/create'),
                                child: const Text('+ Daftarkan Cabang Baru Terlebih Dahulu', style: TextStyle(color: textBlue, fontSize: 13)),
                              )
                            : DropdownButtonFormField<String>(
                                // isExpanded:true supaya field ikut lebar penuh dan nama
                                // cabang yang panjang di-ellipsis, bukan overflow di
                                // belakang ikon panah dropdown (bug klasik Flutter kalau
                                // isExpanded dibiarkan default false).
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
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedLaundryId = val),
                                decoration: _buildInputDecoration('Pilih Cabang', Icons.storefront_outlined),
                                validator: (v) => v == null ? 'Cabang penempatan wajib dipilih' : null,
                              ),
                        const SizedBox(height: AppTheme.lg),

                        const Text('Tanggal Bergabung', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 6),
                        InkWell(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
                            padding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 20),
                                const SizedBox(width: AppTheme.md),
                                Text(
                                  '${_hireDate.day.toString().padLeft(2, '0')}/${_hireDate.month.toString().padLeft(2, '0')}/${_hireDate.year.toString().padLeft(4, '0')}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.lg),

                        // "Akses Aplikasi" pada mockup dan "Status Karyawan" sama-sama
                        // mengontrol field is_active - sengaja tidak dipisah jadi
                        // field `canLogin` baru sesuai keputusan, jadi keduanya
                        // di-bind ke _isActive yang sama.
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Akses Aplikasi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                                    Text('Berikan akses login aplikasi', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _isActive,
                                activeColor: textBlue,
                                onChanged: (val) => setState(() => _isActive = val),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.lg),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Status Karyawan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                                    Text('Status saat ini: ${_isActive ? 'Aktif' : 'Tidak Aktif'}', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _isActive,
                                activeColor: textBlue,
                                onChanged: (val) => setState(() => _isActive = val),
                              ),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: AppTheme.xl),
                      Divider(color: Colors.grey.shade200),
                      const SizedBox(height: 6),
                      Text(
                        'Detail Tambahan (gaji, kode, hak akses)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: AppTheme.lg),

                      _sectionCard([
                        const Text('Kode Karyawan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _employeeCodeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: _buildInputDecoration('Contoh: EMP01, KSR02', Icons.vpn_key_outlined),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Kode karyawan tidak boleh kosong' : null,
                        ),
                        const SizedBox(height: AppTheme.lg),

                        const Text('Gaji Pokok (IDR)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _salaryController,
                          keyboardType: TextInputType.number,
                          decoration: _buildInputDecoration('Contoh: 3000000', Icons.payments_outlined),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Gaji pokok wajib diisi' : null,
                        ),
                        const SizedBox(height: AppTheme.lg),

                        const Text('Komisi per Transaksi (%)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _commissionController,
                          keyboardType: TextInputType.number,
                          decoration: _buildInputDecoration('Contoh: 5.0', Icons.add_chart_outlined),
                        ),
                        const SizedBox(height: AppTheme.lg),

                        const Text('Hak Akses Fitur Karyawan (Permissions)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              CheckboxListTile(
                                title: const Text('Dapat Membuat Pesanan (Order)', style: TextStyle(fontSize: 13)),
                                value: _canCreateOrder,
                                activeColor: textBlue,
                                onChanged: (v) => setState(() => _canCreateOrder = v ?? false),
                              ),
                              Divider(height: 1, color: Colors.grey.shade200),
                              CheckboxListTile(
                                title: const Text('Dapat Mengelola Data Pelanggan', style: TextStyle(fontSize: 13)),
                                value: _canManageCustomer,
                                activeColor: textBlue,
                                onChanged: (v) => setState(() => _canManageCustomer = v ?? false),
                              ),
                              Divider(height: 1, color: Colors.grey.shade200),
                              CheckboxListTile(
                                title: const Text('Dapat Melihat Laporan Keuangan (Report)', style: TextStyle(fontSize: 13)),
                                value: _canViewReport,
                                activeColor: textBlue,
                                onChanged: (v) => setState(() => _canViewReport = v ?? false),
                              ),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: AppTheme.xxl),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _saveEmployee,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: textBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: Text(
                            _isEditMode ? 'Simpan Perubahan' : 'Simpan Karyawan',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      if (_isEditMode && _isActive) ...[
                        const SizedBox(height: AppTheme.md),
                        Center(
                          child: TextButton.icon(
                            onPressed: _confirmTerminate,
                            icon: const Icon(Icons.person_off_outlined, size: 18, color: Colors.redAccent),
                            label: const Text(
                              'Nonaktifkan Karyawan',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.redAccent),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
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
        title: const Text('Nonaktifkan Karyawan'),
        content: const Text('Apakah Anda yakin ingin menonaktifkan karyawan ini? Riwayat transaksi lama akan tetap aman.'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: const Text('Ya, Nonaktifkan', style: TextStyle(color: Colors.redAccent)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Karyawan telah dinonaktifkan.'), backgroundColor: Colors.orangeAccent),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menonaktifkan karyawan: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
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
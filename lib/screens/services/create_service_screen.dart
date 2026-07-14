import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/themes/app_theme.dart';
import '../../models/service.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/service_repository.dart';
import '../../widgets/common/app_input.dart';

class CreateServiceScreen extends ConsumerStatefulWidget {
  const CreateServiceScreen({super.key});

  @override
  ConsumerState<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends ConsumerState<CreateServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;

  PricingType _selectedPricingType = PricingType.perKg;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _durationController = TextEditingController(text: '24');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // FIX: authStateProvider berbasis Stream (authStateChanges), sehingga
      // ref.read(...).value bisa sesaat null saat token sedang refresh /
      // provider baru rebuild (race condition), walau user sebenarnya masih
      // login. FirebaseAuth.instance.currentUser bersifat sinkron dan selalu
      // mencerminkan sesi login terkini, jadi lebih aman dipakai di sini.
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      if (userId.isEmpty) {
        throw Exception('Sesi pengguna tidak ditemukan. Silakan login kembali.');
      }

      // Sesuai blueprint: setiap dokumen di users/{user_id}/service_types/
      // wajib memiliki company_id (lihat 3.3.3 Manajemen Jenis Layanan).
      // Karena MVP mengasumsikan 1 user = 1 company (alur onboarding
      // setup_company_screen), company_id diambil dari
      // users/{user_id}/companies/{company_id} yang pertama dibuat.
      final companySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('companies')
          .limit(1)
          .get();

      if (companySnapshot.docs.isEmpty) {
        throw Exception(
          'Perusahaan belum dibuat. Selesaikan proses onboarding (setup perusahaan) terlebih dahulu.',
        );
      }

      final companyId = companySnapshot.docs.first.id;

      final serviceRepository = ServiceRepository(userId: userId);
      final priceValue = double.parse(_priceController.text.trim());

      final newService = Service(
        id: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: companyId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        pricingType: _selectedPricingType,
        pricePerKg: _selectedPricingType == PricingType.perKg ? priceValue : null,
        pricePerItem: _selectedPricingType == PricingType.perItem ? priceValue : null,
        estimatedDuration: int.parse(_durationController.text.trim()),
        isActive: true,
        sortOrder: 0,
      );

      await serviceRepository.addService(newService);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Layanan berhasil ditambahkan!'),
            backgroundColor: Color(0xFF51CF66),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan layanan: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 800;
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 16 : 24,
                        isMobile ? 16 : 24,
                        isMobile ? 16 : 24,
                        24,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTopBar(context),
                            const SizedBox(height: AppTheme.xl),
                            _buildHeader(context),
                            const SizedBox(height: AppTheme.xxl),
                            _buildForm(context),
                            const SizedBox(height: AppTheme.xxl),
                            _buildSaveButton(context),
                            const SizedBox(height: AppTheme.lg),
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
      ),
    );
  }

  /// Build top bar (back button + title)
  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => context.pop(),
          borderRadius: BorderRadius.circular(11),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppTheme.textPrimary),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          'Tambah Layanan',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Build Header
  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.lg),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: Icon(
            Icons.local_laundry_service_rounded,
            color: AppTheme.primaryColor,
            size: 34,
          ),
        ),
        const SizedBox(height: AppTheme.xl),
        Text(
          'Layanan Baru',
          style: GoogleFonts.poppins(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.sm),
        Text(
          'Lengkapi detail jenis layanan laundry yang kamu sediakan',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Build Form
  Widget _buildForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Nama Layanan
          AppInput(
            label: 'Nama Layanan *',
            controller: _nameController,
            hintText: 'Contoh: Cuci Kering Setrika Reguler',
            prefixIcon: Icons.label_outline_rounded,
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Nama layanan tidak boleh kosong' : null,
          ),

          const SizedBox(height: AppTheme.lg),

          // Deskripsi (opsional)
          AppInput(
            label: 'Deskripsi (Opsional)',
            controller: _descriptionController,
            hintText: 'Contoh: Proses cuci, pengeringan mesin, dan setrika rapi.',
            prefixIcon: Icons.notes_rounded,
            maxLines: 3,
          ),

          const SizedBox(height: AppTheme.lg),

          // Metode Perhitungan Harga
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Metode Perhitungan Harga',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.sm),
          Row(
            children: [
              Expanded(
                child: _buildPricingTypeChip(
                  label: 'Per Kilogram (Kg)',
                  isSelected: _selectedPricingType == PricingType.perKg,
                  onTap: () => setState(() => _selectedPricingType = PricingType.perKg),
                ),
              ),
              const SizedBox(width: AppTheme.md),
              Expanded(
                child: _buildPricingTypeChip(
                  label: 'Per Satuan Item',
                  isSelected: _selectedPricingType == PricingType.perItem,
                  onTap: () => setState(() => _selectedPricingType = PricingType.perItem),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.lg),

          // Harga
          AppInput(
            label: _selectedPricingType == PricingType.perKg
                ? 'Harga per Kg (Rp) *'
                : 'Harga per Item (Rp) *',
            controller: _priceController,
            hintText: 'Contoh: 10000',
            prefixIcon: Icons.payments_outlined,
            keyboardType: TextInputType.number,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Harga tidak boleh kosong';
              if (double.tryParse(val.trim()) == null) return 'Masukkan angka yang valid';
              return null;
            },
          ),

          const SizedBox(height: AppTheme.lg),

          // Estimasi Waktu Pengerjaan
          AppInput(
            label: 'Estimasi Waktu Pengerjaan (Jam) *',
            controller: _durationController,
            hintText: 'Contoh: 24',
            prefixIcon: Icons.timelapse_rounded,
            keyboardType: TextInputType.number,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Estimasi durasi pengerjaan tidak boleh kosong';
              }
              if (int.tryParse(val.trim()) == null) return 'Masukkan angka bulat jam yang valid';
              return null;
            },
          ),
        ],
      ),
    );
  }

  /// Chip pemilihan metode harga, dibuat manual (bukan ChoiceChip) supaya
  /// stylingnya konsisten dengan AppTheme (radius, warna, shadow) seperti
  /// komponen lain di layar ini.
  Widget _buildPricingTypeChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  /// Build Save Button
  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: !_isLoading ? _handleSubmit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
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
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.md),
                  Text(
                    'Sedang Menyimpan...',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : Text(
                'Simpan Layanan',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}
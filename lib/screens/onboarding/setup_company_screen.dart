import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/themes/app_theme.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/common/app_input.dart';

/// Setup Company Screen — Step 4 dari onboarding.
/// Sesuai PRD section 5.1 User Flow, Step 4: Setup Perusahaan.
/// Alur: Setup Profile → [halaman ini] → Pilih Paket.
/// Data disimpan lewat AuthRepository.saveCompanyData() ke Firestore
/// (users/{uid}.company + companyCompleted: true), supaya konsisten
/// dengan pola yang dipakai ChoosePlanScreen (savePlanChoice) dan
/// dikenali oleh redirect logic di routes.dart.
/// Desain disamakan dengan SetupProfileScreen & VerifyEmailScreen
/// (card putih polos, tanpa gradient, konsisten AppTheme).
///
/// PRD ini didesain dengan asumsi 1 user = 1 perusahaan (lihat
/// AuthRepository.saveCompanyData(): kalau company sudah ada, di-update,
/// bukan dibuat baru). Jadi TIDAK ada layar terpisah "Tambah Perusahaan
/// Baru" — screen ini dipakai ulang untuk dua konteks lewat
/// [isOnboarding]:
/// - true (default): dipanggil sebagai bagian alur onboarding, redirect
///   ke '/choose-plan' setelah simpan.
/// - false: dipanggil sebagai fallback ketika CreateLaundryScreen tidak
///   menemukan data company (kasus data-inconsistency yang seharusnya
///   tidak terjadi di alur normal) — setelah simpan, cukup kembali ke
///   layar sebelumnya, TIDAK memaksa user balik ke pemilihan paket.
class SetupCompanyScreen extends ConsumerStatefulWidget {
  const SetupCompanyScreen({Key? key, this.isOnboarding = true})
      : super(key: key);

  final bool isOnboarding;

  @override
  ConsumerState<SetupCompanyScreen> createState() =>
      _SetupCompanyScreenState();
}

class _SetupCompanyScreenState extends ConsumerState<SetupCompanyScreen> {
  // Controllers
  late TextEditingController _companyNameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;
  late TextEditingController _descriptionController;

  // Form key
  final _formKey = GlobalKey<FormState>();

  // State
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _phoneController = TextEditingController();
    _websiteController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Handle save company
  Future<void> _handleSaveCompany() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final router = GoRouter.of(context);
      final authRepo = ref.read(authRepositoryProvider);

      await authRepo.saveCompanyData(
        companyName: _companyNameController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        phone: _phoneController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Data perusahaan berhasil disimpan!',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }

      // Kalau dipanggil sebagai bagian onboarding, lanjut ke step 5:
      // Pilih Paket, sesuai PRD 5.1. Kalau bukan (dipanggil sebagai
      // fallback dari layar lain, mis. CreateLaundryScreen), user sudah
      // pernah lewat onboarding sebelumnya — jangan paksa balik ke
      // pemilihan paket, cukup kembali ke layar asal.
      if (widget.isOnboarding) {
        router.go('/choose-plan');
      } else if (mounted) {
        if (context.canPop()) {
          context.pop(true);
        } else {
          router.go('/laundries');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/setup-profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: _buildCard(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopRow(),
          const SizedBox(height: 20),
          _buildStepIndicator(),
          const SizedBox(height: 24),
          _buildHeader(),
          const SizedBox(height: 28),
          if (_errorMessage != null) ...[
            _buildErrorMessage(),
            const SizedBox(height: 20),
          ],
          _buildForm(),
          const SizedBox(height: 28),
          _buildSaveButton(),
          const SizedBox(height: 16),
          _buildBackLink(),
        ],
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        Material(
          color: AppTheme.backgroundColor,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: !_isLoading ? _handleBack : null,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Step indicator — 7 langkah sesuai PRD (Register, Verifikasi, Profile,
  /// Perusahaan, Pilih Paket, Pembayaran, Setup Awal). Posisi saat ini: 4.
  Widget _buildStepIndicator() {
    const totalSteps = 7;
    const currentStep = 4;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps * 2 - 1, (index) {
        if (index.isOdd) {
          final stepBefore = (index + 1) ~/ 2;
          final isDone = stepBefore < currentStep;
          return Container(
            width: 16,
            height: 2,
            color: isDone ? AppTheme.primaryColor : AppTheme.borderColor,
          );
        }
        final step = (index ~/ 2) + 1;
        final isActive = step == currentStep;
        final isDone = step < currentStep;
        return Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: (isActive || isDone)
                ? AppTheme.primaryColor
                : AppTheme.borderColor,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.business_outlined,
            color: AppTheme.primaryColor,
            size: 34,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Data Perusahaan',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Lengkapi informasi perusahaan laundry Anda',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.08),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.errorColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage ?? 'Terjadi kesalahan',
              style: GoogleFonts.poppins(
                color: AppTheme.errorColor,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          AppInput(
            label: 'Nama Perusahaan *',
            controller: _companyNameController,
            hintText: 'Contoh: NetWash Jakarta',
            prefixIcon: Icons.business_outlined,
            enabled: !_isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama perusahaan tidak boleh kosong';
              }
              if (value.length < 3) {
                return 'Nama perusahaan minimal 3 karakter';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          AppInput(
            label: 'Alamat Lengkap *',
            controller: _addressController,
            hintText: 'Jalan, nomor, kelurahan',
            prefixIcon: Icons.location_on_outlined,
            enabled: !_isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Alamat tidak boleh kosong';
              }
              if (value.length < 5) {
                return 'Alamat minimal 5 karakter';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          AppInput(
            label: 'Kota/Kabupaten *',
            controller: _cityController,
            hintText: 'Contoh: Jakarta Pusat',
            prefixIcon: Icons.location_city_outlined,
            enabled: !_isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Kota tidak boleh kosong';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          AppInput(
            label: 'Nomor Telepon *',
            controller: _phoneController,
            hintText: 'Contoh: 0812345678',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            enabled: !_isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nomor telepon tidak boleh kosong';
              }
              if (value.length < 10) {
                return 'Nomor telepon minimal 10 digit';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          AppInput(
            label: 'Website (Optional)',
            controller: _websiteController,
            hintText: 'Contoh: www.netwash.com',
            keyboardType: TextInputType.url,
            prefixIcon: Icons.language_outlined,
            enabled: !_isLoading,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (!RegExp(
                  r'^(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
                ).hasMatch(value)) {
                  return 'Format website tidak valid';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          AppInput(
            label: 'Deskripsi Singkat (Optional)',
            controller: _descriptionController,
            hintText: 'Jelaskan layanan atau spesialisasi perusahaan Anda',
            prefixIcon: Icons.description_outlined,
            enabled: !_isLoading,
            maxLines: 3,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (value.length < 10) {
                  return 'Deskripsi minimal 10 karakter';
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: !_isLoading ? _handleSaveCompany : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
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
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sedang Menyimpan...',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lanjut ke Pilih Paket',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
      ),
    );
  }

  Widget _buildBackLink() {
    return Center(
      child: TextButton(
        onPressed: !_isLoading ? _handleBack : null,
        style: TextButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
        ),
        child: Text(
          'Kembali',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
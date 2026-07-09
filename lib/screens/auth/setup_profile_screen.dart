import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/themes/app_theme.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/common/app_input.dart';

/// Setup Profile Screen — Melengkapi data profil setelah email terverifikasi.
/// Sesuai PRD section 5.1 User Flow, Step 3: Setup Profile.
/// Alur: Verifikasi Email → [halaman ini] → Setup Perusahaan.
/// Data tersimpan di: users/{user_id}/ (name, phone, avatarUrl).
class SetupProfileScreen extends ConsumerStatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  ConsumerState<SetupProfileScreen> createState() =>
      _SetupProfileScreenState();
}

class _SetupProfileScreenState extends ConsumerState<SetupProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isLoadingInitialData = true;
  String? _errorMessage;

  // Placeholder avatar; upload gambar bisa diintegrasikan nanti pakai
  // firebase_storage + image_picker. Untuk sekarang cukup ikon default.
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Prefill form dengan data yang sudah diisi pas register (nama, telepon).
  Future<void> _loadInitialData() async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final profile = await authRepo.getUserProfile();

      if (mounted && profile != null) {
        setState(() {
          _nameController.text = profile['name'] ?? '';
          _phoneController.text = profile['phone'] ?? '';
          _avatarUrl = profile['avatarUrl'];
        });
      }
    } catch (_) {
      // Kalau gagal load, biarkan form kosong, user tetap bisa isi manual.
    } finally {
      if (mounted) {
        setState(() => _isLoadingInitialData = false);
      }
    }
  }

  Future<void> _handleAvatarTap() async {
    // TODO: Integrasikan image_picker + firebase_storage di sini untuk
    // upload avatar sungguhan. Untuk sekarang tampilkan info sementara.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Upload foto profil akan segera tersedia.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleContinue() async {
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

      await authRepo.updateUserProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        avatarUrl: _avatarUrl,
      );

      // Sesuai alur PRD Step 4: Setup Perusahaan.
      // Sesuaikan nama route ini jika berbeda di router kamu.
      router.go('/setup-company');
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: _isLoadingInitialData
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
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
          _buildStepIndicator(),
          const SizedBox(height: 24),
          Text(
            'Lengkapi Profil Kamu',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Data ini akan digunakan di seluruh aplikasi NetWash',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          Center(child: _buildAvatarPicker()),
          const SizedBox(height: 28),
          if (_errorMessage != null) ...[
            _buildErrorMessage(),
            const SizedBox(height: 20),
          ],
          _buildForm(),
          const SizedBox(height: 28),
          _buildContinueButton(),
        ],
      ),
    );
  }

  /// Indikator langkah kecil di atas — biar user tau ini step keberapa
  /// dari alur onboarding (Register → Verifikasi → Profile → Perusahaan...).
  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepDot(isActive: false, isDone: true),
        _buildStepLine(isDone: true),
        _buildStepDot(isActive: true, isDone: false),
        _buildStepLine(isDone: false),
        _buildStepDot(isActive: false, isDone: false),
        _buildStepLine(isDone: false),
        _buildStepDot(isActive: false, isDone: false),
      ],
    );
  }

  Widget _buildStepDot({required bool isActive, required bool isDone}) {
    final color = (isActive || isDone)
        ? AppTheme.primaryColor
        : AppTheme.borderColor;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildStepLine({required bool isDone}) {
    return Container(
      width: 28,
      height: 2,
      color: isDone ? AppTheme.primaryColor : AppTheme.borderColor,
    );
  }

  Widget _buildAvatarPicker() {
    return GestureDetector(
      onTap: !_isLoading ? _handleAvatarTap : null,
      child: Stack(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      _avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildAvatarFallbackIcon(),
                    ),
                  )
                : _buildAvatarFallbackIcon(),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.cardColor, width: 2.5),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallbackIcon() {
    return Icon(
      Icons.person_rounded,
      color: AppTheme.primaryColor,
      size: 42,
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
            label: 'Nama Lengkap',
            controller: _nameController,
            hintText: 'Masukkan nama lengkap Anda',
            keyboardType: TextInputType.name,
            prefixIcon: Icons.person_outline_rounded,
            enabled: !_isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama tidak boleh kosong';
              }
              if (value.length < 3) {
                return 'Nama minimal 3 karakter';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          AppInput(
            label: 'Nomor Telepon',
            controller: _phoneController,
            hintText: 'Contoh: 081234567890',
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
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: !_isLoading ? _handleContinue : null,
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
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lanjutkan',
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
}
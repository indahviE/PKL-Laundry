import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/app_feedback.dart';
import '../../core/themes/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/common/app_input.dart';

/// Register Screen — Pendaftaran akun Owner (Pemilik Usaha Laundry)
/// Sesuai PRD section 5.1 User Flow, Step 1: Registrasi.
/// Setelah berhasil, alur berlanjut ke: Verifikasi Email → Setup Profile →
/// Setup Perusahaan → Pilih Paket → Pembayaran → Setup Cabang & Karyawan.
/// Tema visual disamakan dengan LoginScreen (sky blue / brand icon).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _phoneController;

  // Form key
  final _formKey = GlobalKey<FormState>();

  // State
  bool _isLoading = false;
  bool _agreeToTerms = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String? _errorMessage;

  // State loading terpisah untuk daftar via Google, supaya tombol form
  // email dan tombol Google tidak saling mengunci satu sama lain.
  bool _isGoogleLoading = false;

  /// Register publik ini untuk Pemilik Usaha (Owner) yang mendaftarkan
  /// bisnis laundry-nya sebagai tenant baru di platform NetWash.
  /// Karyawan nantinya ditambahkan oleh Owner sendiri dari dashboard,
  /// bukan lewat halaman register publik ini.
  static const String _publicRegisterRole = 'owner';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Validasi kekuatan kata sandi
  String? _validatePasswordStrength(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 8) {
      return 'Password minimal 8 karakter';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password harus mengandung huruf besar';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password harus mengandung huruf kecil';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password harus mengandung angka';
    }
    return null;
  }

  /// Eksekusi Pendaftaran
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      AppFeedback.playSound(ref, AppSound.error);
      AppSnackbar.error(context, 'Lengkapi data yang wajib diisi terlebih dahulu');
      return;
    }

    if (!_agreeToTerms) {
      AppFeedback.playSound(ref, AppSound.error);
      AppSnackbar.error(context, 'Anda harus menyetujui syarat dan ketentuan');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final router = GoRouter.of(context);
      final authRepo = ref.read(authRepositoryProvider);

      await authRepo.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _publicRegisterRole,
      );

      if (mounted) {
        AppFeedback.playSound(ref, AppSound.success);
        AppSnackbar.success(
          context,
          'Akun berhasil dibuat! Silakan cek email Anda untuk verifikasi.',
        );
      }

      // Sesuai alur PRD (Step 2: Verifikasi Email), user diarahkan ke halaman
      // verifikasi email dulu, bukan langsung ke login/dashboard.
      // Sesuaikan nama route ini jika berbeda di router kamu.
      router.go('/verify-email');
    } catch (e) {
      if (mounted) {
        AppFeedback.playSound(ref, AppSound.error);
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Daftar/masuk pakai akun Google. Berbeda dari _handleRegister:
  /// - Tidak butuh form (nama & email diambil langsung dari akun Google).
  /// - Email dari Google sudah terverifikasi, jadi step /verify-email
  ///   di-skip — cukup arahkan ke '/dashboard' dan biarkan redirect
  ///   GoRouter yang menentukan step onboarding selanjutnya (Setup
  ///   Profile/Perusahaan/dst) berdasarkan flag di Firestore.
  /// - Kalau akun Google itu ternyata sudah pernah dipakai login
  ///   sebelumnya (bukan user baru), ini otomatis jadi "login", bukan
  ///   duplikat akun — sesuai perilaku signInWithGoogle() di repository.
  Future<void> _handleGoogleRegister() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final router = GoRouter.of(context);
      final authRepo = ref.read(authRepositoryProvider);

      final result = await authRepo.signInWithGoogle();

      // result == null berarti user menutup/cancel popup pilih akun.
      // Bukan error, jadi tidak perlu munculkan dialog apa pun.
      if (result == null) return;

      if (mounted) {
        AppFeedback.playSound(ref, AppSound.success);
        router.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.playSound(ref, AppSound.error);
        _showGoogleErrorDialog(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  /// Dialog khusus kegagalan Google Sign-In — tampilan lebih rapi (ikon
  /// di lingkaran berwarna + tombol aksi) dibanding banner error inline
  /// yang dipakai untuk kegagalan form email/password, karena kegagalan
  /// Google biasanya butuh perhatian user (mis. coba akun lain) bukan
  /// sekadar info kecil di atas form.
  void _showGoogleErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppTheme.errorColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Daftar dengan Google Gagal',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Mengerti',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Kembali ke halaman login
  void _handleBackToLogin() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;

            // Mobile: header brand gradient + card form.
            // Sama seperti LoginScreen, card di-center vertikal di sisa
            // ruang layar (bukan cuma nempel di bawah header) supaya
            // tidak terlihat "menggantung" di atas pada layar HP tinggi.
            if (isMobile) {
              return LayoutBuilder(
                builder: (context, outerConstraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: outerConstraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildMobileBrandHeader(),
                            Expanded(
                              child: Center(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 28, 20, 24),
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 440),
                                    child: _buildRegisterCard(isMobile),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }

            // Desktop: panel brand kiri (sama seperti login), form kanan
            return Row(
              children: [
                Expanded(
                  flex: 40,
                  child: _buildBrandPanel(),
                ),
                Expanded(
                  flex: 60,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 32,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: _buildRegisterCard(isMobile),
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

  // ==========================================================
  // PANEL BRAND (DESKTOP) — identik dengan LoginScreen
  // ==========================================================
  Widget _buildBrandPanel() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _LaundryPatternPainter()),
          ),
          // Tombol back diposisikan tetap di pojok kiri atas, terpisah dari
          // konten yang di-center, supaya tidak ikut turun ke tengah.
          Positioned(
            top: 16,
            left: 16,
            child: _buildBackButton(light: true),
          ),
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLogoBadge(size: 88, iconSize: 44),
                const SizedBox(height: 40),
                Text(
                  'Daftarkan\nBisnis Anda',
                  style: GoogleFonts.poppins(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -1,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Kelola perusahaan, cabang, dan\nkaryawan laundry Anda dalam satu aplikasi',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                _buildFeatureChips(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChips() {
    final features = [
      ('Multi Cabang', Icons.storefront_outlined),
      ('Manajemen Karyawan', Icons.badge_outlined),
      ('Laporan Real-time', Icons.bar_chart_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features
          .map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(f.$2, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    f.$1,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ==========================================================
  // HEADER BRAND (MOBILE) — identik gaya dengan LoginScreen
  // ==========================================================
  Widget _buildMobileBrandHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      decoration: const BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              child: CustomPaint(painter: _LaundryPatternPainter()),
            ),
          ),
          // Tombol back mepet ke pojok kiri atas
          Positioned(
            top: 0,
            left: 0,
            child: _buildBackButton(light: true),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Column(
                children: [
                  _buildLogoBadge(size: 68, iconSize: 34),
                  const SizedBox(height: 18),
                  Text(
                    'Daftarkan Bisnis Anda',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kelola perusahaan & karyawan\nlaundry Anda dalam satu aplikasi',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton({bool light = false}) {
    return Material(
      color: light ? Colors.white.withOpacity(0.18) : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: !_isLoading ? _handleBackToLogin : null,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.arrow_back_rounded,
            color: light ? Colors.white : AppTheme.textPrimary,
            size: 20,
          ),
        ),
      ),
    );
  }

  /// Badge logo putih membulat berbayang — konsisten dengan LoginScreen
  Widget _buildLogoBadge({required double size, required double iconSize}) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Image.asset(
        'asset/icon/Netwash_Logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_laundry_service_rounded,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // CARD FORM REGISTER
  // ==========================================================
  Widget _buildRegisterCard(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 36,
        vertical: isMobile ? 28 : 40,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isMobile
            ? null
            : [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isMobile) ...[
            Text(
              'Buat Akun Owner',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Langkah pertama untuk mulai mengelola bisnis laundry Anda',
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
          ],
          if (_errorMessage != null) ...[
            _buildErrorMessage(),
            const SizedBox(height: 20),
          ],
          _buildForm(isMobile),
          SizedBox(height: isMobile ? 20 : 24),
          _buildTermsCheckbox(),
          SizedBox(height: isMobile ? 24 : 28),
          _buildRegisterButton(),
          SizedBox(height: isMobile ? 24 : 28),
          _buildOrDivider(),
          SizedBox(height: isMobile ? 24 : 28),
          _buildGoogleButton(),
          SizedBox(height: isMobile ? 20 : 24),
          _buildLoginLink(),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.08),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.errorColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage ?? 'Terjadi kesalahan',
              style: GoogleFonts.poppins(
                color: AppTheme.errorColor,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool isMobile) {
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
          SizedBox(height: isMobile ? 16 : 20),
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
          SizedBox(height: isMobile ? 16 : 20),
          AppInput(
            label: 'Email',
            controller: _emailController,
            hintText: 'Masukkan email Anda',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline_rounded,
            enabled: !_isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email tidak boleh kosong';
              }
              if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                  .hasMatch(value)) {
                return 'Format email tidak valid';
              }
              return null;
            },
          ),
          SizedBox(height: isMobile ? 16 : 20),
          AppInput(
            label: 'Password',
            controller: _passwordController,
            hintText: 'Min 8 karakter (huruf besar, kecil, angka)',
            obscureText: !_showPassword,
            prefixIcon: Icons.lock_outline_rounded,
            enabled: !_isLoading,
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppTheme.textTertiary,
              ),
              onPressed: () =>
                  setState(() => _showPassword = !_showPassword),
            ),
            validator: _validatePasswordStrength,
          ),
          SizedBox(height: isMobile ? 16 : 20),
          AppInput(
            label: 'Konfirmasi Password',
            controller: _confirmPasswordController,
            hintText: 'Masukkan ulang password Anda',
            obscureText: !_showConfirmPassword,
            prefixIcon: Icons.lock_outline_rounded,
            enabled: !_isLoading,
            suffixIcon: IconButton(
              icon: Icon(
                _showConfirmPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppTheme.textTertiary,
              ),
              onPressed: () =>
                  setState(() => _showConfirmPassword = !_showConfirmPassword),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Konfirmasi password tidak boleh kosong';
              }
              if (value != _passwordController.text) {
                return 'Password tidak cocok';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: !_isLoading
              ? (value) => setState(() => _agreeToTerms = value ?? false)
              : null,
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTheme.primaryColor;
            }
            return Colors.transparent;
          }),
          side: BorderSide(color: AppTheme.borderColor, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
                children: [
                  const TextSpan(text: 'Saya setuju dengan '),
                  TextSpan(
                    text: 'Syarat & Ketentuan',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' dan '),
                  TextSpan(
                    text: 'Kebijakan Privasi',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: (!_isLoading && !_isGoogleLoading) ? _handleRegister : null,
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
                    'Sedang mendaftar...',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                'Daftar Sekarang',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.borderColor.withOpacity(0),
                  AppTheme.borderColor,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'atau',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textTertiary,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.borderColor,
                  AppTheme.borderColor.withOpacity(0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Tombol "Daftar dengan Google" — full-width, beda dari LoginScreen yang
  /// setengah lebar (berdampingan dengan WhatsApp), karena di sini belum
  /// ada opsi WhatsApp untuk register.
  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: (!_isLoading && !_isGoogleLoading) ? _handleGoogleRegister : null,
        icon: _isGoogleLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryColor,
                ),
              )
            : const Icon(Icons.g_mobiledata, size: 22),
        label: Text(
          _isGoogleLoading ? 'Memproses...' : 'Daftar dengan Google',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryColor,
          side: BorderSide(color: AppTheme.borderColor, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          splashFactory: NoSplash.splashFactory,
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          Text(
            'Sudah punya akun? ',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          TextButton(
            onPressed: (!_isLoading && !_isGoogleLoading) ? _handleBackToLogin : null,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              splashFactory: NoSplash.splashFactory,
            ),
            child: Text(
              'Login Sekarang',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pola dekoratif — sama dengan yang dipakai di LoginScreen agar konsisten
class _LaundryPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final circlePaint = Paint()..color = Colors.white.withOpacity(0.07);

    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.12), 110, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 0.85), 150, circlePaint);
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.75),
      70,
      Paint()..color = Colors.white.withOpacity(0.05),
    );

    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final center = Offset(size.width * 0.82, size.height * 0.14);
    for (final r in [40.0, 62.0, 84.0]) {
      canvas.drawCircle(center, r, ringPaint);
    }

    final dotPaint = Paint()..color = Colors.white.withOpacity(0.16);
    final rnd = math.Random(11);
    for (int i = 0; i < 14; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      final r = 2.0 + rnd.nextDouble() * 3.5;
      canvas.drawCircle(Offset(dx, dy), r, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
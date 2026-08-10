import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/app_feedback.dart';
import '../../core/themes/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  // State loading terpisah untuk Google Sign-In, supaya tombol Email
  // dan tombol Google tidak saling mengunci satu sama lain.
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      AppFeedback.playSound(ref, AppSound.error);
      AppSnackbar.error(context, 'Lengkapi data yang wajib diisi terlebih dahulu');
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      await ref.read(loginProvider.notifier).login(
            email: email,
            password: password,
          );

      final loginState = ref.read(loginProvider);

      if (mounted) {
        if (loginState.isSuccess) {
          AppFeedback.playSound(ref, AppSound.success);
          context.go('/dashboard');
        } else if (loginState.error != null) {
          AppFeedback.playSound(ref, AppSound.error);
          _handleAuthError(loginState.error!);
        }
      }
    } catch (e) {
      AppFeedback.playSound(ref, AppSound.error);
      _showErrorDialog("Terjadi kesalahan sistem: $e");
    }
  }

  /// Login/register otomatis pakai akun Google lewat AuthRepository.
  /// Beda jalur dari _handleLogin (yang lewat loginProvider) karena
  /// signInWithGoogle() sudah handle create Firestore doc untuk user
  /// baru sekaligus di dalam repository-nya.
  Future<void> _handleGoogleLogin() async {
    setState(() => _isGoogleLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.signInWithGoogle();

      // result == null berarti user menutup/cancel popup pilih akun.
      // Ini bukan error, jadi tidak perlu munculkan dialog apa pun.
      if (result == null) return;

      if (mounted) {
        AppFeedback.playSound(ref, AppSound.success);
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.playSound(ref, AppSound.error);
        _showGoogleErrorDialog(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  /// Dialog khusus kegagalan Google Sign-In — dibedakan dari
  /// _showErrorDialog biasa (yang dipakai login email/password) supaya
  /// tampilannya lebih ramah: ada ikon di lingkaran berwarna, dan tombol
  /// aksi langsung "Coba Lagi" biar user tidak perlu buka menu lagi.
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
                'Login Google Gagal',
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

  void _handleAuthError(String errorCode) {
    String message = "";
    switch (errorCode) {
      case 'user-not-found':
        message = "Email tidak terdaftar.";
        break;
      case 'wrong-password':
        message = "Password yang Anda masukkan salah.";
        break;
      case 'invalid-email':
        message = "Format email tidak valid.";
        break;
      case 'user-disabled':
        message = "Akun ini telah dinonaktifkan.";
        break;
      default:
        message = errorCode;
    }
    _showErrorDialog(message);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text(
          'Login Gagal',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);
    final isLoading = loginState.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;

            // Mobile: 1 kolom, header brand + form.
            // Card form di-center VERTIKAL di sisa ruang layar (bukan
            // cuma nempel di bawah header) lewat pola ConstrainedBox
            // (minHeight) + IntrinsicHeight + Expanded + Center. Kalau
            // layar HP-nya tinggi, card jadi di tengah, bukan mepet atas.
            // Kalau konten kepanjangan (mis. keyboard muncul), tetap bisa
            // di-scroll normal karena masih dibungkus SingleChildScrollView.
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
                                    child: _buildLoginCard(isLoading, isMobile),
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

            // Desktop: 2 kolom - kiri brand panel, kanan form
            return Row(
              children: [
                Expanded(
                  flex: 45,
                  child: _buildBrandPanel(),
                ),
                Expanded(
                  flex: 55,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 24,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: _buildLoginCard(isLoading, isMobile),
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
  // PANEL BRAND (DESKTOP) — menggantikan ilustrasi lama dengan
  // gradient sky-blue + pola ikon laundry, senada dengan app icon
  // ==========================================================
  Widget _buildBrandPanel() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
      child: Stack(
        children: [
          // Pola dekoratif lingkaran & ikon laundry di background
          Positioned.fill(
            child: CustomPaint(
              painter: _LaundryPatternPainter(),
            ),
          ),
          // Konten utama
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLogoBadge(size: 88, iconSize: 44),
                const SizedBox(height: 40),
                Text(
                  'Netwash',
                  style: GoogleFonts.poppins(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -1,
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
  // HEADER BRAND (MOBILE) — pengganti ilustrasi, gradient banner
  // ringkas dengan logo & nama brand
  // ==========================================================
  Widget _buildMobileBrandHeader() {
  return Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: AppTheme.brandGradient,
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
    ),
    // Kita gunakan Stack hanya untuk background, lalu gunakan Column
    // di atasnya untuk konten agar mudah di-center.
    child: Stack(
      children: [
        // Background dekoratif
        Positioned.fill(
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            child: CustomPaint(painter: _LaundryPatternPainter()),
          ),
        ),
        // Konten utama: di-center di sini
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Agar Column tidak melebar ke bawah
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center, // Horizontal center
              children: [
                _buildLogoBadge(size: 68, iconSize: 34),
                const SizedBox(height: 18),
                Text(
                  'NetWash',
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
                  'Kelola perusahaan & karyawan laundry Anda',
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

  /// Badge logo putih membulat berbayang — dipakai di mobile & desktop
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
      child: _buildLogo(),
    );
  }

  /// Logo aplikasi (reusable) — menggunakan asset icon app yang sudah ada
  Widget _buildLogo() {
    return Image.asset(
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
    );
  }

  /// Card form login (reusable untuk mobile & desktop)
  Widget _buildLoginCard(bool isLoading, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 36,
        vertical: isMobile ? 28 : 44,
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
          Text(
            'Selamat Datang!',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Masuk untuk melanjutkan ke akun Anda',
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: isMobile ? 28 : 32),
          _buildForm(isLoading),
        ],
      ),
    );
  }

  /// Form dengan input fields
  Widget _buildForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Input
          AppInput(
            label: 'Email',
            controller: _emailController,
            hintText: 'Masukkan email Anda',
            prefixIcon: Icons.mail_outline_rounded,
            enabled: !isLoading,
            keyboardType: TextInputType.emailAddress,
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

          const SizedBox(height: 20),

          // Password Input
          AppInput(
            label: 'Password',
            controller: _passwordController,
            hintText: 'Masukkan password Anda',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: !_isPasswordVisible,
            enabled: !isLoading,
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppTheme.textTertiary,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password tidak boleh kosong';
              }
              if (value.length < 6) {
                return 'Password minimal 6 karakter';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // Forgot Password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading ? null : () => context.go('/forgot-password'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                splashFactory: NoSplash.splashFactory,
              ),
              child: Text(
                'Lupa Password?',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Login Button
          SizedBox(
            height: 52,
            child: AppButton(
              label: isLoading ? 'Masuk...' : 'Masuk',
              onPressed: isLoading ? null : _handleLogin,
              isLoading: isLoading,
            ),
          ),

          const SizedBox(height: 24),

          // Divider
          Row(
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
          ),

          const SizedBox(height: 24),

          // Social Login
          _buildSocialButton(
            icon: Icons.g_mobiledata,
            label: _isGoogleLoading ? 'Memproses...' : 'Masuk dengan Google',
            isLoadingButton: _isGoogleLoading,
            onPressed: (isLoading || _isGoogleLoading)
                ? null
                : _handleGoogleLogin,
          ),

          const SizedBox(height: 24),

          // Sign Up Link
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                Text(
                  'Belum punya akun? ',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),
                TextButton(
                  onPressed: isLoading ? null : () => context.go('/register'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    splashFactory: NoSplash.splashFactory,
                  ),
                  child: Text(
                    'Daftar sekarang',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isLoadingButton = false,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: isLoadingButton
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryColor,
              ),
            )
          : Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        foregroundColor: AppTheme.primaryColor,
        side: BorderSide(
          color: AppTheme.borderColor,
          width: 1.2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        splashFactory: NoSplash.splashFactory,
      ),
    );
  }
}

/// Pola dekoratif berupa lingkaran-lingkaran lembut & ikon laundry samar
/// yang menggantikan ilustrasi lama, senada dengan gaya app icon (flat, minimal).
class _LaundryPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final circlePaint = Paint()..color = Colors.white.withOpacity(0.07);

    // Lingkaran besar dekoratif di sudut-sudut panel
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.12), 110, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 0.85), 150, circlePaint);
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.75),
      70,
      Paint()..color = Colors.white.withOpacity(0.05),
    );

    // Garis-garis melingkar tipis menyerupai putaran mesin cuci
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final center = Offset(size.width * 0.82, size.height * 0.14);
    for (final r in [40.0, 62.0, 84.0]) {
      canvas.drawCircle(center, r, ringPaint);
    }

    // Titik-titik kecil (bubble) tersebar, kesan "bersih & segar"
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.16);
    final rnd = math.Random(7);
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
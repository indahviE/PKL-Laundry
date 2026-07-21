import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/themes/app_theme.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/common/app_input.dart';

/// Halaman "Lupa Password".
///
/// Alurnya: user masukkan email -> panggil
/// `AuthRepository.resetPassword(email)` (sudah tersedia, tinggal dipakai
/// di sini) -> Firebase mengirim email reset password -> tampilkan pesan
/// sukses. Firebase Auth sengaja tidak membedakan "email terdaftar" atau
/// tidak lewat pesan error yang berbeda (demi keamanan/privasi), jadi
/// pesan sukses selalu ditampilkan selama formatnya valid & request tidak
/// gagal karena alasan lain (mis. terlalu banyak percobaan).
///
/// Tampilan disamakan dengan RegisterScreen: brand header/panel bergradasi
/// + laundry pattern di background, logo badge, dan card form dengan
/// layout mobile/desktop yang sama (split panel di desktop, header di
/// atas card untuk mobile).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.resetPassword(email);

      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _handleBackToLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;

            // Mobile: header brand gradient + card form, card di-center
            // vertikal di sisa ruang layar — sama seperti RegisterScreen.
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
                                    child: _buildForgotCard(isMobile),
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

            // Desktop: panel brand kiri (sama seperti LoginScreen/RegisterScreen),
            // form kanan.
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
                        child: _buildForgotCard(isMobile),
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
  // PANEL BRAND (DESKTOP) — identik dengan RegisterScreen
  // ==========================================================
  Widget _buildBrandPanel() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _LaundryPatternPainter()),
          ),
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
                  'Lupa Kata\nSandi Anda?',
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
                  'Tenang, kami akan bantu Anda\nmengatur ulang password dengan aman',
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
      ('Verifikasi via Email', Icons.mark_email_read_outlined),
      ('Link Aman & Terenkripsi', Icons.verified_user_outlined),
      ('Proses Hanya Beberapa Menit', Icons.bolt_outlined),
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
  // HEADER BRAND (MOBILE) — identik gaya dengan RegisterScreen
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
                    _emailSent ? 'Email Terkirim' : 'Lupa Password?',
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
                    _emailSent
                        ? 'Cek inbox (atau folder spam)\nemail Anda untuk melanjutkan'
                        : 'Masukkan email terdaftar untuk\nmengatur ulang password Anda',
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

  /// Badge logo putih membulat berbayang — konsisten dengan LoginScreen &
  /// RegisterScreen.
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
            child: Icon(
              _emailSent
                  ? Icons.mark_email_read_rounded
                  : Icons.lock_reset_rounded,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // CARD FORM LUPA PASSWORD
  // ==========================================================
  Widget _buildForgotCard(bool isMobile) {
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
              _emailSent ? 'Email Terkirim' : 'Atur Ulang Password',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _emailSent
                  ? 'Kami sudah mengirimkan link reset password ke ${_emailController.text.trim()}'
                  : 'Masukkan email yang terdaftar untuk menerima link reset',
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
          if (!_emailSent) ...[
            _buildForm(isMobile),
            SizedBox(height: isMobile ? 24 : 28),
            _buildSendButton(),
          ] else ...[
            _buildBackToLoginButton(),
            const SizedBox(height: 12),
            _buildResendLink(),
          ],
          SizedBox(height: isMobile ? 8 : 12),
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
      child: AppInput(
        label: 'Email',
        controller: _emailController,
        hintText: 'nama@email.com',
        prefixIcon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
        enabled: !_isLoading,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Email tidak boleh kosong';
          }
          final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
          if (!emailRegex.hasMatch(value.trim())) {
            return 'Format email tidak valid';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: !_isLoading ? _handleSendResetEmail : null,
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
                    'Mengirim...',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                'Kirim Link Reset',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildBackToLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _handleBackToLogin,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryColor,
          side: BorderSide(color: AppTheme.borderColor, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          splashFactory: NoSplash.splashFactory,
        ),
        child: Text(
          'Kembali ke Login',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildResendLink() {
    return Center(
      child: TextButton(
        onPressed: () {
          setState(() {
            _emailSent = false;
            _errorMessage = null;
          });
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          splashFactory: NoSplash.splashFactory,
        ),
        child: Text(
          'Tidak menerima email? Kirim ulang',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}

/// Pola dekoratif — sama dengan yang dipakai di LoginScreen/RegisterScreen
/// agar konsisten.
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
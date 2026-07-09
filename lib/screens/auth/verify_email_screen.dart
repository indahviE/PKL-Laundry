import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/themes/app_theme.dart';
import '../../repositories/auth_repository.dart';

/// Verify Email Screen — Halaman verifikasi email setelah registrasi.
/// Sesuai PRD section 5.1 User Flow, Step 2: Verifikasi Email.
/// Alur: Registrasi → [halaman ini] → Setup Profile.
/// User menunggu di sini sampai link verifikasi di email diklik.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  Timer? _pollingTimer;
  Timer? _resendCooldownTimer;

  bool _isChecking = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _infoMessage;

  int _resendCooldown = 0;
  static const int _cooldownDuration = 30;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _resendCooldownTimer?.cancel();
    super.dispose();
  }

  /// Polling otomatis tiap 3 detik buat cek status emailVerified.
  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final authRepo = ref.read(authRepositoryProvider);
      final verified = await authRepo.checkEmailVerified();
      if (verified && mounted) {
        timer.cancel();
        _goToNextStep();
      }
    });
  }

  void _goToNextStep() {
    if (!mounted) return;
    // Sesuai alur PRD Step 3: Setup Profile.
    // Sesuaikan nama route ini jika berbeda di router kamu.
    context.go('/setup-profile');
  }

  /// Cek manual saat tombol "Saya Sudah Verifikasi" ditekan.
  Future<void> _handleManualCheck() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final verified = await authRepo.checkEmailVerified();

      if (verified) {
        _goToNextStep();
        return;
      }

      if (mounted) {
        setState(() {
          _errorMessage =
              'Email belum terverifikasi. Silakan cek inbox atau folder spam kamu.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  /// Kirim ulang email verifikasi, dengan cooldown 30 detik.
  Future<void> _handleResend() async {
    if (_resendCooldown > 0) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.resendEmailVerification();

      if (mounted) {
        setState(() {
          _infoMessage = 'Email verifikasi berhasil dikirim ulang.';
        });
        _startResendCooldown();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _startResendCooldown() {
    setState(() => _resendCooldown = _cooldownDuration);
    _resendCooldownTimer?.cancel();
    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown -= 1);
      }
    });
  }

  Future<void> _handleBackToLogin() async {
    final authRepo = ref.read(authRepositoryProvider);
    await authRepo.signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.read(authRepositoryProvider).currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _buildCard(email),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String email) {
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
        children: [
          _buildIconBadge(),
          const SizedBox(height: 24),
          Text(
            'Verifikasi Email Kamu',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Kami sudah kirim link verifikasi ke:',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          _buildStatusIndicator(),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildMessageBox(_errorMessage!, isError: true),
          ],
          if (_infoMessage != null) ...[
            const SizedBox(height: 16),
            _buildMessageBox(_infoMessage!, isError: false),
          ],
          const SizedBox(height: 28),
          _buildManualCheckButton(),
          const SizedBox(height: 16),
          _buildResendButton(),
          const SizedBox(height: 20),
          _buildBackToLoginLink(),
        ],
      ),
    );
  }

  Widget _buildIconBadge() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.mark_email_unread_rounded,
        color: AppTheme.primaryColor,
        size: 34,
      ),
    );
  }

  /// Indikator kecil bahwa sistem lagi nunggu (polling) secara otomatis.
  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.textTertiary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Menunggu kamu klik link di email...',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBox(String message, {required bool isError}) {
    final color = isError ? AppTheme.errorColor : AppTheme.successColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(fontSize: 12.5, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualCheckButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: !_isChecking ? _handleManualCheck : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
        child: _isChecking
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Saya Sudah Verifikasi',
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildResendButton() {
    final isDisabled = _isResending || _resendCooldown > 0;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: !isDisabled ? _handleResend : null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppTheme.borderColor, width: 1.5),
          foregroundColor: AppTheme.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
        child: _isResending
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.textPrimary,
                  ),
                ),
              )
            : Text(
                _resendCooldown > 0
                    ? 'Kirim Ulang (${_resendCooldown}s)'
                    : 'Kirim Ulang Email',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildBackToLoginLink() {
    return TextButton(
      onPressed: _handleBackToLogin,
      style: TextButton.styleFrom(
        splashFactory: NoSplash.splashFactory,
      ),
      child: Text(
        'Kembali ke Login',
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}
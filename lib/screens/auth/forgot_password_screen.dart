import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/themes/app_theme.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/common/app_button.dart';
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

    setState(() => _isLoading = true);

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
        setState(() => _isLoading = false);
        _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text(
          'Gagal Mengirim Email',
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _emailSent
                      ? Icons.mark_email_read_rounded
                      : Icons.lock_reset_rounded,
                  color: AppTheme.primaryColor,
                  size: 30,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _emailSent ? 'Email Terkirim' : 'Lupa Password?',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _emailSent
                    ? 'Kami sudah mengirimkan link reset password ke ${_emailController.text.trim()}. Silakan cek inbox (atau folder spam) email Anda.'
                    : 'Masukkan email yang terdaftar. Kami akan mengirimkan link untuk mengatur ulang password Anda.',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              if (!_emailSent) ...[
                Form(
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
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: AppButton(
                    label: _isLoading ? 'Mengirim...' : 'Kirim Link Reset',
                    onPressed: _isLoading ? null : _handleSendResetEmail,
                    isLoading: _isLoading,
                  ),
                ),
              ] else ...[
                SizedBox(
                  height: 52,
                  child: AppButton(
                    label: 'Kembali ke Login',
                    variant: ButtonVariant.outline,
                    onPressed: () => context.go('/login'),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() => _emailSent = false);
                    },
                    child: Text(
                      'Tidak menerima email? Kirim ulang',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

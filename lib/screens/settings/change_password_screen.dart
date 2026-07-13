import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/themes/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  // Login pakai email/password atau enggak (relevan pas nanti ada
  // Google Sign-In — user Google gak punya password buat direauth).
  bool get _isPasswordProvider =>
      _user?.providerData.any((p) => p.providerId == 'password') ?? false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _user;
    final email = user?.email;
    if (user == null || email == null) return;

    setState(() => _isSaving = true);
    try {
      // 1. Reauthenticate pakai password lama dulu, wajib sebelum
      //    updatePassword biar gak kena error requires-recent-login.
      final credential = EmailAuthProvider.credential(
        email: email,
        password: _oldPasswordController.text,
      );
      await user.reauthenticateWithCredential(credential);

      // 2. Baru update ke password baru.
      await user.updatePassword(_newPasswordController.text);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password berhasil diubah')),
      );
      Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapError(e))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal ubah password: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Password lama salah';
      case 'weak-password':
        return 'Password baru terlalu lemah, minimal 6 karakter';
      case 'requires-recent-login':
        return 'Sesi login kamu udah lama, silakan login ulang dulu';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan, coba lagi nanti';
      default:
        return 'Gagal ubah password: ${e.message}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: _isPasswordProvider
                        ? _buildForm()
                        : _buildUnavailableNotice(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 20, 24, 28),
      decoration: const BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 4),
          Text(
            'Ubah Password',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel('Password Lama'),
          _buildPasswordField(
            controller: _oldPasswordController,
            obscure: _obscureOld,
            onToggle: () => setState(() => _obscureOld = !_obscureOld),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password lama wajib diisi';
              return null;
            },
          ),
          const SizedBox(height: 18),
          _sectionLabel('Password Baru'),
          _buildPasswordField(
            controller: _newPasswordController,
            obscure: _obscureNew,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password baru wajib diisi';
              if (v.length < 6) return 'Minimal 6 karakter';
              if (v == _oldPasswordController.text) {
                return 'Password baru gak boleh sama dengan yang lama';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          _sectionLabel('Konfirmasi Password Baru'),
          _buildPasswordField(
            controller: _confirmPasswordController,
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Konfirmasi password wajib diisi';
              if (v != _newPasswordController.text) {
                return 'Konfirmasi tidak cocok dengan password baru';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildUnavailableNotice() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor),
          const SizedBox(height: 12),
          Text(
            'Akun kamu login pakai provider lain (misalnya Google), jadi gak ada password yang bisa diubah di sini.',
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textTertiary,
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.poppins(fontSize: 14.5, color: AppTheme.textPrimary),
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.lock_outline_rounded,
            color: AppTheme.primaryColor, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: AppTheme.textTertiary,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: AppTheme.cardColor,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Text(
                'Simpan Password Baru',
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
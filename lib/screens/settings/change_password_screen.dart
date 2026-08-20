import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';

/// Local design tokens — DISAMAIN PERSIS dengan _DS di
/// reports_screen.dart / services_list_screen.dart (Be Vietnam Pro,
/// navy/primary NetWash, card putih shadow tipis, tombol back bulat).
/// Tetap lokal di file ini (bukan dipindah ke app_theme.dart) mengikuti
/// pola yang sudah dipakai di layar-layar lain, jadi gak ada layar lain
/// yang ikut berubah tampilannya.
class _DS {
  static const canvas = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const onSurface = Color(0xFF1B1C1C);
  static const onSurfaceVariant = Color(0xFF404752);
  static const outlineVariant = Color(0xFFBFC7D4);

  static const navy = Color(0xFF0B3B66);
  static const primary = Color(0xFF0061A4);

  static const danger = Color(0xFFE03131);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static TextStyle headlineMd({Color? color}) => GoogleFonts.beVietnamPro(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: color ?? onSurface,
        letterSpacing: -0.2,
      );

  static TextStyle bodyMd({Color? color, FontWeight? weight}) => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: weight ?? FontWeight.w400,
        color: color ?? onSurface,
      );

  static TextStyle bodySm({Color? color, FontWeight? weight}) => GoogleFonts.beVietnamPro(
        fontSize: 12.5,
        fontWeight: weight ?? FontWeight.w400,
        color: color ?? onSurfaceVariant,
      );

  static TextStyle labelBold({Color? color}) => GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color ?? onSurfaceVariant,
      );
}

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
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.passwordChangeSuccess)),
      );
      Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapError(e, AppLocalizations.of(context)!))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.passwordChangeGenericError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _mapError(FirebaseAuthException e, AppLocalizations t) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return t.wrongOldPasswordError;
      case 'weak-password':
        return t.weakPasswordError;
      case 'requires-recent-login':
        return t.requiresRecentLoginError;
      case 'too-many-requests':
        return t.tooManyRequestsError;
      default:
        return t.passwordChangeGenericError(e.message ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DS.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(context),
                    const SizedBox(height: 16),
                    _buildHeader(),
                    const SizedBox(height: 22),
                    _isPasswordProvider ? _buildFormCard() : _buildUnavailableNotice(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Tombol back bulat — disamain persis sama tombol back di
  /// reports_screen.dart / services_list_screen.dart (lingkaran putih,
  /// shadow tipis, ikon navy).
  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _DS.surface,
              shape: BoxShape.circle,
              boxShadow: _DS.cardShadow,
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 20, color: _DS.navy),
          ),
        ),
      ],
    );
  }

  /// Header — icon box biru muda + judul navy, pola sama dengan
  /// _buildHeader di reports_screen.dart / services_list_screen.dart.
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFD1E4FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.lock_outline_rounded, color: _DS.navy, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.changePasswordTitle,
            style: _DS.headlineMd(color: _DS.navy),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Card putih rounded shadow — bungkus form ganti password, konsisten
  /// sama gaya card KPI/breakdown di reports_screen.dart.
  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _DS.cardShadow,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionLabel(AppLocalizations.of(context)!.oldPasswordLabel),
            _buildPasswordField(
              controller: _oldPasswordController,
              obscure: _obscureOld,
              onToggle: () => setState(() => _obscureOld = !_obscureOld),
              validator: (v) {
                if (v == null || v.isEmpty) return AppLocalizations.of(context)!.oldPasswordRequiredError;
                return null;
              },
            ),
            const SizedBox(height: 18),
            _sectionLabel(AppLocalizations.of(context)!.newPasswordLabel),
            _buildPasswordField(
              controller: _newPasswordController,
              obscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
              validator: (v) {
                if (v == null || v.isEmpty) return AppLocalizations.of(context)!.newPasswordRequiredError;
                if (v.length < 6) return AppLocalizations.of(context)!.passwordMinLengthError;
                if (v == _oldPasswordController.text) {
                  return AppLocalizations.of(context)!.newPasswordSameAsOldError;
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _sectionLabel(AppLocalizations.of(context)!.confirmPasswordLabel),
            _buildPasswordField(
              controller: _confirmPasswordController,
              obscure: _obscureConfirm,
              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              validator: (v) {
                if (v == null || v.isEmpty) return AppLocalizations.of(context)!.confirmPasswordRequiredError;
                if (v != _newPasswordController.text) {
                  return AppLocalizations.of(context)!.confirmPasswordMismatchError;
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  /// Notice provider lain (mis. Google) — disamain ke gaya card putih
  /// rounded shadow, ikon & teks pakai token _DS.
  Widget _buildUnavailableNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _DS.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFD1E4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.info_outline_rounded, color: _DS.navy, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            AppLocalizations.of(context)!.otherProviderNotice,
            style: _DS.bodySm(),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        text,
        style: _DS.labelBold(),
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
      style: _DS.bodyMd(),
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: _DS.navy, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: _DS.onSurfaceVariant,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: _DS.canvas,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _DS.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _DS.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _DS.primary, width: 1.5),
        ),
        errorStyle: _DS.bodySm(color: _DS.danger).copyWith(fontSize: 11.5),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: _DS.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
                AppLocalizations.of(context)!.savePasswordButton,
                style: _DS.bodyMd(color: Colors.white, weight: FontWeight.w600),
              ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/themes/app_theme.dart';
// import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input.dart';
// import '../../widgets/common/loading_widget.dart';
// import '../../widgets/common/error_widget.dart';

/// Register Screen
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

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

  /// Validate password strength
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

  /// Handle register
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus menyetujui syarat dan ketentuan'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Connect ke Firebase atau backend API
      // Simulasi register process
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Uncomment ini ketika Firebase auth siap
      // final authService = ref.read(firebaseAuthServiceProvider);
      // await authService.register(
      //   email: _emailController.text,
      //   password: _passwordController.text,
      //   name: _nameController.text,
      //   phone: _phoneController.text,
      // );

      // TODO: Navigate ke email verification atau login
      // context.go('/login/verify-email');

      // Untuk sekarang, show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pendaftaran berhasil! (Testing mode)'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Handle back to login
  void _handleBackToLogin() {
    // TODO: Navigate ke login screen
    // context.go('/login');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: !_isLoading ? _handleBackToLogin : null,
        ),
        title: const Text('Daftar Akun'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),

                // Spacer
                const SizedBox(height: AppTheme.xl),

                // Error message
                if (_errorMessage != null) ...[
                  _buildErrorMessage(),
                  const SizedBox(height: AppTheme.lg),
                ],

                // Form
                _buildForm(),

                // Spacer
                const SizedBox(height: AppTheme.lg),

                // Terms & Conditions
                _buildTermsCheckbox(),

                // Spacer
                const SizedBox(height: AppTheme.lg),

                // Register button
                _buildRegisterButton(),

                // Spacer
                const SizedBox(height: AppTheme.xl),

                // Login link
                _buildLoginLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build header
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Buat Akun Baru',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.darkColor,
              ),
        ),
        const SizedBox(height: AppTheme.md),
        Text(
          'Lengkapi data Anda untuk mendaftar',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.gray600,
              ),
        ),
      ],
    );
  }

  /// Build error message
  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        border: Border.all(color: AppTheme.errorColor),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.errorColor,
          ),
          const SizedBox(width: AppTheme.md),
          Expanded(
            child: Text(
              _errorMessage ?? 'Terjadi kesalahan',
              style: const TextStyle(
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build form
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Full name field
          AppInput(
            label: 'Nama Lengkap',
            controller: _nameController,
            hintText: 'Masukkan nama lengkap Anda',
            keyboardType: TextInputType.name,
            prefixIcon: Icons.person_outline,
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

          const SizedBox(height: AppTheme.lg),

          // Phone field
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

          const SizedBox(height: AppTheme.lg),

          // Email field
          AppInput(
            label: 'Email',
            controller: _emailController,
            hintText: 'Masukkan email Anda',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
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

          const SizedBox(height: AppTheme.lg),

          // Password field
          AppInput(
            label: 'Password',
            controller: _passwordController,
            hintText: 'Min 8 karakter (huruf besar, kecil, angka)',
            obscureText: !_showPassword,
            prefixIcon: Icons.lock_outlined,
            enabled: !_isLoading,
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppTheme.gray500,
              ),
              onPressed: () {
                setState(() {
                  _showPassword = !_showPassword;
                });
              },
            ),
            validator: _validatePasswordStrength,
          ),

          const SizedBox(height: AppTheme.lg),

          // Confirm password field
          AppInput(
            label: 'Konfirmasi Password',
            controller: _confirmPasswordController,
            hintText: 'Masukkan ulang password Anda',
            obscureText: !_showConfirmPassword,
            prefixIcon: Icons.lock_outlined,
            enabled: !_isLoading,
            suffixIcon: IconButton(
              icon: Icon(
                _showConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppTheme.gray500,
              ),
              onPressed: () {
                setState(() {
                  _showConfirmPassword = !_showConfirmPassword;
                });
              },
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

  /// Build terms checkbox
  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: !_isLoading
              ? (value) {
                  setState(() {
                    _agreeToTerms = value ?? false;
                  });
                }
              : null,
          fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return AppTheme.primaryColor;
            }
            return Colors.transparent;
          }),
          side: const BorderSide(
            color: AppTheme.borderColor,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AppTheme.md),
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.gray600,
                    ),
                children: [
                  const TextSpan(text: 'Saya setuju dengan '),
                  TextSpan(
                    text: 'Syarat & Ketentuan',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const TextSpan(text: ' dan '),
                  TextSpan(
                    text: 'Kebijakan Privasi',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

  /// Build register button
  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: !_isLoading ? _handleRegister : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
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
                  const Text('Sedang mendaftar...'),
                ],
              )
            : const Text(
                'Daftar Sekarang',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  /// Build login link
  Widget _buildLoginLink() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          Text(
            'Sudah punya akun? ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.gray600,
                ),
          ),
          TextButton(
            onPressed: !_isLoading ? _handleBackToLogin : null,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.sm),
            ),
            child: Text(
              'Login Sekarang',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
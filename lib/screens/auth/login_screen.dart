import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/themes/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

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

  /// Handle login action
  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Trigger login via Riverpod provider
    await ref.read(loginProvider.notifier).login(
      email: email,
      password: password,
    );

    // Get state setelah login
    final loginState = ref.read(loginProvider);

    if (mounted) {
      if (loginState.isSuccess) {
        // Navigate ke dashboard
        context.go('/dashboard');
      } else if (loginState.error != null) {
        // Show error dialog
        _showErrorDialog(loginState.error ?? 'Unknown error');
      }
    }
  }

  /// Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Error'),
        content: Text(message),
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
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.lg,
            vertical: AppTheme.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Spacing
              SizedBox(height: MediaQuery.of(context).size.height * 0.08),

              // Logo or Title
              _buildHeader(),

              SizedBox(height: AppTheme.xl),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Email Input
                    AppInput(
                      label: 'Email',
                      controller: _emailController,
                      hintText: 'Masukkan email Anda',
                      prefixIcon: Icons.email_outlined,
                      enabled: !isLoading,
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

                    SizedBox(height: AppTheme.lg),

                    // Password Input
                    AppInput(
                      label: 'Password',
                      controller: _passwordController,
                      hintText: 'Masukkan password Anda',
                      prefixIcon: Icons.lock_outlined,
                      obscureText: !_isPasswordVisible,
                      enabled: !isLoading,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
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

                    SizedBox(height: AppTheme.md),

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading
                            ? null
                            : () => context.go('/forgot-password'),
                        child: const Text(
                          'Lupa Password?',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: AppTheme.xl),

                    // Login Button
                    SizedBox(
                      height: 50,
                      child: AppButton(
                        label: isLoading ? 'Loading...' : 'Masuk',
                        onPressed: isLoading ? null : _handleLogin,
                        isLoading: isLoading,
                      ),
                    ),

                    SizedBox(height: AppTheme.lg),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppTheme.borderColor)),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.md,
                          ),
                          child: Text(
                            'atau',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Expanded(child: Divider(color: AppTheme.borderColor)),
                      ],
                    ),

                    SizedBox(height: AppTheme.lg),

                    // Social Login Buttons
                    _buildSocialLoginButtons(isLoading),

                    SizedBox(height: AppTheme.xl),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Belum punya akun? ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => context.go('/register'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'Daftar sekarang',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build header dengan logo dan title
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo Placeholder
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: const Icon(
            Icons.local_laundry_service,
            color: Colors.white,
            size: 28,
          ),
        ),
        SizedBox(height: AppTheme.lg),
        Text(
          'Selamat Datang di NetWash',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        SizedBox(height: AppTheme.sm),
        Text(
          'Kelola bisnis laundry Anda dengan mudah dan efisien',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  /// Build social login buttons
  Widget _buildSocialLoginButtons(bool isLoading) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Google Button
        _buildSocialButton(
          icon: Icons.g_mobiledata,
          label: 'Google',
          onPressed: isLoading ? null : () => _handleGoogleLogin(),
        ),
        SizedBox(width: AppTheme.lg),
        // Phone Button
        _buildSocialButton(
          icon: Icons.phone_outlined,
          label: 'Nomor HP',
          onPressed: isLoading ? null : () => _handlePhoneLogin(),
        ),
      ],
    );
  }

  /// Build individual social button
  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
        ),
      ),
    );
  }

  /// Handle Google login
  void _handleGoogleLogin() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google login akan diimplement segera'),
        backgroundColor: AppTheme.infoColor,
      ),
    );
  }

  /// Handle Phone login
  void _handlePhoneLogin() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phone login akan diimplement segera'),
        backgroundColor: AppTheme.infoColor,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';
import '../../widgets/common/app_input.dart';

/// Create Customer Screen
class CreateCustomerScreen extends StatefulWidget {
  const CreateCustomerScreen({Key? key}) : super(key: key);

  @override
  State<CreateCustomerScreen> createState() => _CreateCustomerScreenState();
}

class _CreateCustomerScreenState extends State<CreateCustomerScreen> {
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;

  // Form key
  final _formKey = GlobalKey<FormState>();

  // State
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Handle save customer
  Future<void> _handleSaveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 2));
      // TODO: Save customer ke backend (Firestore)

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pelanggan berhasil ditambahkan! (Testing mode)'),
            backgroundColor: Color(0xFF51CF66),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? AppTheme.lg : AppTheme.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context),

              const SizedBox(height: AppTheme.xxl),

              // Form
              _buildForm(context),

              const SizedBox(height: AppTheme.xxl),

              // Save Button
              _buildSaveButton(context),

              const SizedBox(height: AppTheme.lg),
            ],
          ),
        ),
      ),
    );
  }

  /// Build App Bar
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Tambah Pelanggan'),
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    );
  }

  /// Build Header
  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.lg),
          decoration: BoxDecoration(
            color: const Color(0xFF5DADE2).withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: const Icon(
            Icons.person_add_alt_1_rounded,
            color: Color(0xFF5DADE2),
            size: 36,
          ),
        ),
        const SizedBox(height: AppTheme.xl),
        Text(
          'Pelanggan Baru',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppTheme.md),
        Text(
          'Lengkapi data pelanggan untuk menambahkannya ke sistem',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.gray600,
              ),
        ),
      ],
    );
  }

  /// Build Form
  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Nama Lengkap
          AppInput(
            label: 'Nama Lengkap *',
            controller: _nameController,
            hintText: 'Masukkan nama pelanggan',
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nama pelanggan tidak boleh kosong';
              }
              return null;
            },
          ),

          const SizedBox(height: AppTheme.lg),

          // No. Telepon
          AppInput(
            label: 'No. Telepon *',
            controller: _phoneController,
            hintText: 'Contoh: 081234567890',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'No. telepon tidak boleh kosong';
              }
              if (!RegExp(r'^[0-9]{9,14}$').hasMatch(value.trim())) {
                return 'Format no. telepon tidak valid';
              }
              return null;
            },
          ),

          const SizedBox(height: AppTheme.lg),

          // Email (opsional)
          AppInput(
            label: 'Email (Opsional)',
            controller: _emailController,
            hintText: 'Masukkan email pelanggan',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                  .hasMatch(value.trim())) {
                return 'Format email tidak valid';
              }
              return null;
            },
          ),

          const SizedBox(height: AppTheme.lg),

          // Alamat (opsional)
          AppInput(
            label: 'Alamat (Opsional)',
            controller: _addressController,
            hintText: 'Masukkan alamat pelanggan',
            prefixIcon: Icons.location_on_outlined,
            maxLines: 2,
          ),

          const SizedBox(height: AppTheme.lg),

          // Catatan (opsional)
          AppInput(
            label: 'Catatan (Opsional)',
            controller: _notesController,
            hintText: 'Catatan khusus untuk pelanggan ini',
            prefixIcon: Icons.note_outlined,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  /// Build Save Button
  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: !_isLoading ? _handleSaveCustomer : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5DADE2),
          padding: const EdgeInsets.symmetric(vertical: AppTheme.lg),
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
                  const Text(
                    'Sedang Menyimpan...',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : const Text(
                'Simpan Pelanggan',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        Navigator.pop(context, true);
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 16 : 24,
                      isMobile ? 16 : 24,
                      isMobile ? 16 : 24,
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(context),
                        const SizedBox(height: AppTheme.xl),
                        _buildHeader(context),
                        const SizedBox(height: AppTheme.xxl),
                        _buildForm(context),
                        const SizedBox(height: AppTheme.xxl),
                        _buildSaveButton(context),
                        const SizedBox(height: AppTheme.lg),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build top bar (back button + title)
  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context, false),
          borderRadius: BorderRadius.circular(11),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppTheme.textPrimary),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          'Tambah Pelanggan',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
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
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: Icon(
            Icons.person_add_alt_1_rounded,
            color: AppTheme.primaryColor,
            size: 34,
          ),
        ),
        const SizedBox(height: AppTheme.xl),
        Text(
          'Pelanggan Baru',
          style: GoogleFonts.poppins(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.sm),
        Text(
          'Lengkapi data pelanggan untuk menambahkannya ke sistem',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Build Form
  Widget _buildForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
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
      ),
    );
  }

  /// Build Save Button
  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: !_isLoading ? _handleSaveCustomer : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
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
                  Text(
                    'Sedang Menyimpan...',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : Text(
                'Simpan Pelanggan',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}
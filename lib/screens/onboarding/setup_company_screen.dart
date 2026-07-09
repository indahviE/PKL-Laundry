import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';
import '../../widgets/common/app_input.dart';

/// Setup Company Screen - Step 4 dari onboarding
class SetupCompanyScreen extends StatefulWidget {
  const SetupCompanyScreen({Key? key}) : super(key: key);

  @override
  State<SetupCompanyScreen> createState() => _SetupCompanyScreenState();
}

class _SetupCompanyScreenState extends State<SetupCompanyScreen> {
  // Controllers
  late TextEditingController _companyNameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;
  late TextEditingController _descriptionController;

  // Form key
  final _formKey = GlobalKey<FormState>();

  // State
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _phoneController = TextEditingController();
    _websiteController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Handle save company
  Future<void> _handleSaveCompany() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Connect ke Firebase atau backend API
      // Simulasi save company process
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Uncomment ini ketika Firebase setup siap
      // final companyService = ref.read(companyServiceProvider);
      // await companyService.createCompany(
      //   name: _companyNameController.text,
      //   address: _addressController.text,
      //   city: _cityController.text,
      //   phone: _phoneController.text,
      //   website: _websiteController.text,
      //   description: _descriptionController.text,
      // );

      // TODO: Navigate ke choose plan screen
      // context.go('/onboarding/choose-plan');

      // Untuk sekarang, show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data perusahaan berhasil disimpan! (Testing mode)'),
            backgroundColor: Color(0xFF51CF66),
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
              // Progress Indicator
              _buildProgressIndicator(context),

              const SizedBox(height: AppTheme.xxl),

              // Header
              _buildHeader(context),

              const SizedBox(height: AppTheme.xxl),

              // Error Message
              if (_errorMessage != null) ...[
                _buildErrorMessage(context),
                const SizedBox(height: AppTheme.lg),
              ],

              // Form
              _buildForm(context),

              const SizedBox(height: AppTheme.xxl),

              // Save Button
              _buildSaveButton(context),

              const SizedBox(height: AppTheme.lg),

              // Skip Link
              _buildSkipLink(context),

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
      title: const Text('Setup Perusahaan'),
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: !_isLoading ? () => Navigator.pop(context) : null,
      ),
    );
  }

  /// Build Progress Indicator
  Widget _buildProgressIndicator(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        Row(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF5DADE2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.sm),
            Expanded(
              flex: 3,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.md),

        // Step indicator
        Text(
          'Step 4 dari 7',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Color(0xFF5DADE2),
                fontWeight: FontWeight.w600,
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
        // Icon
        Container(
          padding: const EdgeInsets.all(AppTheme.lg),
          decoration: BoxDecoration(
            color: const Color(0xFF5DADE2).withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: const Icon(
            Icons.business_outlined,
            color: Color(0xFF5DADE2),
            size: 36,
          ),
        ),
        const SizedBox(height: AppTheme.xl),

        // Title
        Text(
          'Data Perusahaan',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.darkColor,
              ),
        ),
        const SizedBox(height: AppTheme.md),

        // Subtitle
        Text(
          'Lengkapi informasi perusahaan laundry Anda',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.gray600,
              ),
        ),
      ],
    );
  }

  /// Build Error Message
  Widget _buildErrorMessage(BuildContext context) {
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
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Form
  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Company Name Field
          AppInput(
            label: 'Nama Perusahaan *',
            controller: _companyNameController,
            hintText: 'Contoh: NetWash Jakarta',
            prefixIcon: Icons.business_outlined,
            enabled: !_isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama perusahaan tidak boleh kosong';
              }
              if (value.length < 3) {
                return 'Nama perusahaan minimal 3 karakter';
              }
              return null;
            },
          ),

          const SizedBox(height: AppTheme.lg),

          // Address Field
          AppInput(
            label: 'Alamat Lengkap *',
            controller: _addressController,
            hintText: 'Jalan, nomor, kelurahan',
            prefixIcon: Icons.location_on_outlined,
            enabled: !_isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Alamat tidak boleh kosong';
              }
              if (value.length < 5) {
                return 'Alamat minimal 5 karakter';
              }
              return null;
            },
          ),

          const SizedBox(height: AppTheme.lg),

          // City Field
          AppInput(
            label: 'Kota/Kabupaten *',
            controller: _cityController,
            hintText: 'Contoh: Jakarta Pusat',
            prefixIcon: Icons.location_city_outlined,
            enabled: !_isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Kota tidak boleh kosong';
              }
              return null;
            },
          ),

          const SizedBox(height: AppTheme.lg),

          // Phone Field
          AppInput(
            label: 'Nomor Telepon *',
            controller: _phoneController,
            hintText: 'Contoh: 0812345678',
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

          // Website Field (Optional)
          AppInput(
            label: 'Website (Optional)',
            controller: _websiteController,
            hintText: 'Contoh: www.netwash.com',
            keyboardType: TextInputType.url,
            prefixIcon: Icons.language_outlined,
            enabled: !_isLoading,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (!RegExp(r'^(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$')
                    .hasMatch(value)) {
                  return 'Format website tidak valid';
                }
              }
              return null;
            },
          ),

          const SizedBox(height: AppTheme.lg),

          // Description Field (Optional)
          AppInput(
            label: 'Deskripsi Singkat (Optional)',
            controller: _descriptionController,
            hintText: 'Jelaskan layanan atau spesialisasi perusahaan Anda',
            prefixIcon: Icons.description_outlined,
            enabled: !_isLoading,
            maxLines: 3,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (value.length < 10) {
                  return 'Deskripsi minimal 10 karakter';
                }
              }
              return null;
            },
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
        onPressed: !_isLoading ? _handleSaveCompany : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5DADE2),
          padding: const EdgeInsets.symmetric(vertical: AppTheme.lg),
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
                  const Text(
                    'Sedang Menyimpan...',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              )
            : const Text(
                'Lanjut ke Pilih Paket',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  /// Build Skip Link
  Widget _buildSkipLink(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: !_isLoading ? () => Navigator.pop(context) : null,
        child: Text(
          'Kembali',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Color(0xFF5DADE2),
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
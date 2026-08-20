import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/themes/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/services/app_feedback.dart';
import '../../repositories/subscription_repository.dart';
import '../../services/subscription_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/app_input.dart';

/// Edit Customer Screen
class EditCustomerScreen extends ConsumerStatefulWidget {
  final String customerId;

  const EditCustomerScreen({
    Key? key,
    required this.customerId,
  }) : super(key: key);

  @override
  ConsumerState<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends ConsumerState<EditCustomerScreen> {
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;

  // Form key
  final _formKey = GlobalKey<FormState>();

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _customerName;

  /// Alert error - disamakan persis dengan CreateOrderScreen/
  /// CreateCustomerScreen: pakai AppSnackbar (bukan SnackBar bawaan) +
  /// getar & suara error lewat AppFeedback, supaya rasanya konsisten
  /// di seluruh form "Tambah"/"Edit".
  void _showError(String message) {
    AppFeedback.haptic(ref, type: HapticFeedbackType.heavy);
    AppFeedback.playSound(ref, AppSound.error);
    AppSnackbar.error(context, message);
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _notesController = TextEditingController();
    _fetchCustomerData();
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

  /// Fetch existing customer data dari Firestore
  Future<void> _fetchCustomerData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'Session not found';
      }

      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final customerDoc = await userDocRef.collection('customers').doc(widget.customerId).get();

      if (!customerDoc.exists) {
        throw 'Customer not found';
      }

      final data = customerDoc.data() as Map<String, dynamic>;

      setState(() {
        _nameController.text = data['full_name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _emailController.text = data['email'] ?? '';
        _addressController.text = data['address'] ?? '';
        _notesController.text = data['notes'] ?? '';
        _customerName = data['full_name'] ?? 'Customer';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Handle update customer -> update di Firestore: users/{uid}/customers/{customerId}
  Future<void> _handleUpdateCustomer(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) {
      // Selain teks merah kecil di bawah tiap field, sekarang juga
      // munculin alert (snackbar merah + getar + suara error) - disamakan
      // dengan CreateDeliveryScreen/CreateCustomerScreen.
      _showError('Lengkapi data yang wajib diisi terlebih dahulu');
      return;
    }

        setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw l10n.sessionNotFoundError;
      }

      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      // FEATURE GATING: edit customer termasuk actionType transactional -
      // diblok begitu subscription expired & lewat grace period. Ambil
      // company_id dari subcollection companies (sama seperti
      // create_customer_screen) karena EditCustomerScreen tidak
      // menyimpan companyId langsung.
      final companiesSnapshot = await userDocRef.collection('companies').limit(1).get();
      if (companiesSnapshot.docs.isNotEmpty) {
        final companyId = companiesSnapshot.docs.first.id;
        final subscriptionRepo = ref.read(subscriptionRepositoryProvider);
        final subscription =
            await subscriptionRepo.streamSubscriptionForCompany(companyId).first;
        final subscriptionService =
            SubscriptionService(currentSubscription: subscription);
        final access =
            subscriptionService.checkAccess(SubscriptionActionType.transactional);
        if (!access.allowed) {
          throw l10n.subscriptionExpiredWarning;
        }
      }

      await userDocRef.collection('customers').doc(widget.customerId).update({
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'notes': _notesController.text.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        AppFeedback.haptic(ref);
        AppFeedback.playSound(ref, AppSound.success);
        AppSnackbar.success(context, 'Pelanggan berhasil diperbarui');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showError('Gagal memperbarui pelanggan: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Text(_errorMessage ?? 'Error', style: GoogleFonts.poppins(color: Colors.red)),
        ),
      );
    }

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
                        _buildTopBar(context, l10n),
                        const SizedBox(height: AppTheme.xl),
                        _buildHeader(context, l10n),
                        const SizedBox(height: AppTheme.xxl),
                        _buildForm(context, l10n),
                        const SizedBox(height: AppTheme.xxl),
                        _buildSaveButton(context, l10n),
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
  Widget _buildTopBar(BuildContext context, AppLocalizations l10n) {
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
          'Edit Pelanggan',
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
  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
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
            Icons.edit_outlined,
            color: AppTheme.primaryColor,
            size: 34,
          ),
        ),
        const SizedBox(height: AppTheme.xl),
        Text(
          'Edit Data Pelanggan',
          style: GoogleFonts.poppins(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.sm),
        Text(
          'Perbarui informasi pelanggan $_customerName',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Build Form
  Widget _buildForm(BuildContext context, AppLocalizations l10n) {
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
              label: '${l10n.fullNameLabel} *',
              controller: _nameController,
              hintText: l10n.customerNameHint,
              prefixIcon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.customerNameEmptyError;
                }
                return null;
              },
            ),

            const SizedBox(height: AppTheme.lg),

            // No. Telepon
            AppInput(
              label: '${l10n.phoneNumberLabel} *',
              controller: _phoneController,
              hintText: l10n.phoneNumberHint,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.phoneNumberEmptyError;
                }
                if (!RegExp(r'^[0-9]{9,14}$').hasMatch(value.trim())) {
                  return l10n.phoneNumberInvalidError;
                }
                return null;
              },
            ),

            const SizedBox(height: AppTheme.lg),

            // Email (opsional)
            AppInput(
              label: '${l10n.emailLabel}${l10n.optionalFieldSuffix}',
              controller: _emailController,
              hintText: l10n.customerEmailHint,
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                    .hasMatch(value.trim())) {
                  return l10n.emailInvalidError;
                }
                return null;
              },
            ),

            const SizedBox(height: AppTheme.lg),

            // Alamat (opsional)
            AppInput(
              label: '${l10n.addressLabel}${l10n.optionalFieldSuffix}',
              controller: _addressController,
              hintText: l10n.customerAddressHint,
              prefixIcon: Icons.location_on_outlined,
              maxLines: 2,
            ),

            const SizedBox(height: AppTheme.lg),

            // Catatan (opsional)
            AppInput(
              label: '${l10n.notesLabel}${l10n.optionalFieldSuffix}',
              controller: _notesController,
              hintText: l10n.notesHint,
              prefixIcon: Icons.note_outlined,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  /// Build Save Button
  Widget _buildSaveButton(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: !_isSaving ? () => _handleUpdateCustomer(l10n) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
        child: _isSaving
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
                    l10n.savingButtonLabel,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : Text(
                'Simpan Perubahan',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}
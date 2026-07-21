import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/themes/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/app_input.dart';

/// Opsi cabang buat dropdown, di-fetch dari users/{uid}/laundries
/// (sesuai Blueprint §3.2.3).
class _LaundryOption {
  final String id;
  final String name;

  _LaundryOption({required this.id, required this.name});

  factory _LaundryOption.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return _LaundryOption(
      id: doc.id,
      name: (data['name'] ?? 'Cabang Tanpa Nama') as String,
    );
  }
}

/// Create Customer Screen
///
/// UPDATED: sekarang customer di-assign ke 1 cabang (laundry_id) - field
/// ini TIDAK ada di skema `customers` versi PRD (Blueprint §3.3.1, cuma
/// company_id), sengaja ditambahkan supaya saat CreateOrderScreen pilih
/// Cabang A, dropdown pelanggan bisa di-filter cuma nampilin pelanggan
/// Cabang A juga (pola sama seperti employee -> laundry_id).
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

  // Cabang - dropdown cuma ditampilkan kalau _laundriesList.length > 1,
  // pola sama persis dengan _showLaundryDropdown di CreateOrderScreen.
  bool _isLoadingLaundries = true;
  String? _laundriesError;
  List<_LaundryOption> _laundriesList = [];
  String? _selectedLaundryId;

  bool get _showLaundryDropdown => _laundriesList.length > 1;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _notesController = TextEditingController();
    _fetchLaundries();
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

  /// Ambil semua cabang aktif milik company ini, buat dropdown penempatan
  /// pelanggan. Sama pola dengan _fetchBusinessContext() di
  /// CreateOrderScreen - kalau cabang cuma 1, auto-pick tanpa dropdown.
  Future<void> _fetchLaundries() async {
    setState(() {
      _isLoadingLaundries = true;
      _laundriesError = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'Sesi tidak ditemukan, silakan login ulang.';
      }
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      final companiesSnap = await userDocRef.collection('companies').limit(1).get();
      if (companiesSnap.docs.isEmpty) {
        throw 'Perusahaan belum diatur. Selesaikan onboarding terlebih dahulu.';
      }
      final companyId = companiesSnap.docs.first.id;

      final laundriesSnap = await userDocRef
          .collection('laundries')
          .where('company_id', isEqualTo: companyId)
          .where('is_active', isEqualTo: true)
          .get();
      if (laundriesSnap.docs.isEmpty) {
        throw 'Belum ada cabang laundry. Tambahkan cabang dulu sebelum menambah pelanggan.';
      }

      final laundries = laundriesSnap.docs.map((d) => _LaundryOption.fromFirestore(d)).toList();

      setState(() {
        _laundriesList = laundries;
        _selectedLaundryId = laundries.first.id;
        _isLoadingLaundries = false;
      });
    } catch (e) {
      setState(() {
        _laundriesError = e.toString();
        _isLoadingLaundries = false;
      });
    }
  }

  /// Generate customer_code berikutnya, format CUST001, CUST002, dst
  /// berdasarkan jumlah customer yang sudah ada.
  Future<String> _generateCustomerCode(CollectionReference customersRef) async {
    final countSnapshot = await customersRef.count().get();
    final nextNumber = (countSnapshot.count ?? 0) + 1;
    return 'CUST${nextNumber.toString().padLeft(3, '0')}';
  }

  /// Handle save customer -> tulis ke Firestore: users/{uid}/customers
  Future<void> _handleSaveCustomer(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLaundryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_laundriesError ?? 'Cabang belum siap, coba lagi sebentar.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw l10n.sessionNotFoundError;
      }

      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Ambil company_id dari subcollection users/{uid}/companies
      final companiesSnapshot = await userDocRef.collection('companies').limit(1).get();
      if (companiesSnapshot.docs.isEmpty) {
        throw l10n.companyNotSetupError;
      }
      final companyId = companiesSnapshot.docs.first.id;

      final customersRef = userDocRef.collection('customers');
      final customerCode = await _generateCustomerCode(customersRef);

      await customersRef.add({
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'notes': _notesController.text.trim(),
        'company_id': companyId,
        'laundry_id': _selectedLaundryId,
        'customer_code': customerCode,
        'membership_type': 'reguler',
        'is_active': true,
        'total_orders': 0,
        'total_spent': 0,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.addCustomerSuccessTesting),
            backgroundColor: const Color(0xFF51CF66),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.addCustomerError(e.toString())),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                        if (_laundriesError != null) ...[
                          _buildLaundryError(context),
                          const SizedBox(height: AppTheme.xxl),
                        ],
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

  /// Banner error kalau cabang belum siap/belum ada sama sekali.
  Widget _buildLaundryError(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: AppTheme.errorColor),
          const SizedBox(width: AppTheme.sm),
          Expanded(
            child: Text(
              _laundriesError!,
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.errorColor),
            ),
          ),
          TextButton(
            onPressed: _fetchLaundries,
            child: Text('Coba lagi', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
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
          l10n.addCustomerButton,
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
            Icons.person_add_alt_1_rounded,
            color: AppTheme.primaryColor,
            size: 34,
          ),
        ),
        const SizedBox(height: AppTheme.xl),
        Text(
          l10n.newCustomerHeaderTitle,
          style: GoogleFonts.poppins(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.sm),
        Text(
          l10n.newCustomerHeaderSubtitle,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Dropdown pilih cabang penempatan pelanggan. Cuma dirender kalau
  /// _showLaundryDropdown true (cabang > 1).
  Widget _buildLaundryDropdown(BuildContext context) {
    if (_isLoadingLaundries) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.lg),
        alignment: Alignment.center,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _laundriesList.any((l) => l.id == _selectedLaundryId) ? _selectedLaundryId : null,
      onChanged: (value) => setState(() => _selectedLaundryId = value),
      style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
      isExpanded: true,
      items: _laundriesList
          .map((laundry) => DropdownMenuItem(
                value: laundry.id,
                child: Text(
                  laundry.name,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 13.5),
                ),
              ))
          .toList(),
      decoration: InputDecoration(
        labelText: 'Cabang *',
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
        hintText: 'Pilih cabang pelanggan ini',
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textTertiary),
        prefixIcon: Icon(Icons.storefront_outlined, color: AppTheme.textTertiary),
        filled: true,
        fillColor: AppTheme.backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Pilih cabang terlebih dahulu';
        }
        return null;
      },
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
            // Dropdown cabang - cuma muncul kalau owner punya > 1 cabang
            // aktif. Kalau cuma 1 (mis. paket Starter), auto-pick tanpa
            // dropdown, sama persis pola di CreateOrderScreen.
            if (_showLaundryDropdown) ...[
              _buildLaundryDropdown(context),
              const SizedBox(height: AppTheme.lg),
            ],

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
        onPressed: !_isLoading ? () => _handleSaveCustomer(l10n) : null,
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
                    l10n.savingButtonLabel,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : Text(
                l10n.saveCustomerButton,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}
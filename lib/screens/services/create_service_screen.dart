import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/themes/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/service.dart';
import '../../repositories/laundry_repository.dart';
import '../../core/services/app_feedback.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/service_repository.dart';

/// Local design tokens matching the new "NetWash Utility System" design
/// (see DESIGN.md / code.html). Kept local to this screen instead of
/// touching the global AppTheme, so no other screen's look changes.
class _DS {
  static const canvas = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const onSurface = Color(0xFF1B1C1C);
  static const onSurfaceVariant = Color(0xFF404752);
  static const outline = Color(0xFF707883);
  static const outlineVariant = Color(0xFFBFC7D4);

  static const primary = Color(0xFF0061A4);
  static const primaryFixed = Color(0xFFD1E4FF);

  static const tertiary = Color(0xFF526069);
  static const tertiaryFixed = Color(0xFFD6E5EF);

  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);

  static const secondaryContainer = Color(0xFFE0E3E6);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static TextStyle headlineMd({Color? color}) => GoogleFonts.beVietnamPro(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color ?? onSurface,
        letterSpacing: -0.1,
      );

  static TextStyle subtitleMd({Color? color}) => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color ?? onSurfaceVariant,
      );

  static TextStyle bodyMd({Color? color}) => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color ?? onSurface,
      );

  static TextStyle bodySm({Color? color}) => GoogleFonts.beVietnamPro(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: color ?? onSurfaceVariant,
      );

  static TextStyle labelBold({Color? color}) => GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color ?? onSurfaceVariant,
        letterSpacing: 0.3,
      );
}

class CreateServiceScreen extends ConsumerStatefulWidget {
  const CreateServiceScreen({super.key});

  @override
  ConsumerState<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends ConsumerState<CreateServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _expressFeeController;
  late TextEditingController _minWeightController;
  late TextEditingController _durationController;

  PricingType _selectedPricingType = PricingType.perKg;
  String _durationUnit = 'hours'; // 'hours' | 'days'
  bool _isActive = true;
  final Set<String> _selectedBranchIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _expressFeeController = TextEditingController();
    _minWeightController = TextEditingController();
    _durationController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _expressFeeController.dispose();
    _minWeightController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _setDuration(int value, String unit) {
    setState(() {
      _durationController.text = value.toString();
      _durationUnit = unit;
    });
  }

  void _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // FirebaseAuth.instance.currentUser bersifat sinkron dan selalu
      // mencerminkan sesi login terkini, lebih aman dibanding authStateProvider
      // yang bisa sesaat null saat token sedang refresh (race condition).
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      if (userId.isEmpty) {
        throw Exception(l10n.sessionNotFoundError);
      }

      // Sesuai blueprint: setiap dokumen di users/{user_id}/service_types/
      // wajib memiliki company_id. MVP mengasumsikan 1 user = 1 company,
      // jadi company_id diambil dari users/{user_id}/companies/{company_id}
      // yang pertama dibuat.
      final companySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('companies')
          .limit(1)
          .get();

      if (companySnapshot.docs.isEmpty) {
        throw Exception(l10n.companyNotSetupError);
      }

      final companyId = companySnapshot.docs.first.id;
      final serviceRepository = ServiceRepository(userId: userId);

      final priceValue = double.parse(_priceController.text.trim());
      final durationValue = int.parse(_durationController.text.trim());
      final estimatedDurationHours =
          _durationUnit == 'days' ? durationValue * 24 : durationValue;

      double? pricePerKg;
      double? pricePerItem;
      double? expressFee;
      double? minWeight;

      switch (_selectedPricingType) {
        case PricingType.perKg:
          pricePerKg = priceValue;
          final minWeightText = _minWeightController.text.trim();
          minWeight = minWeightText.isNotEmpty ? double.tryParse(minWeightText) : null;
          break;
        case PricingType.perItem:
          pricePerItem = priceValue;
          break;
        case PricingType.express:
          // "Harga Dasar" express disimpan di pricePerItem karena sifatnya
          // flat (bukan per-kg). expressFee adalah biaya tambahan di atasnya.
          pricePerItem = priceValue;
          final feeText = _expressFeeController.text.trim();
          expressFee = feeText.isNotEmpty ? double.tryParse(feeText) : null;
          break;
      }

      final newService = Service(
        id: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: companyId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        pricingType: _selectedPricingType,
        pricePerKg: pricePerKg,
        pricePerItem: pricePerItem,
        expressFee: expressFee,
        minWeight: minWeight,
        estimatedDuration: estimatedDurationHours,
        durationUnit: _durationUnit,
        branchIds: _selectedBranchIds.toList(),
        isActive: _isActive,
        sortOrder: 0,
      );

      await serviceRepository.addService(newService);

      if (mounted) {
      AppFeedback.playSound(ref, AppSound.success);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.addServiceSuccess),
          backgroundColor: const Color(0xFF51CF66),
        ),
      );
      context.pop();
    }
    } catch (e) {
      if (mounted) {
        AppFeedback.playSound(ref, AppSound.error);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.addServiceError(e.toString())),
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
      backgroundColor: _DS.canvas,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              _buildTopBar(context, l10n),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildNameField(l10n),
                                  const SizedBox(height: AppTheme.xl),
                                  _buildPricingTypeSelector(l10n),
                                  const SizedBox(height: AppTheme.xl),
                                  ..._buildDynamicPriceFields(l10n),
                                  const SizedBox(height: AppTheme.xl),
                                  _buildDurationSection(l10n),
                                  const SizedBox(height: AppTheme.xl),
                                  _buildBranchSection(l10n),
                                  const SizedBox(height: AppTheme.xl),
                                  _buildDescriptionField(l10n),
                                  const SizedBox(height: AppTheme.xl),
                                  _buildStatusToggle(l10n),
                                  const SizedBox(height: AppTheme.xxl),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildSaveBar(l10n),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Top bar
  // ---------------------------------------------------------------------
  Widget _buildTopBar(BuildContext context, AppLocalizations l10n) {
    return Container(
      color: _DS.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 22, color: _DS.primary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            l10n.createServiceAppBarTitle,
            style: _DS.headlineMd(color: _DS.primary),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Nama Layanan
  // ---------------------------------------------------------------------
  Widget _buildNameField(AppLocalizations l10n) {
    return _sectionColumn(
      label: l10n.serviceNameLabel,
      child: TextFormField(
        controller: _nameController,
        style: _DS.bodyMd(),
        decoration: _inputDecoration(hintText: l10n.serviceNameHint),
        validator: (val) =>
            val == null || val.trim().isEmpty ? l10n.serviceNameError : null,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Tipe Layanan — Kiloan / Satuan / Express
  // ---------------------------------------------------------------------
  Widget _buildPricingTypeSelector(AppLocalizations l10n) {
    return _sectionColumn(
      label: l10n.serviceTypeSectionLabel,
      child: Row(
        children: [
          Expanded(
            child: _buildTypeCard(
              type: PricingType.perKg,
              label: l10n.pricingTypeKgChipLabel,
              icon: Icons.monitor_weight_rounded,
              iconBg: _DS.primaryFixed,
              iconColor: _DS.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTypeCard(
              type: PricingType.perItem,
              label: l10n.pricingTypeItemChipLabel,
              icon: Icons.checkroom_rounded,
              iconBg: _DS.tertiaryFixed,
              iconColor: _DS.tertiary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTypeCard(
              type: PricingType.express,
              label: l10n.pricingTypeExpressLabel,
              icon: Icons.bolt_rounded,
              iconBg: _DS.errorContainer,
              iconColor: _DS.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard({
    required PricingType type,
    required String label,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    final isSelected = _selectedPricingType == type;
    return InkWell(
      onTap: () => setState(() => _selectedPricingType = type),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? _DS.primaryFixed.withOpacity(0.35) : _DS.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _DS.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected ? [] : _DS.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: _DS.labelBold(color: _DS.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Dynamic price fields (harga, express fee, min weight)
  // ---------------------------------------------------------------------
  List<Widget> _buildDynamicPriceFields(AppLocalizations l10n) {
    String priceLabel;
    switch (_selectedPricingType) {
      case PricingType.perKg:
        priceLabel = l10n.pricePerKgFieldLabel;
        break;
      case PricingType.perItem:
        priceLabel = l10n.pricePerItemFieldLabel;
        break;
      case PricingType.express:
        priceLabel = l10n.baseFeeLabel;
        break;
    }

    final widgets = <Widget>[
      _sectionColumn(
        label: priceLabel,
        child: TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          style: _DS.bodyMd(),
          decoration: _inputDecoration(hintText: '0', prefixText: 'Rp '),
          validator: (val) {
            if (val == null || val.trim().isEmpty) return l10n.priceEmptyError;
            if (double.tryParse(val.trim()) == null) return l10n.priceInvalidError;
            return null;
          },
        ),
      ),
    ];

    if (_selectedPricingType == PricingType.express) {
      widgets.add(const SizedBox(height: AppTheme.xl));
      widgets.add(
        _sectionColumn(
          label: l10n.expressFeeLabel,
          child: TextFormField(
            controller: _expressFeeController,
            keyboardType: TextInputType.number,
            style: _DS.bodyMd(),
            decoration: _inputDecoration(hintText: '0', prefixText: 'Rp '),
          ),
        ),
      );
    }

    if (_selectedPricingType == PricingType.perKg) {
      widgets.add(const SizedBox(height: AppTheme.xl));
      widgets.add(
        _sectionColumn(
          label: l10n.minWeightLabel,
          child: TextFormField(
            controller: _minWeightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: _DS.bodyMd(),
            decoration: _inputDecoration(hintText: '1.0'),
          ),
        ),
      );
    }

    return widgets;
  }

  // ---------------------------------------------------------------------
  // Estimasi Durasi
  // ---------------------------------------------------------------------
  Widget _buildDurationSection(AppLocalizations l10n) {
    return _sectionColumn(
      label: l10n.estimatedDurationSectionLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  style: _DS.bodyMd(),
                  decoration: _inputDecoration(hintText: '0'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return l10n.durationEmptyErrorFull;
                    }
                    if (int.tryParse(val.trim()) == null) {
                      return l10n.durationInvalidErrorFull;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: _DS.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _DS.outlineVariant),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _durationUnit,
                    style: _DS.bodyMd(),
                    icon: const Icon(Icons.expand_more_rounded, color: _DS.onSurfaceVariant),
                    items: [
                      DropdownMenuItem(value: 'hours', child: Text(l10n.durationUnitHours)),
                      DropdownMenuItem(value: 'days', child: Text(l10n.durationUnitDays)),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _durationUnit = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _durationChip(l10n.durationChipHoursLabel(3), 3, 'hours'),
                const SizedBox(width: 8),
                _durationChip(l10n.durationChipDaysLabel(1), 1, 'days'),
                const SizedBox(width: 8),
                _durationChip(l10n.durationChipDaysLabel(2), 2, 'days'),
                const SizedBox(width: 8),
                _durationChip(l10n.durationChipDaysLabel(3), 3, 'days'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _durationChip(String label, int value, String unit) {
    final isActive =
        _durationController.text == value.toString() && _durationUnit == unit;
    return InkWell(
      onTap: () => _setDuration(value, unit),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _DS.primaryFixed : _DS.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? _DS.primary : _DS.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: _DS.labelBold(color: isActive ? _DS.primary : _DS.onSurfaceVariant),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Tersedia di Cabang — chip style selector
  // ---------------------------------------------------------------------
  Widget _buildBranchSection(AppLocalizations l10n) {
    final laundriesAsync = ref.watch(laundriesStreamProvider);

    return _sectionColumn(
      label: l10n.availableAtBranchesLabel,
      child: laundriesAsync.when(
        data: (laundries) {
          if (laundries.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _DS.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _DS.cardShadow,
              ),
              child: Row(
                children: [
                  Icon(Icons.store_mall_directory_outlined,
                      color: _DS.outline, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.noBranchesForServiceHint,
                      style: _DS.bodySm(),
                    ),
                  ),
                ],
              ),
            );
          }

          final allSelected = _selectedBranchIds.length == laundries.length;
          final noneSelected = _selectedBranchIds.isEmpty;

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _DS.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: _DS.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ringkasan + tombol pilih semua
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        noneSelected
                            ? l10n.noBranchSelectedLabel
                            : l10n.branchesSelectedCountLabel(
                                _selectedBranchIds.length, laundries.length),
                        style: _DS.bodySm(),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (allSelected) {
                            _selectedBranchIds.clear();
                          } else {
                            _selectedBranchIds
                              ..clear()
                              ..addAll(laundries.map((l) => l.id));
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: allSelected ? _DS.primaryFixed : _DS.canvas,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              allSelected
                                  ? Icons.remove_done_rounded
                                  : Icons.done_all_rounded,
                              size: 15,
                              color: _DS.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              allSelected ? l10n.deselectAllLabel : l10n.selectAllLabel,
                              style: _DS.labelBold(color: _DS.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Chip list cabang
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: laundries.map((laundry) {
                    final isSelected = _selectedBranchIds.contains(laundry.id);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedBranchIds.remove(laundry.id);
                          } else {
                            _selectedBranchIds.add(laundry.id);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.only(
                            left: 10, right: 14, top: 8, bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _DS.primaryFixed.withOpacity(0.55)
                              : _DS.canvas,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isSelected ? _DS.primary : _DS.outlineVariant,
                            width: isSelected ? 1.4 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? _DS.primary : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? _DS.primary : _DS.outline,
                                  width: 1.4,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded,
                                      size: 13, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              laundry.name,
                              style: _DS
                                  .bodyMd(
                                      color: isSelected
                                          ? _DS.primary
                                          : _DS.onSurface)
                                  .copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
        loading: () => Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: _DS.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _DS.cardShadow,
          ),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (err, stack) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _DS.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _DS.cardShadow,
          ),
          child: Text(l10n.loadBranchesFailedLabel, style: _DS.bodySm(color: _DS.error)),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Deskripsi
  // ---------------------------------------------------------------------
  Widget _buildDescriptionField(AppLocalizations l10n) {
    return _sectionColumn(
      label: l10n.serviceDescriptionLabel,
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 3,
        style: _DS.bodyMd(),
        decoration: _inputDecoration(hintText: l10n.serviceDescriptionHint),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Status toggle
  // ---------------------------------------------------------------------
  Widget _buildStatusToggle(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _DS.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.activeServiceSwitchTitle, style: _DS.subtitleMd(color: _DS.onSurface)),
                const SizedBox(height: 2),
                Text(l10n.activeServiceSwitchSubtitle, style: _DS.bodySm()),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (val) => setState(() => _isActive = val),
            activeColor: _DS.surface,
            activeTrackColor: _DS.primary,
            inactiveThumbColor: _DS.surface,
            inactiveTrackColor: _DS.secondaryContainer,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Save bar (sticky bottom)
  // ---------------------------------------------------------------------
  Widget _buildSaveBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.surface,
        border: const Border(top: BorderSide(color: _DS.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: !_isLoading ? _handleSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _DS.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
                        Text(l10n.savingButtonLabel, style: _DS.headlineMd(color: Colors.white)),
                      ],
                    )
                  : Text(l10n.saveServiceButton, style: _DS.headlineMd(color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------
  Widget _sectionColumn({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _DS.subtitleMd()),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration({required String hintText, String? prefixText}) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hintText,
      hintStyle: _DS.bodyMd(color: _DS.outline),
      prefixText: prefixText,
      prefixStyle: _DS.subtitleMd(),
      filled: true,
      fillColor: _DS.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border(_DS.outlineVariant, 1),
      enabledBorder: border(_DS.outlineVariant, 1),
      focusedBorder: border(_DS.primary, 1.5),
      errorBorder: border(_DS.error, 1),
      focusedErrorBorder: border(_DS.error, 1.5),
      errorStyle: _DS.bodySm(color: _DS.error),
    );
  }
}
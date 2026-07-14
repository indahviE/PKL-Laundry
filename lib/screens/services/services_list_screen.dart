import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../core/themes/app_theme.dart';
import '../../models/service.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/service_repository.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input.dart';

class ServicesListScreen extends ConsumerWidget {
  const ServicesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // Menggunakan authStateProvider sesuai berkas auth_provider.dart
    final authState = ref.watch(authStateProvider);
    final userId = authState.value?.uid ?? '';

    final serviceRepository = ServiceRepository(userId: userId);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, l10n)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              sliver: StreamBuilder<List<Service>>(
                stream: serviceRepository.streamServices(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildErrorState(context, l10n, snapshot.error),
                    );
                  }

                  final services = snapshot.data ?? [];

                  if (services.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(l10n),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = services[index];
                        return _ServiceCard(
                          service: service,
                          onEdit: () => _showEditSheet(context, serviceRepository, service),
                          onToggleActive: () => _toggleActive(context, l10n, serviceRepository, service),
                          onDelete: () => _confirmDelete(context, l10n, serviceRepository, service),
                        );
                      },
                      childCount: services.length,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/services/create'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 2,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          l10n.newServiceFab,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  // ==========================================================
  // HEADER — gradient banner senada dengan login_screen.dart,
  // konsisten dengan brand identity NetWash
  // ==========================================================
  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.servicesListAppBarTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.servicesListSubtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.local_laundry_service_rounded, color: AppTheme.primaryColor, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.layers_clear_outlined, size: 44, color: AppTheme.primaryColor.withOpacity(0.6)),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.emptyServicesTitle,
              style: GoogleFonts.poppins(
                fontSize: 15.5,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.emptyServicesSubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AppLocalizations l10n, Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 44, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              l10n.errorStateTitle,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // EDIT — bottom sheet form, prefilled dari data layanan yang ada
  // ==========================================================
  void _showEditSheet(BuildContext context, ServiceRepository repo, Service service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditServiceSheet(service: service, repository: repo),
    );
  }

  // ==========================================================
  // NONAKTIFKAN / AKTIFKAN — soft delete sesuai desain blueprint:
  // field `is_active` sudah disediakan di skema service_types (§3.3.3)
  // justru untuk kasus ini, supaya riwayat order lama yang masih
  // menyimpan snapshot service_name/harga tidak terganggu.
  // ==========================================================
  void _toggleActive(BuildContext context, AppLocalizations l10n, ServiceRepository repo, Service service) async {
    final newStatus = !service.isActive;
    try {
      await repo.updateService(service.id, {'is_active': newStatus});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? l10n.serviceActivatedSnackbar(service.name)
                  : l10n.serviceDeactivatedSnackbar(service.name),
            ),
            backgroundColor: newStatus ? Colors.green[600] : Colors.grey[700],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.toggleStatusError(e.toString())), backgroundColor: Colors.red[600]),
        );
      }
    }
  }

  // ==========================================================
  // HAPUS PERMANEN — aksi terpisah & lebih "berbahaya" dari nonaktifkan.
  // Blueprint tidak melarang, tapi karena service_type_id direferensikan
  // di orders.items, hapus permanen sebaiknya jadi opsi sadar risiko,
  // bukan default action. Nonaktifkan (di atas) adalah cara yang
  // direkomendasikan untuk pemakaian sehari-hari.
  // ==========================================================
  void _confirmDelete(BuildContext context, AppLocalizations l10n, ServiceRepository repo, Service service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[600], size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.deleteConfirmTitle,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.deleteConfirmContent(service.name),
          style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await repo.deleteService(service.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.deleteServiceSuccess(service.name)),
                      backgroundColor: Colors.green[600],
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.deleteServiceError(e.toString())),
                      backgroundColor: Colors.red[600],
                    ),
                  );
                }
              }
            },
            child: Text(l10n.deletePermanentButton, style: GoogleFonts.poppins(color: Colors.red[600], fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// KARTU LAYANAN — reusable widget, styling senada dengan
// card login (rounded 20, shadow lembut, aksen brand)
// ==========================================================
class _ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const _ServiceCard({
    required this.service,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPerKg = service.pricingType == PricingType.perKg;
    final hargaText = isPerKg
        ? l10n.pricePerKgValue(service.pricePerKg?.toStringAsFixed(0) ?? '0')
        : l10n.pricePerItemValue(service.pricePerItem?.toStringAsFixed(0) ?? '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.brandGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isPerKg ? Icons.scale_outlined : Icons.local_laundry_service_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15.5, color: AppTheme.textPrimary),
                    ),
                    if (service.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        service.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: AppTheme.textTertiary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'toggle') onToggleActive();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 18, color: Colors.black87),
                        const SizedBox(width: 10),
                        Text(l10n.editServiceMenuItem, style: GoogleFonts.poppins(fontSize: 13.5)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          service.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 18,
                          color: Colors.black87,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          service.isActive ? l10n.deactivateMenuItem : l10n.activateMenuItem,
                          style: GoogleFonts.poppins(fontSize: 13.5),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_forever_outlined, size: 18, color: Colors.red[600]),
                        const SizedBox(width: 10),
                        Text(l10n.deleteMenuItem, style: GoogleFonts.poppins(fontSize: 13.5, color: Colors.red[600])),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: AppTheme.borderColor.withOpacity(0.6)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 15, color: AppTheme.textTertiary),
              const SizedBox(width: 5),
              Text(
                l10n.durationInHours(service.estimatedDuration),
                style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: service.isActive ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  service.isActive ? l10n.activeStatusChip : l10n.inactiveStatusChip,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: service.isActive ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                hargaText,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// BOTTOM SHEET EDIT — form prefilled, memanggil
// ServiceRepository.updateService (sudah tersedia di repository)
// ==========================================================
class _EditServiceSheet extends StatefulWidget {
  final Service service;
  final ServiceRepository repository;

  const _EditServiceSheet({required this.service, required this.repository});

  @override
  State<_EditServiceSheet> createState() => _EditServiceSheetState();
}

class _EditServiceSheetState extends State<_EditServiceSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;
  late PricingType _pricingType;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _pricingType = s.pricingType;
    _isActive = s.isActive;
    _nameController = TextEditingController(text: s.name);
    _descriptionController = TextEditingController(text: s.description);
    _priceController = TextEditingController(
      text: (_pricingType == PricingType.perKg ? s.pricePerKg : s.pricePerItem)?.toStringAsFixed(0) ?? '',
    );
    _durationController = TextEditingController(text: s.estimatedDuration.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);

    try {
      final priceValue = double.parse(_priceController.text.trim());
      // FIX: pakai _pricingType.name ('perKg'/'perItem') supaya SAMA PERSIS
      // dengan Service.toJson() (dipakai ServiceRepository.addService) dan
      // yang dicari balik oleh Service.fromJson (e.name == json['pricing_type']).
      // Sebelumnya ditulis 'per_kg'/'per_item' (snake_case) yang TIDAK PERNAH
      // match, jadi tiap kali di-update, fromJson selalu jatuh ke fallback
      // PricingType.perKg — makanya harga/jenis pricing kelihatan "gak ke-update".
      await widget.repository.updateService(widget.service.id, {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'pricing_type': _pricingType.name,
        'price_per_kg': _pricingType == PricingType.perKg ? priceValue : null,
        'price_per_item': _pricingType == PricingType.perItem ? priceValue : null,
        'estimated_duration': int.parse(_durationController.text.trim()),
        'is_active': _isActive,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.saveChangesSuccess),
            backgroundColor: Colors.green[600],
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.saveChangesError(e.toString())),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.borderColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Text(
                  l10n.editServiceSheetTitle,
                  style: GoogleFonts.poppins(fontSize: 19, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.editServiceSheetSubtitle,
                  style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 22),

                AppInput(
                  controller: _nameController,
                  label: l10n.serviceNameLabel,
                  hintText: l10n.serviceNameHint,
                  validator: (val) => val == null || val.isEmpty ? l10n.serviceNameError : null,
                ),
                const SizedBox(height: 16),

                AppInput(
                  controller: _descriptionController,
                  label: l10n.serviceDescriptionLabel,
                  hintText: l10n.serviceDescriptionHint,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                Text(
                  l10n.pricingMethodLabel,
                  style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Center(child: Text(l10n.pricingTypeKgShort, style: GoogleFonts.poppins(fontWeight: FontWeight.w500))),
                        selected: _pricingType == PricingType.perKg,
                        onSelected: (selected) {
                          if (selected) setState(() => _pricingType = PricingType.perKg);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: Center(child: Text(l10n.pricingTypeItemShort, style: GoogleFonts.poppins(fontWeight: FontWeight.w500))),
                        selected: _pricingType == PricingType.perItem,
                        onSelected: (selected) {
                          if (selected) setState(() => _pricingType = PricingType.perItem);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                AppInput(
                  controller: _priceController,
                  label: _pricingType == PricingType.perKg ? l10n.pricePerKgLabel : l10n.pricePerItemLabel,
                  hintText: l10n.priceHint,
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.isEmpty) return l10n.priceEmptyError;
                    if (double.tryParse(val) == null) return l10n.priceInvalidError;
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AppInput(
                  controller: _durationController,
                  label: l10n.durationLabelShort,
                  hintText: l10n.durationHint,
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.isEmpty) return l10n.durationEmptyErrorShort;
                    if (int.tryParse(val) == null) return l10n.durationInvalidErrorShort;
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                  activeColor: AppTheme.primaryColor,
                  title: Text(
                    l10n.activeServiceSwitchTitle,
                    style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  subtitle: Text(
                    l10n.activeServiceSwitchSubtitle,
                    style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  height: 52,
                  child: AppButton(
                    label: _isSaving ? l10n.savingButtonLabel : l10n.saveChangesButton,
                    onPressed: _isSaving ? null : _handleSave,
                    isLoading: _isSaving,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
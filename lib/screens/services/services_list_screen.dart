import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../core/themes/app_theme.dart';
import '../../models/laundry.dart';
import '../../models/service.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/laundry_repository.dart';
import '../../repositories/service_repository.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input.dart';

/// Local design tokens matching the new "NetWash Utility System" design.
/// Kept local to this screen (like create_service_screen.dart) so no other
/// screen's look changes.
class _DS {
  static const canvas = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const onSurface = Color(0xFF1B1C1C);
  static const onSurfaceVariant = Color(0xFF404752);
  static const outlineVariant = Color(0xFFBFC7D4);

  static const navy = Color(0xFF0B3B66); // "selected" filter pill
  static const primary = Color(0xFF0061A4);

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

/// Visual style (bg, fg, label, icon) per pricing type — matches the color
/// coding shown in the new design (Kiloan = blue, Satuan/Item = orange,
/// Express = purple).
class _TypeStyle {
  final Color bg;
  final Color fg;
  final String label;
  final IconData icon;
  const _TypeStyle({required this.bg, required this.fg, required this.label, required this.icon});
}

const Map<PricingType, _TypeStyle> _typeStyles = {
  PricingType.perKg: _TypeStyle(
    bg: Color(0xFFDCEEFC),
    fg: Color(0xFF1976D2),
    label: 'Kiloan',
    icon: Icons.checkroom_rounded,
  ),
  PricingType.perItem: _TypeStyle(
    bg: Color(0xFFFDE9D2),
    fg: Color(0xFFE67E22),
    label: 'Satuan/Item',
    icon: Icons.checkroom_rounded,
  ),
  PricingType.express: _TypeStyle(
    bg: Color(0xFFEDE0FB),
    fg: Color(0xFF7B2FBE),
    label: 'Express',
    icon: Icons.bolt_rounded,
  ),
};

String _priceUnitSuffix(PricingType type) {
  switch (type) {
    case PricingType.perKg:
      return '/kg';
    case PricingType.perItem:
      return '/item';
    case PricingType.express:
      // Express di NetWash pada dasarnya masih dihitung per kg, hanya
      // ditambah biaya kilat (expressFee) di atasnya.
      return '/kg';
  }
}

double _displayPrice(Service service) {
  switch (service.pricingType) {
    case PricingType.perKg:
      return service.pricePerKg ?? 0;
    case PricingType.perItem:
    case PricingType.express:
      return service.pricePerItem ?? 0;
  }
}

class ServicesListScreen extends ConsumerStatefulWidget {
  const ServicesListScreen({super.key});

  @override
  ConsumerState<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends ConsumerState<ServicesListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedBranchId; // null = "Semua Cabang"
  PricingType? _selectedType; // null = "Semua"

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Menggunakan authStateProvider sesuai berkas auth_provider.dart
    final authState = ref.watch(authStateProvider);
    final userId = authState.value?.uid ?? '';

    final serviceRepository = ServiceRepository(userId: userId);
    final laundriesAsync = ref.watch(laundriesStreamProvider);
    final laundries = laundriesAsync.asData?.value ?? const <Laundry>[];

    return Scaffold(
      backgroundColor: _DS.canvas,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, l10n)),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildBranchFilter(laundries)),
            SliverToBoxAdapter(child: _buildTypeFilter()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
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

                  final allServices = snapshot.data ?? [];
                  final services = allServices.where((s) {
                    final matchesSearch = _searchQuery.isEmpty ||
                        s.name.toLowerCase().contains(_searchQuery.toLowerCase());
                    final matchesType = _selectedType == null || s.pricingType == _selectedType;
                    final matchesBranch = _selectedBranchId == null ||
                        s.branchIds.isEmpty ||
                        s.branchIds.contains(_selectedBranchId);
                    return matchesSearch && matchesType && matchesBranch;
                  }).toList();

                  if (allServices.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(l10n),
                    );
                  }

                  if (services.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildNoMatchState(),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = services[index];
                        return _ServiceCard(
                          service: service,
                          laundries: laundries,
                          onEdit: () => _showEditSheet(context, serviceRepository, service, laundries),
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
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 20, 12),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.canPop() ? context.pop() : context.go('/dashboard'),
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
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFD1E4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_laundry_service_rounded, color: _DS.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.servicesListAppBarTitle,
              style: _DS.headlineMd(color: _DS.navy),
            ),
          ),
          InkWell(
            onTap: () => context.push('/services/create'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFD1E4FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: _DS.navy, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SEARCH BAR
  // ==========================================================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: TextField(
        controller: _searchController,
        style: _DS.bodyMd(),
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Cari nama layanan...',
          hintStyle: _DS.bodyMd(color: _DS.onSurfaceVariant),
          prefixIcon: const Icon(Icons.search_rounded, color: _DS.onSurfaceVariant),
          filled: true,
          fillColor: _DS.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
        ),
      ),
    );
  }

  // ==========================================================
  // FILTER CABANG
  // ==========================================================
  Widget _buildBranchFilter(List<Laundry> laundries) {
    if (laundries.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _filterChip(
              label: 'Semua Cabang',
              isSelected: _selectedBranchId == null,
              onTap: () => setState(() => _selectedBranchId = null),
            ),
            for (final branch in laundries) ...[
              const SizedBox(width: 10),
              _filterChip(
                label: branch.name,
                isSelected: _selectedBranchId == branch.id,
                onTap: () => setState(() => _selectedBranchId = branch.id),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filterChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? _DS.navy : _DS.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isSelected ? _DS.navy : _DS.outlineVariant),
        ),
        child: Text(
          label,
          style: _DS.bodySm(
            color: isSelected ? Colors.white : _DS.onSurfaceVariant,
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // FILTER TIPE LAYANAN
  // ==========================================================
  Widget _buildTypeFilter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _typeChip(label: 'Semua', isSelected: _selectedType == null, onTap: () => setState(() => _selectedType = null)),
            for (final type in PricingType.values) ...[
              const SizedBox(width: 10),
              _typeChip(
                label: _typeStyles[type]!.label,
                bg: _typeStyles[type]!.bg,
                fg: _typeStyles[type]!.fg,
                isSelected: _selectedType == type,
                onTap: () => setState(() => _selectedType = type),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _typeChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? bg,
    Color? fg,
  }) {
    // "Semua" (bg/fg null) tetap pakai style navy-selected / outline-unselected.
    // Chip per-tipe (Kiloan/Satuan/Express) selalu tampil dengan warna
    // pastelnya sendiri sesuai desain, lalu diberi border tebal saat dipilih
    // sebagai indikator filter aktif — bukan diredupkan saat tidak dipilih.
    final bgColor = bg ?? (isSelected ? _DS.navy : _DS.surface);
    final fgColor = fg ?? (isSelected ? Colors.white : _DS.onSurfaceVariant);
    final borderColor = bg != null
        ? (isSelected ? fg! : Colors.transparent)
        : (isSelected ? Colors.transparent : _DS.outlineVariant);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor, width: isSelected && bg != null ? 1.5 : 1),
        ),
        child: Text(
          label,
          style: _DS.bodySm(color: fgColor, weight: FontWeight.w700),
        ),
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
                color: _DS.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.layers_clear_outlined, size: 44, color: _DS.primary.withOpacity(0.6)),
            ),
            const SizedBox(height: 20),
            Text(l10n.emptyServicesTitle, style: _DS.bodyMd(weight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(l10n.emptyServicesSubtitle, textAlign: TextAlign.center, style: _DS.bodySm()),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMatchState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 40, color: _DS.onSurfaceVariant.withOpacity(0.6)),
            const SizedBox(height: 14),
            Text('Tidak ada layanan yang cocok', style: _DS.bodyMd(weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Coba ubah kata kunci atau filter', style: _DS.bodySm()),
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
            Text(l10n.errorStateTitle, style: _DS.bodyMd(weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('$error', textAlign: TextAlign.center, style: _DS.bodySm()),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // EDIT — bottom sheet form, prefilled dari data layanan yang ada
  // ==========================================================
  void _showEditSheet(BuildContext context, ServiceRepository repo, Service service, List<Laundry> laundries) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditServiceSheet(service: service, repository: repo, laundries: laundries),
    );
  }

  // ==========================================================
  // NONAKTIFKAN / AKTIFKAN — soft delete sesuai desain blueprint
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
  // HAPUS PERMANEN
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
              child: Text(l10n.deleteConfirmTitle, style: _DS.bodyMd(weight: FontWeight.w600)),
            ),
          ],
        ),
        content: Text(l10n.deleteConfirmContent(service.name), style: _DS.bodySm()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: _DS.bodySm()),
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
            child: Text(
              l10n.deletePermanentButton,
              style: _DS.bodySm(color: Colors.red[600], weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// KARTU LAYANAN
// ==========================================================
class _ServiceCard extends StatelessWidget {
  final Service service;
  final List<Laundry> laundries;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const _ServiceCard({
    required this.service,
    required this.laundries,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isActive = service.isActive;
    final typeStyle = _typeStyles[service.pricingType]!;

    // Kalau tidak aktif, semua aksen warna diredupkan jadi abu-abu —
    // sesuai contoh "Setrika Saja" di desain baru.
    final iconBg = isActive ? typeStyle.bg : const Color(0xFFE9E9E9);
    final iconFg = isActive ? typeStyle.fg : const Color(0xFF9CA3AF);
    final badgeBg = isActive ? typeStyle.bg : const Color(0xFFE9E9E9);
    final badgeFg = isActive ? typeStyle.fg : const Color(0xFF6B7280);
    final priceColor = isActive ? typeStyle.fg : const Color(0xFF9CA3AF);

    final branchNames = (service.branchIds.isEmpty ||
            (laundries.isNotEmpty && service.branchIds.length >= laundries.length))
        ? const ['Semua Cabang']
        : service.branchIds
            .map((id) => laundries.where((l) => l.id == id).map((l) => l.name).firstOrNull ?? '')
            .where((name) => name.isNotEmpty)
            .toList();

    final priceValue = _displayPrice(service);
    final priceText = 'Rp${priceValue.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _DS.cardShadow,
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
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
                child: Icon(typeStyle.icon, color: iconFg, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: _DS.bodyMd(
                        color: isActive ? _DS.onSurface : const Color(0xFF9CA3AF),
                        weight: FontWeight.w700,
                      ).copyWith(fontSize: 15.5),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(8)),
                          child: Text(typeStyle.label, style: _DS.bodySm(color: badgeFg, weight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.access_time_rounded, size: 13, color: _DS.onSurfaceVariant.withOpacity(0.7)),
                        const SizedBox(width: 3),
                        Text(
                          service.durationUnit == 'days'
                              ? '${(service.estimatedDuration / 24).round()} Hari'
                              : '${service.estimatedDuration} Jam',
                          style: _DS.bodySm(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: _DS.onSurfaceVariant.withOpacity(0.5)),
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
                        Text(l10n.editServiceMenuItem, style: _DS.bodySm(color: _DS.onSurface)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 18,
                          color: Colors.black87,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isActive ? l10n.deactivateMenuItem : l10n.activateMenuItem,
                          style: _DS.bodySm(color: _DS.onSurface),
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
                        Text(l10n.deleteMenuItem, style: _DS.bodySm(color: Colors.red[600])),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: _DS.outlineVariant.withOpacity(0.5)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: branchNames
                      .map((name) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F3F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(name, style: _DS.bodySm(weight: FontWeight.w500)),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: priceText,
                      style: _DS.bodyMd(color: priceColor, weight: FontWeight.w700).copyWith(fontSize: 15),
                    ),
                    TextSpan(
                      text: _priceUnitSuffix(service.pricingType),
                      style: _DS.bodySm(color: priceColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

// ==========================================================
// BOTTOM SHEET EDIT — Kiloan / Satuan / Express + cabang
// ==========================================================
class _EditServiceSheet extends ConsumerStatefulWidget {
  final Service service;
  final ServiceRepository repository;
  final List<Laundry> laundries;

  const _EditServiceSheet({required this.service, required this.repository, required this.laundries});

  @override
  ConsumerState<_EditServiceSheet> createState() => _EditServiceSheetState();
}

class _EditServiceSheetState extends ConsumerState<_EditServiceSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _expressFeeController;
  late TextEditingController _minWeightController;
  late TextEditingController _durationController;
  late PricingType _pricingType;
  late bool _isActive;
  late Set<String> _selectedBranchIds;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _pricingType = s.pricingType;
    _isActive = s.isActive;
    _selectedBranchIds = {...s.branchIds};
    _nameController = TextEditingController(text: s.name);
    _descriptionController = TextEditingController(text: s.description);
    _priceController = TextEditingController(
      text: (_pricingType == PricingType.perKg ? s.pricePerKg : s.pricePerItem)?.toStringAsFixed(0) ?? '',
    );
    _expressFeeController = TextEditingController(text: s.expressFee?.toStringAsFixed(0) ?? '');
    _minWeightController = TextEditingController(text: s.minWeight?.toString() ?? '');
    _durationController = TextEditingController(text: s.estimatedDuration.toString());
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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);

    try {
      final priceValue = double.parse(_priceController.text.trim());

      double? pricePerKg;
      double? pricePerItem;
      double? expressFee;
      double? minWeight;

      switch (_pricingType) {
        case PricingType.perKg:
          pricePerKg = priceValue;
          final minWeightText = _minWeightController.text.trim();
          minWeight = minWeightText.isNotEmpty ? double.tryParse(minWeightText) : null;
          break;
        case PricingType.perItem:
          pricePerItem = priceValue;
          break;
        case PricingType.express:
          pricePerItem = priceValue;
          final feeText = _expressFeeController.text.trim();
          expressFee = feeText.isNotEmpty ? double.tryParse(feeText) : null;
          break;
      }

      // FIX: pakai _pricingType.name ('perKg'/'perItem'/'express') supaya
      // SAMA PERSIS dengan Service.toJson()/fromJson() (e.name ==
      // json['pricing_type']). Jangan pernah pakai snake_case di sini.
      await widget.repository.updateService(widget.service.id, {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'pricing_type': _pricingType.name,
        'price_per_kg': pricePerKg,
        'price_per_item': pricePerItem,
        'express_fee': expressFee,
        'min_weight': minWeight,
        'estimated_duration': int.parse(_durationController.text.trim()),
        'branch_ids': _selectedBranchIds.toList(),
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: Center(child: Text(l10n.pricingTypeItemShort, style: GoogleFonts.poppins(fontWeight: FontWeight.w500))),
                        selected: _pricingType == PricingType.perItem,
                        onSelected: (selected) {
                          if (selected) setState(() => _pricingType = PricingType.perItem);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: Center(child: Text('Express', style: GoogleFonts.poppins(fontWeight: FontWeight.w500))),
                        selected: _pricingType == PricingType.express,
                        onSelected: (selected) {
                          if (selected) setState(() => _pricingType = PricingType.express);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                AppInput(
                  controller: _priceController,
                  label: _pricingType == PricingType.perKg
                      ? l10n.pricePerKgLabel
                      : (_pricingType == PricingType.perItem ? l10n.pricePerItemLabel : 'Harga Dasar'),
                  hintText: l10n.priceHint,
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.isEmpty) return l10n.priceEmptyError;
                    if (double.tryParse(val) == null) return l10n.priceInvalidError;
                    return null;
                  },
                ),

                if (_pricingType == PricingType.express) ...[
                  const SizedBox(height: 16),
                  AppInput(
                    controller: _expressFeeController,
                    label: 'Biaya Tambahan Express',
                    hintText: l10n.priceHint,
                    keyboardType: TextInputType.number,
                  ),
                ],

                if (_pricingType == PricingType.perKg) ...[
                  const SizedBox(height: 16),
                  AppInput(
                    controller: _minWeightController,
                    label: 'Berat Minimum (Kg)',
                    hintText: '1.0',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],

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
                const SizedBox(height: 16),

                if (widget.laundries.isNotEmpty) ...[
                  Text(
                    'Tersedia di Cabang',
                    style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < widget.laundries.length; i++) ...[
                          if (i > 0) Divider(height: 1, color: AppTheme.borderColor),
                          CheckboxListTile(
                            value: _selectedBranchIds.contains(widget.laundries[i].id),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedBranchIds.add(widget.laundries[i].id);
                                } else {
                                  _selectedBranchIds.remove(widget.laundries[i].id);
                                }
                              });
                            },
                            controlAffinity: ListTileControlAffinity.trailing,
                            dense: true,
                            activeColor: AppTheme.primaryColor,
                            title: Text(
                              widget.laundries[i].name,
                              style: GoogleFonts.poppins(fontSize: 13.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kosongkan semua untuk tersedia di semua cabang.',
                    style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.textTertiary),
                  ),
                  const SizedBox(height: 16),
                ],

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
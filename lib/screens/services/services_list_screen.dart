import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/services/app_feedback.dart';
import '../../l10n/app_localizations.dart';
import '../../core/themes/app_theme.dart';
import '../../models/laundry.dart';
import '../../models/service.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/laundry_repository.dart';
import '../../repositories/service_repository.dart';

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

  // Tokens tambahan — disamakan dengan CreateServiceScreen supaya
  // bottom sheet edit punya tema visual yang identik dengan layar create.
  static const primaryFixed = Color(0xFFD1E4FF);
  static const tertiary = Color(0xFF526069);
  static const tertiaryFixed = Color(0xFFD6E5EF);
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const secondaryContainer = Color(0xFFE0E3E6);
  static const outline = Color(0xFF707883);

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

  static TextStyle subtitleMd({Color? color}) => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color ?? onSurfaceVariant,
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
  final IconData icon;
  const _TypeStyle({required this.bg, required this.fg, required this.icon});
}

const Map<PricingType, _TypeStyle> _typeStyles = {
  PricingType.perKg: _TypeStyle(
    bg: Color(0xFFDCEEFC),
    fg: Color(0xFF1976D2),
    icon: Icons.checkroom_rounded,
  ),
  PricingType.perItem: _TypeStyle(
    bg: Color(0xFFFDE9D2),
    fg: Color(0xFFE67E22),
    icon: Icons.checkroom_rounded,
  ),
  PricingType.express: _TypeStyle(
    bg: Color(0xFFEDE0FB),
    fg: Color(0xFF7B2FBE),
    icon: Icons.bolt_rounded,
  ),
};

/// Localized display label for each pricing type — resolved at render time
/// (instead of baked into the const _typeStyles map) so it follows the
/// active app locale.
String _typeLabel(AppLocalizations l10n, PricingType type) {
  switch (type) {
    case PricingType.perKg:
      return l10n.pricingTypeKgChipLabel;
    case PricingType.perItem:
      return l10n.pricingTypeItemChipLabel;
    case PricingType.express:
      return l10n.pricingTypeExpressLabel;
  }
}

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
            SliverToBoxAdapter(child: _buildSearchBar(l10n)),
            SliverToBoxAdapter(child: _buildBranchFilter(laundries, l10n)),
            SliverToBoxAdapter(child: _buildTypeFilter(l10n)),
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
                      child: _buildNoMatchState(l10n),
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
  Widget _buildSearchBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: TextField(
        controller: _searchController,
        style: _DS.bodyMd(),
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: l10n.searchServiceHint,
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
  Widget _buildBranchFilter(List<Laundry> laundries, AppLocalizations l10n) {
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
              label: l10n.allBranchesLabel,
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
  Widget _buildTypeFilter(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _typeChip(label: l10n.filterAllLabel, isSelected: _selectedType == null, onTap: () => setState(() => _selectedType = null)),
            for (final type in PricingType.values) ...[
              const SizedBox(width: 10),
              _typeChip(
                label: _typeLabel(l10n, type),
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

  Widget _buildNoMatchState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 40, color: _DS.onSurfaceVariant.withOpacity(0.6)),
            const SizedBox(height: 14),
            Text(l10n.noMatchingServicesTitle, style: _DS.bodyMd(weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(l10n.tryDifferentKeywordFilterHint, style: _DS.bodySm()),
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
        AppFeedback.playSound(ref, AppSound.success);
        if (newStatus) {
          AppSnackbar.success(context, l10n.serviceActivatedSnackbar(service.name));
        } else {
          AppSnackbar.info(context, l10n.serviceDeactivatedSnackbar(service.name));
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.playSound(ref, AppSound.error);
        AppSnackbar.error(context, l10n.toggleStatusError(e.toString()));
      }
    }
  }

  // ==========================================================
  // HAPUS PERMANEN — gaya AlertDialog disamakan dengan
  // _confirmCancelOrder di OrderDetailScreen (title plain bold,
  // tombol batal abu-abu, tombol aksi merah bold, tanpa icon warning).
  // ==========================================================
  void _confirmDelete(BuildContext context, AppLocalizations l10n, ServiceRepository repo, Service service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text(
          l10n.deleteConfirmTitle,
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, color: _DS.onSurface),
        ),
        content: Text(l10n.deleteConfirmContent(service.name), style: _DS.bodySm()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: GoogleFonts.beVietnamPro(color: _DS.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await repo.deleteService(service.id);
                if (context.mounted) {
                  AppFeedback.playSound(ref, AppSound.success);
                  AppSnackbar.success(context, l10n.deleteServiceSuccess(service.name));
                }
              } catch (e) {
                if (context.mounted) {
                  AppFeedback.playSound(ref, AppSound.error);
                  AppSnackbar.error(context, l10n.deleteServiceError(e.toString()));
                }
              }
            },
            child: Text(
              l10n.deletePermanentButton,
              style: GoogleFonts.beVietnamPro(color: _DS.error, fontWeight: FontWeight.w700),
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

  // Badge cabang - tampil 1 nama cabang pertama + "+N" kalau lebih dari
  // satu, supaya gak overflow/melar ke bawah kalau layanan tersedia di
  // banyak cabang. Nama pertama dipotong ellipsis kalau kepanjangan.
  Widget _branchBadge(List<String> branchNames) {
    if (branchNames.length <= 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          branchNames.isNotEmpty ? branchNames.first : '-',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _DS.bodySm(weight: FontWeight.w500),
        ),
      );
    }

    final extra = branchNames.length - 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              branchNames.first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _DS.bodySm(weight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _DS.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '+$extra',
            style: _DS.bodySm(color: _DS.primary, weight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

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

    // FIX: sebelumnya kalau jumlah branchIds tersimpan >= jumlah total
    // cabang SAAT INI, otomatis dianggap "Semua Cabang" - ini salah kalau
    // ada cabang yang DIHAPUS belakangan (total cabang berkurang, jadi
    // kebetulan jumlahnya <= branchIds lama), padahal layanan ini aslinya
    // cuma dipilih untuk sebagian cabang. Sekarang "Semua Cabang" HANYA
    // ditampilkan kalau branchIds memang benar-benar kosong (sesuai
    // konvensi: kosong = tersedia di semua cabang).
    final branchNames = service.branchIds.isEmpty
        ? [l10n.allBranchesLabel]
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
                          child: Text(_typeLabel(l10n, service.pricingType), style: _DS.bodySm(color: badgeFg, weight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.access_time_rounded, size: 13, color: _DS.onSurfaceVariant.withOpacity(0.7)),
                        const SizedBox(width: 3),
                        Text(
                          service.durationUnit == 'days'
                              ? l10n.durationChipDaysLabel((service.estimatedDuration / 24).round())
                              : l10n.durationChipHoursLabel(service.estimatedDuration),
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
              Expanded(child: _branchBadge(branchNames)),
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
// BOTTOM SHEET EDIT — tema disamakan dengan CreateServiceScreen
// (warna, font Be Vietnam Pro, card tipe layanan, tombol, alert)
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
    if (!_formKey.currentState!.validate()) {
      AppFeedback.playSound(ref, AppSound.error);
      return;
    }

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
        AppFeedback.playSound(ref, AppSound.success);
        AppSnackbar.success(context, l10n.saveChangesSuccess);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.playSound(ref, AppSound.error);
        AppSnackbar.error(context, l10n.saveChangesError(e.toString()));
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
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
        decoration: const BoxDecoration(
          color: _DS.canvas,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle + title bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: _DS.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(l10n.editServiceSheetTitle, style: _DS.headlineMd(color: _DS.primary)),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close_rounded, color: _DS.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l10n.editServiceSheetSubtitle, style: _DS.bodySm()),
                  ),
                ],
              ),
            ),
            // Scrollable form body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _sectionColumn(
                        label: l10n.serviceNameLabel,
                        child: TextFormField(
                          controller: _nameController,
                          style: _DS.bodyMd(),
                          decoration: _inputDecoration(hintText: l10n.serviceNameHint),
                          validator: (val) => val == null || val.trim().isEmpty ? l10n.serviceNameError : null,
                        ),
                      ),
                      const SizedBox(height: 20),

                      _sectionColumn(
                        label: l10n.serviceDescriptionLabel,
                        child: TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          style: _DS.bodyMd(),
                          decoration: _inputDecoration(hintText: l10n.serviceDescriptionHint),
                        ),
                      ),
                      const SizedBox(height: 20),

                      _sectionColumn(
                        label: l10n.pricingMethodLabel,
                        child: Row(
                          children: [
                            Expanded(
                              child: _typeCard(
                                type: PricingType.perKg,
                                label: l10n.pricingTypeKgChipLabel,
                                icon: Icons.monitor_weight_rounded,
                                iconBg: _DS.primaryFixed,
                                iconColor: _DS.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _typeCard(
                                type: PricingType.perItem,
                                label: l10n.pricingTypeItemChipLabel,
                                icon: Icons.checkroom_rounded,
                                iconBg: _DS.tertiaryFixed,
                                iconColor: _DS.tertiary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _typeCard(
                                type: PricingType.express,
                                label: l10n.pricingTypeExpressLabel,
                                icon: Icons.bolt_rounded,
                                iconBg: _DS.errorContainer,
                                iconColor: _DS.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      _sectionColumn(
                        label: _pricingType == PricingType.perKg
                            ? l10n.pricePerKgLabel
                            : (_pricingType == PricingType.perItem ? l10n.pricePerItemLabel : l10n.baseFeeLabel),
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

                      if (_pricingType == PricingType.express) ...[
                        const SizedBox(height: 20),
                        _sectionColumn(
                          label: l10n.expressFeeLabel,
                          child: TextFormField(
                            controller: _expressFeeController,
                            keyboardType: TextInputType.number,
                            style: _DS.bodyMd(),
                            decoration: _inputDecoration(hintText: '0', prefixText: 'Rp '),
                          ),
                        ),
                      ],

                      if (_pricingType == PricingType.perKg) ...[
                        const SizedBox(height: 20),
                        _sectionColumn(
                          label: l10n.minWeightLabel,
                          child: TextFormField(
                            controller: _minWeightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: _DS.bodyMd(),
                            decoration: _inputDecoration(hintText: '1.0'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      _sectionColumn(
                        label: l10n.durationLabelShort,
                        child: TextFormField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          style: _DS.bodyMd(),
                          decoration: _inputDecoration(hintText: l10n.durationHint),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return l10n.durationEmptyErrorShort;
                            if (int.tryParse(val.trim()) == null) return l10n.durationInvalidErrorShort;
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (widget.laundries.isNotEmpty) ...[
                        _sectionColumn(
                          label: l10n.availableAtBranchesLabel,
                          child: _buildBranchPicker(l10n),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.emptyBranchSelectionMeansAllHint,
                          style: _DS.bodySm().copyWith(fontSize: 11.5),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Status toggle — sama seperti card status di CreateServiceScreen
                      Container(
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
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
            // Sticky save bar — sama seperti _buildSaveBar di CreateServiceScreen
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
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
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: !_isSaving ? _handleSave : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _DS.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.7)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(l10n.savingButtonLabel, style: _DS.headlineMd(color: Colors.white)),
                          ],
                        )
                      : Text(l10n.saveChangesButton, style: _DS.headlineMd(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // Type card — identik dengan _buildTypeCard di CreateServiceScreen
  // --------------------------------------------------------
  Widget _typeCard({
    required PricingType type,
    required String label,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    final isSelected = _pricingType == type;
    return InkWell(
      onTap: () => setState(() => _pricingType = type),
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
            Text(label, textAlign: TextAlign.center, style: _DS.labelBold(color: _DS.onSurface)),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // Branch picker — identik dengan _buildBranchSection di CreateServiceScreen
  // --------------------------------------------------------
  Widget _buildBranchPicker(AppLocalizations l10n) {
    final laundries = widget.laundries;
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
          Row(
            children: [
              Expanded(
                child: Text(
                  noneSelected
                      ? l10n.noBranchSelectedLabel
                      : l10n.branchesSelectedCountLabel(_selectedBranchIds.length, laundries.length),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: allSelected ? _DS.primaryFixed : _DS.canvas,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        allSelected ? Icons.remove_done_rounded : Icons.done_all_rounded,
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
                  padding: const EdgeInsets.only(left: 10, right: 14, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? _DS.primaryFixed.withOpacity(0.55) : _DS.canvas,
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
                            ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        laundry.name,
                        style: _DS.bodyMd(color: isSelected ? _DS.primary : _DS.onSurface).copyWith(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
  }

  // --------------------------------------------------------
  // Shared helpers — identik dengan CreateServiceScreen
  // --------------------------------------------------------
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
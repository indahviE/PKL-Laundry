import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/themes/app_theme.dart';
import '../../models/laundry.dart';
import '../../repositories/laundry_repository.dart';
import '../../l10n/app_localizations.dart';

/// Local design tokens matching the new "NetWash Utility System" design
/// (samain persis dengan EmployeesListScreen: canvas abu kebiruan, kartu
/// putih shadow lembut, Be Vietnam Pro, header navy + icon badge biru muda).
/// Sengaja TIDAK menyentuh AppTheme global, biar layar lain gak ikut berubah.
class _DS {
  static const canvas = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const onSurface = Color(0xFF1B1C1C);
  static const onSurfaceVariant = Color(0xFF404752);
  static const outline = Color(0xFF707883);
  static const outlineVariant = Color(0xFFBFC7D4);

  static const navy = Color(0xFF0B3B66);
  static const primary = Color(0xFF0061A4);
  static const primaryFixed = Color(0xFFD1E4FF);

  static const error = Color(0xFFBA1A1A);
  static const success = Color(0xFF27AE60);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

/// Warna badge status - disamakan persis dengan referensi visual
const _kSuccessBg = Color(0xFFDCFCE7);
const _kSuccessText = Color(0xFF15803D);
const _kInactiveBg = Color(0xFFF3F4F6);
const _kInactiveText = Color(0xFF4B5563);

/// Laundries (Cabang) List Screen
class LaundriesListScreen extends ConsumerStatefulWidget {
  const LaundriesListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LaundriesListScreen> createState() => _LaundriesListScreenState();
}

class _LaundriesListScreenState extends ConsumerState<LaundriesListScreen> {
  // Controllers
  late TextEditingController _searchController;

  // State
  String _selectedFilter = 'all'; // all, active, inactive
  String _searchQuery = '';
  bool _showAllList = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filter dan search cabang
  List<Laundry> _applyFiltersAndSearch(List<Laundry> laundries) {
    final query = _searchQuery.trim().toLowerCase();
    return laundries.where((laundry) {
      final statusMatch = _selectedFilter == 'all' ||
          (_selectedFilter == 'active' && laundry.isActive) ||
          (_selectedFilter == 'inactive' && !laundry.isActive);
      final searchMatch = query.isEmpty ||
          laundry.name.toLowerCase().contains(query) ||
          laundry.code.toLowerCase().contains(query) ||
          laundry.city.toLowerCase().contains(query);
      return statusMatch && searchMatch;
    }).toList();
  }

  /// Buka Create Laundry screen
  Future<void> _openCreateLaundry(BuildContext context) async {
    await context.push<bool>('/laundries/create');
  }

  @override
  Widget build(BuildContext context) {
    final laundriesAsync = ref.watch(laundriesStreamProvider);

    return Scaffold(
      // Disamakan dengan EmployeesListScreen (canvas abu kebiruan)
      backgroundColor: _DS.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;
            final horizontalPadding = isMobile ? 16.0 : 24.0;

            return Column(
              children: [
                // ==== Bagian yang TETAP (pinned) saat di-scroll ====
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Container(
                      // Beri warna background yang sama dengan Scaffold supaya
                      // konten yang lewat di bawahnya tidak terlihat menembus.
                      color: _DS.canvas,
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        isMobile ? 16 : 24,
                        horizontalPadding,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context),
                          const SizedBox(height: AppTheme.lg),
                        ],
                      ),
                    ),
                  ),
                ),
                // ==== Bagian yang BISA di-scroll ====
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            0,
                            horizontalPadding,
                            24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSearchBar(context),
                              const SizedBox(height: AppTheme.lg),
                              _buildFilterButtons(context),
                              const SizedBox(height: AppTheme.xl),
                              laundriesAsync.when(
                                data: (laundries) {
                                  final filtered = _applyFiltersAndSearch(laundries);
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildStatsSummary(context, laundries),
                                      const SizedBox(height: AppTheme.xl),
                                      filtered.isEmpty
                                          ? _buildEmptyState(context)
                                          : _buildLaundriesList(context, filtered),
                                      const SizedBox(height: 88),
                                    ],
                                  );
                                },
                                loading: () => const Padding(
                                  padding: EdgeInsets.symmetric(vertical: AppTheme.xxl),
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                                error: (error, stack) => _buildErrorState(context, error),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Build header
  Widget _buildHeader(BuildContext context) {
    final canGoBack = context.canPop();
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        if (canGoBack) ...[
          InkWell(
            onTap: () => context.pop(),
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
        ],
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _DS.primaryFixed,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.storefront_outlined, color: _DS.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            l10n.laundriesTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.beVietnamPro(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: _DS.navy,
            ),
          ),
        ),
        InkWell(
          onTap: () => _openCreateLaundry(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: _DS.primaryFixed,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_rounded, color: _DS.navy, size: 22),
          ),
        ),
      ],
    );
  }

  /// Build search bar
  Widget _buildSearchBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: _DS.primary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.beVietnamPro(fontSize: 13.5, color: _DS.onSurface),
        decoration: InputDecoration(
          hintText: l10n.searchLaundryHint,
          hintStyle: GoogleFonts.beVietnamPro(fontSize: 13.5, color: _DS.outline),
          prefixIcon: Icon(Icons.search, color: _DS.outline),
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
            borderSide: BorderSide(color: _DS.primary, width: 1.5),
          ),
          filled: true,
          fillColor: _DS.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.lg,
            vertical: AppTheme.md,
          ),
        ),
      ),
    );
  }

  /// Build filter buttons
  /// FIX OVERFLOW: sebelumnya pakai `SingleChildScrollView(horizontal) + Row`,
  /// yang tetap bisa overflow secara visual/terpotong di layar sempit karena
  /// isi tiap chip dipaksa 1 baris. Diganti ke `Wrap` supaya kalau total
  /// lebar 3 chip tidak muat di 1 baris (mis. layar 360px), chip terakhir
  /// otomatis turun ke baris berikutnya alih-alih overflow ke luar layar.
  Widget _buildFilterButtons(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filters = [
      ('all', l10n.filterAllLaundries, Icons.apartment_outlined),
      ('active', l10n.filterActiveLaundries, Icons.check_circle_outline),
      ('inactive', l10n.filterInactiveLaundries, Icons.pause_circle_outline),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = _selectedFilter == f.$1;
          return InkWell(
            onTap: () => setState(() => _selectedFilter = f.$1),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? _DS.navy : _DS.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: isSelected ? _DS.navy : _DS.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(f.$3, size: 15, color: isSelected ? Colors.white : _DS.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    f.$2,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : _DS.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build stats summary
  Widget _buildStatsSummary(BuildContext context, List<Laundry> laundries) {
    final l10n = AppLocalizations.of(context)!;
    final totalLaundries = laundries.length;
    final activeLaundries = laundries.where((l) => l.isActive).length;

    return Row(
      children: [
        Expanded(
          child: _StatBox(
            title: l10n.totalLaundriesLabel,
            value: '$totalLaundries',
            icon: Icons.apartment_outlined,
            color: _DS.primary,
          ),
        ),
        const SizedBox(width: AppTheme.lg),
        Expanded(
          child: _StatBox(
            title: l10n.activeLaundriesLabel,
            value: '$activeLaundries',
            icon: Icons.check_circle_outline,
            color: _kSuccessText,
          ),
        ),
      ],
    );
  }

  /// Build empty state
  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.xxl),
        child: Column(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: _DS.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.storefront_outlined,
                size: 40,
                color: _DS.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppTheme.lg),
            Text(
              l10n.emptyLaundriesTitle,
              style: GoogleFonts.beVietnamPro(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _DS.onSurface,
              ),
            ),
            const SizedBox(height: AppTheme.sm),
            Text(
              l10n.emptyLaundriesSubtitle,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                color: _DS.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.xl),
            ElevatedButton.icon(
              onPressed: () => _openCreateLaundry(context),
              icon: const Icon(Icons.add_business_outlined, size: 18),
              label: Text(l10n.addBranchButton, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _DS.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.xl, vertical: AppTheme.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.xxl),
        child: Column(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: AppTheme.lg),
            Text(
              l10n.loadLaundriesError,
              style: GoogleFonts.beVietnamPro(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _DS.onSurface,
              ),
            ),
            const SizedBox(height: AppTheme.sm),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 12.5,
                color: _DS.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build laundries list
  Widget _buildLaundriesList(BuildContext context, List<Laundry> laundries) {
    final l10n = AppLocalizations.of(context)!;
    const previewCount = 3;
    final visible = _showAllList ? laundries : laundries.take(previewCount).toList();
    final hasMore = laundries.length > previewCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.branchListTitle(laundries.length),
              style: GoogleFonts.beVietnamPro(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _DS.onSurface,
              ),
            ),
            if (hasMore)
              TextButton(
                onPressed: () => setState(() => _showAllList = !_showAllList),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _showAllList ? l10n.hideLabel : l10n.viewAllLabel,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _DS.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppTheme.md),
        ...List.generate(
          visible.length,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index < visible.length - 1 ? AppTheme.lg : 0),
            child: _LaundryCard(
              laundry: visible[index],
              onTap: () => context.push('/laundries/${visible[index].id}'),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================
// HELPER WIDGETS
// ============================================

/// Stat Box Widget
class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: _DS.primary.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: AppTheme.md),
          Text(
            value,
            style: GoogleFonts.beVietnamPro(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _DS.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              color: _DS.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// Laundry (Cabang) Card Widget
class _LaundryCard extends StatelessWidget {
  final Laundry laundry;
  final VoidCallback onTap;

  const _LaundryCard({
    required this.laundry,
    required this.onTap,
  });

  DayHours _todayHours(OperatingHours hours) {
    final list = [
      hours.monday,
      hours.tuesday,
      hours.wednesday,
      hours.thursday,
      hours.friday,
      hours.saturday,
      hours.sunday,
    ];
    return list[DateTime.now().weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final today = _todayHours(laundry.operatingHours);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.lg),
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: _DS.primary.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 76),
                  child: _buildCardHeaderRow(context, l10n, today),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: 5),
                    decoration: BoxDecoration(
                      color: laundry.isActive ? _kSuccessBg : _kInactiveBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      (laundry.isActive ? l10n.filterActiveLaundries : l10n.filterInactiveLaundries).toUpperCase(),
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: laundry.isActive ? _kSuccessText : _kInactiveText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.md),
            Divider(height: 1, color: _DS.outlineVariant.withOpacity(0.6)),
            const SizedBox(height: AppTheme.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 16, color: _DS.primary),
                    const SizedBox(width: 6),
                    Text(
                      l10n.cardCapacityLabel(laundry.capacity),
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _DS.onSurface,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.chevron_right_rounded, color: _DS.primary, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeaderRow(BuildContext context, AppLocalizations l10n, DayHours today) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _DS.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.storefront_rounded,
            color: _DS.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: AppTheme.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      laundry.name,
                      style: GoogleFonts.beVietnamPro(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                        color: _DS.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _DS.outlineVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      laundry.code,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _DS.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 13,
                    color: _DS.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      laundry.city.isNotEmpty
                          ? '${laundry.address}, ${laundry.city}'
                          : laundry.address,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12.5,
                        color: _DS.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(Icons.schedule_outlined, size: 13, color: _DS.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      laundry.isActive ? l10n.openTodayStatus(today.open, today.close) : l10n.closedTemporarilyLabel,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: _DS.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/themes/app_theme.dart';
import '../../models/laundry.dart';
import '../../repositories/laundry_repository.dart';
import '../../l10n/app_localizations.dart';

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
      // Disamakan background-nya dengan Detail Screen (#F5F7FA)
      backgroundColor: const Color(0xFFFBF9F8),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
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
                        _buildHeader(context),
                        const SizedBox(height: 22),
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
                              ],
                            );
                          },
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppTheme.xxl),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (error, stack) => _buildErrorState(context, error),
                        ),
                        const SizedBox(height: 88),
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

  /// Build header
  Widget _buildHeader(BuildContext context) {
    final canGoBack = context.canPop();
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        if (canGoBack) ...[
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary, size: 22),
            ),
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.laundriesTitle,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.laundriesSubtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: AppTheme.primaryColor,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () => _openCreateLaundry(context),
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.add_rounded, color: Colors.white, size: 22),
            ),
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
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: l10n.searchLaundryHint,
          hintStyle: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textTertiary),
          prefixIcon: Icon(Icons.search, color: AppTheme.textTertiary),
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
          filled: true,
          fillColor: AppTheme.cardColor,
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

    return Wrap(
      spacing: AppTheme.md,
      runSpacing: AppTheme.sm,
      children: List.generate(
        filters.length,
        (index) => FilterChip(
          selected: _selectedFilter == filters[index].$1,
          onSelected: (selected) {
            setState(() {
              _selectedFilter = filters[index].$1;
            });
          },
          showCheckmark: false,
          // Mencegah overflow vertikal dan memberikan padding yang pas
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          labelPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: EdgeInsets.zero,
          label: Row(
            mainAxisSize: MainAxisSize.min, // Menghindari horizontal/flex overflow
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                filters[index].$3,
                size: 15,
                color: _selectedFilter == filters[index].$1
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                filters[index].$2,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: _selectedFilter == filters[index].$1
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.cardColor,
          selectedColor: AppTheme.primaryColor.withOpacity(0.12),
          side: BorderSide(
            color: _selectedFilter == filters[index].$1
                ? AppTheme.primaryColor.withOpacity(0.4)
                : AppTheme.borderColor,
          ),
        ),
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
            color: AppTheme.primaryColor,
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
                color: AppTheme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.storefront_outlined,
                size: 40,
                color: AppTheme.primaryColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppTheme.lg),
            Text(
              l10n.emptyLaundriesTitle,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.sm),
            Text(
              l10n.emptyLaundriesSubtitle,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.xl),
            ElevatedButton.icon(
              onPressed: () => _openCreateLaundry(context),
              icon: const Icon(Icons.add_business_outlined, size: 18),
              label: Text(l10n.addBranchButton, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
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
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.sm),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build laundries list
  Widget _buildLaundriesList(BuildContext context, List<Laundry> laundries) {
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
              'Daftar Cabang (${laundries.length})',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
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
                  _showAllList ? 'Sembunyikan' : 'Lihat Semua',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
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
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textTertiary,
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
                      style: GoogleFonts.poppins(
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
            Divider(height: 1, color: AppTheme.borderColor.withOpacity(0.6)),
            const SizedBox(height: AppTheme.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      l10n.cardCapacityLabel(laundry.capacity),
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.chevron_right_rounded, color: AppTheme.primaryColor, size: 20),
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
            color: AppTheme.primaryColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.storefront_rounded,
            color: AppTheme.primaryColor,
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
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.borderColor.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      laundry.code,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
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
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      laundry.city.isNotEmpty
                          ? '${laundry.address}, ${laundry.city}'
                          : laundry.address,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(Icons.schedule_outlined, size: 13, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      laundry.isActive ? 'Buka • ${today.open} - ${today.close}' : 'Tutup Sementara',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textSecondary,
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
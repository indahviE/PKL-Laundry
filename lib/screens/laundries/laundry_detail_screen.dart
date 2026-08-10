import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/themes/app_theme.dart';
import '../../models/laundry.dart';
import '../../models/employee.dart';
import '../../repositories/laundry_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/services/app_feedback.dart';
import '../employees/employees_list_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// ---------------------------------------------------------------------------
// Design tokens — diselaraskan dengan referensi visual "Kelola Cabang"
// (code.html), yang menggunakan palet Material 3 + font Be Vietnam Pro.
// Token ini dipakai lokal di screen ini (bukan mengubah AppTheme global).
// ---------------------------------------------------------------------------
/// Local design tokens matching the new "NetWash Utility System" design
/// (samain persis dengan EmployeesListScreen/EmployeeDetailScreen: canvas
/// abu kebiruan #F5F7FA, kartu putih shadow lembut, Be Vietnam Pro, header
/// navy + icon badge biru muda). Sengaja TIDAK menyentuh AppTheme global.
class _DS {
  static const canvas = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const onSurface = Color(0xFF1B1C1C);
  static const onSurfaceVariant = Color(0xFF404752);
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

const _kPrimary = _DS.primary;
const _kPageBg = _DS.canvas;
const _kSurfaceContainerLowest = _DS.surface;
const _kOnSurface = _DS.onSurface;
const _kSecondary = _DS.onSurfaceVariant;
const _kOutlineVariant = _DS.outlineVariant;
const _kActiveBg = Color(0xFFDCFCE7);
const _kActiveText = Color(0xFF15803D);
const _kInactiveBg = Color(0xFFF3F4F6);
const _kInactiveText = Color(0xFF4B5563);

/// Shadow kartu netral ala "card-shadow" pada referensi (bukan lagi tinted
/// warna primary), supaya kartu terasa flat & bersih di atas [_kPageBg].
const List<BoxShadow> _kCardShadow = [
  BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4)),
];

/// Laundry (Cabang) Detail Screen
///
/// Restyle mengikuti referensi visual "Branch Detail - NetWash" (code.html):
/// - Header identitas dengan aksen border kiri + badge status.
/// - Bento grid statistik ringkas (staf, kapasitas, jam buka hari ini).
/// - Kartu informasi dengan judul section + baris ikon bulat.
/// - Jam operasional collapsible dengan highlight hari berjalan.
/// Semua nilai tetap diambil dari data asli (Laundry, Employee, l10n) - tidak
/// ada data dummy.
class LaundryDetailScreen extends ConsumerStatefulWidget {
  final String laundryId;

  const LaundryDetailScreen({Key? key, required this.laundryId}) : super(key: key);

  @override
  ConsumerState<LaundryDetailScreen> createState() => _LaundryDetailScreenState();
}

class _LaundryDetailScreenState extends ConsumerState<LaundryDetailScreen> {
  // State lokal untuk expand/collapse kartu jam operasional lengkap.
  bool _hoursExpanded = true;

  // State lokal untuk expand/collapse daftar staf cabang - default
  // TERTUTUP (beda dari jam operasional) karena daftar karyawan bisa
  // panjang dan bikin halaman jadi berat/kepanjangan kalau selalu
  // terbuka penuh.
  bool _staffExpanded = false;

  // Controller peta lokasi cabang - dipakai untuk tombol "kembali ke
  // titik awal" saat user sudah geser/zoom peta menjauh dari marker asli.
  final MapController _detailMapController = MapController();

  List<String> _dayLabels(AppLocalizations l10n) => [
        l10n.monday,
        l10n.tuesday,
        l10n.wednesday,
        l10n.thursday,
        l10n.friday,
        l10n.saturday,
        l10n.sunday,
      ];

  List<DayHours> _dayHoursList(OperatingHours hours) => [
        hours.monday,
        hours.tuesday,
        hours.wednesday,
        hours.thursday,
        hours.friday,
        hours.saturday,
        hours.sunday,
      ];

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Laundry laundry) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.deleteBranchTitle,
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          l10n.deleteBranchConfirmDetail(laundry.name, laundry.code),
          style: GoogleFonts.beVietnamPro(fontSize: 13, color: _kSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: GoogleFonts.beVietnamPro(color: _kSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteButton, style: GoogleFonts.beVietnamPro(color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(laundryRepositoryProvider).deleteLaundryBranch(laundry.id);
      if (context.mounted) {
        context.pop();
        AppFeedback.playSound(ref, AppSound.success);
        AppSnackbar.success(context, l10n.branchDeleteSuccess(laundry.name));
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.playSound(ref, AppSound.error);
        AppSnackbar.error(context, l10n.deleteBranchError(e.toString()));
      }
    }
  }

  Future<void> _toggleActive(BuildContext context, WidgetRef ref, Laundry laundry) async {
    try {
      await ref.read(laundryRepositoryProvider).updateLaundryBranch(
        laundry.id,
        {'is_active': !laundry.isActive},
      );
      if (context.mounted) {
        AppFeedback.playSound(ref, AppSound.success);
      }
    } catch (e) {
      if (context.mounted) {
        AppFeedback.playSound(ref, AppSound.error);
        AppSnackbar.error(context, AppLocalizations.of(context)!.toggleStatusError(e.toString()));
      }
    }
  }

  String _formatDate(AppLocalizations l10n, DateTime date) {
    final months = [
      l10n.monthJan, l10n.monthFeb, l10n.monthMar, l10n.monthApr, l10n.monthMay, l10n.monthJun,
      l10n.monthJul, l10n.monthAug, l10n.monthSep, l10n.monthOct, l10n.monthNov, l10n.monthDec,
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final laundryAsync = ref.watch(laundryByIdProvider(widget.laundryId));
    final employeesAsync = ref.watch(employeesStreamProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _kPageBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;
            final horizontalPadding = isMobile ? 16.0 : 24.0;

            return laundryAsync.when(
              data: (laundry) {
                if (laundry == null) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            isMobile ? 16 : 24,
                            horizontalPadding,
                            24,
                          ),
                          child: _buildNotFound(context, l10n),
                        ),
                      ),
                    ),
                  );
                }
                final allEmployees = employeesAsync.value ?? const <Employee>[];
                final branchStaff = allEmployees.where((e) => e.laundryId == laundry.id).toList();
                return Column(
                  children: [
                    // ==== Top bar TETAP (pinned) saat konten di-scroll ====
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: Container(
                          color: _kPageBg,
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            isMobile ? 16 : 24,
                            horizontalPadding,
                            0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTopBar(context, ref, laundry, l10n),
                              const SizedBox(height: AppTheme.lg),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // ==== Konten detail yang bisa di-scroll ====
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 700),
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
                                  _buildIdentityHeader(context, ref, laundry, l10n),
                                  const SizedBox(height: AppTheme.lg),
                                  _buildStatsGrid(context, laundry, branchStaff, l10n),
                                  const SizedBox(height: AppTheme.lg),
                                  _buildInfoCard(context, laundry, l10n),
                                  const SizedBox(height: AppTheme.lg),
                                  _buildStaffCard(context, branchStaff, employeesAsync.isLoading, l10n),
                                  const SizedBox(height: AppTheme.lg),
                                  _buildCapacityLocationCard(context, laundry, l10n),
                                  const SizedBox(height: AppTheme.lg),
                                  _buildMetaCard(context, laundry, l10n),
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        isMobile ? 16 : 24,
                        horizontalPadding,
                        24,
                      ),
                      child: _buildErrorState(context, error, l10n),
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

  /// Top bar: tombol back + judul + aksi edit + aksi hapus - disamakan
  /// persis dengan pola EmployeeDetailScreen (tombol back bulat shadow,
  /// icon badge biru muda, tombol aksi bulat biru muda di kanan).
  Widget _buildTopBar(BuildContext context, WidgetRef ref, Laundry laundry, AppLocalizations l10n) {
    return Row(
      children: [
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                laundry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: _DS.navy,
                ),
              ),
              Text(
                laundry.code,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: _kSecondary,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () => context.push('/laundries/${laundry.id}/edit'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: _DS.primaryFixed,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit_outlined, color: _DS.navy, size: 18),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => _confirmDelete(context, ref, laundry),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _DS.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.delete_outline_rounded, color: _DS.error, size: 18),
          ),
        ),
      ],
    );
  }

  /// Kartu identitas utama: aksen border kiri, badge status (tap untuk toggle),
  /// nama cabang, dan alamat singkat sebagai subtitle - meniru header card
  /// pada referensi visual, dengan data asli laundry.
  Widget _buildIdentityHeader(BuildContext context, WidgetRef ref, Laundry laundry, AppLocalizations l10n) {
    final subtitle = [laundry.address, laundry.city].where((s) => s.isNotEmpty).join(', ');

    return Container(
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        color: _kSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: _kPrimary, width: 4)),
        boxShadow: _kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Badge status: rounded-lg + bg-color-100/text-color-700,
              // meniru badge "Aktif/Nonaktif" pada kartu referensi.
              InkWell(
                onTap: () => _toggleActive(context, ref, laundry),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: laundry.isActive ? _kActiveBg : _kInactiveBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    (laundry.isActive ? l10n.filterActiveLaundries : l10n.filterInactiveLaundries).toUpperCase(),
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: laundry.isActive ? _kActiveText : _kInactiveText,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '• ${l10n.updatedLabel}: ${_formatDate(l10n, laundry.updatedAt)}',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.beVietnamPro(fontSize: 11.5, color: _kSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            laundry.name,
            style: GoogleFonts.beVietnamPro(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: _kOnSurface,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.beVietnamPro(fontSize: 13, color: _kSecondary),
            ),
          ],
        ],
      ),
    );
  }

  /// Bento grid statistik ringkas: total staf, kapasitas, & jam buka hari ini.
  /// Semua angka berasal dari data asli (jumlah karyawan cabang, kapasitas
  /// mesin, dan jadwal operasional), bukan angka contoh seperti pada referensi.
  Widget _buildStatsGrid(BuildContext context, Laundry laundry, List<Employee> branchStaff, AppLocalizations l10n) {
    final dayHours = _dayHoursList(laundry.operatingHours);
    final todayIndex = DateTime.now().weekday - 1;
    final todayHours = dayHours[todayIndex];

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatTile(
              icon: Icons.group_outlined,
              iconColor: _kPrimary,
              label: l10n.totalStaffLabel,
              value: '${branchStaff.length}',
              big: true,
            ),
          ),
          const SizedBox(width: AppTheme.md),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.inventory_2_outlined,
                    iconColor: _kPrimary,
                    label: l10n.capacityShortLabel,
                    value: '${laundry.capacity}',
                  ),
                ),
                const SizedBox(height: AppTheme.md),
                Expanded(
                  child: _StatTile(
                    icon: Icons.schedule_outlined,
                    iconColor: Colors.white,
                    label: l10n.openTodayLabel,
                    value: todayHours.isOpen ? '${todayHours.open} - ${todayHours.close}' : l10n.dayOffLabel,
                    filled: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu "Informasi Cabang": alamat, kontak, & jam operasional.
  Widget _buildInfoCard(BuildContext context, Laundry laundry, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.lg, AppTheme.lg, AppTheme.lg, AppTheme.md),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: _kPrimary, size: 20),
                const SizedBox(width: 8),
                _sectionTitle(l10n.contactInfoSection),
              ],
            ),
          ),
          Divider(height: 1, color: _kOutlineVariant.withOpacity(0.5)),
          Padding(
            padding: const EdgeInsets.all(AppTheme.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(
                  Icons.location_on_outlined,
                  l10n.addressShortLabel,
                  [laundry.address, laundry.city, laundry.province].where((s) => s.isNotEmpty).join(', '),
                ),
                const SizedBox(height: AppTheme.md),
                _infoRow(Icons.call_outlined, l10n.phoneShortLabel, laundry.phone.isNotEmpty ? laundry.phone : '-'),
                const SizedBox(height: AppTheme.md),
                _infoRow(Icons.email_outlined, l10n.emailLabel, laundry.email.isNotEmpty ? laundry.email : '-'),
                Divider(height: AppTheme.lg * 2, color: _kOutlineVariant.withOpacity(0.4)),
                _buildOperatingHoursSection(context, laundry, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Jam operasional collapsible dengan highlight hari berjalan - meniru
  /// interaksi toggle pada referensi visual (chevron berputar saat expand).
  Widget _buildOperatingHoursSection(BuildContext context, Laundry laundry, AppLocalizations l10n) {
    final dayHours = _dayHoursList(laundry.operatingHours);
    final dayLabels = _dayLabels(l10n);
    final todayIndex = DateTime.now().weekday - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _hoursExpanded = !_hoursExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.operatingHoursLabel.toUpperCase(),
                style: GoogleFonts.beVietnamPro(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: _kSecondary,
                ),
              ),
              AnimatedRotation(
                turns: _hoursExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.expand_more, color: _kSecondary, size: 20),
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: AppTheme.sm),
            child: Column(
              children: List.generate(7, (i) {
                final isToday = i == todayIndex;
                return Padding(
                  padding: EdgeInsets.only(bottom: i < 6 ? AppTheme.sm : 0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 92,
                        child: Text(
                          dayLabels[i],
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12.5,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                            color: isToday ? _kPrimary : _kOnSurface,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          dayHours[i].isOpen ? '${dayHours[i].open} - ${dayHours[i].close}' : l10n.dayOffLabel,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12.5,
                            fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                            fontStyle: dayHours[i].isOpen ? FontStyle.normal : FontStyle.italic,
                            color: isToday ? _kPrimary : (dayHours[i].isOpen ? _kSecondary : _DS.error),
                          ),
                        ),
                      ),
                      if (isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppTheme.sm, vertical: 2),
                          decoration: BoxDecoration(
                            color: _kPrimary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            l10n.todayLabel,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
          crossFadeState: _hoursExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  /// Kartu manajer & staf cabang (daftar karyawan dengan laundry_id yang sama).
  /// Collapsible - defaultnya cuma nampilin judul + jumlah staf (biar
  /// halaman gak kepanjangan kalau stafnya banyak), tap header buat
  /// expand/collapse daftarnya, sama pola dengan jam operasional di atas.
  Widget _buildStaffCard(BuildContext context, List<Employee> staff, bool isLoading, AppLocalizations l10n) {
    String displayNameOf(Employee e) => e.fullName.isNotEmpty ? e.fullName : (e.employeeCode.isNotEmpty ? e.employeeCode : '-');

    return Container(
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        color: _kSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _staffExpanded = !_staffExpanded),
            child: Row(
              children: [
                Icon(Icons.groups_outlined, color: _kPrimary, size: 20),
                const SizedBox(width: 8),
                Expanded(child: _sectionTitle(l10n.staffAtThisBranchLabel(staff.length))),
                if (isLoading)
                  const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  AnimatedRotation(
                    turns: _staffExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, color: _kSecondary, size: 20),
                  ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: AppTheme.md),
              child: staff.isEmpty
                  ? Text(
                      l10n.noStaffAtBranch,
                      style: GoogleFonts.beVietnamPro(fontSize: 12.5, color: _kSecondary),
                    )
                  : Column(
                      children: staff
                          .map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: AppTheme.sm),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: _kPrimary.withOpacity(0.1),
                                      child: Text(
                                        displayNameOf(e)[0].toUpperCase(),
                                        style: GoogleFonts.beVietnamPro(fontSize: 11, color: _kPrimary, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayNameOf(e),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.beVietnamPro(fontSize: 12.5, fontWeight: FontWeight.w600, color: _kOnSurface),
                                          ),
                                          Text(
                                            e.position,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.beVietnamPro(fontSize: 11, color: _kSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: (e.isActive ? Colors.green : Colors.grey).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        e.isActive ? l10n.filterActiveLaundries : l10n.resignedLabel,
                                        style: TextStyle(color: e.isActive ? Colors.green : Colors.grey, fontSize: 9.5, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
            ),
            crossFadeState: _staffExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  /// Kartu lokasi: preview peta (placeholder visual, tanpa API key) + tombol
  /// "Lihat di Google Maps" yang membuka koordinat asli laundry di aplikasi
  /// Maps - meniru kartu peta pada referensi visual.
  Widget _buildCapacityLocationCard(BuildContext context, Laundry laundry, AppLocalizations l10n) {
    final hasLocation = laundry.location.lat != 0.0 || laundry.location.lng != 0.0;
    final latLng = LatLng(laundry.location.lat, laundry.location.lng);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _kSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _kCardShadow,
      ),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          children: [
            // Peta beneran (read-only, tanpa interaksi user - cuma preview)
            // pakai tile OpenStreetMap via flutter_map, gratis tanpa API key.
            // Kalau belum ada lokasi tersimpan, tampilkan placeholder abu-abu
            // seperti sebelumnya supaya gak nge-load tile buat koordinat 0,0.
            Positioned.fill(
              child: hasLocation
                  ? FlutterMap(
                      mapController: _detailMapController,
                      options: MapOptions(
                        initialCenter: latLng,
                        initialZoom: 15,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.netwash.app', // ganti sesuai applicationId kamu
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: latLng,
                              width: 40,
                              height: 40,
                              alignment: Alignment.topCenter,
                              child: const Icon(Icons.location_on, size: 40, color: _kPrimary),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFE1EAF5), Color(0xFFF2F5F9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(Icons.map_outlined, size: 56, color: _kPrimary.withOpacity(0.18)),
                      ),
                    ),
            ),
            // Tombol "kembali ke titik awal" - cuma muncul kalau peta aktif
            // (ada lokasi tersimpan), ngambang di pojok kanan atas kartu
            // supaya gak nutupin marker atau tombol Google Maps di bawah.
            if (hasLocation)
              Positioned(
                right: 12,
                top: 12,
                child: InkWell(
                  onTap: () => _detailMapController.move(latLng, 15),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: _kCardShadow,
                    ),
                    child: Icon(Icons.my_location_rounded, size: 18, color: _kPrimary),
                  ),
                ),
              ),
            Positioned(
              left: 12,
              bottom: 12,
              child: InkWell(
                onTap: hasLocation ? () => _openInGoogleMaps(context, laundry) : null,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: _kCardShadow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.near_me_rounded, size: 14, color: _kPrimary),
                      const SizedBox(width: 6),
                      Text(
                        hasLocation ? l10n.coordinatesLabel.toUpperCase() : l10n.notSetLabel.toUpperCase(),
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: _kPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Buka koordinat laundry di aplikasi/situs Google Maps.
  /// Butuh package `url_launcher` di pubspec.yaml (belum ada import-nya
  /// otomatis kalau project belum pakai package ini).
  Future<void> _openInGoogleMaps(BuildContext context, Laundry laundry) async {
    final lat = laundry.location.lat;
    final lng = laundry.location.lng;
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        AppFeedback.playSound(ref, AppSound.error);
        AppSnackbar.error(context, AppLocalizations.of(context)!.toggleStatusError(e.toString()));
      }
    }
  }

  /// Kartu metadata: dibuat & diperbarui.
  Widget _buildMetaCard(BuildContext context, Laundry laundry, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        color: _kSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _kCardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _metaItem(l10n.createdLabel, _formatDate(l10n, laundry.createdAt)),
          ),
          Container(width: 1, height: 32, color: _kOutlineVariant.withOpacity(0.6)),
          Expanded(
            child: _metaItem(l10n.updatedLabel, _formatDate(l10n, laundry.updatedAt)),
          ),
        ],
      ),
    );
  }

  Widget _metaItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.beVietnamPro(fontSize: 11, color: _kSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _kOnSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _kOnSurface,
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _kPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(icon, size: 16, color: _kPrimary),
        ),
        const SizedBox(width: AppTheme.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.beVietnamPro(fontSize: 9.5, letterSpacing: 0.5, color: _kSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _kOnSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotFound(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 100),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.storefront_outlined,
                size: 40,
                color: _kPrimary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppTheme.lg),
            Text(
              l10n.branchNotFoundTitle,
              style: GoogleFonts.beVietnamPro(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _kOnSurface,
              ),
            ),
            const SizedBox(height: AppTheme.sm),
            Text(
              l10n.branchNotFoundSubtitle,
              style: GoogleFonts.beVietnamPro(fontSize: 13, color: _kSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 100),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
            ),
            const SizedBox(height: AppTheme.lg),
            Text(
              l10n.loadLaundriesError,
              style: GoogleFonts.beVietnamPro(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _kOnSurface,
              ),
            ),
            const SizedBox(height: AppTheme.sm),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(fontSize: 12.5, color: _kSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu kecil untuk bento-grid statistik di bagian atas halaman.
/// [big] memberi padding lebih besar & ukuran angka lebih besar untuk sel
/// utama (mis. total staf). [filled] membuat kartu berwarna primer solid
/// (dipakai untuk highlight "Jam Buka Hari Ini"), meniru sel berwarna pada
/// referensi visual.
class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool big;
  final bool filled;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.big = false,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // Padding lebih ketat utk tile kecil (non-`big`) supaya konten tidak
      // overflow di tinggi terbatas hasil split Column Expanded di grid.
      padding: EdgeInsets.symmetric(
        horizontal: big ? AppTheme.lg : 12,
        vertical: big ? AppTheme.lg : 8,
      ),
      decoration: BoxDecoration(
        color: filled ? _kPrimary : _kSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: big ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: big ? 40 : 24,
            height: big ? 40 : 24,
            decoration: BoxDecoration(
              color: filled ? Colors.white.withOpacity(0.18) : iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(big ? 14 : 8),
            ),
            child: Icon(icon, size: big ? 20 : 13, color: filled ? Colors.white : iconColor),
          ),
          SizedBox(height: big ? AppTheme.md : 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.beVietnamPro(
                  fontSize: big ? 11 : 9.5,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                  color: filled ? Colors.white.withOpacity(0.85) : _kSecondary,
                ),
              ),
              SizedBox(height: big ? 2 : 1),
              Text(
                value,
                style: GoogleFonts.beVietnamPro(
                  fontSize: big ? 22 : 14,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: filled ? Colors.white : _kOnSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
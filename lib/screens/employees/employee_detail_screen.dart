import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/themes/app_theme.dart';
import '../../core/services/app_feedback.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../models/employee.dart';
import '../../repositories/employee_repository.dart';
import '../../repositories/laundry_repository.dart';
import '../../l10n/app_localizations.dart';

/// Local design tokens matching the new "NetWash Utility System" design
/// (samain persis dengan ServicesListScreen, EmployeesListScreen, dan
/// CreateEmployeeScreen). Sengaja TIDAK menyentuh AppTheme global.
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
}

/// Model ringan untuk satu entri riwayat aktivitas karyawan (UI-only).
/// Diisi dari EmployeeActivityEntry (employee_repository.dart) lewat
/// _buildActivityItems - bukan lagi data dummy.
class _ActivityItem {
  final IconData icon;
  final String label;
  final String time;
  final String dateGroup;
  final bool isLatest;

  const _ActivityItem({
    required this.icon,
    required this.label,
    required this.time,
    required this.dateGroup,
    this.isLatest = false,
  });
}

// Gunakan ConsumerWidget untuk mengakses Riverpod Provider secara efisien
class EmployeeDetailScreen extends ConsumerWidget {
  final String employeeId;

  const EmployeeDetailScreen({super.key, required this.employeeId});

  // Helper untuk mendapatkan inisial nama untuk Avatar lingkaran
  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // Helper formatting uang (Salary) agar serupa dengan format di Customer
  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  /// Konversi EmployeeActivityEntry (data asli, dari status_history order)
  /// jadi _ActivityItem (model UI). Entri pertama (paling baru, karena
  /// stream sudah di-sort descending) ditandai isLatest.
  List<_ActivityItem> _buildActivityItems(BuildContext context, List<EmployeeActivityEntry> entries) {
    final l10n = AppLocalizations.of(context)!;
    return List.generate(entries.length, (i) {
      final e = entries[i];
      return _ActivityItem(
        icon: _iconForActivityStatus(e.status),
        label: l10n.activityLogEntryLabel(_statusLabelFor(context, e.status), e.orderNumber),
        time: e.timestamp != null
            ? '${e.timestamp!.hour.toString().padLeft(2, '0')}.${e.timestamp!.minute.toString().padLeft(2, '0')}'
            : '-',
        dateGroup: _dateGroupFor(context, e.timestamp),
        isLatest: i == 0,
      );
    });
  }

  IconData _iconForActivityStatus(String status) {
    switch (status) {
      case 'washing':
        return Icons.local_laundry_service;
      case 'drying':
        return Icons.air;
      case 'ironing':
        return Icons.checkroom;
      case 'qualityCheck':
        return Icons.verified;
      default:
        return Icons.circle;
    }
  }

  String _statusLabelFor(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'washing':
        return l10n.orderDetailStatusWashing;
      case 'drying':
        return l10n.orderDetailStatusDrying;
      case 'ironing':
        return l10n.orderDetailStatusIroning;
      case 'qualityCheck':
        return l10n.orderDetailStatusQualityCheck;
      default:
        return status;
    }
  }

  String _dateGroupFor(BuildContext context, DateTime? ts) {
    final l10n = AppLocalizations.of(context)!;
    if (ts == null) return '-';
    final now = DateTime.now();
    final that = DateTime(ts.year, ts.month, ts.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return l10n.today;
    if (diff == 1) return l10n.yesterday;
    return '${ts.day}/${ts.month}/${ts.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ambil data karyawan dari StreamProvider
    final employeeAsync = ref.watch(employeeDetailProvider(employeeId));
    final laundriesAsync = ref.watch(laundriesStreamProvider);
    final laundryNames = <String, String>{
      for (final l in laundriesAsync.value ?? const []) l.id: l.name,
    };

    return Scaffold(
      backgroundColor: _DS.canvas,
      body: SafeArea(
        child: Column(
          children: [
            employeeAsync.when(
              data: (employee) => _buildTopBar(context, employee),
              error: (_, __) => _buildTopBar(context, null),
              loading: () => _buildTopBar(context, null),
            ),
            Expanded(
              child: employeeAsync.when(
                data: (employee) {
                  if (employee == null) {
                    return _buildErrorState(AppLocalizations.of(context)!.employeeNotFoundError);
                  }
                  return _buildContent(context, ref, employee, laundryNames);
                },
                error: (err, stack) => _buildErrorState(AppLocalizations.of(context)!.employeeGenericError(err.toString())),
                loading: () => Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: _DS.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Top bar - samain persis pola ServicesListScreen: tombol back bulat
  /// (shadow), icon box badge biru muda, judul, tombol edit bulat biru muda
  /// di kanan (cuma muncul kalau data karyawan sudah ada).
  Widget _buildTopBar(BuildContext context, Employee? employee) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 20, 12),
      child: Row(
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
            child: const Icon(Icons.badge_outlined, color: _DS.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(AppLocalizations.of(context)!.employeeDetailTitle, style: _DS.headlineMd(color: _DS.navy)),
          ),
          if (employee != null)
            InkWell(
              onTap: () => context.push('/employees/${employee.id}/edit'),
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
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Employee employee, Map<String, String> laundryNames) {
    final displayName = employee.fullName.isNotEmpty
        ? employee.fullName
        : (employee.employeeCode.isNotEmpty ? AppLocalizations.of(context)!.employeeCodeFallback(employee.employeeCode) : AppLocalizations.of(context)!.laundryStaffFallback);
    final initials = _getInitials(employee.fullName.isNotEmpty ? employee.fullName : employee.position);

    // Riwayat aktivitas pengerjaan tahap proses (washing/drying/ironing/
    // qualityCheck), di-derive real-time dari status_history order lewat
    // employeeActivityLogProvider - lihat employee_repository.dart.
    final activityLogAsync = ref.watch(employeeActivityLogProvider(employee.id));
    final activities = activityLogAsync.when(
      data: (entries) => _buildActivityItems(context, entries),
      loading: () => const <_ActivityItem>[],
      error: (_, __) => const <_ActivityItem>[],
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Profile Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _DS.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: _DS.cardShadow,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: _DS.primaryFixed,
                        child: Text(
                          initials,
                          style: GoogleFonts.beVietnamPro(
                            color: _DS.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _DS.bodyMd(weight: FontWeight.w700).copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            // Role/jabatan & status ditaruh di baris sendiri
                            // (Wrap) supaya keduanya bisa wrap ke bawah kalau
                            // ruang sempit, tidak overflow.
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _DS.primaryFixed.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    employee.position.isNotEmpty ? employee.position.toUpperCase() : '-',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _DS.bodySm(color: _DS.primary, weight: FontWeight.w700).copyWith(fontSize: 11),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (employee.isActive ? _DS.success : Colors.grey).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    employee.isActive ? AppLocalizations.of(context)!.statusActive : AppLocalizations.of(context)!.statusInactive,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _DS.bodySm(
                                      color: employee.isActive ? _DS.success : Colors.grey.shade600,
                                      weight: FontWeight.w700,
                                    ).copyWith(fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Card Kontak & Penempatan
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _DS.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: _DS.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildContactRow(
                        icon: Icons.phone_outlined,
                        label: AppLocalizations.of(context)!.phoneNumberLabel,
                        value: employee.phone.isNotEmpty ? employee.phone : '-',
                        color: const Color(0xFF2F80ED),
                      ),
                      const SizedBox(height: 18),
                      _buildContactRow(
                        icon: Icons.email_outlined,
                        label: AppLocalizations.of(context)!.emailLabel,
                        value: employee.email.isNotEmpty ? employee.email : '-',
                        color: const Color(0xFFAB47BC),
                      ),
                      const SizedBox(height: 18),
                      _buildContactRow(
                        icon: Icons.storefront_outlined,
                        label: AppLocalizations.of(context)!.assignedBranchLabel,
                        value: laundryNames[employee.laundryId] ?? '-',
                        color: const Color(0xFFF2994A),
                      ),
                      if (employee.hireDate != null) ...[
                        const SizedBox(height: 18),
                        _buildContactRow(
                          icon: Icons.calendar_today_outlined,
                          label: AppLocalizations.of(context)!.hireDateLabel,
                          value: '${employee.hireDate!.day}/${employee.hireDate!.month}/${employee.hireDate!.year}',
                          color: const Color(0xFF2BB3A3),
                        ),
                      ],
                      if (employee.address.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1, color: _DS.outlineVariant.withOpacity(0.6)),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on_outlined, size: 20, color: _DS.onSurfaceVariant.withOpacity(0.7)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(AppLocalizations.of(context)!.addressFullLabel, style: _DS.bodySm(color: _DS.onSurface, weight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(employee.address, style: _DS.bodyMd(color: _DS.onSurfaceVariant).copyWith(fontSize: 13.5)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 3 & 4. Informasi Pekerjaan & Hak Akses Sistem (accordion)
                _ExpandableInfoCard(
                  icon: Icons.work_outline,
                  title: AppLocalizations.of(context)!.employmentInfoTitle,
                  children: [
                    _buildInfoRow(Icons.badge_outlined, AppLocalizations.of(context)!.documentIdLabel, employee.id),
                    _buildInfoRow(Icons.qr_code_outlined, AppLocalizations.of(context)!.employeeCodeLabel, employee.employeeCode),
                    _buildInfoRow(Icons.work_outline, AppLocalizations.of(context)!.positionLabel, employee.position),
                    _buildInfoRow(Icons.payments_outlined, AppLocalizations.of(context)!.baseSalaryShortLabel, _formatCurrency(employee.salary)),
                    _buildInfoRow(Icons.percent_outlined, AppLocalizations.of(context)!.commissionLabel, '${employee.commissionRate}%'),
                  ],
                ),
                const SizedBox(height: 12),
                _ExpandableInfoCard(
                  icon: Icons.admin_panel_settings_outlined,
                  title: AppLocalizations.of(context)!.systemAccessTitle,
                  children: [
                    _buildPermissionRow(Icons.shopping_bag_outlined, AppLocalizations.of(context)!.createOrdersPermissionShort, employee.permissions.canCreateOrder),
                    _buildPermissionRow(Icons.people_outline, AppLocalizations.of(context)!.manageCustomersPermissionShort, employee.permissions.canManageCustomer),
                    _buildPermissionRow(Icons.bar_chart_outlined, AppLocalizations.of(context)!.viewReportsPermissionShort, employee.permissions.canViewReport),
                  ],
                ),
                const SizedBox(height: 12),

                // 5. Riwayat Aktivitas - accordion dengan diagram timeline +
                // pencarian & filter tanggal inline (tanpa pindah halaman).
                // Datanya dari employeeActivityLogProvider (real, bukan dummy).
                _ActivityHistoryCard(
                  activities: activities,
                ),
                const SizedBox(height: 12),

                // 6. Reset Password tetap baris menu biasa
                _buildMenuRow(
                  context,
                  icon: Icons.lock_reset_outlined,
                  label: AppLocalizations.of(context)!.resetPasswordLabel,
                  onTap: () {
                    AppFeedback.haptic(ref, type: HapticFeedbackType.light);
                    AppFeedback.playSound(ref, AppSound.notification);
                    AppSnackbar.info(context, AppLocalizations.of(context)!.resetPasswordUnavailable);
                  },
                ),
                const SizedBox(height: AppTheme.xxl),

                // 7. Tombol Nonaktifkan Karyawan (Soft Delete)
                if (employee.isActive)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showTerminateDialog(context, ref, employee.id),
                      icon: Icon(Icons.person_off_outlined, size: 18, color: _DS.error),
                      label: Text(
                        AppLocalizations.of(context)!.deactivateEmployeeTitle,
                        style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, fontSize: 13.5, color: _DS.error),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _DS.error.withOpacity(0.08),
                        foregroundColor: _DS.error,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Baris kontak: icon dalam kotak bulat berwarna, label bold di atas,
  /// value di bawahnya.
  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 19, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _DS.bodySm(color: _DS.onSurface, weight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _DS.bodyMd(color: _DS.onSurfaceVariant).copyWith(fontSize: 13.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _DS.onSurfaceVariant.withOpacity(0.7)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _DS.bodySm(color: _DS.onSurfaceVariant, weight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _DS.bodyMd(color: _DS.onSurface, weight: FontWeight.w600).copyWith(fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(IconData icon, String label, bool hasPermission) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _DS.onSurfaceVariant.withOpacity(0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _DS.bodySm(color: _DS.onSurfaceVariant, weight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            hasPermission ? Icons.check_circle : Icons.cancel,
            color: hasPermission ? _DS.success : Colors.grey.shade400,
            size: 20,
          ),
        ],
      ),
    );
  }

  /// Baris menu (icon kiri, label, chevron kanan) - sekarang cuma dipakai
  /// untuk "Reset Password".
  Widget _buildMenuRow(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _DS.cardShadow,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: _DS.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _DS.bodyMd(color: _DS.onSurface, weight: FontWeight.w600).copyWith(fontSize: 13.5),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: _DS.onSurfaceVariant.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: _DS.error.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: _DS.bodyMd(color: _DS.onSurfaceVariant, weight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // Menampilkan dialog konfirmasi soft-termination agar sinkron dengan repository
  void _showTerminateDialog(BuildContext context, WidgetRef ref, String employeeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context)!.deactivateEmployeeTitle, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700)),
        content: Text(
          AppLocalizations.of(context)!.deactivateEmployeeConfirmAlt,
          style: _DS.bodySm(color: _DS.onSurfaceVariant).copyWith(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, color: _DS.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () async {
              // Mengakses repositori melalui Riverpod dan memecat karyawan secara soft-terminate
              await ref.read(employeeRepositoryProvider).terminateEmployee(employeeId);
              if (context.mounted) {
                Navigator.pop(context); // Tutup Dialog
                context.pop(); // Kembali ke daftar karyawan
              }
            },
            child: Text(AppLocalizations.of(context)!.yesDeactivateButton, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, color: _DS.error)),
          ),
        ],
      ),
    );
  }
}

/// Card accordion: ringkas kayak baris menu (icon + label + chevron), tapi
/// kalau di-tap detailnya buka inline di dalam card yang sama. Dipakai
/// untuk "Informasi Pekerjaan" & "Hak Akses Sistem".
class _ExpandableInfoCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _ExpandableInfoCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  State<_ExpandableInfoCard> createState() => _ExpandableInfoCardState();
}

class _ExpandableInfoCardState extends State<_ExpandableInfoCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _DS.cardShadow,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(widget.icon, size: 20, color: _DS.onSurfaceVariant),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _DS.bodyMd(color: _DS.onSurface, weight: FontWeight.w600).copyWith(fontSize: 13.5),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.chevron_right_rounded, size: 20, color: _DS.onSurfaceVariant.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeInOut,
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(height: 20, color: _DS.outlineVariant.withOpacity(0.6)),
                  ...widget.children,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card accordion khusus "Riwayat Aktivitas". Sama pola-nya dengan
/// [_ExpandableInfoCard] (header + chevron animasi). Default cuma
/// menampilkan aktivitas "Hari Ini"; buat lihat tanggal lain tinggal ketik
/// tanggalnya (atau kata kunci lain) di kotak pencarian - tidak ada lagi
/// chip filter terpisah. Tiap grup tanggal dibatasi 5 item per "slide",
/// kalau lebih ada navigasi < 1/2 > buat geser ke item berikutnya.
class _ActivityHistoryCard extends StatefulWidget {
  final List<_ActivityItem> activities;
  final int itemsPerPage;

  const _ActivityHistoryCard({required this.activities, this.itemsPerPage = 5});

  @override
  State<_ActivityHistoryCard> createState() => _ActivityHistoryCardState();
}

class _ActivityHistoryCardState extends State<_ActivityHistoryCard> {
  bool _expanded = false;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // Halaman aktif per grup tanggal, supaya tiap grup bisa digeser
  // independen (mis. "Hari Ini" di halaman 2, "Kemarin" tetap di 1).
  final Map<String, int> _pageByGroup = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Tanpa query: hanya tampilkan aktivitas hari ini. Dengan query: cari
  /// di label aktivitas/no. order MAUPUN nama grup tanggalnya (jadi ketik
  /// "Kemarin" atau "4/8/2026" juga bisa langsung nemu).
  List<_ActivityItem> _filtered(BuildContext context) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) {
      final todayLabel = AppLocalizations.of(context)!.today;
      return widget.activities.where((a) => a.dateGroup == todayLabel).toList();
    }
    return widget.activities
        .where((a) => a.label.toLowerCase().contains(q) || a.dateGroup.toLowerCase().contains(q))
        .toList();
  }

  Map<String, List<_ActivityItem>> _groupByDate(List<_ActivityItem> items) {
    final map = <String, List<_ActivityItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.dateGroup, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered(context);
    final grouped = _groupByDate(filtered);

    return Container(
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _DS.cardShadow,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.history, size: 20, color: _DS.onSurfaceVariant),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.activityHistoryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _DS.bodyMd(color: _DS.onSurface, weight: FontWeight.w600).copyWith(fontSize: 13.5),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.chevron_right_rounded, size: 20, color: _DS.onSurfaceVariant.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeInOut,
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(height: 20, color: _DS.outlineVariant.withOpacity(0.6)),
                  if (widget.activities.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        AppLocalizations.of(context)!.noActivityYet,
                        style: _DS.bodySm(color: _DS.onSurfaceVariant),
                      ),
                    )
                  else ...[
                    // Kotak pencarian: nama aktivitas, no. order, atau
                    // tanggal (mis. ketik "Kemarin" buat lihat aktivitas
                    // kemarin, tanpa perlu pindah halaman).
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      style: _DS.bodyMd(color: _DS.onSurface).copyWith(fontSize: 13.5),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Cari aktivitas, no. order, atau tanggal...',
                        hintStyle: _DS.bodySm(color: _DS.onSurfaceVariant.withOpacity(0.7)),
                        prefixIcon: Icon(Icons.search, size: 18, color: _DS.onSurfaceVariant.withOpacity(0.7)),
                        suffixIcon: _query.isEmpty
                            ? null
                            : InkWell(
                                onTap: () => setState(() {
                                  _searchController.clear();
                                  _query = '';
                                }),
                                child: Icon(Icons.close, size: 16, color: _DS.onSurfaceVariant.withOpacity(0.7)),
                              ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: _DS.canvas,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Tidak ada aktivitas yang cocok.',
                          style: _DS.bodySm(color: _DS.onSurfaceVariant),
                        ),
                      )
                    else
                      ...grouped.entries.map((entry) {
                        final groupKey = entry.key;
                        final items = entry.value;
                        final totalPages = (items.length / widget.itemsPerPage).ceil();
                        final page = (_pageByGroup[groupKey] ?? 0).clamp(0, totalPages - 1);
                        final start = page * widget.itemsPerPage;
                        final pageItems = items.skip(start).take(widget.itemsPerPage).toList();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10, left: 2),
                                child: Text(
                                  groupKey,
                                  style: _DS.bodySm(color: _DS.onSurfaceVariant, weight: FontWeight.w600).copyWith(fontSize: 11.5),
                                ),
                              ),
                              _ActivityTimeline(items: pageItems),
                              if (totalPages > 1)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: _ActivityPager(
                                    page: page,
                                    totalPages: totalPages,
                                    onPrev: page > 0
                                        ? () => setState(() => _pageByGroup[groupKey] = page - 1)
                                        : null,
                                    onNext: page < totalPages - 1
                                        ? () => setState(() => _pageByGroup[groupKey] = page + 1)
                                        : null,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Navigasi "< halaman/total >" buat geser slide aktivitas dalam satu
/// grup tanggal, dipakai kalau jumlah aktivitas di grup itu melebihi
/// [_ActivityHistoryCard.itemsPerPage].
class _ActivityPager extends StatelessWidget {
  final int page;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _ActivityPager({
    required this.page,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        InkWell(
          onTap: onPrev,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.chevron_left_rounded,
              size: 18,
              color: onPrev == null ? _DS.outlineVariant : _DS.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          '${page + 1}/$totalPages',
          style: _DS.bodySm(color: _DS.onSurfaceVariant, weight: FontWeight.w600).copyWith(fontSize: 11.5),
        ),
        InkWell(
          onTap: onNext,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: onNext == null ? _DS.outlineVariant : _DS.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Diagram garis waktu (timeline) vertikal: tiap entri punya bulatan ikon
/// yang tersambung garis ke entri berikutnya. Entri dengan [isLatest]
/// ditandai warna primer + label "Terbaru".
class _ActivityTimeline extends StatelessWidget {
  final List<_ActivityItem> items;

  const _ActivityTimeline({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < items.length; i++)
          _ActivityTimelineRow(
            item: items[i],
            isLast: i == items.length - 1,
          ),
      ],
    );
  }
}

class _ActivityTimelineRow extends StatelessWidget {
  final _ActivityItem item;
  final bool isLast;

  const _ActivityTimelineRow({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isLatest ? _DS.primaryFixed : _DS.surface,
                  border: Border.all(
                    color: item.isLatest ? _DS.primary : _DS.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Icon(
                  item.icon,
                  size: 12,
                  color: item.isLatest ? _DS.primary : _DS.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    color: _DS.outlineVariant.withOpacity(0.6),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _DS.bodyMd(color: _DS.onSurface, weight: FontWeight.w500).copyWith(fontSize: 13.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.time,
                          style: _DS.bodySm(color: _DS.onSurfaceVariant).copyWith(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  if (item.isLatest) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _DS.primaryFixed.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.latestActivityBadge,
                        style: _DS.bodySm(color: _DS.primary, weight: FontWeight.w700).copyWith(fontSize: 10.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
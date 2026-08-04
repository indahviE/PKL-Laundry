import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/themes/app_theme.dart';
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

                // 5. Menu tambahan - Riwayat Aktivitas & Reset Password
                _buildMenuRow(
                  context,
                  icon: Icons.history,
                  label: AppLocalizations.of(context)!.activityHistoryLabel,
                  onTap: () => context.push('/employees/${employee.id}/activity'),
                ),
                const SizedBox(height: 12),
                _buildMenuRow(
                  context,
                  icon: Icons.lock_reset_outlined,
                  label: AppLocalizations.of(context)!.resetPasswordLabel,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.resetPasswordUnavailable, style: GoogleFonts.beVietnamPro())),
                  ),
                ),
                const SizedBox(height: AppTheme.xxl),

                // 6. Tombol Nonaktifkan Karyawan (Soft Delete)
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

  /// Baris menu (icon kiri, label, chevron kanan) - dipakai untuk
  /// "Riwayat Aktivitas" & "Reset Password".
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/themes/app_theme.dart';
import '../../core/themes/design_tokens.dart';
import '../../models/employee.dart';
import '../../models/laundry.dart';
import '../../repositories/employee_repository.dart';
import '../../repositories/laundry_repository.dart';
import '../../l10n/app_localizations.dart';

// ============================================
// DESIGN TOKENS
// Sebelumnya class `_DS` lokal di file ini punya token yang tumpang
// tindih persis dengan `_c...` di OrderDetailScreen (canvas, onSurface,
// primary, dst nilainya sama). Sekarang keduanya digabung jadi satu
// sumber kebenaran di lib/core/themes/design_tokens.dart (DesignTokens).
//
// `_DS` dipertahankan di sini sebagai alias tipis ke DesignTokens supaya
// SELURUH pemakaian `_DS.xxx` di bawah tidak perlu diganti satu-satu -
// nilainya 100% sama dengan sebelumnya.
// ============================================
class _DS {
  static const canvas = DesignTokens.canvas;
  static const surface = DesignTokens.surface;
  static const onSurface = DesignTokens.onSurface;
  static const onSurfaceVariant = DesignTokens.onSurfaceVariant;
  static const outline = DesignTokens.outline;
  static const outlineVariant = DesignTokens.outlineVariant;

  static const navy = DesignTokens.navy;
  static const primary = DesignTokens.primary;
  static const primaryFixed = DesignTokens.primaryFixed;

  static const error = DesignTokens.error;
  static const success = DesignTokens.success;

  static List<BoxShadow> get cardShadow => DesignTokens.cardShadow;

  static TextStyle headlineMd({Color? color}) => DesignTokens.headlineMd(color: color);
  static TextStyle bodyMd({Color? color, FontWeight? weight}) => DesignTokens.bodyMd(color: color, weight: weight);
  static TextStyle bodySm({Color? color, FontWeight? weight}) => DesignTokens.bodySm(color: color, weight: weight);
  static TextStyle labelBold({Color? color}) => DesignTokens.labelBold(color: color);
}

/// Provider untuk mengambil data karyawan secara real-time
final employeesStreamProvider = StreamProvider<List<Employee>>((ref) {
  final repo = ref.watch(employeeRepositoryProvider);
  return repo.streamEmployees();
});

class EmployeesListScreen extends ConsumerStatefulWidget {
  const EmployeesListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EmployeesListScreen> createState() => _EmployeesListScreenState();
}

class _EmployeesListScreenState extends ConsumerState<EmployeesListScreen> {
  late TextEditingController _searchController;
  String _selectedFilter = 'all'; // all, active, inactive
  String? _selectedLaundryId; // null = semua cabang
  String? _selectedRole; // null = semua role/jabatan

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Warna badge per role/jabatan, dipakai konsisten di dropdown filter role
  /// maupun badge role pada kartu karyawan (sesuai mockup: Manajer biru,
  /// Kasir hijau, Operator Cuci oranye, Kurir ungu, Quality Control teal).
  /// Role di luar daftar ini (jabatan custom) jatuh ke warna primary theme.
  Color _roleColor(String position) {
    switch (position.trim().toLowerCase()) {
      case 'manajer':
        return const Color(0xFF2F80ED);
      case 'kasir':
        return const Color(0xFF27AE60);
      case 'operator cuci':
        return const Color(0xFFF2994A);
      case 'quality control':
        return const Color(0xFF17A398);
      case 'kurir':
        return const Color(0xFF9B51E0);
      default:
        return _DS.primary;
    }
  }

  /// Buka Create Employee screen (disamakan pola dengan
  /// LaundriesListScreen._openCreateLaundry)
  Future<void> _openCreateEmployee(BuildContext context) async {
    await context.push<bool>('/employees/create');
  }

  /// Fungsi untuk menonaktifkan karyawan (Terminasi)
  Future<void> _terminateEmployee(Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context)!.terminateEmployeeTitle, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700)),
        content: Text(
          AppLocalizations.of(context)!.terminateEmployeeConfirm(
            employee.fullName.isNotEmpty ? employee.fullName : employee.employeeCode,
            employee.position,
          ),
          style: _DS.bodySm(color: _DS.onSurfaceVariant),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.cancel, style: GoogleFonts.beVietnamPro())),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.yesDeactivateButton, style: GoogleFonts.beVietnamPro(color: _DS.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(employeeRepositoryProvider).terminateEmployee(employee.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.employeeDeactivatedWithCodeSuccess(employee.employeeCode), style: GoogleFonts.beVietnamPro())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(employeesStreamProvider);
    final laundriesAsync = ref.watch(laundriesStreamProvider);

    // Map laundry_id -> nama cabang, dipakai untuk nampilin & nyari
    // berdasarkan cabang di kartu karyawan. Kalau data cabang belum/gagal
    // dimuat, map ini kosong dan kartu jatuh ke fallback "-".
    final laundryNames = <String, String>{
      for (final l in laundriesAsync.value ?? const []) l.id: l.name,
    };

    return Scaffold(
      backgroundColor: _DS.canvas,
      body: SafeArea(
        child: employeesAsync.when(
          loading: () => Center(child: CircularProgressIndicator(strokeWidth: 2, color: _DS.primary)),
          error: (err, stack) => Center(child: Text(AppLocalizations.of(context)!.employeeGenericError(err.toString()), style: GoogleFonts.beVietnamPro())),
          data: (allEmployees) {
            // Logika Filter & Search
            final filteredEmployees = allEmployees.where((emp) {
              bool statusMatch = _selectedFilter == 'all' ||
                  (_selectedFilter == 'active' && emp.isActive) ||
                  (_selectedFilter == 'inactive' && !emp.isActive);
              bool laundryMatch = _selectedLaundryId == null || emp.laundryId == _selectedLaundryId;
              bool roleMatch = _selectedRole == null || emp.position.toLowerCase() == _selectedRole!.toLowerCase();
              final query = _searchController.text.toLowerCase();
              final laundryName = laundryNames[emp.laundryId] ?? '';
              bool searchMatch = query.isEmpty ||
                  emp.fullName.toLowerCase().contains(query) ||
                  emp.employeeCode.toLowerCase().contains(query) ||
                  emp.position.toLowerCase().contains(query) ||
                  emp.phone.toLowerCase().contains(query) ||
                  laundryName.toLowerCase().contains(query);
              return statusMatch && laundryMatch && roleMatch && searchMatch;
            }).toList();

            return _buildMainContent(context, filteredEmployees, laundryNames, laundriesAsync.value ?? const [], allEmployees);
          },
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, List<Employee> employees, Map<String, String> laundryNames, List<Laundry> laundries, List<Employee> allEmployees) {
    // Daftar role untuk dropdown filter: diambil dari data karyawan yang benar-benar
    // ada (supaya jabatan custom tetap muncul sebagai pilihan), dengan fallback
    // ke daftar role standar kalau datanya masih kosong.
    final rolesFromData = allEmployees.map((e) => e.position).where((p) => p.trim().isNotEmpty).toSet().toList()..sort();
    final availableRoles = rolesFromData.isNotEmpty
        ? rolesFromData
        : ['Manajer', 'Kasir', 'Operator Cuci', 'Quality Control', 'Kurir', 'Staff Gudang'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 12 : 24,
                  isMobile ? 16 : 24,
                  isMobile ? 20 : 24,
                  isMobile ? 16 : 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 22),
                    _buildSearchBar(),
                    const SizedBox(height: AppTheme.lg),
                    _buildTotalStat(allEmployees.length),
                    const SizedBox(height: AppTheme.lg),
                    _buildStatusChips(),
                    const SizedBox(height: 12),
                    _buildFilterDropdowns(laundries, availableRoles),
                    const SizedBox(height: AppTheme.xl),
                    employees.isEmpty
                        ? _buildEmptyState()
                        : _buildEmployeesList(employees, laundryNames),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Header - samain persis dengan pola ServicesListScreen: tombol back
  /// bulat (shadow), icon box badge biru muda, judul, tombol tambah bulat
  /// biru muda di kanan.
  Widget _buildHeader(BuildContext context) {
    final canGoBack = context.canPop();

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
          child: const Icon(Icons.badge_outlined, color: _DS.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            AppLocalizations.of(context)!.manageEmployeesTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _DS.headlineMd(color: _DS.navy),
          ),
        ),
        InkWell(
          onTap: () => _openCreateEmployee(context),
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

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      style: _DS.bodyMd(),
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.searchEmployeeHint,
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
    );
  }

  /// Chip status Semua/Aktif/Tidak Aktif - restyle jadi pill navy-selected
  /// sesuai pola _filterChip di ServicesListScreen.
  Widget _buildStatusChips() {
    final filters = [
      ('all', AppLocalizations.of(context)!.filterAllLabel, Icons.groups_outlined),
      ('active', AppLocalizations.of(context)!.statusActive, Icons.check_circle_outline),
      ('inactive', AppLocalizations.of(context)!.statusInactive, Icons.cancel_outlined),
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
                    style: _DS.bodySm(
                      color: isSelected ? Colors.white : _DS.onSurfaceVariant,
                      weight: FontWeight.w600,
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

  /// Filter Cabang & Role berdampingan (Cabang di kiri, Role di kanan),
  /// masing-masing setengah lebar - restyle pakai warna & radius _DS.
  Widget _buildFilterDropdowns(List<Laundry> laundries, List<String> roles) {
    return Row(
      children: [
        Expanded(child: _buildBranchDropdown(laundries)),
        const SizedBox(width: 10),
        Expanded(child: _buildRoleDropdown(roles)),
      ],
    );
  }

  Widget _buildBranchDropdown(List<Laundry> laundries) {
    final validIds = laundries.map((l) => l.id).toSet();
    final value = (_selectedLaundryId != null && validIds.contains(_selectedLaundryId)) ? _selectedLaundryId : null;

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _DS.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _DS.onSurfaceVariant, size: 20),
          borderRadius: BorderRadius.circular(14),
          style: _DS.bodySm(color: _DS.onSurface),
          onChanged: (val) => setState(() => _selectedLaundryId = val),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Row(
                children: [
                  const Icon(Icons.storefront_outlined, size: 15, color: _DS.primary),
                  const SizedBox(width: 6),
                  Flexible(child: Text(AppLocalizations.of(context)!.allBranchesLabel, overflow: TextOverflow.ellipsis, style: _DS.bodySm(color: _DS.onSurface))),
                ],
              ),
            ),
            ...laundries.map(
              (l) => DropdownMenuItem<String?>(
                value: l.id,
                child: Text(l.name, overflow: TextOverflow.ellipsis, style: _DS.bodySm(color: _DS.onSurface)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleDropdown(List<String> roles) {
    final validRoles = roles.map((r) => r.toLowerCase()).toSet();
    final value = (_selectedRole != null && validRoles.contains(_selectedRole!.toLowerCase())) ? _selectedRole : null;

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _DS.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _DS.onSurfaceVariant, size: 20),
          borderRadius: BorderRadius.circular(14),
          style: _DS.bodySm(color: _DS.onSurface),
          onChanged: (val) => setState(() => _selectedRole = val),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Row(
                children: [
                  const Icon(Icons.badge_outlined, size: 15, color: _DS.primary),
                  const SizedBox(width: 6),
                  Flexible(child: Text(AppLocalizations.of(context)!.allRolesLabel, overflow: TextOverflow.ellipsis, style: _DS.bodySm(color: _DS.onSurface))),
                ],
              ),
            ),
            ...roles.map(
              (r) => DropdownMenuItem<String?>(
                value: r,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: _roleColor(r)),
                    ),
                    const SizedBox(width: 8),
                    Flexible(child: Text(r, overflow: TextOverflow.ellipsis, style: _DS.bodySm(color: _DS.onSurface))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kartu "Total Karyawan" - restyle pakai _DS.cardShadow & warna primary.
  Widget _buildTotalStat(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _DS.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.totalEmployeesLabel, style: _DS.bodySm()),
          const SizedBox(height: 6),
          Text('$total', style: _DS.headlineMd(color: _DS.primary).copyWith(fontSize: 22)),
        ],
      ),
    );
  }

  Widget _buildEmployeesList(List<Employee> employees, Map<String, String> laundryNames) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: employees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final emp = employees[index];
        return _EmployeeCard(
          employee: emp,
          laundryName: laundryNames[emp.laundryId] ?? '-',
          roleColor: _roleColor(emp.position),
          onTap: () => context.push('/employees/${emp.id}'),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: _DS.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.badge_outlined, size: 44, color: _DS.primary.withOpacity(0.6)),
            ),
            const SizedBox(height: 20),
            Text(AppLocalizations.of(context)!.noEmployeesFoundTitle, style: _DS.bodyMd(weight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(AppLocalizations.of(context)!.noEmployeesFoundSubtitle, style: _DS.bodySm()),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _openCreateEmployee(context),
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
              label: Text(AppLocalizations.of(context)!.newEmployeeButton, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _DS.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu 1 karyawan - restyle mengikuti pola _ServiceCard di
/// ServicesListScreen: icon avatar kiri, nama, badge role & cabang, telepon,
/// titik status & chevron di kanan.
class _EmployeeCard extends StatelessWidget {
  final Employee employee;
  final String laundryName;
  final Color roleColor;
  final VoidCallback onTap;

  const _EmployeeCard({
    required this.employee,
    required this.laundryName,
    required this.roleColor,
    required this.onTap,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = employee.isActive;
    final displayName = employee.fullName.isNotEmpty ? employee.fullName : AppLocalizations.of(context)!.noNameFallback;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _DS.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? roleColor.withOpacity(0.12) : const Color(0xFFE9E9E9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _getInitials(employee.fullName.isNotEmpty ? employee.fullName : employee.position),
                style: _DS.bodyMd(
                  color: isActive ? roleColor : const Color(0xFF9CA3AF),
                  weight: FontWeight.w700,
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
                    style: _DS.bodyMd(
                      color: isActive ? _DS.onSurface : const Color(0xFF9CA3AF),
                      weight: FontWeight.w700,
                    ).copyWith(fontSize: 14.5),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (employee.position.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive ? roleColor.withOpacity(0.12) : const Color(0xFFE9E9E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            employee.position.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _DS.bodySm(
                              color: isActive ? roleColor : const Color(0xFF6B7280),
                              weight: FontWeight.w700,
                            ).copyWith(fontSize: 10.5),
                          ),
                        ),
                      Text(laundryName, maxLines: 1, overflow: TextOverflow.ellipsis, style: _DS.bodySm()),
                    ],
                  ),
                  if (employee.phone.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 14, color: _DS.onSurfaceVariant.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(employee.phone, maxLines: 1, overflow: TextOverflow.ellipsis, style: _DS.bodySm()),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? _DS.success : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 20),
                Icon(Icons.chevron_right_rounded, size: 20, color: _DS.onSurfaceVariant.withOpacity(0.6)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
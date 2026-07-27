import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/themes/app_theme.dart';
import '../../models/employee.dart';
import '../../models/laundry.dart';
import '../../repositories/employee_repository.dart';
import '../../repositories/laundry_repository.dart';

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

  /// Format Mata Uang
  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  /// Warna badge per role/jabatan, dipakai konsisten di dropdown filter role
  /// maupun badge role pada kartu karyawan (sesuai mockup: Manajer biru,
  /// Kasir hijau, Operator Cuci oranye, Kurir ungu). Role di luar daftar ini
  /// (jabatan custom) jatuh ke warna primary theme.
  Color _roleColor(String position) {
    switch (position.trim().toLowerCase()) {
      case 'manajer':
        return const Color(0xFF2F80ED);
      case 'kasir':
        return const Color(0xFF27AE60);
      case 'operator cuci':
        return const Color(0xFFF2994A);
      case 'kurir':
        return const Color(0xFF9B51E0);
      default:
        return AppTheme.primaryColor;
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
        title: Text('Terminasi Karyawan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menonaktifkan ${employee.fullName.isNotEmpty ? employee.fullName : employee.employeeCode} (${employee.position})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Nonaktifkan', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(employeeRepositoryProvider).terminateEmployee(employee.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Karyawan ${employee.employeeCode} telah dinonaktifkan')),
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
      backgroundColor: const Color(0xFFFBF9F8), // Disamakan dengan latar order_list_screen
      // Tombol create dipindah ke header (lihat _buildHeader), FAB dihapus
      // supaya polanya konsisten dengan LaundriesListScreen.
      body: SafeArea(
        child: employeesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
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
    final availableRoles = rolesFromData.isNotEmpty ? rolesFromData : ['Manajer', 'Kasir', 'Operator Cuci', 'Kurir'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
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
                    const SizedBox(height: 10),
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

  /// Header: tombol back (conditional) + icon + judul + tombol create bulat
  /// di kanan, disamakan persis dengan LaundriesListScreen._buildHeader.
  Widget _buildHeader(BuildContext context) {
    final canGoBack = context.canPop();

    return Row(
      children: [
        // Tombol back disamakan persis dengan LaundriesListScreen._buildHeader
        // (InkWell + Padding, tanpa background bulat berwarna).
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
          child: Text(
            'Kelola Karyawan',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        // Tombol create, disamakan persis dengan LaundriesListScreen (bulat,
        // warna primary, icon add_rounded putih) — menggantikan FAB lama.
        Material(
          color: AppTheme.primaryColor,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () => _openCreateEmployee(context),
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

  Widget _buildSearchBar() {
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
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Cari nama atau nomor telepon karyawan...',
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

  /// Chip status Semua/Aktif/Tidak Aktif (tetap chip sesuai mockup, karena
  /// cuma 3 opsi jadi ga makan tempat).
  Widget _buildStatusChips() {
    final filters = [
      ('all', 'Semua', Icons.groups_outlined),
      ('active', 'Aktif', Icons.check_circle_outline),
      ('inactive', 'Tidak Aktif', Icons.cancel_outlined),
    ];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = _selectedFilter == f.$1;
          return ChoiceChip(
            label: Text(f.$2, overflow: TextOverflow.ellipsis),
            selected: isSelected,
            onSelected: (val) => setState(() => _selectedFilter = f.$1),
            avatar: Icon(f.$3, size: 16, color: isSelected ? Colors.white : AppTheme.primaryColor),
            showCheckmark: false,
            selectedColor: AppTheme.primaryColor,
            labelStyle: GoogleFonts.poppins(color: isSelected ? Colors.white : AppTheme.textSecondary, fontSize: 12),
          );
        },
      ),
    );
  }

  /// Filter Cabang & Role sekarang jadi dropdown berdampingan (menggantikan
  /// 2 baris chip yang bisa kepanjangan kalau datanya banyak). Cabang di
  /// kiri, Role di kanan, masing-masing setengah lebar.
  Widget _buildFilterDropdowns(List<Laundry> laundries, List<String> roles) {
    return Row(
      children: [
        Expanded(child: _buildBranchDropdown(laundries)),
        const SizedBox(width: 10),
        Expanded(child: _buildRoleDropdown(roles)),
      ],
    );
  }

  /// Dropdown filter cabang, menggantikan _buildBranchChips lama (sesuai
  /// mockup "Semua Cabang | Sudirman | Menteng | ..." tapi dalam bentuk
  /// dropdown biar ga makan tempat kalau cabangnya banyak).
  Widget _buildBranchDropdown(List<Laundry> laundries) {
    final validIds = laundries.map((l) => l.id).toSet();
    final value = (_selectedLaundryId != null && validIds.contains(_selectedLaundryId)) ? _selectedLaundryId : null;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.6)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textTertiary, size: 20),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textPrimary),
          onChanged: (val) => setState(() => _selectedLaundryId = val),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Row(
                children: [
                  Icon(Icons.storefront_outlined, size: 15, color: AppTheme.primaryColor),
                  const SizedBox(width: 6),
                  const Flexible(child: Text('Semua Cabang', overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
            ...laundries.map(
              (l) => DropdownMenuItem<String?>(
                value: l.id,
                child: Text(l.name, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dropdown filter role/jabatan, menggantikan _buildRoleChips lama (sesuai
  /// mockup "Semua | Manajer | Kasir | Operator Cuci"). Tiap opsi tetap
  /// dikasih titik warna sesuai _roleColor supaya konsisten dengan badge
  /// role di kartu karyawan.
  Widget _buildRoleDropdown(List<String> roles) {
    final validRoles = roles.map((r) => r.toLowerCase()).toSet();
    final value = (_selectedRole != null && validRoles.contains(_selectedRole!.toLowerCase())) ? _selectedRole : null;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.6)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textTertiary, size: 20),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textPrimary),
          onChanged: (val) => setState(() => _selectedRole = val),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Row(
                children: [
                  Icon(Icons.badge_outlined, size: 15, color: AppTheme.primaryColor),
                  const SizedBox(width: 6),
                  const Flexible(child: Text('Semua Role', overflow: TextOverflow.ellipsis)),
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
                    Flexible(child: Text(r, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kartu "Total Karyawan" tunggal sesuai mockup (angka staf aktif tetap
  /// bisa dilihat lewat chip filter status "Aktif" di atasnya).
  Widget _buildTotalStat(int total) {
    return Container(
      width: double.infinity,
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
          Text('Total Karyawan', style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textSecondary)),
          const SizedBox(height: 6),
          Text('$total', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
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
                Icons.badge_outlined,
                size: 40,
                color: AppTheme.primaryColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppTheme.lg),
            Text(
              'Data karyawan tidak ditemukan',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.sm),
            Text(
              'Coba ubah filter atau tambahkan karyawan baru',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.xl),
            ElevatedButton.icon(
              onPressed: () => _openCreateEmployee(context),
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
              label: Text('Karyawan Baru', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
}

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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.fullName.isNotEmpty ? employee.fullName : 'Tanpa Nama',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14.5),
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
                            color: roleColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            employee.position.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: roleColor),
                          ),
                        ),
                      Text(
                        laundryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  if (employee.phone.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 14, color: AppTheme.textTertiary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            employee.phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textSecondary),
                          ),
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
                    color: employee.isActive ? const Color(0xFF27AE60) : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 20),
                Icon(Icons.chevron_right, size: 20, color: AppTheme.textTertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
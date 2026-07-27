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

  /// Warna badge per role/jabatan, dipakai konsisten di chip filter role
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
      // CTA "Karyawan Baru" dipindah ke FAB, sama persis polanya dengan
      // LaundriesListScreen ("Cabang Baru") biar konsisten se-app —
      // sebelumnya ini tombol ElevatedButton biasa di pojok kanan header.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/employees/create'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.person_add_alt_1_outlined, size: 20),
        label: Text(
          'Karyawan Baru',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
      ),
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
    // Daftar role untuk chip filter: diambil dari data karyawan yang benar-benar
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
                    _buildBranchChips(laundries),
                    const SizedBox(height: 10),
                    _buildRoleChips(availableRoles),
                    const SizedBox(height: AppTheme.xl),
                    employees.isEmpty
                        ? _buildEmptyState()
                        : _buildEmployeesList(employees, laundryNames),
                    // Spacer biar list terakhir gak ketutupan FAB, sama
                    // kayak yang dipakai di LaundriesListScreen.
                    const SizedBox(height: 88),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Header: tombol back (conditional, hanya muncul kalau screen ini bisa
  /// di-pop) + icon + judul. CTA "Baru" sekarang di FAB (lihat build()),
  /// jadi header ini murni informasional, sama pola dengan
  /// LaundriesListScreen.
  Widget _buildHeader(BuildContext context) {
    final canGoBack = context.canPop();

    return Row(
      children: [
        if (canGoBack) ...[
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: AppTheme.md),
        ],
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(Icons.badge_outlined, color: AppTheme.primaryColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Karyawan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              Text('Kelola staf dan hak akses cabang',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
            ],
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Cari nama atau nomor telepon karyawan...',
          prefixIcon: const Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  /// Chip status Semua/Aktif/Tidak Aktif (baris pertama, sesuai mockup).
  Widget _buildStatusChips() {
    final filters = [
      ('all', 'Semua', Icons.groups_outlined),
      ('active', 'Aktif', Icons.check_circle_outline),
      ('inactive', 'Tidak Aktif', Icons.cancel_outlined),
    ];

    // Dibungkus scroll horizontal (bukan Row biasa) supaya tiap chip tetap
    // dapat lebar aslinya dan tinggal di-scroll kalau tidak muat di layar
    // sempit, tidak overflow atau bikin teks chip terpotong jadi 2 baris.
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

  /// Chip filter cabang (baris kedua, menggantikan dropdown lama - sesuai
  /// mockup "Semua Cabang | Sudirman | Menteng | ..."). Discroll horizontal
  /// supaya nama cabang berapa pun banyaknya tidak pernah overflow.
  Widget _buildBranchChips(List<Laundry> laundries) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: laundries.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final laundry = isAll ? null : laundries[index - 1];
          final isSelected = isAll ? _selectedLaundryId == null : _selectedLaundryId == laundry!.id;
          return ChoiceChip(
            label: Text(isAll ? 'Semua Cabang' : laundry!.name, overflow: TextOverflow.ellipsis),
            selected: isSelected,
            onSelected: (val) => setState(() => _selectedLaundryId = isAll ? null : laundry!.id),
            showCheckmark: false,
            selectedColor: AppTheme.primaryColor,
            backgroundColor: AppTheme.cardColor,
            labelStyle: GoogleFonts.poppins(color: isSelected ? Colors.white : AppTheme.textSecondary, fontSize: 12),
          );
        },
      ),
    );
  }

  /// Chip filter role/jabatan (baris ketiga, baru - sesuai mockup "Semua |
  /// Manajer | Kasir | Operator Cuci"). Tiap chip diwarnai sesuai role,
  /// pakai _roleColor supaya konsisten dengan badge role di kartu karyawan.
  Widget _buildRoleChips(List<String> roles) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: roles.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final role = isAll ? null : roles[index - 1];
          final isSelected = isAll ? _selectedRole == null : _selectedRole == role;
          final color = isAll ? AppTheme.primaryColor : _roleColor(role!);
          return ChoiceChip(
            label: Text(isAll ? 'Semua' : role!, overflow: TextOverflow.ellipsis),
            selected: isSelected,
            onSelected: (val) => setState(() => _selectedRole = isAll ? null : role),
            showCheckmark: false,
            selectedColor: color,
            backgroundColor: color.withOpacity(0.1),
            side: BorderSide(color: color.withOpacity(0.4)),
            labelStyle: GoogleFonts.poppins(color: isSelected ? Colors.white : color, fontSize: 12, fontWeight: FontWeight.w600),
          );
        },
      ),
    );
  }

  /// Kartu "Total Karyawan" tunggal sesuai mockup (sebelumnya 2 kotak
  /// Total Staf/Staf Aktif; angka staf aktif tetap bisa dilihat lewat chip
  /// filter status "Aktif" di bawahnya).
  Widget _buildTotalStat(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16)),
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
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.badge_outlined, size: 64, color: AppTheme.textTertiary),
          const SizedBox(height: 16),
          Text('Data karyawan tidak ditemukan', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
        ],
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
                  // Badge role berwarna + nama cabang di sebelahnya, sesuai
                  // kartu pada mockup ("MANAJER  Sudirman").
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
            // Dot status (hijau=aktif, abu=tidak aktif) + chevron navigasi,
            // sesuai kartu pada mockup.
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
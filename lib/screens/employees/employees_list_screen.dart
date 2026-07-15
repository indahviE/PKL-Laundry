import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/themes/app_theme.dart';
import '../../models/employee.dart';
import '../../repositories/employee_repository.dart';

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

  /// Fungsi untuk menonaktifkan karyawan (Terminasi)
  Future<void> _terminateEmployee(Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Terminasi Karyawan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menonaktifkan ${employee.position} ini?'),
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
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
              bool searchMatch = _searchController.text.isEmpty ||
                  emp.employeeCode.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                  emp.position.toLowerCase().contains(_searchController.text.toLowerCase());
              return statusMatch && searchMatch;
            }).toList();

            return _buildMainContent(context, filteredEmployees);
          },
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, List<Employee> employees) {
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
                    _buildFilterButtons(),
                    const SizedBox(height: AppTheme.xl),
                    _buildStatsSummary(employees),
                    const SizedBox(height: AppTheme.xl),
                    employees.isEmpty
                        ? _buildEmptyState()
                        : _buildEmployeesList(employees),
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
  /// di-pop) + icon + judul, dan CTA "Baru" di kanan.
  Widget _buildHeader(BuildContext context) {
    final canGoBack = context.canPop();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Karyawan',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                Text('Kelola staf dan hak akses cabang',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => context.push('/employees/create'),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Baru'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
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
          hintText: 'Cari Kode atau Jabatan...',
          prefixIcon: const Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildFilterButtons() {
    final filters = [
      ('all', 'Semua', Icons.groups_outlined),
      ('active', 'Aktif', Icons.check_circle_outline),
      ('inactive', 'Resign', Icons.cancel_outlined),
    ];

    return Row(
      children: filters.map((f) {
        final isSelected = _selectedFilter == f.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(f.$2),
            selected: isSelected,
            onSelected: (val) => setState(() => _selectedFilter = f.$1),
            avatar: Icon(f.$3, size: 16, color: isSelected ? Colors.white : AppTheme.primaryColor),
            selectedColor: AppTheme.primaryColor,
            labelStyle: GoogleFonts.poppins(color: isSelected ? Colors.white : AppTheme.textSecondary, fontSize: 12),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsSummary(List<Employee> employees) {
    final activeCount = employees.where((e) => e.isActive).length;
    return Row(
      children: [
        Expanded(child: _StatBox(title: 'Total Staf', value: '${employees.length}', icon: Icons.badge, color: AppTheme.primaryColor)),
        const SizedBox(width: 16),
        Expanded(child: _StatBox(title: 'Staf Aktif', value: '$activeCount', icon: Icons.how_to_reg, color: Colors.green)),
      ],
    );
  }

  Widget _buildEmployeesList(List<Employee> employees) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: employees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final emp = employees[index];
        return _EmployeeCard(
          employee: emp,
          formattedSalary: _formatCurrency(emp.salary),
          onTerminate: () => _terminateEmployee(emp),
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

class _StatBox extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;

  const _StatBox({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(title, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final Employee employee;
  final String formattedSalary;
  final VoidCallback onTerminate;
  final VoidCallback onTap;

  const _EmployeeCard({required this.employee, required this.formattedSalary, required this.onTerminate, required this.onTap});

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
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(employee.position[0].toUpperCase(), style: TextStyle(color: AppTheme.primaryColor)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(employee.employeeCode, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      Text(employee.position, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                if (employee.isActive)
                  IconButton(
                    icon: const Icon(Icons.person_off_outlined, color: Colors.redAccent, size: 20),
                    onPressed: onTerminate,
                    tooltip: 'Terminasi',
                  ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(Icons.payments_outlined, formattedSalary),
                _buildInfoItem(Icons.percent, '${employee.commissionRate}% Komisi'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (employee.isActive ? Colors.green : Colors.grey).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    employee.isActive ? 'Aktif' : 'Resign',
                    style: TextStyle(color: employee.isActive ? Colors.green : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textTertiary),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/themes/app_theme.dart'; // Menggunakan AppTheme yang sama dengan Customer
import '../../models/employee.dart'; // Sesuaikan path model
import '../../repositories/employee_repository.dart';

// Gunakan ConsumerWidget untuk mengakses Riverpod Provider secara efisien
class EmployeeDetailScreen extends ConsumerWidget {
  final String employeeId;

  const EmployeeDetailScreen({super.key, required this.employeeId});

  // Helper untuk mendapatkan inisial nama untuk Avatar lingkaran
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor, // Tema latar belakang dari Customer Screen
      appBar: AppBar(
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Detail Karyawan',
          style: GoogleFonts.poppins(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          employeeAsync.when(
            data: (employee) => employee != null
                ? IconButton(
                    icon: Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
                    onPressed: () {
                      // Implementasi navigasi ke halaman edit employee di sini
                    },
                  )
                : const SizedBox(),
            error: (_, __) => const SizedBox(),
            loading: () => const SizedBox(),
          ),
        ],
      ),
      body: SafeArea(
        child: employeeAsync.when(
          data: (employee) {
            if (employee == null) {
              return _buildErrorState('Data karyawan tidak ditemukan.');
            }
            return _buildContent(context, ref, employee);
          },
          error: (err, stack) => _buildErrorState('Terjadi kesalahan: $err'),
          loading: () => Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Employee employee) {
    // Sebagai placeholder karena nama lengkap berada di model Profile terpisah,
    // kita tampilkan kode karyawan (employeeCode) atau posisi sebagai pengenal utama.
    final displayName = employee.employeeCode.isNotEmpty 
        ? 'Karyawan ${employee.employeeCode}' 
        : 'Staf Laundry';
    final initials = _getInitials(employee.position);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Profile Header Card (Mengikuti gaya visual _CustomerCard)
                Container(
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
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                        child: Text(
                          initials,
                          style: GoogleFonts.poppins(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              employee.position.toUpperCase(), // Menampilkan posisi/role
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status Badge (Aktif / Tidak Aktif)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.md,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (employee.isActive ? const Color(0xFF51CF66) : Colors.grey)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: Text(
                          employee.isActive ? 'Aktif' : 'Tidak Aktif',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: employee.isActive ? const Color(0xFF51CF66) : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.xl),

                // 2. Card Informasi Detail Finansial & Pekerjaan
                _buildSectionCard(
                  title: 'Informasi Pekerjaan',
                  items: [
                    _buildInfoRow(Icons.badge_outlined, 'ID Dokumen', employee.id),
                    _buildInfoRow(Icons.work_outline, 'Posisi Kerja', employee.position),
                    _buildInfoRow(Icons.payments_outlined, 'Gaji Pokok', _formatCurrency(employee.salary)),
                    _buildInfoRow(Icons.percent_outlined, 'Komisi', '${employee.commissionRate}%'),
                    if (employee.hireDate != null)
                      _buildInfoRow(
                        Icons.calendar_today_outlined, 
                        'Tanggal Masuk', 
                        '${employee.hireDate!.day}/${employee.hireDate!.month}/${employee.hireDate!.year}'
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.lg),

                // 3. Card Izin / Hak Akses (Permissions)
                _buildSectionCard(
                  title: 'Hak Akses Sistem',
                  items: [
                    _buildPermissionRow(Icons.shopping_bag_outlined, 'Membuat Pesanan', employee.permissions.canCreateOrder),
                    _buildPermissionRow(Icons.people_outline, 'Mengelola Pelanggan', employee.permissions.canManageCustomer),
                    _buildPermissionRow(Icons.bar_chart_outlined, 'Melihat Laporan', employee.permissions.canViewReport),
                  ],
                ),
                const SizedBox(height: AppTheme.xxl),

                // 4. Tombol Berhenti / Pecat Karyawan (Soft Delete)
                if (employee.isActive)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showTerminateDialog(context, ref, employee.id),
                      icon: const Icon(Icons.person_off_outlined, size: 18),
                      label: Text(
                        'Nonaktifkan Karyawan',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        elevation: 0,
                        side: BorderSide(color: Colors.red.shade200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
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

  // Widget Pembungkus Card Seksi (Mengadaptasi desain standard card agar seragam)
  Widget _buildSectionCard({required String title, required List<Widget> items}) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 14.5,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Divider(color: AppTheme.borderColor.withOpacity(0.5)),
          const SizedBox(height: 6),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textTertiary),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
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
          Icon(icon, size: 18, color: AppTheme.textTertiary),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Icon(
            hasPermission ? Icons.check_circle : Icons.cancel,
            color: hasPermission ? const Color(0xFF51CF66) : Colors.grey.shade400,
            size: 20,
          ),
        ],
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
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
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
        title: Text(
          'Nonaktifkan Karyawan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Apakah Anda yakin ingin menonaktifkan status aktif karyawan ini? Riwayat transaksi lama akan tetap aman.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
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
            child: Text(
              'Ya, Nonaktifkan',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
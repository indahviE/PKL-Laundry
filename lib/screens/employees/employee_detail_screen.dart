import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/themes/app_theme.dart'; // Menggunakan AppTheme yang sama dengan Customer
import '../../models/employee.dart'; // Sesuaikan path model
import '../../repositories/employee_repository.dart';
import '../../repositories/laundry_repository.dart';

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
    final laundriesAsync = ref.watch(laundriesStreamProvider);
    final laundryNames = <String, String>{
      for (final l in laundriesAsync.value ?? const []) l.id: l.name,
    };

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8), // Disamakan dengan latar order_list_screen
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
                    onPressed: () => context.push('/employees/${employee.id}/edit'),
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
            return _buildContent(context, ref, employee, laundryNames);
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

  Widget _buildContent(BuildContext context, WidgetRef ref, Employee employee, Map<String, String> laundryNames) {
    final displayName = employee.fullName.isNotEmpty
        ? employee.fullName
        : (employee.employeeCode.isNotEmpty ? 'Karyawan ${employee.employeeCode}' : 'Staf Laundry');
    final initials = _getInitials(employee.fullName.isNotEmpty ? employee.fullName : employee.position);

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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Role/jabatan dipindah ke bawah nama (bukan sebaris dengan
                            // badge status) supaya tidak lagi berebut ruang horizontal
                            // dan tumpang tindih dengan badge "Aktif" saat nama pendek.
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    employee.position.isNotEmpty ? employee.position.toUpperCase() : '-',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                                // Status Badge (Aktif / Tidak Aktif) - sekarang di baris
                                // sendiri bersama badge role, jadi keduanya bisa
                                // wrap ke bawah kalau ruang sempit, tidak overflow lagi.
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (employee.isActive ? const Color(0xFF51CF66) : Colors.grey)
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    employee.isActive ? 'Aktif' : 'Tidak Aktif',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: employee.isActive ? const Color(0xFF51CF66) : Colors.grey.shade600,
                                    ),
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
                const SizedBox(height: AppTheme.xl),

                // 2. Card Kontak & Penempatan (disamain persis sama mockup:
                // tiap baris punya icon dalam kotak bulat warna-warni
                // (biru=telepon, ungu=email, oranye=cabang, teal=tanggal),
                // label bold di atas, value di bawahnya - bukan lagi
                // label-kiri value-kanan sebaris. Alamat tetap icon polos
                // tanpa kotak warna, dipisah pakai divider seperti sebelumnya.
                Container(
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
                      _buildContactRow(
                        icon: Icons.phone_outlined,
                        label: 'Nomor Telepon',
                        value: employee.phone.isNotEmpty ? employee.phone : '-',
                        color: const Color(0xFF2F80ED),
                      ),
                      const SizedBox(height: 18),
                      _buildContactRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: employee.email.isNotEmpty ? employee.email : '-',
                        color: const Color(0xFFAB47BC),
                      ),
                      const SizedBox(height: 18),
                      _buildContactRow(
                        icon: Icons.storefront_outlined,
                        label: 'Cabang Bertugas',
                        value: laundryNames[employee.laundryId] ?? '-',
                        color: const Color(0xFFF2994A),
                      ),
                      if (employee.hireDate != null) ...[
                        const SizedBox(height: 18),
                        _buildContactRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Tanggal Bergabung',
                          value: '${employee.hireDate!.day}/${employee.hireDate!.month}/${employee.hireDate!.year}',
                          color: const Color(0xFF2BB3A3),
                        ),
                      ],
                      if (employee.address.isNotEmpty) ...[
                        const Divider(height: 32),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on_outlined, size: 20, color: AppTheme.textTertiary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Alamat Lengkap',
                                    style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    employee.address,
                                    style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w400, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.lg),

                // 3 & 4. Informasi Pekerjaan & Hak Akses Sistem: tampilannya
                // tetap ringkas kayak baris menu (icon + label + chevron),
                // tapi detailnya buka ke bawah inline (accordion) pas
                // di-tap - bukan lagi bottom sheet - biar alurnya kerasa
                // nyambung sama section Kontak & Penempatan di atasnya.
                _ExpandableInfoCard(
                  icon: Icons.work_outline,
                  title: 'Informasi Pekerjaan',
                  children: [
                    _buildInfoRow(Icons.badge_outlined, 'ID Dokumen', employee.id),
                    _buildInfoRow(Icons.qr_code_outlined, 'Kode Karyawan', employee.employeeCode),
                    _buildInfoRow(Icons.work_outline, 'Posisi Kerja', employee.position),
                    _buildInfoRow(Icons.payments_outlined, 'Gaji Pokok', _formatCurrency(employee.salary)),
                    _buildInfoRow(Icons.percent_outlined, 'Komisi', '${employee.commissionRate}%'),
                  ],
                ),
                const SizedBox(height: AppTheme.md),
                _ExpandableInfoCard(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Hak Akses Sistem',
                  children: [
                    _buildPermissionRow(Icons.shopping_bag_outlined, 'Membuat Pesanan', employee.permissions.canCreateOrder),
                    _buildPermissionRow(Icons.people_outline, 'Mengelola Pelanggan', employee.permissions.canManageCustomer),
                    _buildPermissionRow(Icons.bar_chart_outlined, 'Melihat Laporan', employee.permissions.canViewReport),
                  ],
                ),
                const SizedBox(height: AppTheme.md),

                // 5. Menu tambahan sesuai mockup - Riwayat Aktivitas & Reset
                // Password. Belum ada route/repository untuk ini, jadi
                // sementara di-wire ke placeholder snackbar dulu. Statistik
                // Kinerja (Pesanan Ditangani/Transaksi Sukses) SENGAJA belum
                // ditambahkan karena datanya belum ada di model Employee.
                _buildMenuRow(
                  context,
                  icon: Icons.history,
                  label: 'Riwayat Aktivitas',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Riwayat aktivitas belum tersedia.')),
                  ),
                ),
                const SizedBox(height: AppTheme.md),
                _buildMenuRow(
                  context,
                  icon: Icons.lock_reset_outlined,
                  label: 'Reset Password',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reset password belum tersedia.')),
                  ),
                ),
                const SizedBox(height: AppTheme.xxl),

                // 6. Tombol Berhenti / Pecat Karyawan (Soft Delete)
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

  // Baris kontak ala mockup: icon dalam kotak bulat berwarna (beda warna
  // tiap jenis kontak), label bold di atas, value di bawahnya. Dipakai
  // khusus untuk Nomor Telepon, Email, Cabang Bertugas, & Tanggal Bergabung.
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
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w400, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    // Sebelumnya label & value ditaruh di kiri-kanan Row dengan Spacer tanpa
    // batas lebar, jadi value yang panjang (ID dokumen, email, dll) bisa
    // overflow horizontal. Sekarang keduanya dibungkus Flexible + ellipsis
    // supaya menyempit atau terpotong rapi, tidak pernah overflow.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.textTertiary),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
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
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            hasPermission ? Icons.check_circle : Icons.cancel,
            color: hasPermission ? const Color(0xFF51CF66) : Colors.grey.shade400,
            size: 20,
          ),
        ],
      ),
    );
  }

  // Baris menu ala mockup (icon kiri, label, chevron kanan) - dipakai untuk
  // "Riwayat Aktivitas" & "Reset Password".
  Widget _buildMenuRow(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.lg, vertical: 14),
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
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: AppTheme.textTertiary),
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

// Card accordion: tampilannya ringkas kayak baris menu (icon + label +
// chevron), tapi kalau di-tap detailnya buka ke bawah inline di dalam card
// yang sama (bukan bottom sheet/route baru). Dipakai untuk "Informasi
// Pekerjaan" & "Hak Akses Sistem" supaya halaman detail karyawan tetap
// ringkas secara default tapi detailnya gampang diakses.
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
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.lg, vertical: 14),
              child: Row(
                children: [
                  Icon(widget.icon, size: 20, color: AppTheme.textSecondary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.chevron_right, size: 20, color: AppTheme.textTertiary),
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
              padding: const EdgeInsets.fromLTRB(AppTheme.lg, 0, AppTheme.lg, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(height: 20, color: AppTheme.borderColor.withOpacity(0.5)),
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
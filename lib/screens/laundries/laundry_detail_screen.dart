import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/themes/app_theme.dart';
import '../../models/laundry.dart';
import '../../repositories/laundry_repository.dart';

/// Laundry (Cabang) Detail Screen
class LaundryDetailScreen extends ConsumerWidget {
  final String laundryId;

  const LaundryDetailScreen({Key? key, required this.laundryId}) : super(key: key);

  static const List<String> _dayLabels = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text(
          'Hapus Cabang?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          'Cabang "${laundry.name}" (${laundry.code}) akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.',
          style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus', style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(laundryRepositoryProvider).deleteLaundryBranch(laundry.id);
      if (context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cabang "${laundry.name}" berhasil dihapus.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus cabang: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _toggleActive(BuildContext context, WidgetRef ref, Laundry laundry) async {
    try {
      await ref.read(laundryRepositoryProvider).updateLaundryBranch(
        laundry.id,
        {'is_active': !laundry.isActive},
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final laundryAsync = ref.watch(laundryByIdProvider(laundryId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 16 : 24,
                      isMobile ? 16 : 24,
                      isMobile ? 16 : 24,
                      24,
                    ),
                    child: laundryAsync.when(
                      data: (laundry) {
                        if (laundry == null) {
                          return _buildNotFound(context);
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTopBar(context, ref, laundry),
                            const SizedBox(height: AppTheme.lg),
                            _buildProfileCard(context, ref, laundry),
                            const SizedBox(height: AppTheme.lg),
                            _buildContactCard(context, laundry),
                            const SizedBox(height: AppTheme.lg),
                            _buildOperatingHoursCard(context, laundry),
                            const SizedBox(height: AppTheme.lg),
                            _buildCapacityLocationCard(context, laundry),
                            const SizedBox(height: AppTheme.lg),
                            _buildMetaCard(context, laundry),
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 120),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, stack) => _buildErrorState(context, error),
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

  /// Top bar: tombol back + judul + aksi edit + aksi hapus
  Widget _buildTopBar(BuildContext context, WidgetRef ref, Laundry laundry) {
    return Row(
      children: [
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
        Expanded(
          child: Text(
            'Detail Cabang',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        // Tombol Edit -> buka CreateLaundryScreen dalam mode edit
        InkWell(
          onTap: () => context.push('/laundries/${laundry.id}/edit'),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: AppTheme.sm),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(Icons.edit_outlined, color: AppTheme.primaryColor, size: 20),
          ),
        ),
        InkWell(
          onTap: () => _confirmDelete(context, ref, laundry),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
          ),
        ),
      ],
    );
  }

  /// Kartu profil utama: icon, nama, kode, badge status (bisa di-tap untuk toggle)
  Widget _buildProfileCard(BuildContext context, WidgetRef ref, Laundry laundry) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.storefront_rounded, color: AppTheme.primaryColor, size: 26),
          ),
          const SizedBox(width: AppTheme.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  laundry.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    laundry.code,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _toggleActive(context, ref, laundry),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: 7),
              decoration: BoxDecoration(
                color: (laundry.isActive ? const Color(0xFF51CF66) : Colors.grey).withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Text(
                laundry.isActive ? 'Aktif' : 'Tidak Aktif',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: laundry.isActive ? const Color(0xFF51CF66) : Colors.grey.shade600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu kontak: alamat, telepon, email
  Widget _buildContactCard(BuildContext context, Laundry laundry) {
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
          _sectionTitle('Informasi Kontak'),
          const SizedBox(height: AppTheme.md),
          _infoRow(
            Icons.location_on_outlined,
            'Alamat',
            [laundry.address, laundry.city, laundry.province].where((s) => s.isNotEmpty).join(', '),
          ),
          const SizedBox(height: AppTheme.md),
          _infoRow(Icons.phone_outlined, 'Telepon', laundry.phone.isNotEmpty ? laundry.phone : '-'),
          const SizedBox(height: AppTheme.md),
          _infoRow(Icons.email_outlined, 'Email', laundry.email.isNotEmpty ? laundry.email : '-'),
        ],
      ),
    );
  }

  /// Kartu jam operasional per hari
  Widget _buildOperatingHoursCard(BuildContext context, Laundry laundry) {
    final dayHours = _dayHoursList(laundry.operatingHours);
    final todayIndex = DateTime.now().weekday - 1; // 0 = Senin

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
          _sectionTitle('Jam Operasional'),
          const SizedBox(height: AppTheme.md),
          ...List.generate(7, (i) {
            final isToday = i == todayIndex;
            return Padding(
              padding: EdgeInsets.only(bottom: i < 6 ? AppTheme.sm : 0),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(
                      _dayLabels[i],
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                        color: isToday ? AppTheme.primaryColor : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${dayHours[i].open} - ${dayHours[i].close}',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                        color: isToday ? AppTheme.primaryColor : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Hari ini',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Kartu kapasitas & lokasi
  Widget _buildCapacityLocationCard(BuildContext context, Laundry laundry) {
    final hasLocation = laundry.location.lat != 0.0 || laundry.location.lng != 0.0;

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
          _sectionTitle('Kapasitas & Lokasi'),
          const SizedBox(height: AppTheme.md),
          _infoRow(Icons.inventory_2_outlined, 'Kapasitas', '${laundry.capacity}'),
          const SizedBox(height: AppTheme.md),
          _infoRow(
            Icons.map_outlined,
            'Koordinat',
            hasLocation
                ? '${laundry.location.lat.toStringAsFixed(6)}, ${laundry.location.lng.toStringAsFixed(6)}'
                : 'Belum diatur',
          ),
        ],
      ),
    );
  }

  /// Kartu metadata: dibuat & diperbarui
  Widget _buildMetaCard(BuildContext context, Laundry laundry) {
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
      child: Row(
        children: [
          Expanded(
            child: _metaItem('Dibuat', _formatDate(laundry.createdAt)),
          ),
          Container(width: 1, height: 32, color: AppTheme.borderColor.withOpacity(0.6)),
          Expanded(
            child: _metaItem('Diperbarui', _formatDate(laundry.updatedAt)),
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
            style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textTertiary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
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
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: AppTheme.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textTertiary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 100),
      child: Center(
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
              'Cabang tidak ditemukan',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.sm),
            Text(
              'Cabang mungkin sudah dihapus atau id tidak valid',
              style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
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
              'Gagal memuat data cabang',
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
              style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
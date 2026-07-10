import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/themes/app_theme.dart';

/// Dashboard Screen - NetWash
/// Struktur baru: wave header + floating summary card + weekly chart +
/// horizontal quick actions + timeline pesanan aktif.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color primaryBlue = Color(0xFF8ED8F5); // Biru cerah sesuai logo NetWash
  static const Color lightBlue = Color(0xFFB3E5FC); // Tint lebih muda untuk aksen ringan
  static const Color deepBlue = Color(0xFF4FC3F7); // Biru logo yang sedikit lebih pekat, untuk gradient/border
  static const Color textBlue = Color(0xFF0288D1); // Varian gelap dari biru logo, khusus teks di atas putih agar tetap kontras
  static const Color bgColor = Color(0xFFF5F8FB);

  int _filterIndex = 0;
  final List<String> _filters = const ['Semua', 'Diproses', 'Siap Diambil', 'Selesai'];

  // Setup checklist onboarding - tampil sampai owner menyelesaikan semua langkah
  // atau memilih untuk menyembunyikannya. Ganti `completed` sesuai status asli
  // dari backend (mis. cabang sudah ada karyawan / layanan atau belum).
  bool _setupDismissed = false;
  final List<_SetupStep> _setupSteps = [
    _SetupStep(
      title: 'Mulai Setup Cabang',
      subtitle: 'Lengkapi profil & alamat cabang',
      icon: Icons.store_mall_directory_outlined,
      completed: true,
      route: '/setup/branch',
    ),
    _SetupStep(
      title: 'Tambahkan Karyawan',
      subtitle: 'Undang staf untuk kelola pesanan',
      icon: Icons.person_add_alt_1_rounded,
      completed: false,
      route: '/setup/employees',
    ),
    _SetupStep(
      title: 'Tambahkan Layanan',
      subtitle: 'Atur jenis cuci & harga',
      icon: Icons.local_laundry_service_rounded,
      completed: false,
      route: '/setup/services',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isDesktop = width >= 1024;
    final maxContentWidth = isDesktop ? 1100.0 : double.infinity;

    return Scaffold(
      backgroundColor: bgColor,
      body: DefaultTextStyle.merge(
        // Menerapkan font Plus Jakarta Sans ke SEMUA Text di dalam dashboard ini,
        // tanpa perlu mengubah tiap TextStyle satu-satu. Text yang tidak mengeset
        // fontFamily sendiri otomatis mewarisi font ini.
        style: GoogleFonts.plusJakartaSans(),
        child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildWaveHeader(context, isMobile)),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -46),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? AppTheme.lg : AppTheme.xxl),
                    child: _buildBalanceCard(context),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? AppTheme.lg : AppTheme.xxl,
                  0,
                  isMobile ? AppTheme.lg : AppTheme.xxl,
                  AppTheme.xxl,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (!_setupDismissed && _setupSteps.any((s) => !s.completed)) ...[
                      _buildSetupChecklistCard(context),
                      const SizedBox(height: AppTheme.xl),
                    ],
                    _buildQuickActions(context),
                    const SizedBox(height: AppTheme.xl),
                    _buildWeeklyChart(context),
                    const SizedBox(height: AppTheme.xl),
                    _buildOrdersHeader(context),
                    const SizedBox(height: AppTheme.md),
                    _buildFilterChips(context),
                    const SizedBox(height: AppTheme.lg),
                    _buildTimeline(context),
                  ]),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  // ============================================
  // WAVE HEADER
  // ============================================
  Widget _buildWaveHeader(BuildContext context, bool isMobile) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Selamat Pagi' : (hour < 17 ? 'Selamat Sore' : 'Selamat Malam');

    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          isMobile ? AppTheme.lg : AppTheme.xxl,
          AppTheme.lg + MediaQuery.of(context).padding.top,
          isMobile ? AppTheme.lg : AppTheme.xxl,
          80,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [deepBlue, primaryBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        // Putih solid (bukan transparan) supaya logo tetap
                        // kontras dan tidak menyatu dengan gradient biru header,
                        // konsisten dengan gaya badge logo di halaman login.
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      // Logo NetWash asli, disimpan di asset/icon/Netwash_Logo.png
                      // Pastikan sudah didaftarkan di pubspec.yaml:
                      //   flutter:
                      //     assets:
                      //       - asset/icon/Netwash_Logo.png
                      child: Image.asset(
                        'asset/icon/Netwash_Logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: AppTheme.md),
                    const Text(
                      'NetWash',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
                    ),
                  ],
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE74C3C),
                          shape: BoxShape.circle,
                          border: Border.all(color: deepBlue, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.xl),
            Text(
              greeting,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Berikut ringkasan bisnis laundry Anda',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // FLOATING BALANCE / SUMMARY CARD
  // ============================================
  Widget _buildBalanceCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pendapatan bulan ini',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rp 5.200.000',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27AE60).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_upward_rounded, size: 11, color: Color(0xFF27AE60)),
                          SizedBox(width: 2),
                          Text('12%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF27AE60))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('vs bulan lalu', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          Container(width: 1, height: 50, color: Colors.grey.shade200),
          const SizedBox(width: AppTheme.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('245', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textBlue)),
              Text('Pelanggan', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(height: 10),
              Text('12', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textBlue)),
              Text('Pesanan aktif', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // SETUP CHECKLIST CARD (onboarding cabang baru)
  // ============================================
  Widget _buildSetupChecklistCard(BuildContext context) {
    final total = _setupSteps.length;
    final done = _setupSteps.where((s) => s.completed).length;
    final progress = done / total;

    return Container(
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: textBlue, size: 18),
              ),
              const SizedBox(width: AppTheme.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selesaikan Setup Cabang',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$done dari $total langkah selesai',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                color: Colors.grey.shade400,
                splashRadius: 18,
                onPressed: () => setState(() => _setupDismissed = true),
                tooltip: 'Sembunyikan',
              ),
            ],
          ),
          const SizedBox(height: AppTheme.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation(primaryBlue),
            ),
          ),
          const SizedBox(height: AppTheme.lg),
          ...List.generate(_setupSteps.length, (i) {
            final step = _setupSteps[i];
            final isLast = i == _setupSteps.length - 1;
            return InkWell(
              onTap: () {
                // context.push(step.route); // arahkan ke halaman setup terkait
              },
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : AppTheme.md),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: step.completed ? const Color(0xFF27AE60).withOpacity(0.12) : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        step.completed ? Icons.check_rounded : step.icon,
                        size: 16,
                        color: step.completed ? const Color(0xFF27AE60) : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: AppTheme.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: step.completed ? Colors.grey.shade400 : Colors.black87,
                              decoration: step.completed ? TextDecoration.lineThrough : null,
                              decorationColor: Colors.grey.shade400,
                            ),
                          ),
                          Text(
                            step.subtitle,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    if (!step.completed)
                      Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }


  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      (Icons.add_circle_outline_rounded, 'Pesanan\nBaru', primaryBlue),
      (Icons.person_add_alt_1_rounded, 'Pelanggan\nBaru', deepBlue),
      (Icons.local_shipping_outlined, 'Antar\nJemput', const Color(0xFF27AE60)),
      (Icons.bar_chart_rounded, 'Laporan', const Color(0xFFE67E22)),
      (Icons.settings_outlined, 'Pengaturan', Colors.grey.shade700),
    ];

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTheme.lg),
        itemBuilder: (context, i) {
          final (icon, label, color) = actions[i];
          return InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(40),
            child: SizedBox(
              width: 64,
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.15),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================
  // WEEKLY REVENUE CHART (CustomPainter, tanpa dependency)
  // ============================================
  Widget _buildWeeklyChart(BuildContext context) {
    const values = [0.4, 0.6, 0.5, 0.8, 0.65, 0.9, 0.7];
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return Container(
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pendapatan Mingguan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('7 hari', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textBlue)),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.lg),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (i) {
                final isPeak = values[i] == values.reduce((a, b) => a > b ? a : b);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: 80 * values[i],
                          decoration: BoxDecoration(
                            color: isPeak ? primaryBlue : primaryBlue.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(days[i], style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Pesanan Aktif', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        TextButton(
          onPressed: () {},
          child: const Text('Lihat Semua', style: TextStyle(color: textBlue, fontWeight: FontWeight.w600, fontSize: 12.5)),
        ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTheme.sm),
        itemBuilder: (context, i) {
          final selected = i == _filterIndex;
          return ChoiceChip(
            label: Text(_filters[i]),
            selected: selected,
            onSelected: (_) => setState(() => _filterIndex = i),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.grey.shade700,
            ),
            selectedColor: textBlue,
            backgroundColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  // ============================================
  // TIMELINE PESANAN (garis vertikal + titik status)
  // ============================================
  Widget _buildTimeline(BuildContext context) {
    final orders = [
      ('#ORD-12345', 'Budi Santoso', '5 item · Rp 150.000', 'Sedang Diproses', const Color(0xFFE67E22)),
      ('#ORD-12344', 'Siti Nurhaliza', '3 item · Rp 90.000', 'Siap Diambil', const Color(0xFF27AE60)),
      ('#ORD-12343', 'Ahmad Wijaya', '8 item · Rp 220.000', 'Menunggu Pembayaran', const Color(0xFFE74C3C)),
    ];

    return Column(
      children: List.generate(orders.length, (i) {
        final (id, name, detail, status, color) = orders[i];
        final isLast = i == orders.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withOpacity(0.25), width: 4),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(width: 2, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(vertical: 4)),
                    ),
                ],
              ),
              const SizedBox(width: AppTheme.md),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(bottom: isLast ? 0 : AppTheme.lg),
                  padding: const EdgeInsets.all(AppTheme.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
                                const SizedBox(width: 6),
                                Text(id, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(detail, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.sm, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(status, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Clipper untuk bentuk lengkung (wave) di header
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Model data satu langkah pada setup checklist onboarding cabang
class _SetupStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool completed;
  final String route;

  _SetupStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.completed,
    required this.route,
  });
}
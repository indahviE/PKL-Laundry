import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/themes/app_theme.dart';

/// Dashboard Screen - NetWash
/// Terintegrasi dengan Firebase Firestore (Real-time Streams)
/// Mengimplementasikan Fitur Gating / Limit Paket Langganan secara Asli
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color primaryBlue = Color(0xFF8ED8F5); // Biru cerah sesuai logo NetWash
  static const Color lightBlue = Color(0xFFB3E5FC); // Tint lebih muda untuk aksen ringan
  static const Color deepBlue = Color(0xFF4FC3F7); // Biru logo pekat untuk gradient
  static const Color textBlue = Color(0xFF0288D1); // Gelap untuk teks di atas putih
  static const Color bgColor = Color(0xFFF5F8FB);

  int _filterIndex = 0;
  final List<String> _filters = const ['Semua', 'Diproses', 'Siap Diambil', 'Selesai'];

  // Status dismiss checklist onboarding secara lokal
  bool _setupDismissed = false;
  
  // Mengambil uid user yang sedang login dari Firebase Auth
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "placeholder_uid";

  /// Mapping indeks filter ke status database NetWash asli
  List<String>? _getStatusFilter(int index) {
    switch (index) {
      case 1: // Diproses
        return ['pending', 'confirmed', 'in_progress', 'washing', 'drying', 'ironing', 'quality_check'];
      case 2: // Siap Diambil
        return ['ready'];
      case 3: // Selesai
        return ['completed'];
      default: // Semua
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isDesktop = width >= 1024;
    final maxContentWidth = isDesktop ? 1100.0 : double.infinity;

    return Scaffold(
      backgroundColor: bgColor,
      body: DefaultTextStyle.merge(
        // Menerapkan font Plus Jakarta Sans ke seluruh teks di dalam dashboard ini
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
                      child: _buildBalanceCardRealtime(),
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
                      _buildSetupChecklistRealtime(),
                      const SizedBox(height: AppTheme.xl),
                      _buildQuickActions(context),
                      const SizedBox(height: AppTheme.xl),
                      _buildWeeklyChartRealtime(),
                      const SizedBox(height: AppTheme.xl),
                      _buildOrdersHeader(context),
                      const SizedBox(height: AppTheme.md),
                      _buildFilterChips(context),
                      const SizedBox(height: AppTheme.lg),
                      _buildTimelineRealtime(),
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
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: const Icon(Icons.local_laundry_service_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: AppTheme.md),
                    const Text(
                      'NetWash',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
                    ),
                  ],
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.xl),
            Text(
              greeting,
              style: const TextStyle(
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
  // REAL-TIME SUMMARY CARD (Firestore Stream)
  // ============================================
  Widget _buildBalanceCardRealtime() {
    final userRef = FirebaseFirestore.instance.collection('users').doc(_currentUserId);

    return StreamBuilder<QuerySnapshot>(
      stream: userRef.collection('orders').snapshots(),
      builder: (context, orderSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: userRef.collection('customers').snapshots(),
          builder: (context, customerSnapshot) {
            int totalCustomers = customerSnapshot.hasData ? customerSnapshot.data!.docs.length : 0;
            int activeOrders = 0;
            double totalRevenueThisMonth = 0;

            if (orderSnapshot.hasData) {
              final now = DateTime.now();
              final startOfMonth = DateTime(now.year, now.month, 1);

              for (var doc in orderSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                String status = data['status'] ?? 'pending';
                
                // Menghitung pesanan yang belum selesai
                if (['pending', 'confirmed', 'in_progress', 'washing', 'drying', 'ironing', 'quality_check', 'ready'].contains(status)) {
                  activeOrders++;
                }

                // Menghitung pendapatan dari transaksi sukses (paid) bulan ini
                Timestamp? orderDate = data['order_date'] as Timestamp?;
                if (orderDate != null && orderDate.toDate().isAfter(startOfMonth)) {
                  if (data['payment_status'] == 'paid') {
                    totalRevenueThisMonth += (data['total_amount'] ?? 0).toDouble();
                  }
                }
              }
            }

            // Memformat visual ke UI Card asli
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
                          'Rp ${totalRevenueThisMonth.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            letterSpacing: -0.3,
                           ),
                        ),
                        const SizedBox(height: 6),
                        Text('Sinkronisasi otomatis', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 50, color: Colors.grey.shade200),
                  const SizedBox(width: AppTheme.lg),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$totalCustomers', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textBlue)),
                      Text('Pelanggan', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      const SizedBox(height: 10),
                      Text('$activeOrders', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textBlue)),
                      Text('Pesanan aktif', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================
  // REAL-TIME SETUP ONBOARDING CHECKLIST
  // ============================================
  Widget _buildSetupChecklistRealtime() {
    if (_setupDismissed) return const SizedBox.shrink();

    final userRef = FirebaseFirestore.instance.collection('users').doc(_currentUserId);

    return StreamBuilder<QuerySnapshot>(
      stream: userRef.collection('employees').snapshots(),
      builder: (context, employeeSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: userRef.collection('service_types').snapshots(),
          builder: (context, serviceSnap) {
            
            // Setup Cabang dipaksa true karena sudah diselesaikan saat awal onboarding pendaftaran
            bool hasBranch = true; 
            bool hasEmployee = employeeSnap.hasData && employeeSnap.data!.docs.isNotEmpty;
            bool hasService = serviceSnap.hasData && serviceSnap.data!.docs.isNotEmpty;

            final List<_SetupStep> steps = [
              _SetupStep(
                title: 'Mulai Setup Cabang',
                subtitle: 'Lengkapi profil & alamat cabang',
                icon: Icons.store_mall_directory_outlined,
                completed: hasBranch,
                route: '/setup/branch',
              ),
              _SetupStep(
                title: 'Tambahkan Karyawan',
                subtitle: 'Undang staf untuk kelola pesanan',
                icon: Icons.person_add_alt_1_rounded,
                completed: hasEmployee,
                route: '/setup/employees',
              ),
              _SetupStep(
                title: 'Tambahkan Layanan',
                subtitle: 'Atur jenis cuci & harga',
                icon: Icons.local_laundry_service_rounded,
                completed: hasService,
                route: '/setup/services',
              ),
            ];

            // Jika semua langkah setup selesai dilakukan, sembunyikan card secara otomatis
            if (steps.every((s) => s.completed)) return const SizedBox.shrink();

            int done = steps.where((s) => s.completed).length;
            double progress = done / steps.length;

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
                              '$done dari ${steps.length} langkah selesai',
                              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: Colors.grey.shade400,
                        onPressed: () => setState(() => _setupDismissed = true),
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
                  ...List.generate(steps.length, (i) {
                    final step = steps[i];
                    final isLast = i == steps.length - 1;
                    return InkWell(
                      onTap: () => context.push(step.route),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : AppTheme.md),
                        child: Row(
                          children: [
                            Container(
                              width: 30, height: 30,
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
                                    ),
                                  ),
                                  Text(step.subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
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
          },
        );
      },
    );
  }

  // ============================================
  // QUICK ACTIONS + FEATURE GATING INTEGRATION
  // ============================================
  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      (Icons.add_circle_outline_rounded, 'Pesanan\nBaru', primaryBlue, '/create-order', 'orders', 500),
      (Icons.person_add_alt_1_rounded, 'Karyawan\nBaru', deepBlue, '/create-employee', 'employees', 5),
      (Icons.local_shipping_outlined, 'Antar\nJemput', const Color(0xFF27AE60), '/antar-jemput', '', 0),
      (Icons.bar_chart_rounded, 'Laporan', const Color(0xFFE67E22), '/laporan', '', 0),
      (Icons.settings_outlined, 'Pengaturan', Colors.grey.shade700, '/settings', '', 0),
    ];

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTheme.lg),
        itemBuilder: (context, i) {
          final (icon, label, color, route, collectionToCheck, limit) = actions[i]; 
          return InkWell(
            onTap: () async {
              if (collectionToCheck.isNotEmpty) {
                final snap = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_currentUserId)
                    .collection(collectionToCheck)
                    .count()
                    .get();
                
                // Mengantisipasi nilai null safety pada properti count
                if ((snap.count ?? 0) >= limit) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Batas kuota harian/bulanan paket Starter untuk $label telah tercapai! Silakan upgrade.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
              }
              context.push(route); 
            },
            borderRadius: BorderRadius.circular(40),
            child: SizedBox(
              width: 64,
              child: Column(
                children: [
                  Container(
                    width: 52, height: 52,
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
  // REAL-TIME WEEKLY REVENUE CHART
  // ============================================
  Widget _buildWeeklyChartRealtime() {
    final startOfWeek = DateTime.now().subtract(const Duration(days: 7));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .collection('orders')
          .where('order_date', isGreaterThanOrEqualTo: startOfWeek)
          .snapshots(),
      builder: (context, snapshot) {
        List<double> values = List.filled(7, 0.0);
        List<String> days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            Timestamp? orderDate = data['order_date'] as Timestamp?;
            if (orderDate != null && data['payment_status'] == 'paid') {
              int weekday = orderDate.toDate().weekday - 1; 
              if (weekday >= 0 && weekday < 7) {
                values[weekday] += (data['total_amount'] ?? 0).toDouble();
              }
            }
          }
        }

        double maxVal = values.reduce((a, b) => a > b ? a : b);
        List<double> scaledValues = values.map((v) => maxVal > 0 ? (v / maxVal) : 0.0).toList();

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
                  children: List.generate(scaledValues.length, (i) {
                    final isPeak = scaledValues[i] == scaledValues.reduce((a, b) => a > b ? a : b) && scaledValues[i] > 0;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              height: 80 * scaledValues[i],
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
      },
    );
  }

  // ============================================
  // ORDERS HEADER
  // ============================================
  Widget _buildOrdersHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Pesanan Utama', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        TextButton(
          onPressed: () => context.push('/orders'),
          child: const Text('Lihat Semua', style: TextStyle(color: textBlue, fontWeight: FontWeight.w600, fontSize: 12.5)),
        ),
      ],
    );
  }

  // ============================================
  // FILTER CHIPS
  // ============================================
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
  // REAL-TIME TIMELINE PESANAN (Firestore Stream)
  // ============================================
  Widget _buildTimelineRealtime() {
    var query = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('orders')
        .orderBy('order_date', descending: true);

    List<String>? statusFilter = _getStatusFilter(_filterIndex);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('Tidak ada data pesanan.')));
        }

        var docs = snapshot.data!.docs;
        if (statusFilter != null) {
          docs = docs.where((doc) => statusFilter.contains(doc['status'])).toList();
        }

        if (docs.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('Tidak ada pesanan dengan status ini.')));
        }

        return Column(
          children: List.generate(docs.length, (i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final id = data['order_number'] ?? '#ORD-UNKNOWN';
            final customerName = data['customer_name'] ?? 'Pelanggan Umum';
            final detail = '${data['total_items'] ?? 0} item · Rp ${(data['total_amount'] ?? 0).toString()}';
            final status = data['status'] ?? 'pending';
            final isLast = i == docs.length - 1;

            Color statusColor;
            String statusLabel;
            switch (status) {
              case 'ready':
                statusColor = const Color(0xFF27AE60);
                statusLabel = 'Siap Diambil';
                break;
              case 'completed':
                statusColor = Colors.blue;
                statusLabel = 'Selesai';
                break;
              case 'cancelled':
                statusColor = const Color(0xFFE74C3C);
                statusLabel = 'Batal';
                break;
              default:
                statusColor = const Color(0xFFE67E22);
                statusLabel = 'Sedang Diproses';
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 12, height: 12,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: statusColor.withOpacity(0.25), width: 4),
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
                                    Text(customerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
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
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(statusLabel, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: statusColor)),
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
      },
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 60);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

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
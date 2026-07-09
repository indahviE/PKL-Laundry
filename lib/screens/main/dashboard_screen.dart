import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';

/// Dashboard Screen - Sesuai logo NetWash, design modern & responsive
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? AppTheme.lg : AppTheme.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Card
              _buildGreetingCard(context),

              SizedBox(height: isMobile ? AppTheme.xl : AppTheme.xxl),

              // Stats Section
              _buildStatsSection(context, isMobile),

              SizedBox(height: isMobile ? AppTheme.xl : AppTheme.xxl),

              // Quick Actions
              _buildQuickActions(context, isMobile),

              SizedBox(height: isMobile ? AppTheme.xl : AppTheme.xxl),

              // Recent Orders
              _buildRecentOrdersSection(context, isMobile),

              const SizedBox(height: AppTheme.lg),
            ],
          ),
        ),
      ),
    );
  }

  /// Build App Bar
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'Dashboard',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: () {},
        ),
      ],
    );
  }

  /// Build Greeting Card - Sesuai warna logo NetWash
  Widget _buildGreetingCard(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Selamat Pagi'
        : hour < 17
            ? 'Selamat Sore'
            : 'Selamat Malam';

    return Container(
      padding: const EdgeInsets.all(AppTheme.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF5DADE2), // Light blue sesuai logo NetWash
            const Color(0xFF3498DB), // Slightly darker blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5DADE2).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppTheme.sm),
                    Text(
                      'Kelola bisnis laundry Anda dengan mudah',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppTheme.md),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(
                  Icons.local_laundry_service,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.lg),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.md,
              vertical: AppTheme.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.info_outlined,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: AppTheme.sm),
                Text(
                  'Anda memiliki 3 pesanan baru hari ini',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build Stats Section
  Widget _buildStatsSection(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistik Hari Ini',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppTheme.lg),

        // Stats Grid
        GridView.count(
          crossAxisCount: isMobile ? 2 : 4,
          crossAxisSpacing: AppTheme.lg,
          mainAxisSpacing: AppTheme.lg,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StatCard(
              icon: Icons.receipt_outlined,
              iconColor: const Color(0xFF5DADE2),
              title: 'Pesanan',
              value: '12',
              subtitle: 'pesanan baru',
            ),
            _StatCard(
              icon: Icons.people_outlined,
              iconColor: const Color(0xFF3498DB),
              title: 'Pelanggan',
              value: '245',
              subtitle: 'total pelanggan',
            ),
            _StatCard(
              icon: Icons.trending_up,
              iconColor: const Color(0xFF51CF66),
              title: 'Revenue',
              value: 'Rp 5.2M',
              subtitle: 'bulan ini',
            ),
            _StatCard(
              icon: Icons.badge_outlined,
              iconColor: const Color(0xFFFFA500),
              title: 'Karyawan',
              value: '8',
              subtitle: 'total staff',
            ),
          ],
        ),
      ],
    );
  }

  /// Build Quick Actions
  Widget _buildQuickActions(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aksi Cepat',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppTheme.lg),
        GridView.count(
          crossAxisCount: isMobile ? 2 : 4,
          crossAxisSpacing: AppTheme.lg,
          mainAxisSpacing: AppTheme.lg,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _QuickActionButton(
              icon: Icons.add_circle_outline,
              label: 'Pesanan Baru',
              onPressed: () {},
              color: const Color(0xFF5DADE2),
            ),
            _QuickActionButton(
              icon: Icons.person_add_outlined,
              label: 'Pelanggan Baru',
              onPressed: () {},
              color: const Color(0xFF3498DB),
            ),
            _QuickActionButton(
              icon: Icons.assignment_outlined,
              label: 'Laporan',
              onPressed: () {},
              color: const Color(0xFF51CF66),
            ),
            _QuickActionButton(
              icon: Icons.settings_outlined,
              label: 'Pengaturan',
              onPressed: () {},
              color: const Color(0xFFFFA500),
            ),
          ],
        ),
      ],
    );
  }

  /// Build Recent Orders Section
  Widget _buildRecentOrdersSection(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pesanan Terbaru',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  color: Color(0xFF5DADE2),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.lg),

        // Recent Orders List
        _RecentOrderCard(
          orderId: '#ORD-12345',
          customerName: 'Budi Santoso',
          items: '5 item',
          status: 'Sedang Diproses',
          statusColor: Colors.orange,
          amount: 'Rp 150.000',
        ),

        const SizedBox(height: AppTheme.md),

        _RecentOrderCard(
          orderId: '#ORD-12344',
          customerName: 'Siti Nurhaliza',
          items: '3 item',
          status: 'Siap Diambil',
          statusColor: const Color(0xFF51CF66),
          amount: 'Rp 90.000',
        ),

        const SizedBox(height: AppTheme.md),

        _RecentOrderCard(
          orderId: '#ORD-12343',
          customerName: 'Ahmad Wijaya',
          items: '8 item',
          status: 'Menunggu Pembayaran',
          statusColor: Colors.red,
          amount: 'Rp 220.000',
        ),
      ],
    );
  }
}

// ============================================
// HELPER WIDGETS
// ============================================

/// Stat Card Widget - Modern Design
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.md),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(height: AppTheme.lg),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTheme.sm),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkColor,
            ),
          ),
          const SizedBox(height: AppTheme.sm),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick Action Button Widget
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.lg),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: AppTheme.md),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Recent Order Card Widget
class _RecentOrderCard extends StatelessWidget {
  final String orderId;
  final String customerName;
  final String items;
  final String status;
  final Color statusColor;
  final String amount;

  const _RecentOrderCard({
    required this.orderId,
    required this.customerName,
    required this.items,
    required this.status,
    required this.statusColor,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? AppTheme.lg : AppTheme.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orderId,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppTheme.sm),
                    Text(
                      customerName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.md,
                  vertical: AppTheme.sm,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.lg),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: AppTheme.sm),
                  Text(
                    items,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5DADE2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
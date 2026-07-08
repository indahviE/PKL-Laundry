import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';

/// Dashboard Screen
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Card
              _buildGreetingCard(context),

              const SizedBox(height: AppTheme.xxl),

              // Stats Section
              _buildStatsSection(context),

              const SizedBox(height: AppTheme.xxl),

              // Quick Actions
              _buildQuickActions(context),

              const SizedBox(height: AppTheme.xxl),

              // Recent Orders
              _buildRecentOrdersSection(context),

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
      title: const Text('Dashboard'),
      elevation: 0,
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

  /// Build Greeting Card
  Widget _buildGreetingCard(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Selamat Pagi'
        : hour < 17
            ? 'Selamat Sore'
            : 'Selamat Malam';

    return Container(
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.secondaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
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
          const SizedBox(height: AppTheme.md),
          Text(
            'Kelola bisnis laundry Anda dengan mudah',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
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
            child: Text(
              'Anda memiliki 3 pesanan baru hari ini',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Stats Section
  Widget _buildStatsSection(BuildContext context) {
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

        // First Row
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.receipt_outlined,
                iconColor: const Color(0xFF6C63FF),
                title: 'Pesanan',
                value: '12',
                subtitle: 'pesanan baru',
              ),
            ),
            const SizedBox(width: AppTheme.lg),
            Expanded(
              child: _StatCard(
                icon: Icons.people_outlined,
                iconColor: const Color(0xFF00D4FF),
                title: 'Pelanggan',
                value: '245',
                subtitle: 'total pelanggan',
              ),
            ),
          ],
        ),

        const SizedBox(height: AppTheme.lg),

        // Second Row
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.trending_up,
                iconColor: const Color(0xFF51CF66),
                title: 'Revenue',
                value: 'Rp 5.2M',
                subtitle: 'bulan ini',
              ),
            ),
            const SizedBox(width: AppTheme.lg),
            Expanded(
              child: _StatCard(
                icon: Icons.badge_outlined,
                iconColor: const Color(0xFFFFA500),
                title: 'Karyawan',
                value: '8',
                subtitle: 'total staff',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build Quick Actions
  Widget _buildQuickActions(BuildContext context) {
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
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.add_circle_outline,
                label: 'Pesanan Baru',
                onPressed: () {},
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: AppTheme.lg),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.person_add_outlined,
                label: 'Pelanggan Baru',
                onPressed: () {},
                color: AppTheme.secondaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.lg),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.assignment_outlined,
                label: 'Laporan',
                onPressed: () {},
                color: AppTheme.warningColor,
              ),
            ),
            const SizedBox(width: AppTheme.lg),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.settings_outlined,
                label: 'Pengaturan',
                onPressed: () {},
                color: AppTheme.infoColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build Recent Orders Section
  Widget _buildRecentOrdersSection(BuildContext context) {
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
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.lg),

        // Recent Order 1
        _RecentOrderCard(
          orderId: '#ORD-12345',
          customerName: 'Budi Santoso',
          items: '5 item',
          status: 'Sedang Diproses',
          statusColor: Colors.orange,
          amount: 'Rp 150.000',
        ),

        const SizedBox(height: AppTheme.md),

        // Recent Order 2
        _RecentOrderCard(
          orderId: '#ORD-12344',
          customerName: 'Siti Nurhaliza',
          items: '3 item',
          status: 'Siap Diambil',
          statusColor: AppTheme.successColor,
          amount: 'Rp 90.000',
        ),

        const SizedBox(height: AppTheme.md),

        // Recent Order 3
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

/// Stat Card Widget
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
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
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
              color: iconColor.withOpacity(0.1),
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.sm),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkColor,
            ),
          ),
          const SizedBox(height: AppTheme.sm),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
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
    return Container(
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
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
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.md,
                  vertical: AppTheme.sm,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.lg),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                items,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
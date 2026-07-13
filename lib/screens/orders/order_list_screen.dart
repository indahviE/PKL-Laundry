import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';

/// Order Model
class OrderItem {
  final String id;
  final String customerName;
  final String status; // 'pending', 'processing', 'completed', 'cancelled'
  final double amount;
  final int itemCount;
  final DateTime date;
  final String customerPhone;

  OrderItem({
    required this.id,
    required this.customerName,
    required this.status,
    required this.amount,
    required this.itemCount,
    required this.date,
    required this.customerPhone,
  });
}

/// Orders List Screen
class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({Key? key}) : super(key: key);

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  // Controllers
  late TextEditingController _searchController;

  // State
  String _selectedFilter = 'all'; // all, pending, processing, completed, cancelled
  late List<OrderItem> _allOrders;
  late List<OrderItem> _filteredOrders;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _initializeSampleOrders();
    _filteredOrders = _allOrders;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Initialize sample orders
  void _initializeSampleOrders() {
    _allOrders = [
      OrderItem(
        id: '#ORD-12345',
        customerName: 'Budi Santoso',
        status: 'processing',
        amount: 150000,
        itemCount: 5,
        date: DateTime.now(),
        customerPhone: '081234567890',
      ),
      OrderItem(
        id: '#ORD-12344',
        customerName: 'Siti Nurhaliza',
        status: 'completed',
        amount: 90000,
        itemCount: 3,
        date: DateTime.now().subtract(const Duration(days: 1)),
        customerPhone: '082345678901',
      ),
      OrderItem(
        id: '#ORD-12343',
        customerName: 'Ahmad Wijaya',
        status: 'pending',
        amount: 220000,
        itemCount: 8,
        date: DateTime.now(),
        customerPhone: '083456789012',
      ),
      OrderItem(
        id: '#ORD-12342',
        customerName: 'Rina Gunawan',
        status: 'processing',
        amount: 175000,
        itemCount: 6,
        date: DateTime.now().subtract(const Duration(days: 2)),
        customerPhone: '084567890123',
      ),
      OrderItem(
        id: '#ORD-12341',
        customerName: 'Doni Hermawan',
        status: 'completed',
        amount: 320000,
        itemCount: 12,
        date: DateTime.now().subtract(const Duration(days: 3)),
        customerPhone: '085678901234',
      ),
      OrderItem(
        id: '#ORD-12340',
        customerName: 'Eka Putri',
        status: 'cancelled',
        amount: 110000,
        itemCount: 4,
        date: DateTime.now().subtract(const Duration(days: 4)),
        customerPhone: '086789012345',
      ),
    ];
  }

  /// Filter dan search orders
  void _applyFiltersAndSearch() {
    _filteredOrders = _allOrders.where((order) {
      bool statusMatch = _selectedFilter == 'all' || order.status == _selectedFilter;
      bool searchMatch = _searchController.text.isEmpty ||
          order.customerName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          order.id.toLowerCase().contains(_searchController.text.toLowerCase());
      return statusMatch && searchMatch;
    }).toList();
    setState(() {});
  }

  /// Get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return const Color(0xFF5DADE2);
      case 'completed':
        return const Color(0xFF51CF66);
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get status label
  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'processing':
        return 'Diproses';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  /// Format currency
  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  /// Format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

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
              // Header with action button
              _buildHeader(context),

              const SizedBox(height: AppTheme.xl),

              // Search bar
              _buildSearchBar(context),

              const SizedBox(height: AppTheme.lg),

              // Filter buttons
              _buildFilterButtons(context),

              const SizedBox(height: AppTheme.xl),

              // Stats summary
              _buildStatsSummary(context, isMobile),

              const SizedBox(height: AppTheme.xl),

              // Orders table/list
              _filteredOrders.isEmpty
                  ? _buildEmptyState(context)
                  : _buildOrdersList(context, isMobile),

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
        'Pesanan',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    );
  }

  /// Build header
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daftar Pesanan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.sm),
            Text(
              'Kelola semua pesanan laundry Anda',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.gray600,
                  ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Navigasi ke Create Order akan ditambahkan'),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Pesanan Baru'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5DADE2),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.lg,
              vertical: AppTheme.md,
            ),
          ),
        ),
      ],
    );
  }

  /// Build search bar
  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      controller: _searchController,
      onChanged: (value) => _applyFiltersAndSearch(),
      decoration: InputDecoration(
        hintText: 'Cari pesanan atau pelanggan...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: const BorderSide(color: Color(0xFF5DADE2), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.lg,
          vertical: AppTheme.md,
        ),
      ),
    );
  }

  /// Build filter buttons
  Widget _buildFilterButtons(BuildContext context) {
    final filters = [
      ('all', 'Semua', Icons.all_inbox),
      ('pending', 'Menunggu', Icons.schedule),
      ('processing', 'Diproses', Icons.local_laundry_service),
      ('completed', 'Selesai', Icons.check_circle),
      ('cancelled', 'Dibatalkan', Icons.cancel),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          filters.length,
          (index) => Padding(
            padding: EdgeInsets.only(right: index < filters.length - 1 ? AppTheme.md : 0),
            child: FilterChip(
              selected: _selectedFilter == filters[index].$1,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filters[index].$1;
                });
                _applyFiltersAndSearch();
              },
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(filters[index].$3, size: 16),
                  const SizedBox(width: AppTheme.sm),
                  Text(filters[index].$2),
                ],
              ),
              backgroundColor: Colors.grey.shade100,
              selectedColor: const Color(0xFF5DADE2).withOpacity(0.2),
              labelStyle: TextStyle(
                color: _selectedFilter == filters[index].$1
                    ? const Color(0xFF5DADE2)
                    : AppTheme.gray600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build stats summary
  Widget _buildStatsSummary(BuildContext context, bool isMobile) {
    final totalOrders = _filteredOrders.length;
    final totalAmount = _filteredOrders.fold<double>(
      0,
      (sum, order) => sum + order.amount,
    );

    return Row(
      children: [
        Expanded(
          child: _StatBox(
            title: 'Total Pesanan',
            value: '$totalOrders',
            icon: Icons.receipt_outlined,
            color: const Color(0xFF5DADE2),
          ),
        ),
        const SizedBox(width: AppTheme.lg),
        Expanded(
          child: _StatBox(
            title: 'Total Revenue',
            value: _formatCurrency(totalAmount),
            icon: Icons.trending_up,
            color: const Color(0xFF51CF66),
          ),
        ),
      ],
    );
  }

  /// Build empty state
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.xxl),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: AppTheme.lg),
            Text(
              'Tidak ada pesanan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.sm),
            Text(
              'Buat pesanan baru untuk memulai',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.gray600,
                  ),
            ),
            const SizedBox(height: AppTheme.xl),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Buat Pesanan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5DADE2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build orders list
  Widget _buildOrdersList(BuildContext context, bool isMobile) {
    return Column(
      children: List.generate(
        _filteredOrders.length,
        (index) => Column(
          children: [
            _OrderCard(
              order: _filteredOrders[index],
              statusColor: _getStatusColor(_filteredOrders[index].status),
              statusLabel: _getStatusLabel(_filteredOrders[index].status),
              formattedAmount: _formatCurrency(_filteredOrders[index].amount),
              formattedDate: _formatDate(_filteredOrders[index].date),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Detail pesanan ${_filteredOrders[index].id}'),
                  ),
                );
              },
            ),
            if (index < _filteredOrders.length - 1)
              const SizedBox(height: AppTheme.lg),
          ],
        ),
      ),
    );
  }
}

// ============================================
// HELPER WIDGETS
// ============================================

/// Stat Box Widget
class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: AppTheme.md),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.sm),
          Text(
            title,
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

/// Order Card Widget
class _OrderCard extends StatelessWidget {
  final OrderItem order;
  final Color statusColor;
  final String statusLabel;
  final String formattedAmount;
  final String formattedDate;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.statusColor,
    required this.statusLabel,
    required this.formattedAmount,
    required this.formattedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.id,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppTheme.sm),
                    Text(
                      order.customerName,
                      style: TextStyle(
                        fontSize: 13,
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
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Text(
                    statusLabel,
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
                      '${order.itemCount} item',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: AppTheme.sm),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Text(
                  formattedAmount,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5DADE2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
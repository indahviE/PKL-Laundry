import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
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

  /// Buka Create Order screen, refresh list kalau berhasil disimpan
  Future<void> _openCreateOrder(BuildContext context) async {
    final result = await context.push<bool>('/orders/create');
    if (result == true && mounted) {
      // TODO: refresh dari Firestore begitu backend-nya siap
      _applyFiltersAndSearch();
    }
  }

  /// Get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return AppTheme.primaryColor;
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
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 16 : 24,
                      isMobile ? 16 : 24,
                      isMobile ? 16 : 24,
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 22),
                        _buildSearchBar(context),
                        const SizedBox(height: AppTheme.lg),
                        _buildFilterButtons(context),
                        const SizedBox(height: AppTheme.xl),
                        _buildStatsSummary(context, isMobile),
                        const SizedBox(height: AppTheme.xl),
                        _filteredOrders.isEmpty
                            ? _buildEmptyState(context)
                            : _buildOrdersList(context, isMobile),
                        const SizedBox(height: AppTheme.lg),
                      ],
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

  /// Build header (solid, no gradient) — sama gayanya dengan CustomersListScreen
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pesanan',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kelola semua pesanan laundry Anda',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _openCreateOrder(context),
          icon: const Icon(Icons.add, size: 18),
          label: Text(
            'Baru',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.lg,
              vertical: AppTheme.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        ),
      ],
    );
  }

  /// Build search bar
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => _applyFiltersAndSearch(),
        style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Cari pesanan atau pelanggan...',
          hintStyle: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textTertiary),
          prefixIcon: Icon(Icons.search, color: AppTheme.textTertiary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
          ),
          filled: true,
          fillColor: AppTheme.cardColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.lg,
            vertical: AppTheme.md,
          ),
        ),
      ),
    );
  }

  /// Build filter buttons
  Widget _buildFilterButtons(BuildContext context) {
    final filters = [
      ('all', 'Semua', Icons.all_inbox_outlined),
      ('pending', 'Menunggu', Icons.schedule_outlined),
      ('processing', 'Diproses', Icons.local_laundry_service_outlined),
      ('completed', 'Selesai', Icons.check_circle_outline),
      ('cancelled', 'Dibatalkan', Icons.cancel_outlined),
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
              showCheckmark: false,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(filters[index].$3, size: 16),
                  const SizedBox(width: AppTheme.sm),
                  Text(filters[index].$2),
                ],
              ),
              backgroundColor: AppTheme.cardColor,
              selectedColor: AppTheme.primaryColor.withOpacity(0.12),
              side: BorderSide(
                color: _selectedFilter == filters[index].$1
                    ? AppTheme.primaryColor.withOpacity(0.4)
                    : AppTheme.borderColor,
              ),
              labelStyle: GoogleFonts.poppins(
                fontSize: 12.5,
                color: _selectedFilter == filters[index].$1
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
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
            color: AppTheme.primaryColor,
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
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 40,
                color: AppTheme.primaryColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppTheme.lg),
            Text(
              'Tidak ada pesanan',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.sm),
            Text(
              'Buat pesanan baru untuk memulai',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.xl),
            ElevatedButton.icon(
              onPressed: () => _openCreateOrder(context),
              icon: const Icon(Icons.add, size: 18),
              label: Text('Buat Pesanan', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.xl, vertical: AppTheme.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
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
              onTap: () => context.push(
                '/orders/${_filteredOrders[index].id.replaceAll('#', '')}',
              ),
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

/// Stat Box Widget — sama persis gayanya dengan CustomersListScreen
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
          Container(
            padding: const EdgeInsets.all(AppTheme.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
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
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Order Card Widget — sama persis gayanya dengan CustomerCard
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.id,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.customerName,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.md,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.lg),
            Divider(height: 1, color: AppTheme.borderColor.withOpacity(0.6)),
            const SizedBox(height: AppTheme.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 15,
                      color: AppTheme.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${order.itemCount} item',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: AppTheme.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
                Text(
                  formattedAmount,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
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
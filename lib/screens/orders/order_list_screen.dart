import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/themes/app_theme.dart';

/// Order Model
class OrderItem {
  final String id; // Firestore document id
  final String orderNumber;
  final String customerName;
  final String status; // 'pending', 'processing', 'completed', 'cancelled'
  final double amount;
  final int itemCount;
  final DateTime date;
  final String customerPhone;

  OrderItem({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.status,
    required this.amount,
    required this.itemCount,
    required this.date,
    required this.customerPhone,
  });

  /// Mapping dari dokumen Firestore users/{uid}/orders/{orderId}
  /// sesuai skema di PRD (bagian 3.4.1 Struktur Data Pesanan)
  factory OrderItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final orderDate = data['order_date'];

    return OrderItem(
      id: doc.id,
      orderNumber: (data['order_number'] ?? doc.id) as String,
      customerName: (data['customer_name'] ?? '') as String,
      status: (data['status'] ?? 'pending') as String,
      amount: ((data['total_amount'] ?? 0) as num).toDouble(),
      itemCount: (data['total_items'] ?? 0) is int
          ? data['total_items'] as int
          : ((data['total_items'] ?? 0) as num).toInt(),
      date: orderDate is Timestamp ? orderDate.toDate() : DateTime.now(),
      customerPhone: (data['customer_phone'] ?? '') as String,
    );
  }
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
  List<OrderItem> _allOrders = [];
  List<OrderItem> _filteredOrders = [];

  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<QuerySnapshot>? _ordersSubscription;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _listenToOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _ordersSubscription?.cancel();
    super.dispose();
  }

  /// Subscribe realtime ke users/{uid}/orders di Firestore.
  /// Begitu CreateOrderScreen nulis dokumen baru, list ini
  /// otomatis ke-update tanpa perlu manual refresh.
  void _listenToOrders() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sesi tidak ditemukan, silakan login ulang.';
      });
      return;
    }

    final ordersRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .orderBy('order_date', descending: true);

    _ordersSubscription?.cancel();
    _ordersSubscription = ordersRef.snapshots().listen(
      (snapshot) {
        _allOrders = snapshot.docs.map((doc) => OrderItem.fromFirestore(doc)).toList();
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
        _applyFiltersAndSearch();
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
          _errorMessage = error.toString();
        });
      },
    );
  }

  /// Filter dan search orders
  void _applyFiltersAndSearch() {
    _filteredOrders = _allOrders.where((order) {
      bool statusMatch = _selectedFilter == 'all' || order.status == _selectedFilter;
      bool searchMatch = _searchController.text.isEmpty ||
          order.customerName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          order.orderNumber.toLowerCase().contains(_searchController.text.toLowerCase());
      return statusMatch && searchMatch;
    }).toList();
    setState(() {});
  }

  /// Buka Create Order screen. List sudah realtime lewat
  /// snapshots(), jadi begitu order baru tersimpan, dia
  /// otomatis muncul di sini tanpa perlu logic refresh manual.
  Future<void> _openCreateOrder(BuildContext context) async {
    await context.push<bool>('/orders/create');
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
                        _buildHeader(context, isMobile),
                        const SizedBox(height: 22),
                        _buildSearchBar(context),
                        const SizedBox(height: AppTheme.lg),
                        _buildFilterButtons(context),
                        const SizedBox(height: AppTheme.xl),
                        _buildStatsSummary(context, isMobile),
                        const SizedBox(height: AppTheme.xl),
                        if (_isLoading)
                          _buildLoadingState(context)
                        else if (_errorMessage != null)
                          _buildErrorState(context)
                        else if (_filteredOrders.isEmpty)
                          _buildEmptyState(context)
                        else
                          _buildOrdersList(context, isMobile),
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
  ///
  /// FIX overflow mobile: judul + subtitle sekarang dibungkus Expanded
  /// (sebelumnya nggak, jadi Row badge+judul+tombol "Baru" bisa lebih
  /// lebar dari layar HP -> overflow). Khusus mobile tombolnya diringkas
  /// jadi icon-only bulat, persis pola yang dipakai di CustomersListScreen.
  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pesanan',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Kelola semua pesanan laundry Anda',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppTheme.md),
        if (isMobile)
          _CompactAddButton(onTap: () => _openCreateOrder(context))
        else
          ElevatedButton.icon(
            onPressed: () => _openCreateOrder(context),
            icon: const Icon(Icons.note_add_outlined, size: 18),
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

  /// Build loading state
  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.xxl),
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.xxl),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: AppTheme.errorColor),
            const SizedBox(height: AppTheme.md),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: AppTheme.lg),
            TextButton(
              onPressed: _listenToOrders,
              child: Text('Coba lagi', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
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
              icon: const Icon(Icons.note_add_outlined, size: 18),
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
              onTap: () => context.push('/orders/${_filteredOrders[index].id}'),
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

/// Tombol "Baru" versi ringkas (icon-only, bulat) khusus mobile,
/// biar header nggak overflow saat layar sempit — sama pola dengan
/// _CompactAddButton di CustomersListScreen.
class _CompactAddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CompactAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primaryColor,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.note_add_outlined, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

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
                      order.orderNumber,
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
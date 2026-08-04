import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/themes/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Warna background warmer (cream), sama seperti customer_detail_screen
const Color _cSurface = Color(0xFFFBF9F8);

/// Model order history item
class _OrderHistoryItem {
  final String id;
  final String orderNumber;
  final String status;
  final double amount;
  final int itemCount;
  final DateTime date;

  _OrderHistoryItem({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.amount,
    required this.itemCount,
    required this.date,
  });

  factory _OrderHistoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final orderDate = data['order_date'];
    return _OrderHistoryItem(
      id: doc.id,
      orderNumber: (data['order_number'] ?? doc.id) as String,
      status: (data['status'] ?? 'pending') as String,
      amount: ((data['total_amount'] ?? 0) as num).toDouble(),
      itemCount: (data['total_items'] ?? 0) is int
          ? data['total_items'] as int
          : ((data['total_items'] ?? 0) as num).toInt(),
      date: orderDate is Timestamp ? orderDate.toDate() : DateTime.now(),
    );
  }
}

/// Customer Order History Screen - Tampilkan semua order dari customer tertentu
class CustomerOrderHistoryScreen extends StatefulWidget {
  final String customerId;

  const CustomerOrderHistoryScreen({
    Key? key,
    required this.customerId,
  }) : super(key: key);

  @override
  State<CustomerOrderHistoryScreen> createState() => _CustomerOrderHistoryScreenState();
}

class _CustomerOrderHistoryScreenState extends State<CustomerOrderHistoryScreen> {
  List<_OrderHistoryItem> _orders = [];
  bool _isLoading = true;
  String? _customerName;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrdersAndCustomerName();
  }

  /// Fetch customer name dan semua orders dari customer ini
  Future<void> _fetchOrdersAndCustomerName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'Sesi tidak ditemukan';
      }

      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Fetch customer name
      final customerDoc = await userDocRef.collection('customers').doc(widget.customerId).get();
      if (!customerDoc.exists) {
        throw 'Customer tidak ditemukan';
      }
      final customerData = customerDoc.data() as Map<String, dynamic>;
      final customerName = customerData['full_name'] ?? 'Customer';

      // Fetch all orders for this customer (filtered by customer_id field)
      final ordersSnap = await userDocRef
          .collection('orders')
          .where('customer_id', isEqualTo: widget.customerId)
          .orderBy('order_date', descending: true)
          .get();

      final orders = ordersSnap.docs.map((doc) => _OrderHistoryItem.fromFirestore(doc)).toList();

      setState(() {
        _customerName = customerName;
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

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

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _cSurface,
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
                        _buildTopBar(context, l10n),
                        const SizedBox(height: 22),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          )
                        else if (_errorMessage != null)
                          Center(
                            child: Text(_errorMessage ?? 'Error', style: GoogleFonts.poppins(color: Colors.red)),
                          )
                        else if (_orders.isEmpty)
                          _buildEmptyState(context, l10n)
                        else
                          _buildOrdersList(context, l10n),
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

  /// Build top bar
  Widget _buildTopBar(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(11),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppTheme.textPrimary),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Riwayat Pesanan',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _customerName ?? 'Customer',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build empty state
  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: AppTheme.lg),
            Text('Belum ada pesanan', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Pelanggan ini belum membuat pesanan', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  /// Build orders list
  Widget _buildOrdersList(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: List.generate(
        _orders.length,
        (index) => Column(
          children: [
            _OrderCard(
              order: _orders[index],
              statusColor: _getStatusColor(_orders[index].status),
              statusLabel: _getStatusLabel(_orders[index].status),
              formattedAmount: _formatCurrency(_orders[index].amount),
              formattedDate: _formatDate(_orders[index].date),
              onTap: () => context.push('/orders/${_orders[index].id}'),
            ),
            if (index < _orders.length - 1) const SizedBox(height: AppTheme.lg),
          ],
        ),
      ),
    );
  }
}

/// Order card component
class _OrderCard extends StatelessWidget {
  final _OrderHistoryItem order;
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
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDate,
                      style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
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
                    Icon(Icons.shopping_bag_outlined, size: 15, color: AppTheme.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      '${order.itemCount} item',
                      style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.textTertiary),
                    ),
                  ],
                ),
                Text(
                  formattedAmount,
                  style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
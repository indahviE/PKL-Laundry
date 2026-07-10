import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';

/// Order Detail Screen
class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoading = false;

  // Sample order data
  late final Map<String, dynamic> orderData = {
    'id': '#ORD-12345',
    'customerName': 'Budi Santoso',
    'customerPhone': '081234567890',
    'customerAddress': 'Jl. Merdeka No. 123, Jakarta Pusat',
    'status': 'processing',
    'date': DateTime.now(),
    'dueDate': DateTime.now().add(const Duration(days: 2)),
    'items': [
      {'name': 'Kemeja Putih', 'quantity': 3, 'price': 25000},
      {'name': 'Celana Panjang', 'quantity': 2, 'price': 30000},
    ],
    'subtotal': 155000.0,
    'tax': 15000.0,
    'total': 170000.0,
    'paymentMethod': 'Cash',
    'notes': 'Hati-hati dengan kancing dan jahitan',
    'timeline': [
      {'status': 'pending', 'label': 'Pesanan Dibuat', 'time': '10:00'},
      {'status': 'processing', 'label': 'Sedang Diproses', 'time': '11:30'},
      {'status': 'completed', 'label': 'Siap Diambil', 'time': null},
    ],
  };

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

  /// Handle update status
  Future<void> _handleUpdateStatus(String newStatus) async {
    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      // TODO: Update status ke backend

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status berhasil diubah menjadi $newStatus'),
            backgroundColor: const Color(0xFF51CF66),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengupdate status'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
              // Order Header
              _buildOrderHeader(context),

              const SizedBox(height: AppTheme.xxl),

              // Customer Info
              _buildCustomerInfo(context),

              const SizedBox(height: AppTheme.xxl),

              // Order Items
              _buildOrderItems(context),

              const SizedBox(height: AppTheme.xxl),

              // Timeline
              _buildTimeline(context),

              const SizedBox(height: AppTheme.xxl),

              // Price Summary
              _buildPriceSummary(context),

              const SizedBox(height: AppTheme.xxl),

              // Notes
              _buildNotes(context),

              const SizedBox(height: AppTheme.xxl),

              // Action Buttons
              _buildActionButtons(context),

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
      title: Text(
        'Detail Pesanan ${orderData['id']}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    );
  }

  /// Build order header
  Widget _buildOrderHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                orderData['id'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.sm),
              Text(
                _formatDate(orderData['date']),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.lg,
              vertical: AppTheme.md,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(orderData['status']).withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Text(
              _getStatusLabel(orderData['status']),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _getStatusColor(orderData['status']),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build customer info
  Widget _buildCustomerInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informasi Pelanggan',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppTheme.lg),
        Container(
          padding: const EdgeInsets.all(AppTheme.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Nama', orderData['customerName']),
              const Divider(height: AppTheme.xl),
              _buildInfoRow('Telepon', orderData['customerPhone']),
              const Divider(height: AppTheme.xl),
              _buildInfoRow('Alamat', orderData['customerAddress']),
            ],
          ),
        ),
      ],
    );
  }

  /// Build info row
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.gray600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.darkColor,
            ),
          ),
        ),
      ],
    );
  }

  /// Build order items
  Widget _buildOrderItems(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item Pesanan',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppTheme.lg),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: List.generate(
              (orderData['items'] as List).length,
              (index) {
                final item = orderData['items'][index];
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.lg),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppTheme.sm),
                              Text(
                                'Qty: ${item['quantity']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _formatCurrency(item['price'].toDouble()),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5DADE2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index < (orderData['items'] as List).length - 1)
                      Divider(
                        height: 0,
                        color: Colors.grey.shade200,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Build timeline
  Widget _buildTimeline(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Riwayat Status',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppTheme.lg),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: (orderData['timeline'] as List).length,
          itemBuilder: (context, index) {
            final item = orderData['timeline'][index];
            final isLast = index == (orderData['timeline'] as List).length - 1;

            return Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getStatusColor(item['status']).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item['status'] == 'pending'
                            ? Icons.schedule
                            : item['status'] == 'processing'
                                ? Icons.local_laundry_service
                                : Icons.check_circle,
                        color: _getStatusColor(item['status']),
                        size: 20,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 50,
                        color: Colors.grey.shade300,
                      ),
                  ],
                ),
                const SizedBox(width: AppTheme.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['label'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item['time'] != null)
                        Text(
                          item['time'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Build price summary
  Widget _buildPriceSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildPriceRow('Subtotal', orderData['subtotal']),
          const SizedBox(height: AppTheme.md),
          _buildPriceRow('Pajak', orderData['tax']),
          const Divider(height: AppTheme.xl),
          _buildPriceRow(
            'Total',
            orderData['total'],
            isBold: true,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  /// Build price row
  Widget _buildPriceRow(
    String label,
    double amount, {
    bool isBold = false,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          _formatCurrency(amount),
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            fontSize: isTotal ? 16 : 14,
            color: isTotal ? const Color(0xFF5DADE2) : AppTheme.darkColor,
          ),
        ),
      ],
    );
  }

  /// Build notes
  Widget _buildNotes(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catatan',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppTheme.lg),
        Container(
          padding: const EdgeInsets.all(AppTheme.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            orderData['notes'],
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () => _handleUpdateStatus('completed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF51CF66),
              padding: const EdgeInsets.symmetric(vertical: AppTheme.lg),
            ),
            child: const Text(
              'Tandai Selesai',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.lg),
            ),
            child: const Text('Kembali'),
          ),
        ),
      ],
    );
  }
}
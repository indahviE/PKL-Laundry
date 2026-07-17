import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/themes/app_theme.dart';

/// Model item pesanan
class _OrderLineItem {
  final String name;
  final int quantity;
  final double price;

  _OrderLineItem({required this.name, required this.quantity, required this.price});

  factory _OrderLineItem.fromMap(Map<String, dynamic> map) {
    return _OrderLineItem(
      name: (map['service_name'] ?? '') as String,
      quantity: (map['quantity'] ?? 0) is int ? map['quantity'] as int : ((map['quantity'] ?? 0) as num).toInt(),
      price: ((map['price_per_unit'] ?? 0) as num).toDouble(),
    );
  }
}

/// Model 1 entri di riwayat status
class _StatusHistoryEntry {
  final String status;
  final DateTime? timestamp;
  final String note;

  _StatusHistoryEntry({required this.status, required this.timestamp, required this.note});

  factory _StatusHistoryEntry.fromMap(Map<String, dynamic> map) {
    final ts = map['timestamp'];
    return _StatusHistoryEntry(
      status: (map['status'] ?? '') as String,
      timestamp: ts is Timestamp ? ts.toDate() : null,
      note: (map['note'] ?? '') as String,
    );
  }
}

/// Model data order lengkap untuk halaman detail, di-fetch dari
/// users/{uid}/orders/{orderId}
class _OrderDetailData {
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String status;
  final DateTime orderDate;
  final List<_OrderLineItem> items;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final String paymentMethod;
  final String notes;
  final List<_StatusHistoryEntry> statusHistory;

  _OrderDetailData({
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.status,
    required this.orderDate,
    required this.items,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.notes,
    required this.statusHistory,
  });

  factory _OrderDetailData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final orderDate = data['order_date'];
    final rawItems = (data['items'] as List?) ?? [];
    final rawHistory = (data['status_history'] as List?) ?? [];

    return _OrderDetailData(
      orderNumber: (data['order_number'] ?? doc.id) as String,
      customerName: (data['customer_name'] ?? '') as String,
      customerPhone: (data['customer_phone'] ?? '') as String,
      status: (data['status'] ?? 'pending') as String,
      orderDate: orderDate is Timestamp ? orderDate.toDate() : DateTime.now(),
      items: rawItems.map((e) => _OrderLineItem.fromMap(Map<String, dynamic>.from(e))).toList(),
      subtotal: ((data['subtotal'] ?? 0) as num).toDouble(),
      taxAmount: ((data['tax_amount'] ?? 0) as num).toDouble(),
      totalAmount: ((data['total_amount'] ?? 0) as num).toDouble(),
      paymentMethod: (data['payment_method'] ?? 'cash') as String,
      notes: (data['notes'] ?? '') as String,
      statusHistory: rawHistory.map((e) => _StatusHistoryEntry.fromMap(Map<String, dynamic>.from(e))).toList(),
    );
  }
}

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
  bool _isLoading = true;
  bool _isUpdatingStatus = false;
  String? _errorMessage;
  _OrderDetailData? _order;

  @override
  void initState() {
    super.initState();
    _fetchOrder();
  }

  CollectionReference get _ordersRef {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw 'Sesi tidak ditemukan, silakan login ulang.';
    }
    return FirebaseFirestore.instance.collection('users').doc(user.uid).collection('orders');
  }

  Future<void> _fetchOrder() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final doc = await _ordersRef.doc(widget.orderId).get();
      if (!doc.exists) {
        throw 'Pesanan tidak ditemukan.';
      }
      setState(() {
        _order = _OrderDetailData.fromFirestore(doc);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
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

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Handle update status -> tulis ke Firestore: update field `status`,
  /// tambah entri baru ke `status_history`, dan set `actual_completion`
  /// begitu status jadi 'completed'.
  Future<void> _handleUpdateStatus(String newStatus, {String? note}) async {
    if (_order == null) return;

    setState(() => _isUpdatingStatus = true);

    try {
      final historyEntry = {
        'status': newStatus,
        'timestamp': Timestamp.now(),
        'note': note ?? 'Status diubah ke ${_getStatusLabel(newStatus)}',
      };

      final updateData = <String, dynamic>{
        'status': newStatus,
        'status_history': FieldValue.arrayUnion([historyEntry]),
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (newStatus == 'completed') {
        updateData['actual_completion'] = FieldValue.serverTimestamp();
      }

      await _ordersRef.doc(widget.orderId).update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status berhasil diubah menjadi ${_getStatusLabel(newStatus)}'),
            backgroundColor: const Color(0xFF51CF66),
          ),
        );
      }

      await _fetchOrder();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengupdate status: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  /// Normalize nomor telepon Indonesia ke format internasional tanpa
  /// simbol, mis. "081234567890" atau "0812-3456-7890" -> "6281234567890"
  String _normalizePhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    digits = digits.replaceAll('+', '');
    if (digits.startsWith('0')) {
      digits = '62${digits.substring(1)}';
    } else if (!digits.startsWith('62')) {
      digits = '62$digits';
    }
    return digits;
  }

  /// Buka WhatsApp ke nomor customer, isi pesan otomatis
  /// bahwa pesanannya sudah selesai dan siap diambil/diantar.
  Future<void> _openWhatsapp(_OrderDetailData order) async {
    if (order.customerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nomor telepon pelanggan tidak tersedia', style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final normalized = _normalizePhone(order.customerPhone);
    final message = 'Halo kak ${order.customerName}!, ini Mintwash 😊 . '
        'Pesanan kamu (${order.orderNumber}) sudah selesai dan siap. '
        'Mau diantar ke alamat atau mau diambil sendiri ya?';

    final uri = Uri.https('wa.me', '/$normalized', {'text': message});
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak bisa membuka WhatsApp', style: GoogleFonts.poppins())),
      );
    }
  }

  void _confirmCancelOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text(
          'Batalkan Pesanan?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        content: Text(
          'Tindakan ini akan mengubah status pesanan menjadi Dibatalkan.',
          style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tidak', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleUpdateStatus('cancelled', note: 'Pesanan dibatalkan');
            },
            child: Text(
              'Ya, Batalkan',
              style: GoogleFonts.poppins(color: AppTheme.errorColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
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
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 16 : 24,
                      isMobile ? 16 : 24,
                      isMobile ? 16 : 24,
                      24,
                    ),
                    child: _isLoading
                        ? _buildLoadingState(context)
                        : _errorMessage != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTopBar(context),
                                  const SizedBox(height: AppTheme.xxl),
                                  _buildErrorState(context),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTopBar(context),
                                  const SizedBox(height: AppTheme.xl),
                                  _buildOrderHeader(context, _order!),
                                  const SizedBox(height: AppTheme.xxl),
                                  _buildCustomerInfo(context, _order!),
                                  const SizedBox(height: AppTheme.xxl),
                                  _buildOrderItems(context, _order!),
                                  const SizedBox(height: AppTheme.xxl),
                                  _buildTimeline(context, _order!),
                                  const SizedBox(height: AppTheme.xxl),
                                  _buildPriceSummary(context, _order!),
                                  const SizedBox(height: AppTheme.xxl),
                                  _buildNotes(context, _order!),
                                  const SizedBox(height: AppTheme.xxl),
                                  _buildActionButtons(context, _order!),
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

  /// Build top bar (back button + title), gaya sama dengan CreateOrderScreen
  Widget _buildTopBar(BuildContext context) {
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
          child: Text(
            _order != null ? 'Detail Pesanan ${_order!.orderNumber}' : 'Detail Pesanan',
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(context),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.xxl),
          child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              onPressed: _fetchOrder,
              child: Text('Coba lagi', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  /// Build order header
  Widget _buildOrderHeader(BuildContext context, _OrderDetailData order) {
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.orderNumber,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.sm),
              Text(
                _formatDate(order.orderDate),
                style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.lg,
              vertical: AppTheme.md,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(order.status).withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Text(
              _getStatusLabel(order.status),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _getStatusColor(order.status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build customer info
  Widget _buildCustomerInfo(BuildContext context, _OrderDetailData order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informasi Pelanggan',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.lg),
        Container(
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
              _buildInfoRow('Nama', order.customerName),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
                child: Divider(height: 1, color: AppTheme.borderColor.withOpacity(0.6)),
              ),
              _buildInfoRow('Telepon', order.customerPhone),
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
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  /// Build order items
  Widget _buildOrderItems(BuildContext context, _OrderDetailData order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item Pesanan',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.lg),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.lg),
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
            children: List.generate(
              order.items.length,
              (index) {
                final item = order.items[index];
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.lg),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Qty: ${item.quantity}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppTheme.sm),
                          Text(
                            _formatCurrency(item.price),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index < order.items.length - 1)
                      Divider(height: 1, color: AppTheme.borderColor.withOpacity(0.6)),
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
  Widget _buildTimeline(BuildContext context, _OrderDetailData order) {
    if (order.statusHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Riwayat Status',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.lg),
        Container(
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
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.statusHistory.length,
            itemBuilder: (context, index) {
              final item = order.statusHistory[index];
              final isLast = index == order.statusHistory.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _getStatusColor(item.status).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.status == 'pending'
                              ? Icons.schedule
                              : item.status == 'processing'
                                  ? Icons.local_laundry_service
                                  : item.status == 'cancelled'
                                      ? Icons.cancel
                                      : Icons.check_circle,
                          color: _getStatusColor(item.status),
                          size: 18,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 46,
                          color: AppTheme.borderColor,
                        ),
                    ],
                  ),
                  const SizedBox(width: AppTheme.lg),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.note.isNotEmpty ? item.note : _getStatusLabel(item.status),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (item.timestamp != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${_formatDate(item.timestamp!)} ${_formatTime(item.timestamp)}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppTheme.textTertiary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build price summary
  Widget _buildPriceSummary(BuildContext context, _OrderDetailData order) {
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
          Text(
            'Ringkasan Harga',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.lg),
          _buildPriceRow('Subtotal', order.subtotal),
          const SizedBox(height: AppTheme.md),
          _buildPriceRow('Pajak', order.taxAmount),
          const SizedBox(height: AppTheme.md),
          Divider(color: AppTheme.borderColor),
          const SizedBox(height: AppTheme.md),
          _buildPriceRow(
            'Total',
            order.totalAmount,
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
          style: GoogleFonts.poppins(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            fontSize: isTotal ? 14.5 : 12.5,
            color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
        Text(
          _formatCurrency(amount),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: isTotal ? 19 : 12.5,
            color: isTotal ? AppTheme.primaryColor : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Build notes
  Widget _buildNotes(BuildContext context, _OrderDetailData order) {
    if (order.notes.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catatan',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.lg),
        Container(
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
          child: Text(
            order.notes,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  /// Build action buttons — dinamis sesuai status pesanan sekarang.
  /// pending -> "Mulai Proses"; processing -> "Tandai Selesai";
  /// completed/cancelled -> tidak ada aksi ubah status lagi.
  Widget _buildActionButtons(BuildContext context, _OrderDetailData order) {
    final canCancel = order.status == 'pending' || order.status == 'processing';

    return Column(
      children: [
        // Begitu pesanan ditandai selesai, munculin tombol khusus buat
        // langsung chat customer via WhatsApp (nomornya diambil dari
        // order.customerPhone, sudah dinormalisasi ke format 62xxx).
        if (order.status == 'completed')
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.md),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _openWhatsapp(order),
                icon: const Icon(Icons.chat_outlined, size: 18),
                label: Text(
                  'Kabari via WhatsApp',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF51CF66),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                ),
              ),
            ),
          ),
        if (order.status == 'pending')
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isUpdatingStatus
                  ? null
                  : () => _handleUpdateStatus('processing', note: 'Mulai diproses'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5DADE2),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
              ),
              child: _isUpdatingStatus
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Mulai Proses',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
            ),
          ),
        if (order.status == 'processing')
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isUpdatingStatus
                  ? null
                  : () => _handleUpdateStatus('completed', note: 'Pesanan selesai'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF51CF66),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
              ),
              child: _isUpdatingStatus
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Tandai Selesai',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
            ),
          ),
        if (canCancel) ...[
          const SizedBox(height: AppTheme.md),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: _isUpdatingStatus ? null : _confirmCancelOrder,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
                side: BorderSide(color: AppTheme.errorColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
              ),
              child: Text(
                'Batalkan Pesanan',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ],
        const SizedBox(height: AppTheme.md),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: _isUpdatingStatus ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              side: BorderSide(color: AppTheme.borderColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
            ),
            child: Text(
              'Kembali',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
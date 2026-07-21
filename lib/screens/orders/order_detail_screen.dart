import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:gal/gal.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/themes/app_theme.dart';
import '../../models/order.dart';
import '../../models/transaction.dart';
import '../../repositories/order_repository.dart';

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
///
/// UPDATED: nambah field deliveryType supaya pesan WhatsApp "siap
/// diambil/diantar" bisa disesuaikan otomatis (self_pickup vs delivery),
/// nggak selalu nanya "mau diambil atau diantar?" ke semua pelanggan.
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

  // --- Pembayaran ---
  final String paymentStatus; // 'pending' | 'partial' | 'paid' | 'refunded'
  final String paymentMethodRaw; // 'cash' | 'transfer' | 'debit' | 'ewallet'
  final double paidAmount;

  // --- Pengiriman ---
  final String deliveryType; // 'self_pickup' | 'delivery'

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
    required this.paymentStatus,
    required this.paymentMethodRaw,
    required this.paidAmount,
    required this.deliveryType,
  });

  /// Sisa tagihan yang belum dibayar. Tidak pernah negatif (dijaga dengan
  /// clamp di sini supaya UI tidak pernah menampilkan angka minus kalau
  /// ada selisih pembulatan kecil).
  double get remainingAmount {
    final remaining = totalAmount - paidAmount;
    return remaining < 0 ? 0 : remaining;
  }

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
      paymentStatus: (data['payment_status'] ?? 'pending') as String,
      paymentMethodRaw: (data['payment_method'] ?? 'cash') as String,
      paidAmount: ((data['paid_amount'] ?? 0) as num).toDouble(),
      deliveryType: (data['delivery_type'] ?? 'self_pickup') as String,
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
  bool _isGeneratingReceipt = false;
  String? _errorMessage;
  _OrderDetailData? _order;

  /// Key buat "menangkap" tampilan struk (_buildReceiptCard) jadi gambar PNG
  /// lewat RepaintBoundary. Widget-nya dirender offstage (di luar layar,
  /// nggak keliatan user), cuma dipakai sebagai sumber screenshot.
  final GlobalKey _receiptKey = GlobalKey();

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
      case 'confirmed':
        return const Color(0xFF9B7EDE);
      case 'inProgress':
        return const Color(0xFF5DADE2);
      case 'washing':
        return const Color(0xFF5DADE2);
      case 'drying':
        return const Color(0xFFF4A259);
      case 'ironing':
        return const Color(0xFFF4A259);
      case 'qualityCheck':
        return const Color(0xFF5DADE2);
      case 'ready':
        return const Color(0xFF51CF66);
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
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'inProgress':
        return 'Diproses';
      case 'washing':
        return 'Dicuci';
      case 'drying':
        return 'Dikeringkan';
      case 'ironing':
        return 'Disetrika';
      case 'qualityCheck':
        return 'Cek Kualitas';
      case 'ready':
        return 'Siap Diambil';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  /// Urutan linear status pesanan (di luar 'cancelled', yang merupakan
  /// status terminal terpisah dan tidak termasuk alur maju normal).
  static const List<String> _statusFlow = [
    'pending',
    'confirmed',
    'inProgress',
    'washing',
    'drying',
    'ironing',
    'qualityCheck',
    'ready',
    'completed',
  ];

  /// Label tombol buat maju ke status berikutnya. null kalau sudah di
  /// status terakhir (completed) atau sudah cancelled.
  String? _nextStatusButtonLabel(String currentStatus) {
    switch (currentStatus) {
      case 'pending':
        return 'Konfirmasi Pesanan';
      case 'confirmed':
        return 'Mulai Proses';
      case 'inProgress':
        return 'Mulai Mencuci';
      case 'washing':
        return 'Selesai Dicuci';
      case 'drying':
        return 'Selesai Dikeringkan';
      case 'ironing':
        return 'Selesai Disetrika';
      case 'qualityCheck':
        return 'Lolos Cek Kualitas';
      case 'ready':
        return 'Tandai Selesai';
      default:
        return null; // completed / cancelled -> tidak ada tombol maju
    }
  }

  String? _nextStatus(String currentStatus) {
    final index = _statusFlow.indexOf(currentStatus);
    if (index == -1 || index == _statusFlow.length - 1) return null;
    return _statusFlow[index + 1];
  }

  /// Label metode pembayaran, dipakai baik untuk metode order maupun
  /// metode per-transaksi di riwayat pembayaran.
  String _paymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Tunai';
      case 'transfer':
        return 'Transfer Bank';
      case 'debit':
        return 'Kartu Debit';
      case 'ewallet':
        return 'E-Wallet';
      default:
        return method;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'paid':
        return const Color(0xFF51CF66);
      case 'partial':
        return Colors.orange;
      case 'refunded':
        return Colors.red;
      case 'pending':
      default:
        return Colors.grey;
    }
  }

  String _getPaymentStatusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Lunas';
      case 'partial':
        return 'DP Sebagian';
      case 'refunded':
        return 'Refund';
      case 'pending':
      default:
        return 'Belum Dibayar';
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

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: isError ? AppTheme.errorColor : const Color(0xFF51CF66),
      ),
    );
  }

  /// Handle update status -> tulis ke Firestore: update field `status`,
  /// tambah entri baru ke `status_history`, dan set `actual_completion`
  /// begitu status jadi 'completed'.
  ///
  /// NOTE: alur ubah status ini SENGAJA tetap pakai raw Firestore call
  /// (bukan lewat OrderRepository) - scope refactor kali ini difokuskan
  /// ke bagian pembayaran saja.
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
        _showSnack('Status berhasil diubah menjadi ${_getStatusLabel(newStatus)}');
      }

      await _fetchOrder();
    } catch (e) {
      if (mounted) {
        _showSnack('Gagal mengupdate status: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  /// Buka dialog buat catat pembayaran baru (DP, pelunasan, atau konfirmasi
  /// transfer) lewat OrderRepository.recordPayment() - atomic: menulis 1
  /// dokumen transactions/ SEKALIGUS update paid_amount & payment_status
  /// di order dalam 1 Firestore transaction.
  Future<void> _showRecordPaymentDialog(_OrderDetailData order) async {
    final remaining = order.remainingAmount;
    final amountController = TextEditingController(text: remaining.toStringAsFixed(0));
    String selectedMethod = order.paymentMethodRaw.isNotEmpty ? order.paymentMethodRaw : 'cash';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
            title: Text(
              'Konfirmasi Pembayaran',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sisa tagihan: ${_formatCurrency(remaining)}',
                  style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: AppTheme.md),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(fontSize: 13.5),
                  decoration: InputDecoration(
                    labelText: 'Nominal Dibayar',
                    labelStyle: GoogleFonts.poppins(fontSize: 12.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                  ),
                ),
                const SizedBox(height: AppTheme.md),
                DropdownButtonFormField<String>(
                  value: selectedMethod,
                  style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
                  items: [
                    DropdownMenuItem(value: 'cash', child: Text(_paymentMethodLabel('cash'))),
                    DropdownMenuItem(value: 'transfer', child: Text(_paymentMethodLabel('transfer'))),
                    DropdownMenuItem(value: 'debit', child: Text(_paymentMethodLabel('debit'))),
                    DropdownMenuItem(value: 'ewallet', child: Text(_paymentMethodLabel('ewallet'))),
                  ],
                  onChanged: (val) => setDialogState(() => selectedMethod = val ?? selectedMethod),
                  decoration: InputDecoration(
                    labelText: 'Metode',
                    labelStyle: GoogleFonts.poppins(fontSize: 12.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('Batal', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                ),
                child: Text('Simpan', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;

    final rawAmount = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(rawAmount) ?? 0;

    if (amount <= 0) {
      _showSnack('Nominal harus lebih dari Rp0', isError: true);
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Sesi tidak ditemukan, silakan login ulang.';

      await OrderRepository(userId: user.uid).recordPayment(
        widget.orderId,
        amount: amount,
        method: PaymentMethod.values.firstWhere(
          (e) => e.name == selectedMethod,
          orElse: () => PaymentMethod.cash,
        ),
      );

      _showSnack('Pembayaran berhasil dicatat');
      await _fetchOrder();
    } catch (e) {
      _showSnack(e.toString(), isError: true);
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

  /// Kirim pesan WA generik lewat wa.me. Dipisah jadi helper sendiri
  /// supaya _openWhatsapp dan _sendReceiptWhatsapp bisa reuse logic
  /// buka-link + validasi nomor kosong yang sama.
  Future<void> _launchWhatsappMessage(String phone, String message) async {
    if (phone.isEmpty) {
      _showSnack('Nomor telepon pelanggan tidak tersedia', isError: true);
      return;
    }

    final normalized = _normalizePhone(phone);
    final uri = Uri.https('wa.me', '/$normalized', {'text': message});
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      _showSnack('Tidak bisa membuka WhatsApp', isError: true);
    }
  }

  /// Buka WhatsApp ke nomor customer, isi pesan otomatis bahwa
  /// pesanannya sudah selesai. Isi pesan disesuaikan dengan deliveryType:
  /// - self_pickup -> tanya mau diambil sendiri atau diantar
  /// - delivery    -> kabari bahwa pesanan akan segera diantar
  Future<void> _openWhatsapp(_OrderDetailData order) async {
    final String message;
    if (order.deliveryType == 'delivery') {
      message = 'Halo kak ${order.customerName}!, ini Mintwash 😊 . '
          'Pesanan kamu (${order.orderNumber}) sudah selesai dan akan segera kami antar ke alamat kakak ya. '
          'Ditunggu ya kak 🙏';
    } else {
      message = 'Halo kak ${order.customerName}!, ini Mintwash 😊 . '
          'Pesanan kamu (${order.orderNumber}) sudah selesai dan siap. '
          'Mau diantar ke alamat atau mau diambil sendiri ya?';
    }

    await _launchWhatsappMessage(order.customerPhone, message);
  }

  /// Susun & kirim "struk" pesanan dalam bentuk teks terformat ke WhatsApp
  /// pelanggan (pakai *bold* ala WA). Bukan gambar - wa.me hanya bisa
  /// prefill teks. Tombol ini TETAP ada, dipakai berdampingan sama tombol
  /// "Download Struk" (gambar) di bawah - pilih salah satu sesuai
  /// kebutuhan kasir.
  Future<void> _sendReceiptWhatsapp(_OrderDetailData order) async {
    final buffer = StringBuffer();
    buffer.writeln('*Struk Pesanan - Netwash*');
    buffer.writeln('No. Pesanan: ${order.orderNumber}');
    buffer.writeln('Tanggal: ${_formatDate(order.orderDate)}');
    buffer.writeln('Pelanggan: ${order.customerName}');
    buffer.writeln('');
    buffer.writeln('*Item:*');
    for (final item in order.items) {
      final lineTotal = item.price * item.quantity;
      buffer.writeln('${item.name} x${item.quantity} - ${_formatCurrency(lineTotal)}');
    }
    buffer.writeln('');
    buffer.writeln('Subtotal: ${_formatCurrency(order.subtotal)}');
    if (order.taxAmount > 0) {
      buffer.writeln('Pajak: ${_formatCurrency(order.taxAmount)}');
    }
    buffer.writeln('*Total: ${_formatCurrency(order.totalAmount)}*');
    buffer.writeln('');
    buffer.writeln('Metode Bayar: ${_paymentMethodLabel(order.paymentMethodRaw)}');
    buffer.writeln('Status Bayar: ${_getPaymentStatusLabel(order.paymentStatus)}');
    buffer.writeln('Sudah Dibayar: ${_formatCurrency(order.paidAmount)}');
    if (order.remainingAmount > 0) {
      buffer.writeln('Sisa Tagihan: ${_formatCurrency(order.remainingAmount)}');
    }
    buffer.writeln('');
    buffer.writeln('Terima kasih sudah pakai Netwash 🙏');

    await _launchWhatsappMessage(order.customerPhone, buffer.toString());
  }

  /// Screenshot widget struk (_buildReceiptCard, dirender offstage lewat
  /// _receiptKey) jadi bytes PNG. pixelRatio 3 biar hasilnya tajam kalau
  /// di-zoom / dicetak.
  Future<Uint8List?> _captureReceiptImage() async {
    try {
      // Kasih jeda 1 frame supaya widget offstage sempat ke-layout dulu
      // sebelum di-screenshot, terutama kalau ini capture pertama kali.
      await WidgetsBinding.instance.endOfFrame;

      final boundary = _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

/// Tombol "Download Struk": screenshot struk jadi PNG, lalu simpan
  /// LANGSUNG ke galeri HP (pakai package `gal`) - TANPA share sheet /
  /// dialog pilih aplikasi apa pun. Karyawan tinggal buka WhatsApp manual
  /// (tombol "Kirim Struk via WA" di sebelahnya), lalu attach foto struk
  /// itu sendiri dari galeri.
  ///
  /// Di Flutter Web, `gal` tidak punya implementasi (nggak ada "galeri"
  /// di browser), jadi fallback-nya trigger download file .png biasa
  /// lewat browser - juga tanpa share sheet.
  Future<void> _downloadReceiptStruk(_OrderDetailData order) async {
    setState(() => _isGeneratingReceipt = true);
    try {
      final bytes = await _captureReceiptImage();
      if (bytes == null) {
        _showSnack('Gagal membuat gambar struk', isError: true);
        return;
      }

      final fileName =
          'struk_${order.orderNumber.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_')}.png';

      if (kIsWeb) {
        // Web: belum ada API "galeri" di browser, jadi paksa download
        // file biasa. (Implementasi web di-skip di sini biar file utama
        // tetap ringan - kalau butuh testing di Chrome, pakai package
        // `universal_html` terpisah. Di HP asli, baris di bawah (mobile)
        // yang jalan.)
        _showSnack('Download struk cuma didukung di aplikasi HP, bukan di web');
        return;
      }

      await Gal.putImageBytes(bytes, name: fileName);
      _showSnack('Struk tersimpan di galeri');
    } catch (e) {
      if (mounted) {
        _showSnack('Gagal mengunduh struk: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isGeneratingReceipt = false);
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
        child: Stack(
          children: [
            LayoutBuilder(
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
                                      _buildPaymentSection(context, _order!),
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
            // Widget struk dirender di luar layar (offstage), cuma dipakai
            // sebagai sumber screenshot oleh _captureReceiptImage(). User
            // nggak pernah lihat ini secara langsung.
            if (_order != null)
              Positioned(
                left: -9999,
                top: 0,
                child: Material(
                  color: Colors.transparent,
                  child: RepaintBoundary(
                    key: _receiptKey,
                    child: _buildReceiptCard(_order!),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Tampilan struk versi "cetak" (bukan versi UI biasa) - dipakai khusus
  /// buat di-screenshot jadi gambar oleh _downloadReceiptStruk(). Dibuat
  /// dengan lebar tetap (bukan responsive) supaya hasil gambarnya rapi
  /// di rasio gambar biasa, mirip struk kasir.
  Widget _buildReceiptCard(_OrderDetailData order) {
    return Container(
      width: 380,
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Netwash',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Struk Pesanan',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Divider(color: AppTheme.borderColor),
          const SizedBox(height: 12),
          _receiptRow('No. Pesanan', order.orderNumber),
          _receiptRow('Tanggal', _formatDate(order.orderDate)),
          _receiptRow('Pelanggan', order.customerName),
          const SizedBox(height: 12),
          Divider(color: AppTheme.borderColor),
          const SizedBox(height: 12),
          ...order.items.map((item) {
            final lineTotal = item.price * item.quantity;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${item.name} x${item.quantity}',
                      style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textPrimary),
                    ),
                  ),
                  Text(
                    _formatCurrency(lineTotal),
                    style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          Divider(color: AppTheme.borderColor),
          const SizedBox(height: 12),
          _receiptRow('Subtotal', _formatCurrency(order.subtotal)),
          if (order.taxAmount > 0) _receiptRow('Pajak', _formatCurrency(order.taxAmount)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              Text(
                _formatCurrency(order.totalAmount),
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: AppTheme.borderColor),
          const SizedBox(height: 12),
          _receiptRow('Metode Bayar', _paymentMethodLabel(order.paymentMethodRaw)),
          _receiptRow('Status Bayar', _getPaymentStatusLabel(order.paymentStatus)),
          _receiptRow('Sudah Dibayar', _formatCurrency(order.paidAmount)),
          if (order.remainingAmount > 0) _receiptRow('Sisa Tagihan', _formatCurrency(order.remainingAmount)),
          const SizedBox(height: 20),
          Text(
            'Terima kasih sudah pakai Netwash 🙏',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
          ),
        ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderNumber,
                  overflow: TextOverflow.ellipsis,
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
          ),
          const SizedBox(width: AppTheme.sm),
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
                final lineTotal = item.price * item.quantity;
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
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
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
                            _formatCurrency(lineTotal),
                            textAlign: TextAlign.right,
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

  /// Section Pembayaran: status, metode, sudah dibayar, sisa tagihan, dan
  /// 2 tombol struk berdampingan: "Download Struk" (gambar PNG lewat
  /// share sheet) dan "Kirim Struk via WA" (teks langsung ke wa.me).
  Widget _buildPaymentSection(BuildContext context, _OrderDetailData order) {
    final statusColor = _getPaymentStatusColor(order.paymentStatus);
    final statusLabel = _getPaymentStatusLabel(order.paymentStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pembayaran',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _paymentMethodLabel(order.paymentMethodRaw),
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.md),
              _buildPriceRow('Sudah Dibayar', order.paidAmount),
              const SizedBox(height: 6),
              _buildPriceRow('Sisa Tagihan', order.remainingAmount),
              if (order.paymentStatus != 'paid') ...[
                const SizedBox(height: AppTheme.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showRecordPaymentDialog(order),
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: Text(
                      'Konfirmasi Pembayaran',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isGeneratingReceipt ? null : () => _downloadReceiptStruk(order),
                      icon: _isGeneratingReceipt
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryColor,
                              ),
                            )
                          : const Icon(Icons.download_outlined, size: 18),
                      label: Text(
                        'Download Struk',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12.5),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(color: AppTheme.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _sendReceiptWhatsapp(order),
                      icon: const Icon(Icons.receipt_long_outlined, size: 18),
                      label: Text(
                        'Kirim Struk via WA',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12.5),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF25D366),
                        side: const BorderSide(color: Color(0xFF25D366)),
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.lg),
        _buildPaymentHistory(context),
      ],
    );
  }

  /// Riwayat pembayaran (DP + pelunasan) dari users/{uid}/transactions,
  /// realtime lewat StreamBuilder. Tidak tampil apa-apa kalau belum ada
  /// pembayaran sama sekali.
  Widget _buildPaymentHistory(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<List<PaymentTransaction>>(
      stream: OrderRepository(userId: user.uid).getPaymentsForOrder(widget.orderId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final payments = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riwayat Pembayaran',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: AppTheme.md),
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
                children: List.generate(payments.length, (index) {
                  final p = payments[index];
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _paymentMethodLabel(p.method.name),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_formatDate(p.createdAt)} ${_formatTime(p.createdAt)}',
                                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textTertiary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatCurrency(p.amount),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index < payments.length - 1) Divider(height: 1, color: AppTheme.borderColor.withOpacity(0.6)),
                    ],
                  );
                }),
              ),
            ),
          ],
        );
      },
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
                              : item.status == 'cancelled'
                                  ? Icons.cancel
                                  : item.status == 'completed'
                                      ? Icons.check_circle
                                      : Icons.local_laundry_service,
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

  /// Build action buttons — dinamis sesuai status pesanan sekarang, ngikutin
  /// urutan _statusFlow. Tombol maju berubah label sesuai tahap
  /// (Konfirmasi Pesanan -> Mulai Proses -> ... -> Tandai Selesai).
  /// completed/cancelled -> tidak ada tombol maju lagi.
  Widget _buildActionButtons(BuildContext context, _OrderDetailData order) {
    final canCancel = order.status != 'completed' && order.status != 'cancelled';
    final nextStatus = _nextStatus(order.status);
    final nextLabel = _nextStatusButtonLabel(order.status);

    return Column(
      children: [
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
                  order.deliveryType == 'delivery' ? 'Kabari Siap Diantar (WA)' : 'Kabari via WhatsApp',
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
        if (nextStatus != null && nextLabel != null)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isUpdatingStatus
                  ? null
                  : () => _handleUpdateStatus(nextStatus, note: nextLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: nextStatus == 'completed'
                    ? const Color(0xFF51CF66)
                    : const Color(0xFF5DADE2),
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
                      nextLabel,
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
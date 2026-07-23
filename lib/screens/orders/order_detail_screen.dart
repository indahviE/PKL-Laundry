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

// ============================================
// DESIGN TOKENS (dari DESIGN.md / code.html referensi "Order Detail -
// NetWash"). Di-hardcode di sini - sama pola dengan OrdersListScreen -
// biar layar ini presisi sama referensi desain, terlepas dari nilai
// AppTheme lama (yang sebelumnya dipakai screen ini, gaya Poppins/biru
// generik).
// ============================================
const Color _cSurface = Color(0xFFFBF9F8);
const Color _cSurfaceContainerLow = Color(0xFFF5F3F3);
const Color _cSurfaceContainer = Color(0xFFF0EDED);
const Color _cSurfaceContainerHighest = Color(0xFFE4E2E1);
const Color _cCard = Color(0xFFFFFFFF);
const Color _cOnSurface = Color(0xFF1B1C1C);
const Color _cOnSurfaceVariant = Color(0xFF404752);
const Color _cOutlineVariant = Color(0xFFBFC7D4);
const Color _cPrimary = Color(0xFF0061A4);
const Color _cPrimaryContainer = Color(0xFF2196F3);
const Color _cPrimaryFixed = Color(0xFFD1E4FF); // bg chip "estimasi"/ring aktif
const Color _cOnPrimaryFixedVariant = Color(0xFF00497D); // teks di atas primaryFixed
const Color _cSecondary = Color(0xFF5B5F61);
const Color _cSecondaryContainer = Color(0xFFE0E3E6);
const Color _cTertiaryFixed = Color(0xFFD6E5EF); // bg ikon cabang
const Color _cOnTertiaryFixed = Color(0xFF0F1D25);
const Color _cError = Color(0xFFBA1A1A);
const Color _cGreenBg = Color(0xFFDCFCE7);
const Color _cGreenText = Color(0xFF15803D);
const Color _cYellowBg = Color(0xFFFEF9C3);
const Color _cYellowText = Color(0xFFA16207);
const Color _cRedBg = Color(0xFFFEE2E2);
const Color _cRedText = Color(0xFFB91C1C);

// Radius token dari referensi (tailwind config): DEFAULT/lg = 16px,
// xl = 20px (dipakai untuk card & tombol besar), full = pill.
const double _rLg = 16;
const double _rXl = 20;

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
///
/// UPDATED lagi: nambah field laundryId - order sudah tersimpan dengan
/// cabang yang benar sejak CreateOrderScreen (lihat laundry_id di
/// dokumen Firestore), cuma sebelumnya gak pernah dibaca/ditampilkan di
/// halaman detail ini. Nama cabang (bukan cuma ID mentah) di-resolve
/// terpisah lewat _fetchLaundryName() setelah order berhasil dimuat.
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

  // --- Cabang ---
  final String laundryId; // bisa kosong buat order lama sebelum fitur cabang ada

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
    required this.laundryId,
  });

  /// Sisa tagihan yang belum dibayar. Tidak pernah negatif (dijaga dengan
  /// clamp di sini supaya UI tidak pernah menampilkan angka minus kalau
  /// ada selisih pembulatan kecil).
  double get remainingAmount {
    final remaining = totalAmount - paidAmount;
    return remaining < 0 ? 0 : remaining;
  }

  /// Total jumlah item (sum quantity semua baris), dipakai di kartu
  /// ringkasan "Jumlah Item" (bento grid), padanan "Total Berat" di
  /// referensi desain - proyek ini nggak nyimpen berat, jadi dipakai
  /// jumlah item sebagai gantinya.
  int get totalItemCount => items.fold<int>(0, (sum, i) => sum + i.quantity);

  /// Ringkasan nama layanan buat kartu "Layanan" - sama pola dengan
  /// OrdersListScreen.serviceSummary.
  String get serviceSummary {
    if (items.isEmpty) return '-';
    if (items.length == 1) return items.first.name;
    return '${items.first.name} +${items.length - 1} lainnya';
  }

  bool get isDelivery => deliveryType == 'delivery';
  String get deliveryTypeLabel => isDelivery ? 'Diantar' : 'Ambil Sendiri';
  IconData get deliveryTypeIcon => isDelivery ? Icons.local_shipping_outlined : Icons.storefront_outlined;

  /// Cari timestamp status tertentu dari riwayat (dipakai timeline).
  DateTime? timestampForStatus(String status) {
    for (final h in statusHistory) {
      if (h.status == status) return h.timestamp;
    }
    return null;
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
      laundryId: (data['laundry_id'] ?? '') as String,
    );
  }
}

/// Urutan linear status pesanan (di luar 'cancelled', yang merupakan
/// status terminal terpisah dan tidak termasuk alur maju normal).
/// Sama persis 9 tahapnya dengan "Lacak Progress" di referensi desain.
const List<String> _statusFlow = [
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

/// Ikon per tahap status, dipetakan sedekat mungkin ke ikon di referensi
/// desain (schedule, check_circle, sync, local_laundry_service, air,
/// checkroom, verified, local_shipping, task_alt).
IconData _iconForStatus(String status) {
  switch (status) {
    case 'pending':
      return Icons.schedule;
    case 'confirmed':
      return Icons.check_circle_outline;
    case 'inProgress':
      return Icons.sync;
    case 'washing':
      return Icons.local_laundry_service;
    case 'drying':
      return Icons.air;
    case 'ironing':
      return Icons.checkroom;
    case 'qualityCheck':
      return Icons.verified;
    case 'ready':
      return Icons.local_shipping_outlined;
    case 'completed':
      return Icons.task_alt;
    default:
      return Icons.circle;
  }
}

/// Catatan singkat buat tahap yang lagi AKTIF di timeline (pengganti
/// timestamp, sama seperti "Sedang dalam mesin cuci" di referensi).
String _activeStepNote(String status) {
  switch (status) {
    case 'pending':
      return 'Menunggu konfirmasi';
    case 'confirmed':
      return 'Pesanan sudah dikonfirmasi';
    case 'inProgress':
      return 'Sedang diproses';
    case 'washing':
      return 'Sedang dalam mesin cuci';
    case 'drying':
      return 'Sedang dikeringkan';
    case 'ironing':
      return 'Sedang disetrika';
    case 'qualityCheck':
      return 'Sedang dicek kualitasnya';
    case 'ready':
      return 'Siap diambil / diantar';
    case 'completed':
      return 'Pesanan sudah selesai';
    default:
      return '';
  }
}

/// Warna badge status pembayaran, dipetakan ke palet yang sama dengan
/// filter status di OrdersListScreen (kuning/hijau/merah).
Color _paymentBg(String status) {
  switch (status) {
    case 'paid':
      return _cGreenBg;
    case 'partial':
      return _cYellowBg;
    case 'refunded':
      return _cRedBg;
    default:
      return _cSurfaceContainerHighest;
  }
}

Color _paymentFg(String status) {
  switch (status) {
    case 'paid':
      return _cGreenText;
    case 'partial':
      return _cYellowText;
    case 'refunded':
      return _cRedText;
    default:
      return _cOnSurfaceVariant;
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

  // Nama cabang (resolved dari laundryId) - null selama masih loading
  // atau kalau order.laundryId kosong (order lama sebelum fitur cabang).
  String? _laundryName;
  bool _isLoadingLaundryName = false;

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
      final order = _OrderDetailData.fromFirestore(doc);
      setState(() {
        _order = order;
        _isLoading = false;
      });
      // Resolve nama cabang setelah order utama selesai dimuat - gak
      // memblokir tampilan utama, cukup nongol belakangan begitu siap.
      if (order.laundryId.isNotEmpty) {
        _fetchLaundryName(order.laundryId);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Ambil nama cabang dari users/{uid}/laundries/{laundryId}, dipanggil
  /// setelah order berhasil dimuat. Kegagalan di sini bukan error fatal -
  /// halaman detail order tetap tampil normal, cuma info cabangnya gak
  /// muncul (fallback ke null, ditangani di UI).
  Future<void> _fetchLaundryName(String laundryId) async {
    setState(() => _isLoadingLaundryName = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('laundries')
          .doc(laundryId)
          .get();

      if (!mounted) return;
      setState(() {
        _laundryName = doc.exists ? ((doc.data()?['name'] ?? '') as String) : null;
        _isLoadingLaundryName = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingLaundryName = false);
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
        return 'Washing (Pencucian)';
      case 'drying':
        return 'Drying (Pengeringan)';
      case 'ironing':
        return 'Ironing (Penyetrikaan)';
      case 'qualityCheck':
        return 'Quality Check';
      case 'ready':
        return 'Siap Diambil/Kirim';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  /// Warna aksen buat status pesanan sekarang - primary di sepanjang alur
  /// normal, hijau kalau completed, merah kalau cancelled. Dipakai di
  /// kartu status & dot indikator.
  Color _statusAccentColor(String status) {
    if (status == 'cancelled') return _cError;
    if (status == 'completed') return _cGreenText;
    return _cPrimary;
  }

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
        content: Text(message, style: GoogleFonts.beVietnamPro()),
        backgroundColor: isError ? _cError : _cGreenText,
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_rLg)),
            title: Text(
              'Konfirmasi Pembayaran',
              style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, color: _cOnSurface),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sisa tagihan: ${_formatCurrency(remaining)}',
                  style: GoogleFonts.beVietnamPro(fontSize: 12.5, color: _cOnSurfaceVariant),
                ),
                const SizedBox(height: AppTheme.md),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.beVietnamPro(fontSize: 13.5),
                  decoration: InputDecoration(
                    labelText: 'Nominal Dibayar',
                    labelStyle: GoogleFonts.beVietnamPro(fontSize: 12.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: AppTheme.md),
                DropdownButtonFormField<String>(
                  value: selectedMethod,
                  style: GoogleFonts.beVietnamPro(fontSize: 13.5, color: _cOnSurface),
                  items: [
                    DropdownMenuItem(value: 'cash', child: Text(_paymentMethodLabel('cash'))),
                    DropdownMenuItem(value: 'transfer', child: Text(_paymentMethodLabel('transfer'))),
                    DropdownMenuItem(value: 'debit', child: Text(_paymentMethodLabel('debit'))),
                    DropdownMenuItem(value: 'ewallet', child: Text(_paymentMethodLabel('ewallet'))),
                  ],
                  onChanged: (val) => setDialogState(() => selectedMethod = val ?? selectedMethod),
                  decoration: InputDecoration(
                    labelText: 'Metode',
                    labelStyle: GoogleFonts.beVietnamPro(fontSize: 12.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('Batal', style: GoogleFonts.beVietnamPro(color: _cOnSurfaceVariant)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cPrimaryContainer,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Simpan', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700)),
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
  /// supaya beberapa aksi WhatsApp lain bisa reuse logic buka-link +
  /// validasi nomor kosong yang sama.
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
      message = 'Halo kak ${order.customerName}!, ini Netwash 😊 . '
          'Pesanan kamu (${order.orderNumber}) sudah selesai dan akan segera kami antar ke alamat kakak ya. '
          'Ditunggu ya kak 🙏';
    } else {
      message = 'Halo kak ${order.customerName}!, ini Netwash 😊 . '
          'Pesanan kamu (${order.orderNumber}) sudah selesai dan siap. '
          'Mau diantar ke alamat atau mau diambil sendiri ya?';
    }

    await _launchWhatsappMessage(order.customerPhone, message);
  }

  /// Kontak umum ke pelanggan (tombol "Hubungi Pelanggan" di action bar),
  /// beda dari _openWhatsapp yang khusus notifikasi "sudah selesai" -
  /// ini cuma sapaan umum yang nyebut nomor pesanan, dipakai di status apa
  /// pun.
  Future<void> _contactCustomerWhatsapp(_OrderDetailData order) async {
    final message = 'Halo kak ${order.customerName}, ini dari Netwash terkait pesanan ${order.orderNumber}.';
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

      final fileName = 'struk_${order.orderNumber.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_')}.png';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_rLg)),
        title: Text(
          'Batalkan Pesanan?',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, color: _cOnSurface),
        ),
        content: Text(
          'Tindakan ini akan mengubah status pesanan menjadi Dibatalkan.',
          style: GoogleFonts.beVietnamPro(fontSize: 13, color: _cOnSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tidak', style: GoogleFonts.beVietnamPro(color: _cOnSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleUpdateStatus('cancelled', note: 'Pesanan dibatalkan');
            },
            child: Text(
              'Ya, Batalkan',
              style: GoogleFonts.beVietnamPro(color: _cError, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cSurface,
      body: SafeArea(
        child: Stack(
          children: [
            // ---- Konten utama (scrollable) ----
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
                          72, // ruang buat top bar fixed
                          isMobile ? 16 : 24,
                          _order != null && _errorMessage == null && !_isLoading ? 110 : 24,
                        ),
                        child: _isLoading
                            ? _buildLoadingState(context)
                            : _errorMessage != null
                                ? _buildErrorState(context)
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildStatusCard(context, _order!),
                                      const SizedBox(height: AppTheme.md),
                                      if (_order!.status == 'cancelled')
                                        _buildCancelledCard(context, _order!)
                                      else
                                        _buildTimelineCard(context, _order!),
                                      const SizedBox(height: AppTheme.md),
                                      _buildBentoGrid(context, _order!, isMobile),
                                      const SizedBox(height: AppTheme.md),
                                      _buildCostBreakdown(context, _order!),
                                      const SizedBox(height: AppTheme.md),
                                      _buildPaymentBanner(context, _order!),
                                      const SizedBox(height: AppTheme.md),
                                      _buildPaymentHistory(context),
                                      if (_order!.notes.isNotEmpty) ...[
                                        const SizedBox(height: AppTheme.md),
                                        _buildNotes(context, _order!),
                                      ],
                                      if (_order!.status != 'completed' && _order!.status != 'cancelled') ...[
                                        const SizedBox(height: AppTheme.lg),
                                        _buildCancelLink(context),
                                      ],
                                    ],
                                  ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // ---- Top bar (fixed) ----
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(context),
            ),
            // ---- Bottom action bar (fixed) ----
            if (!_isLoading && _errorMessage == null && _order != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomActionBar(context, _order!),
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
            style: GoogleFonts.beVietnamPro(fontSize: 20, fontWeight: FontWeight.w700, color: _cOnSurface),
          ),
          const SizedBox(height: 4),
          Text(
            _laundryName != null && _laundryName!.isNotEmpty ? _laundryName! : 'Struk Pesanan',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(fontSize: 12.5, color: _cOnSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Divider(color: _cOutlineVariant),
          const SizedBox(height: 12),
          _receiptRow('No. Pesanan', order.orderNumber),
          _receiptRow('Tanggal', _formatDate(order.orderDate)),
          _receiptRow('Pelanggan', order.customerName),
          const SizedBox(height: 12),
          Divider(color: _cOutlineVariant),
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
                      style: GoogleFonts.beVietnamPro(fontSize: 12.5, color: _cOnSurface),
                    ),
                  ),
                  Text(
                    _formatCurrency(lineTotal),
                    style: GoogleFonts.beVietnamPro(fontSize: 12.5, fontWeight: FontWeight.w600, color: _cOnSurface),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          Divider(color: _cOutlineVariant),
          const SizedBox(height: 12),
          _receiptRow('Subtotal', _formatCurrency(order.subtotal)),
          if (order.taxAmount > 0) _receiptRow('Pajak', _formatCurrency(order.taxAmount)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w700, color: _cOnSurface)),
              Text(
                _formatCurrency(order.totalAmount),
                style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.w700, color: _cPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: _cOutlineVariant),
          const SizedBox(height: 12),
          _receiptRow('Metode Bayar', _paymentMethodLabel(order.paymentMethodRaw)),
          _receiptRow('Status Bayar', _getPaymentStatusLabel(order.paymentStatus)),
          _receiptRow('Sudah Dibayar', _formatCurrency(order.paidAmount)),
          if (order.remainingAmount > 0) _receiptRow('Sisa Tagihan', _formatCurrency(order.remainingAmount)),
          const SizedBox(height: 20),
          Text(
            'Terima kasih sudah pakai Netwash 🙏',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(fontSize: 11.5, color: _cOnSurfaceVariant),
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
          Text(label, style: GoogleFonts.beVietnamPro(fontSize: 12, color: _cOnSurfaceVariant)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w600, color: _cOnSurface),
            ),
          ),
        ],
      ),
    );
  }

  /// Top bar fixed: tombol kembali bulat + nomor pesanan (headline-md
  /// bold, warna primary) - persis referensi desain.
  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 64,
      color: _cSurface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.arrow_back_rounded, color: _cOnSurface, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _order != null ? _order!.orderNumber : 'Detail Pesanan',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.01,
                      color: _cPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.xxl),
      child: Center(child: CircularProgressIndicator(color: _cPrimary)),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 40, color: _cError),
            const SizedBox(height: AppTheme.md),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(fontSize: 13, color: _cOnSurfaceVariant),
            ),
            const SizedBox(height: AppTheme.lg),
            TextButton(
              onPressed: _fetchOrder,
              child: Text('Coba lagi', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, color: _cPrimary)),
            ),
          ],
        ),
      ),
    );
  }

  /// Kartu putih generik dengan radius & shadow sesuai token desain
  /// (rounded-xl 20px, shadow 0px 4px 12px rgba(0,0,0,0.05)).
  BoxDecoration _cardDecoration({bool withBorder = true}) {
    return BoxDecoration(
      color: _cCard,
      borderRadius: BorderRadius.circular(_rXl),
      border: withBorder ? Border.all(color: _cSurfaceContainer) : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// "Status & Badge Section" - status pesanan (dot berdenyut + label
  /// besar berwarna aksen) + badge cara pengiriman.
  Widget _buildStatusCard(BuildContext context, _OrderDetailData order) {
    final accent = _statusAccentColor(order.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STATUS PESANAN',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.02,
                        color: _cOnSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _getStatusLabel(order.status),
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.01,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: _cPrimaryFixed, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  _formatDate(order.orderDate).toUpperCase(),
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.02,
                    color: _cOnPrimaryFixedVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: _cSurfaceContainerLow))),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _cSecondaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(_rLg),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(order.deliveryTypeIcon, size: 18, color: _cSecondary),
                      const SizedBox(width: 6),
                      Text(
                        order.deliveryTypeLabel,
                        style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w700, color: _cSecondary),
                      ),
                    ],
                  ),
                ),
                if (order.laundryId.isNotEmpty && _laundryName != null && _laundryName!.isNotEmpty) ...[
                  const SizedBox(width: AppTheme.sm),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.storefront_outlined, size: 16, color: _cOnSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _laundryName!,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.beVietnamPro(fontSize: 12.5, color: _cOnSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu khusus kalau pesanan dibatalkan - gantiin timeline, karena
  /// "cancelled" bukan bagian dari alur maju normal (_statusFlow).
  Widget _buildCancelledCard(BuildContext context, _OrderDetailData order) {
    _StatusHistoryEntry? cancelEntry;
    for (final h in order.statusHistory) {
      if (h.status == 'cancelled') cancelEntry = h;
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cRedBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(_rXl),
        border: Border.all(color: _cError.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel_outlined, color: _cError, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pesanan Dibatalkan',
                  style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 15, color: _cError),
                ),
                if (cancelEntry != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    cancelEntry.note.isNotEmpty
                        ? cancelEntry.note
                        : '${_formatDate(cancelEntry.timestamp ?? order.orderDate)} ${_formatTime(cancelEntry.timestamp)}',
                    style: GoogleFonts.beVietnamPro(fontSize: 12.5, color: _cOnSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "Lacak Progress" - timeline penuh 9 tahap _statusFlow: tahap yang
  /// sudah lewat ditandai check hijau-primary, tahap aktif di-highlight
  /// dengan ring + catatan singkat, tahap depan digrayscale/opacity 40%.
  Widget _buildTimelineCard(BuildContext context, _OrderDetailData order) {
    final currentIndex = _statusFlow.indexOf(order.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(withBorder: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lacak Progress',
            style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w500, color: _cOnSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Column(
            children: List.generate(_statusFlow.length, (index) {
              final status = _statusFlow[index];
              final isPast = currentIndex >= 0 && index < currentIndex;
              final isCurrent = index == currentIndex;
              final isLast = index == _statusFlow.length - 1;
              final ts = order.timestampForStatus(status);

              Widget circle;
              if (isPast) {
                circle = Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(color: _cPrimary, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                );
              } else if (isCurrent) {
                circle = Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _cPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: _cPrimaryFixed, width: 4),
                  ),
                  child: Icon(_iconForStatus(status), color: Colors.white, size: 15),
                );
              } else {
                circle = Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(color: _cSurfaceContainerHighest, shape: BoxShape.circle),
                  child: Icon(_iconForStatus(status), color: _cOnSurfaceVariant, size: 15),
                );
              }

              final row = Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      circle,
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 34,
                          color: _cSurfaceContainerHighest,
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 22, top: isCurrent ? 2 : 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusLabel(status),
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 14,
                              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                              color: isPast || isCurrent ? _cPrimary.withOpacity(isPast ? 0.7 : 1) : _cOnSurfaceVariant,
                            ),
                          ),
                          if (isPast && ts != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${_formatDate(ts)}, ${_formatTime(ts)}',
                              style: GoogleFonts.beVietnamPro(fontSize: 11, color: _cOnSurfaceVariant),
                            ),
                          ] else if (isCurrent) ...[
                            const SizedBox(height: 2),
                            Text(
                              _activeStepNote(status),
                              style: GoogleFonts.beVietnamPro(fontSize: 11, color: _cOnSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );

              return (!isPast && !isCurrent) ? Opacity(opacity: 0.4, child: row) : row;
            }),
          ),
        ],
      ),
    );
  }

  /// "Bento Grid": kartu info pelanggan (kiri) + 2 mini-kartu ringkasan
  /// jumlah item & layanan (kanan). Di mobile ditumpuk vertikal.
  Widget _buildBentoGrid(BuildContext context, _OrderDetailData order, bool isMobile) {
    final customerCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'INFORMASI PELANGGAN',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.02,
                  color: _cOnSurfaceVariant,
                ),
              ),
              Icon(Icons.person_outline, color: _cSecondary, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.customerName,
            style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.w700, color: _cOnSurface),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.phone_outlined, size: 14, color: _cSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  order.customerPhone.isNotEmpty ? order.customerPhone : '-',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.beVietnamPro(fontSize: 13, color: _cSecondary),
                ),
              ),
            ],
          ),
          if (order.laundryId.isNotEmpty && _laundryName != null && _laundryName!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: _cSurfaceContainerLow))),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: _cTertiaryFixed, borderRadius: BorderRadius.circular(_rLg)),
                    child: Icon(Icons.store_outlined, color: _cOnTertiaryFixed, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CABANG TERDAFTAR',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.02,
                            color: _cOnSurfaceVariant,
                          ),
                        ),
                        Text(
                          _laundryName!,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w500, color: _cOnSurface),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    final statsGrid = Row(
      children: [
        Expanded(child: _miniStatCard(icon: Icons.shopping_bag_outlined, label: 'Jumlah Item', value: '${order.totalItemCount} item')),
        const SizedBox(width: AppTheme.sm),
        Expanded(child: _miniStatCard(icon: Icons.category_outlined, label: 'Layanan', value: order.serviceSummary)),
      ],
    );

    if (isMobile) {
      return Column(
        children: [
          customerCard,
          const SizedBox(height: AppTheme.sm),
          statsGrid,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: customerCard),
        const SizedBox(width: AppTheme.sm),
        Expanded(
          child: Column(
            children: [
              _miniStatCard(icon: Icons.shopping_bag_outlined, label: 'Jumlah Item', value: '${order.totalItemCount} item'),
              const SizedBox(height: AppTheme.sm),
              _miniStatCard(icon: Icons.category_outlined, label: 'Layanan', value: order.serviceSummary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniStatCard({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: _cSecondaryContainer, shape: BoxShape.circle),
            child: Icon(icon, color: _cPrimary, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(fontSize: 11.5, fontWeight: FontWeight.w700, color: _cOnSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.beVietnamPro(fontSize: 15, fontWeight: FontWeight.w700, color: _cPrimary),
          ),
        ],
      ),
    );
  }

  /// "Rincian Biaya" - daftar item, subtotal, pajak, lalu total dengan
  /// highlight background biru muda (primaryFixed).
  Widget _buildCostBreakdown(BuildContext context, _OrderDetailData order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RINCIAN BIAYA',
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.02,
              color: _cOnSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ...order.items.map((item) {
            final lineTotal = item.price * item.quantity;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${item.name}${item.quantity > 1 ? ' x${item.quantity}' : ''}',
                      style: GoogleFonts.beVietnamPro(fontSize: 14, color: _cSecondary),
                    ),
                  ),
                  const SizedBox(width: AppTheme.sm),
                  Text(
                    _formatCurrency(lineTotal),
                    style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w600, color: _cOnSurface),
                  ),
                ],
              ),
            );
          }),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: _cOutlineVariant, width: 1, style: BorderStyle.solid)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal', style: GoogleFonts.beVietnamPro(fontSize: 13, color: _cSecondary)),
                    Text(
                      _formatCurrency(order.subtotal),
                      style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w600, color: _cOnSurface),
                    ),
                  ],
                ),
                if (order.taxAmount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pajak', style: GoogleFonts.beVietnamPro(fontSize: 13, color: _cSecondary)),
                      Text(
                        _formatCurrency(order.taxAmount),
                        style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w600, color: _cOnSurface),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _cPrimaryFixed.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(_rLg),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Tagihan', style: GoogleFonts.beVietnamPro(fontSize: 13.5, fontWeight: FontWeight.w700, color: _cPrimary)),
                      Text(
                        _formatCurrency(order.totalAmount),
                        style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.w700, color: _cPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Banner info pembayaran: metode + badge status berwarna, sisa
  /// tagihan (merah kalau > 0), lalu tombol konfirmasi pembayaran &
  /// 2 tombol struk berdampingan.
  Widget _buildPaymentBanner(BuildContext context, _OrderDetailData order) {
    final badgeBg = _paymentBg(order.paymentStatus);
    final badgeFg = _paymentFg(order.paymentStatus);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cSurfaceContainerLow,
        borderRadius: BorderRadius.circular(_rXl),
        border: Border.all(color: _cOutlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.account_balance_wallet_outlined, color: _cPrimary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PEMBAYARAN',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.02,
                        color: _cOnSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _paymentMethodLabel(order.paymentMethodRaw),
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w500, color: _cOnSurface),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(999)),
                          child: Text(
                            _getPaymentStatusLabel(order.paymentStatus).toUpperCase(),
                            style: GoogleFonts.beVietnamPro(fontSize: 10, fontWeight: FontWeight.w700, color: badgeFg),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: _cOutlineVariant))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sudah Dibayar', style: GoogleFonts.beVietnamPro(fontSize: 13, color: _cOnSurfaceVariant)),
                Text(
                  _formatCurrency(order.paidAmount),
                  style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w700, color: _cOnSurface),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sisa Tagihan', style: GoogleFonts.beVietnamPro(fontSize: 13, color: _cOnSurfaceVariant)),
              Text(
                _formatCurrency(order.remainingAmount),
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: order.remainingAmount > 0 ? _cError : _cGreenText,
                ),
              ),
            ],
          ),
          if (order.paymentStatus != 'paid') ...[
            const SizedBox(height: AppTheme.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showRecordPaymentDialog(order),
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: Text('Konfirmasi Pembayaran', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cPrimaryContainer,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _cPrimary))
                      : const Icon(Icons.download_outlined, size: 18),
                  label: Text('Download Struk', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _cPrimary,
                    side: const BorderSide(color: _cPrimary),
                    backgroundColor: _cCard,
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _sendReceiptWhatsapp(order),
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: Text('Kirim Struk via WA', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF25D366),
                    side: const BorderSide(color: Color(0xFF25D366)),
                    backgroundColor: _cCard,
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RIWAYAT PEMBAYARAN',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.02,
                  color: _cOnSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: List.generate(payments.length, (index) {
                  final p = payments[index];
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _paymentMethodLabel(p.method.name),
                                    style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w600, color: _cOnSurface),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_formatDate(p.createdAt)} ${_formatTime(p.createdAt)}',
                                    style: GoogleFonts.beVietnamPro(fontSize: 11, color: _cOnSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatCurrency(p.amount),
                              style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w700, color: _cPrimary),
                            ),
                          ],
                        ),
                      ),
                      if (index < payments.length - 1) Divider(height: 1, color: _cOutlineVariant.withOpacity(0.4)),
                    ],
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build notes
  Widget _buildNotes(BuildContext context, _OrderDetailData order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CATATAN',
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.02,
              color: _cOnSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            order.notes,
            style: GoogleFonts.beVietnamPro(fontSize: 13.5, color: _cOnSurfaceVariant, height: 1.6),
          ),
        ],
      ),
    );
  }

  /// Link "Batalkan Pesanan" - dipisah dari action bar bawah (yang sudah
  /// dipakai buat aksi maju status), tampil di akhir konten kalau order
  /// masih bisa dibatalkan.
  Widget _buildCancelLink(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: _isUpdatingStatus ? null : _confirmCancelOrder,
        icon: const Icon(Icons.cancel_outlined, size: 18, color: _cError),
        label: Text('Batalkan Pesanan', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 13.5, color: _cError)),
      ),
    );
  }

  /// Action bar bawah (fixed): tombol utama primary (aksi maju status,
  /// atau "Kabari Pelanggan" kalau sudah completed) + tombol sekunder
  /// outline "Hubungi Pelanggan" - persis pola 2-tombol di referensi.
  Widget _buildBottomActionBar(BuildContext context, _OrderDetailData order) {
    final nextStatus = _nextStatus(order.status);
    final nextLabel = _nextStatusButtonLabel(order.status);
    final canCancel = order.status != 'completed' && order.status != 'cancelled';

    return Container(
      decoration: BoxDecoration(
        color: _cCard,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (order.status == 'completed')
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _openWhatsapp(order),
                      icon: const Icon(Icons.chat_outlined, size: 18),
                      label: Text(
                        order.isDelivery ? 'Kabari Siap Diantar' : 'Kabari via WhatsApp',
                        style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cPrimaryContainer,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_rXl)),
                      ),
                    ),
                  )
                else if (nextStatus != null && nextLabel != null)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isUpdatingStatus ? null : () => _handleUpdateStatus(nextStatus, note: nextLabel),
                      icon: _isUpdatingStatus
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.update, size: 18),
                      label: Text(nextLabel, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cPrimaryContainer,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_rXl)),
                      ),
                    ),
                  ),
                if (nextLabel != null || order.status == 'completed') const SizedBox(height: AppTheme.sm),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _contactCustomerWhatsapp(order),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: Text('Hubungi Pelanggan', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _cPrimary,
                      side: const BorderSide(color: _cPrimary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_rXl)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
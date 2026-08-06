import 'dart:async';
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_feedback.dart';
import '../../core/widgets/app_snackbar.dart';
import '../delivery/create_delivery_screen.dart' show CreateDeliveryScheduleScreen;
import '../../core/themes/app_theme.dart';
import '../../core/themes/design_tokens.dart';
import '../../models/order.dart';
import '../../models/transaction.dart';
import '../../models/user_model.dart';
import '../../models/employee.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/employee_repository.dart';
import '../../l10n/app_localizations.dart';

// ============================================
// DESIGN TOKENS
// Sebelumnya di-hardcode lokal di file ini (const Color _c...) - sama
// pola dengan class _DS di EmployeesListScreen, tapi keduanya punya
// token yang tumpang tindih (canvas, onSurface, primary, dst nilainya
// sama persis, cuma didefinisikan 2x di tempat berbeda).
//
// Sekarang digabung jadi SATU sumber kebenaran di
// lib/core/themes/design_tokens.dart (class DesignTokens), dipakai
// bareng oleh OrderDetailScreen & EmployeesListScreen. Alias singkat di
// bawah ini cuma buat minimalisir perubahan di seluruh file - nilainya
// 100% sama dengan sebelumnya, cuma sumbernya sekarang satu.
// ============================================
const Color _cSurface = DesignTokens.canvas;
const Color _cSurfaceContainerLow = DesignTokens.surfaceContainerLow;
const Color _cSurfaceContainer = DesignTokens.surfaceContainer;
const Color _cSurfaceContainerHighest = DesignTokens.surfaceContainerHighest;
const Color _cCard = DesignTokens.surface;
const Color _cOnSurface = DesignTokens.onSurface;
const Color _cOnSurfaceVariant = DesignTokens.onSurfaceVariant;
const Color _cOutlineVariant = DesignTokens.outlineVariant;
const Color _cPrimary = DesignTokens.primary;
const Color _cPrimaryContainer = DesignTokens.primaryContainer;
const Color _cPrimaryFixed = DesignTokens.primaryFixed;
const Color _cOnPrimaryFixedVariant = DesignTokens.onPrimaryFixedVariant;
const Color _cSecondary = DesignTokens.secondary;
const Color _cSecondaryContainer = DesignTokens.secondaryContainer;
const Color _cTertiaryFixed = DesignTokens.tertiaryFixed;
const Color _cOnTertiaryFixed = DesignTokens.onTertiaryFixed;
const Color _cError = DesignTokens.error;
const Color _cGreenBg = DesignTokens.greenBg;
const Color _cGreenText = DesignTokens.greenText;
const Color _cYellowBg = DesignTokens.yellowBg;
const Color _cYellowText = DesignTokens.yellowText;
const Color _cRedBg = DesignTokens.redBg;
const Color _cRedText = DesignTokens.redText;

// Radius token dari referensi (tailwind config): DEFAULT/lg = 16px,
// xl = 20px (dipakai untuk card & tombol besar), full = pill.
const double _rLg = DesignTokens.radiusLg;
const double _rXl = DesignTokens.radiusXl;

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
  // Operator yang menangani tahap ini - kosong kalau tahapnya memang
  // tidak butuh operator (mis. pending/confirmed/ready/completed) atau
  // entri lama sebelum fitur penugasan per-tahap ada.
  final String employeeName;

  _StatusHistoryEntry({
    required this.status,
    required this.timestamp,
    required this.note,
    this.employeeName = '',
  });

  factory _StatusHistoryEntry.fromMap(Map<String, dynamic> map) {
    final ts = map['timestamp'];
    return _StatusHistoryEntry(
      status: (map['status'] ?? '') as String,
      timestamp: ts is Timestamp ? ts.toDate() : null,
      note: (map['note'] ?? '') as String,
      employeeName: (map['employee_name'] ?? '') as String,
    );
  }
}

/// Hasil pilihan dari dialog pemilih operator (_showAssignOperatorDialog).
class _SelectedOperator {
  final String id;
  final String name;

  _SelectedOperator({required this.id, required this.name});
}

/// Data pengajuan pembatalan (users/{uid}/orders/{orderId}.cancellation_request).
///
/// Dipakai buat alur approval: kalau yang mengajukan role-nya 'employee',
/// status pesanan TIDAK langsung berubah jadi 'cancelled' -- cuma nyimpen
/// pengajuan ini dulu (status 'pending'), nunggu di-approve/reject sama
/// Admin/Owner/Manager. Kalau yang mengajukan Admin/Owner/Manager sendiri,
/// alur ini tetap dipakai buat jejak audit tapi statusnya langsung
/// 'approved' bareng dengan update status pesanan jadi 'cancelled'.
class _CancellationRequestData {
  final String requestedByUid;
  final String requestedByName;
  final String requestedByRole;
  final String reason;
  final DateTime? requestedAt;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? reviewedByName;
  final DateTime? reviewedAt;

  _CancellationRequestData({
    required this.requestedByUid,
    required this.requestedByName,
    required this.requestedByRole,
    required this.reason,
    required this.requestedAt,
    required this.status,
    this.reviewedByName,
    this.reviewedAt,
  });

  bool get isPending => status == 'pending';

  factory _CancellationRequestData.fromMap(Map<String, dynamic> map) {
    final requestedAt = map['requested_at'];
    final reviewedAt = map['reviewed_at'];
    return _CancellationRequestData(
      requestedByUid: (map['requested_by_uid'] ?? '') as String,
      requestedByName: (map['requested_by_name'] ?? '') as String,
      requestedByRole: (map['requested_by_role'] ?? '') as String,
      reason: (map['reason'] ?? '') as String,
      requestedAt: requestedAt is Timestamp ? requestedAt.toDate() : null,
      status: (map['status'] ?? 'pending') as String,
      reviewedByName: map['reviewed_by_name'] as String?,
      reviewedAt: reviewedAt is Timestamp ? reviewedAt.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requested_by_uid': requestedByUid,
      'requested_by_name': requestedByName,
      'requested_by_role': requestedByRole,
      'reason': reason,
      'requested_at': FieldValue.serverTimestamp(),
      'status': status,
    };
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

  // --- Penjemputan (cara baju MASUK) ---
  final String orderType; // 'walk_in' | 'pickup'
  // Null selama baju belum beneran dijemput dari pelanggan - order
  // dengan order_type 'pickup' dibuat TANPA item dulu (lihat
  // CreateOrderScreen & PickupDeliveryScreen._ConfirmPickupSheet). Baru
  // terisi begitu kurir menandai "Sudah Dijemput" lewat
  // confirmPickupWithItems().
  final DateTime? pickupDate;

  // --- Cabang ---
  final String laundryId; // bisa kosong buat order lama sebelum fitur cabang ada

  // --- Pembatalan ---
  final _CancellationRequestData? cancellationRequest;

  // --- Penugasan operator per-tahap ---
  // Siapa yang SEDANG memegang order ini di tahap proses aktif (washing/
  // drying/ironing/qualityCheck). Kosong kalau belum ditugaskan atau
  // order sudah lewat dari tahap proses.
  final String assignedEmployeeId;
  final String assignedEmployeeName;

  // --- Notifikasi "siap diambil" (khusus self-pickup) ---
  // True kalau kasir/owner sudah pernah nge-tap tombol "Kabari Pelanggan"
  // di tahap 'ready' - dipakai buat gating tombol maju status jadi
  // 'completed', supaya alur self-pickup gak bisa ditandai selesai
  // sebelum pelanggan beneran dikabarin dulu.
  final bool readyNotified;

  // --- Jadwal pengantaran (khusus delivery) ---
  // True kalau order ini SUDAH punya logistics_schedule tersimpan (hasil
  // dari CreateDeliveryScheduleScreen). Dipakai supaya tombol "Jadwalkan
  // Pengantaran" berubah jadi "Ubah Jadwal Pengantaran" kalau sudah ada
  // jadwal - biar karyawan gak salah kira ini masih perlu dijadwalkan
  // dari nol / gak sengaja ngulang alur jadwal.
  final bool hasLogisticsSchedule;

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
    this.orderType = 'walk_in',
    this.pickupDate,
    required this.laundryId,
    this.cancellationRequest,
    this.assignedEmployeeId = '',
    this.assignedEmployeeName = '',
    this.readyNotified = false,
    this.hasLogisticsSchedule = false,
  });

  /// True kalau ada pengajuan pembatalan yang masih menunggu approval.
  bool get hasPendingCancellationRequest => cancellationRequest?.isPending ?? false;

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
  /// OrdersListScreen.serviceSummary. `othersLabel` dikirim dari UI
  /// (sudah dilokalisasi di sana) supaya model data ini tetap bebas
  /// dependensi ke Flutter localization.
  String serviceSummary(String othersLabel) {
    if (items.isEmpty) return '-';
    if (items.length == 1) return items.first.name;
    return '${items.first.name} +${items.length - 1} $othersLabel';
  }

  bool get isDelivery => deliveryType == 'delivery';
  IconData get deliveryTypeIcon => isDelivery ? Icons.local_shipping_outlined : Icons.storefront_outlined;

  /// True kalau cara baju masuk adalah dijemput kurir (bukan walk-in).
  bool get needsPickup => orderType == 'pickup';

  /// True kalau order ini masih NUNGGU baju beneran dijemput dari
  /// pelanggan - belum ada pickupDate sama sekali. Selama ini true,
  /// order BELUM punya item/berat yang jelas (order pickup dibuat kosong
  /// dari awal), jadi belum boleh dimajukan ke tahap proses
  /// (inProgress/washing/dst) - gak ada yang bisa dicuci kalau barangnya
  /// aja belum ketahuan ada di tangan siapa.
  bool get isAwaitingPickup => needsPickup && pickupDate == null;

  /// Cari timestamp status tertentu dari riwayat (dipakai timeline).
  DateTime? timestampForStatus(String status) {
    for (final h in statusHistory) {
      if (h.status == status) return h.timestamp;
    }
    return null;
  }

  /// Cari nama operator yang menangani tahap tertentu dari riwayat
  /// (dipakai timeline untuk nampilin "oleh Budi" di tahap yang sudah
  /// lewat). Null kalau tahap itu tidak punya operator tercatat.
  String? operatorForStatus(String status) {
    for (final h in statusHistory) {
      if (h.status == status && h.employeeName.isNotEmpty) return h.employeeName;
    }
    return null;
  }

  factory _OrderDetailData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final orderDate = data['order_date'];
    final rawItems = (data['items'] as List?) ?? [];
    final rawHistory = (data['status_history'] as List?) ?? [];
    final rawCancellationRequest = data['cancellation_request'];

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
      orderType: (data['order_type'] ?? 'walk_in') as String,
      pickupDate: data['pickup_date'] is Timestamp ? (data['pickup_date'] as Timestamp).toDate() : null,
      laundryId: (data['laundry_id'] ?? '') as String,
      cancellationRequest: rawCancellationRequest is Map
          ? _CancellationRequestData.fromMap(Map<String, dynamic>.from(rawCancellationRequest))
          : null,
      assignedEmployeeId: (data['assigned_employee_id'] ?? '') as String,
      assignedEmployeeName: (data['assigned_employee_name'] ?? '') as String,
      readyNotified: (data['ready_notified'] ?? false) as bool,
      // PENTING: order dengan order_type 'pickup' sudah punya
// 'logistics_schedule' sejak dibuat (mode: 'penjemputan', diisi dari
// CreateOrderScreen) - itu bukan jadwal PENGANTARAN. Supaya tombol di
// bottom action bar cuma berubah jadi "Ubah Jadwal Pengantaran" kalau
// memang sudah ada jadwal ANTAR (bukan jadwal jemput lama), harus
// dicocokkan juga mode-nya, bukan cuma cek field-nya ada atau tidak.
hasLogisticsSchedule: (data['logistics_schedule'] as Map<String, dynamic>?)?['mode'] == 'pengantaran',
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

/// Tahap proses yang butuh penugasan operator per-tahap - beda operator
/// boleh ditugaskan untuk tiap tahap (mis. Budi nyuci, Ani nyetrika).
/// Begitu order maju ke salah satu status ini, owner/kasir WAJIB pilih
/// dulu siapa operatornya lewat dialog (lihat
/// _OrderDetailScreenState._showAssignOperatorDialog), dan pilihan itu
/// otomatis tercatat sebagai riwayat aktivitas (StatusHistory.employeeId/
/// employeeName) SEKALIGUS jadi "sedang dikerjakan oleh" order.
const List<String> _stagesRequiringOperator = ['washing', 'drying', 'ironing', 'qualityCheck'];

/// Jabatan mana saja yang boleh muncul di dropdown pemilih operator untuk
/// tiap tahap - SENGAJA dibatasi, bukan "semua karyawan aktif", karena
/// posisi seperti Manajer/Kasir/Kurir/Staff Gudang bukan yang benar-benar
/// pegang mesin cuci. Cuma "Operator Cuci" (lihat _positionOptions di
/// CreateEmployeeScreen) yang relevan untuk keempat tahap proses ini.
/// Dipisah jadi map (bukan konstanta tunggal) supaya gampang dibedakan
/// per tahap kalau nanti ada jabatan baru yang lebih spesifik (mis.
/// "Operator Setrika" khusus tahap ironing).
const Map<String, List<String>> _allowedPositionsByStage = {
  'washing': ['Operator Cuci'],
  'drying': ['Operator Pengering'],
  'ironing': ['Operator Setrika'],
  'qualityCheck': ['Quality Control'],
};

/// Pesanan cuma bisa dibatalkan (langsung atau lewat pengajuan) selama
/// MASIH 'pending' (belum dikonfirmasi). Begitu dikonfirmasi (atau tahap
/// manapun sesudahnya: inProgress, washing, ..., ready, completed),
/// dikunci -- sudah tidak bisa dibatalkan lagi.
bool _canCancelForStatus(String status) {
  return status == 'pending';
}

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
class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderDetailScreen({Key? key, required this.orderId}) : super(key: key);
  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen>
  with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isUpdatingStatus = false;
  bool _isGeneratingReceipt = false;
  String? _errorMessage;
  _OrderDetailData? _order;

  // --- Role user yang lagi login, buat gating tombol batalkan/approval ---
  // Dibaca dari users/{uid}.role (bukan custom claims), sama pola dengan
  // AdminGuard. null selama masih loading -- selagi null, tombol batalkan
  // langsung disembunyikan dulu (fail-closed) supaya nggak sempat kelihatan
  // buat role yang harusnya butuh approval.
  String? _currentUserRole;
  String _currentUserName = '';
  StreamSubscription<UserModel?>? _roleSub;
  bool _isSubmittingCancelAction = false;

  /// True selagi nunggu user balik dari WhatsApp setelah nge-tap
  /// "Kabari Pelanggan" (ready, self-pickup). Dipakai di
  /// didChangeAppLifecycleState buat mutuskan apakah perlu munculin
  /// dialog konfirmasi "sudah kirim belum" pas app di-resume.
  bool _awaitingReadyNotifyConfirmation = false;

  // Nama cabang (resolved dari laundryId) - null selama masih loading
  // atau kalau order.laundryId kosong (order lama sebelum fitur cabang).
  String? _laundryName;
  bool _isLoadingLaundryName = false;

  /// Key buat "menangkap" tampilan struk (_buildReceiptCard) jadi gambar PNG
  /// lewat RepaintBoundary. Widget-nya dirender offstage (di luar layar,
  /// nggak keliatan user), cuma dipakai sebagai sumber screenshot.
  final GlobalKey _receiptKey = GlobalKey();

  /// Shortcut ke AppLocalizations - dipakai di seluruh method state ini
  /// (build maupun non-build, mis. handler snackbar) karena State selalu
  /// punya akses ke `context` sendiri.
  AppLocalizations get _t => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchOrder();
    _listenToCurrentUserRole();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _roleSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingReadyNotifyConfirmation) {
      _awaitingReadyNotifyConfirmation = false;
      // Kasih jeda dikit supaya transisi resume-nya mulus dulu sebelum
      // dialog muncul, daripada nyempil pas masih animasi balik ke app.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showConfirmMessageSentDialog();
      });
    }
  }

  /// Dengerin role user yang lagi login dari profilnya sendiri
  /// (users/{uid}.role) - dipakai buat mutuskan apakah "Batalkan Pesanan"
  /// langsung mengubah status, atau cuma bikin pengajuan yang butuh
  /// approval (kalau role-nya 'employee').
  void _listenToCurrentUserRole() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _roleSub = UserRepository(FirebaseFirestore.instance).getUserProfileStream(uid).listen((profile) {
      if (!mounted) return;
      setState(() {
        _currentUserRole = profile?.role ?? 'owner';
        _currentUserName = profile?.fullName ?? '';
      });
    });
  }

  /// Admin/Owner/Manager bisa langsung membatalkan pesanan. Karyawan
  /// (employee) cuma bisa mengajukan, butuh persetujuan salah satu role
  /// di atas.
  bool get _canCancelDirectly =>
      _currentUserRole == 'admin' || _currentUserRole == 'owner' || _currentUserRole == 'manager';

  CollectionReference get _ordersRef {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw _t.sessionNotFoundError;
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
        throw _t.orderNotFoundError;
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
        return _t.orderDetailStatusPending;
      case 'confirmed':
        return _t.orderDetailStatusConfirmed;
      case 'inProgress':
        return _t.orderDetailStatusInProgress;
      case 'washing':
        return _t.orderDetailStatusWashing;
      case 'drying':
        return _t.orderDetailStatusDrying;
      case 'ironing':
        return _t.orderDetailStatusIroning;
      case 'qualityCheck':
        return _t.orderDetailStatusQualityCheck;
      case 'ready':
        return _t.orderDetailStatusReady;
      case 'completed':
        return _t.orderDetailStatusCompleted;
      case 'cancelled':
        return _t.orderDetailStatusCancelled;
      default:
        return status;
    }
  }

  /// Catatan singkat buat tahap yang lagi AKTIF di timeline (pengganti
  /// timestamp, sama seperti "Sedang dalam mesin cuci" di referensi).
  String _activeStepNote(String status) {
    switch (status) {
      case 'pending':
        return _t.orderDetailNotePending;
      case 'confirmed':
        return _t.orderDetailNoteConfirmed;
      case 'inProgress':
        return _t.orderDetailNoteInProgress;
      case 'washing':
        return _t.orderDetailNoteWashing;
      case 'drying':
        return _t.orderDetailNoteDrying;
      case 'ironing':
        return _t.orderDetailNoteIroning;
      case 'qualityCheck':
        return _t.orderDetailNoteQualityCheck;
      case 'ready':
        return _t.orderDetailNoteReady;
      case 'completed':
        return _t.orderDetailNoteCompleted;
      default:
        return '';
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

  String? _nextStatusButtonLabel(String currentStatus) {
    switch (currentStatus) {
      case 'pending':
        return _t.confirmOrderButtonLabel;
      case 'confirmed':
        return _t.startProcessButtonLabel;
      case 'inProgress':
        return _t.startWashingButtonLabel;
      case 'washing':
        return _t.finishWashingButtonLabel;
      case 'drying':
        return _t.finishDryingButtonLabel;
      case 'ironing':
        return _t.finishIroningButtonLabel;
      case 'qualityCheck':
        return _t.passQualityCheckButtonLabel;
      case 'ready':
        return _t.markCompletedButtonLabel;
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
        return _t.paymentMethodCash;
      case 'transfer':
        return _t.paymentMethodTransfer;
      case 'debit':
        return _t.paymentMethodDebit;
      case 'ewallet':
        return _t.paymentMethodEwallet;
      default:
        return method;
    }
  }

  String _getPaymentStatusLabel(String status) {
    switch (status) {
      case 'paid':
        return _t.orderDetailPaymentStatusPaid;
      case 'partial':
        return _t.orderDetailPaymentStatusPartial;
      case 'refunded':
        return _t.orderDetailPaymentStatusRefunded;
      case 'pending':
      default:
        return _t.orderDetailPaymentStatusPending;
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
    if (isError) {
      AppSnackbar.error(context, message);
    } else {
      AppSnackbar.success(context, message);
    }
  }

  /// Handle update status -> tulis ke Firestore: update field `status`,
  /// tambah entri baru ke `status_history`, dan set `actual_completion`
  /// begitu status jadi 'completed'.
  ///
  /// NOTE: alur ubah status ini SENGAJA tetap pakai raw Firestore call
  /// (bukan lewat OrderRepository) - scope refactor kali ini difokuskan
  /// ke bagian pembayaran saja.
  ///
  /// RESOLVED (merge dari 2 branch):
  /// - dari branch fitur "assign operator": parameter employeeId/
  ///   employeeName + logic assigned_employee_* di updateData.
  /// - dari branch "app feedback sound": AppFeedback.playSound() di
  ///   jalur sukses maupun gagal.
  Future<void> _handleUpdateStatus(
    String newStatus, {
    String? note,
    String? employeeId,
    String? employeeName,
  }) async {
    if (_order == null) return;

    setState(() => _isUpdatingStatus = true);

    try {
      final historyEntry = {
        'status': newStatus,
        'timestamp': Timestamp.now(),
        'note': note ?? _t.statusChangedNoteTemplate(_getStatusLabel(newStatus)),
        'employee_id': employeeId,
        'employee_name': employeeName,
      };

      final updateData = <String, dynamic>{
        'status': newStatus,
        'status_history': FieldValue.arrayUnion([historyEntry]),
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (employeeId != null && employeeName != null) {
        // Tahap tujuan butuh operator (washing/drying/ironing/qualityCheck)
        // - simpan juga sebagai "sedang dikerjakan oleh" di level order.
        updateData['assigned_employee_id'] = employeeId;
        updateData['assigned_employee_name'] = employeeName;
      } else if (!_stagesRequiringOperator.contains(newStatus)) {
        // Order sudah lewat dari tahap proses (mis. jadi 'ready') - tidak
        // ada lagi operator yang "memegang" order, walau jejaknya tetap
        // permanen di status_history.
        updateData['assigned_employee_id'] = FieldValue.delete();
        updateData['assigned_employee_name'] = FieldValue.delete();
      }

      if (newStatus == 'completed') {
        updateData['actual_completion'] = FieldValue.serverTimestamp();
      }

      await _ordersRef.doc(widget.orderId).update(updateData);

      if (mounted) {
        AppFeedback.playSound(ref, AppSound.success);
        _showSnack(_t.statusUpdateSuccess(_getStatusLabel(newStatus)));
      }

      await _fetchOrder();
    } catch (e) {
      if (mounted) {
        AppFeedback.playSound(ref, AppSound.error);
        _showSnack(_t.statusUpdateError(e.toString()), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  /// Titik masuk tombol "maju status" di bottom action bar. Kalau tahap
  /// tujuan termasuk yang butuh operator (_stagesRequiringOperator),
  /// munculin dulu dialog pemilihan operator - order TIDAK maju status
  /// kalau dialog dibatalkan / belum pilih siapa-siapa. Tahap lain
  /// (pending -> confirmed, ready -> completed, dst) langsung jalan
  /// seperti biasa tanpa perlu pilih operator.
  Future<void> _handleAdvanceStatus(String nextStatus, String nextLabel) async {
    // Guard tambahan di level logic (bukan cuma tombol UI) - order
    // pickup yang barangnya belum beneran dijemput gak boleh dimajukan
    // lewat 'confirmed', walau entah bagaimana ini sempat terpanggil.
    if (_order != null && _order!.isAwaitingPickup && _order!.status == 'confirmed') {
      _showSnack('Tandai barang sudah dijemput dulu di layar Antar Jemput sebelum melanjutkan proses', isError: true);
      return;
    }
    if (!_stagesRequiringOperator.contains(nextStatus)) {
      await _handleUpdateStatus(nextStatus, note: nextLabel);
      return;
    }

    final selected = await _showAssignOperatorDialog(nextStatus);
    if (selected == null) return; // dibatalkan - status tidak berubah

    await _handleUpdateStatus(
      nextStatus,
      note: nextLabel,
      employeeId: selected.id,
      employeeName: selected.name,
    );
  }

  /// Dialog pemilihan operator untuk tahap proses tertentu - daftar
  /// karyawan aktif di cabang yang sama dengan order (fallback ke semua
  /// karyawan aktif kalau order lama belum punya laundryId). Mengembalikan
  /// null kalau dialog dibatalkan.
  Future<_SelectedOperator?> _showAssignOperatorDialog(String forStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final employeeRepo = EmployeeRepository(userId: user.uid);
    final laundryId = _order?.laundryId ?? '';
    final employeesStream = laundryId.isNotEmpty
        ? employeeRepo.streamEmployeesByLaundry(laundryId)
        : employeeRepo.streamEmployees();

    String? selectedId;
    String? selectedName;
    // Guard supaya listener di fieldViewBuilder cuma nempel sekali, bukan
    // numpuk tiap kali StatefulBuilder rebuild.
    bool listenerAttached = false;

    return showDialog<_SelectedOperator>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_rLg)),
            title: Text(
              _t.assignOperatorDialogTitle,
              style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, color: _cOnSurface),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t.assignOperatorDialogSubtitle(_getStatusLabel(forStatus)),
                    style: GoogleFonts.beVietnamPro(fontSize: 12.5, color: _cOnSurfaceVariant),
                  ),
                  const SizedBox(height: AppTheme.md),
                  StreamBuilder<List<Employee>>(
                    stream: employeesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      // Cocokkan posisi tanpa peduli spasi ekstra / beda
                      // huruf besar-kecil (mis. "operator cuci " vs
                      // "Operator Cuci") - sebelumnya exact-match bikin
                      // karyawan yang posisinya ditulis beda dikit gak
                      // kedeteksi, atau malah karyawan salah bagian ikut
                      // ke-loloskan kalau posisinya ternyata kosong/aneh.
                      final allowedPositions = (_allowedPositionsByStage[forStatus] ?? const [])
                          .map((p) => p.trim().toLowerCase())
                          .toSet();
                      final activeEmployees = (snapshot.data ?? [])
                          .where((e) => e.isActive && allowedPositions.contains(e.position.trim().toLowerCase()))
                          .toList()
                        ..sort((a, b) => a.fullName.compareTo(b.fullName));

                      if (activeEmployees.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            _t.assignOperatorEmptyState,
                            style: GoogleFonts.beVietnamPro(fontSize: 12.5, color: _cOnSurfaceVariant),
                          ),
                        );
                      }

                      return Autocomplete<Employee>(
                        displayStringForOption: (e) => e.fullName,
                        optionsBuilder: (textEditingValue) {
                          final query = textEditingValue.text.trim().toLowerCase();
                          if (query.isEmpty) return activeEmployees;
                          return activeEmployees.where((e) => e.fullName.toLowerCase().startsWith(query));
                        },
                        onSelected: (e) {
                          setDialogState(() {
                            selectedId = e.id;
                            selectedName = e.fullName;
                          });
                        },
                        fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                          if (!listenerAttached) {
                            listenerAttached = true;
                            // Kalau teks diubah manual sampai gak lagi
                            // cocok sama nama yang terakhir dipilih,
                            // batalkan pilihan - tombol konfirmasi
                            // ke-disable lagi, jadi gak bisa asal ketik
                            // nama tanpa milih dari daftar beneran.
                            textController.addListener(() {
                              if (selectedName != null && textController.text != selectedName) {
                                setDialogState(() {
                                  selectedId = null;
                                  selectedName = null;
                                });
                              }
                            });
                          }
                          return TextField(
                            controller: textController,
                            focusNode: focusNode,
                            style: GoogleFonts.beVietnamPro(fontSize: 13.5, color: _cOnSurface),
                            decoration: InputDecoration(
                              labelText: _t.assignOperatorFieldLabel,
                              labelStyle: GoogleFonts.beVietnamPro(fontSize: 12.5),
                              prefixIcon: const Icon(Icons.search_rounded, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(12),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 200),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final e = options.elementAt(index);
                                    return ListTile(
                                      dense: true,
                                      title: Text(e.fullName, style: GoogleFonts.beVietnamPro(fontSize: 13.5)),
                                      onTap: () => onSelected(e),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(_t.cancel, style: GoogleFonts.beVietnamPro(color: _cOnSurfaceVariant)),
              ),
              ElevatedButton(
                onPressed: selectedId == null
                    ? null
                    : () => Navigator.pop(
                          dialogContext,
                          _SelectedOperator(id: selectedId!, name: selectedName ?? ''),
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cPrimaryContainer,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_t.assignOperatorConfirmButtonLabel, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
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
              _t.confirmPaymentDialogTitle,
              style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, color: _cOnSurface),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t.remainingBillDialogLabel(_formatCurrency(remaining)),
                  style: GoogleFonts.beVietnamPro(fontSize: 12.5, color: _cOnSurfaceVariant),
                ),
                const SizedBox(height: AppTheme.md),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.beVietnamPro(fontSize: 13.5),
                  decoration: InputDecoration(
                    labelText: _t.amountPaidFieldLabel,
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
                    labelText: _t.methodFieldLabel,
                    labelStyle: GoogleFonts.beVietnamPro(fontSize: 12.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(_t.cancel, style: GoogleFonts.beVietnamPro(color: _cOnSurfaceVariant)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cPrimaryContainer,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_t.saveButtonLabel, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700)),
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
      _showSnack(_t.amountMustBePositiveError, isError: true);
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw _t.sessionNotFoundError;

      await OrderRepository(userId: user.uid).recordPayment(
        widget.orderId,
        amount: amount,
        method: PaymentMethod.values.firstWhere(
          (e) => e.name == selectedMethod,
          orElse: () => PaymentMethod.cash,
        ),
      );

      _showSnack(_t.paymentRecordSuccess);
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
  Future<bool> _launchWhatsappMessage(String phone, String message) async {
    if (phone.isEmpty) {
      _showSnack(_t.customerPhoneUnavailable, isError: true);
      return false;
    }

    final normalized = _normalizePhone(phone);
    final uri = Uri.https('wa.me', '/$normalized', {'text': message});
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      _showSnack(_t.whatsappOpenError, isError: true);
    }
    return launched;
  }

  /// Buka WhatsApp ke nomor customer, isi pesan otomatis bahwa
  /// pesanannya sudah selesai. Isi pesan disesuaikan dengan deliveryType:
  /// - self_pickup -> tanya mau diambil sendiri atau diantar
  /// - delivery    -> kabari bahwa pesanan akan segera diantar
  Future<void> _openWhatsapp(_OrderDetailData order) async {
    final String message;
    if (order.deliveryType == 'delivery') {
      message = _t.whatsappOrderReadyDeliveryMessage(order.customerName, order.orderNumber);
    } else {
      message = _t.whatsappOrderReadyPickupMessage(order.customerName, order.orderNumber);
    }

    await _launchWhatsappMessage(order.customerPhone, message);
  }

  /// Simpan penanda bahwa pelanggan sudah dikabari "pesanan siap diambil"
  /// (self-pickup, status masih 'ready'). Kegagalan nulis ini bukan error
  /// fatal - WA-nya sudah kebuka duluan, cuma tombol gak otomatis ganti
  /// sampai halaman di-refresh manual.
  Future<void> _markReadyNotified() async {
    try {
      await _ordersRef.doc(widget.orderId).update({
        'ready_notified': true,
        'ready_notified_at': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // sengaja diabaikan, lihat catatan di atas
    }
  }

  /// Kirim WA "pesanan siap diambil" khusus alur self-pickup SAAT STATUS
  /// MASIH 'ready' - beda dari _openWhatsapp yang jalan di status
  /// 'completed'. Dipakai supaya kasir gak bisa langsung "Tandai Selesai"
  /// sebelum beneran ngabarin pelanggan dulu. Begitu WA berhasil kebuka,
  /// flag ready_notified disimpan dan tombol otomatis berganti jadi
  /// "Tandai Selesai" (lewat _fetchOrder() di akhir).
  Future<void> _notifyReadyForPickup(_OrderDetailData order) async {
    final message = _t.whatsappOrderReadyPickupMessage(order.customerName, order.orderNumber);
    final launched = await _launchWhatsappMessage(order.customerPhone, message);
    if (!launched) return;

    _awaitingReadyNotifyConfirmation = true;
  }

  /// Ditampilkan begitu user balik ke app setelah _notifyReadyForPickup
  /// membuka WhatsApp. Cuma di titik INI ready_notified beneran ditulis
  /// ke Firestore - kalau user pilih "Belum", tombol "Kabari Pelanggan"
  /// tetap muncul supaya bisa dicoba lagi.
  void _showConfirmMessageSentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_rLg)),
        title: Text(
          'Sudah dikirim?',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, color: _cOnSurface),
        ),
        content: Text(
          'Apakah pesan "pesanan siap diambil" sudah berhasil dikirim ke pelanggan lewat WhatsApp?',
          style: GoogleFonts.beVietnamPro(fontSize: 13, color: _cOnSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Belum', style: GoogleFonts.beVietnamPro(color: _cOnSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _markReadyNotified();
              if (mounted) await _fetchOrder();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _cPrimaryContainer,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Ya, Sudah', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  /// Kontak umum ke pelanggan (tombol "Hubungi Pelanggan" di action bar),
  /// beda dari _openWhatsapp yang khusus notifikasi "sudah selesai" -
  /// ini cuma sapaan umum yang nyebut nomor pesanan, dipakai di status apa
  /// pun.
  Future<void> _contactCustomerWhatsapp(_OrderDetailData order) async {
    final message = _t.whatsappContactMessage(order.customerName, order.orderNumber);
    await _launchWhatsappMessage(order.customerPhone, message);
  }

  /// Susun & kirim "struk" pesanan dalam bentuk teks terformat ke WhatsApp
  /// pelanggan (pakai *bold* ala WA). Bukan gambar - wa.me hanya bisa
  /// prefill teks. Tombol ini TETAP ada, dipakai berdampingan sama tombol
  /// "Download Struk" (gambar) di bawah - pilih salah satu sesuai
  /// kebutuhan kasir.
  Future<void> _sendReceiptWhatsapp(_OrderDetailData order) async {
    final buffer = StringBuffer();
    buffer.writeln('*${_t.receiptWhatsappTitle}*');
    buffer.writeln('${_t.receiptOrderNumberLabel}: ${order.orderNumber}');
    buffer.writeln('${_t.receiptDateLabel}: ${_formatDate(order.orderDate)}');
    buffer.writeln('${_t.receiptCustomerLabel}: ${order.customerName}');
    buffer.writeln('');
    buffer.writeln('*${_t.receiptItemsLabel}:*');
    for (final item in order.items) {
      final lineTotal = item.price * item.quantity;
      buffer.writeln('${item.name} x${item.quantity} - ${_formatCurrency(lineTotal)}');
    }
    buffer.writeln('');
    buffer.writeln('${_t.subtotalLabel}: ${_formatCurrency(order.subtotal)}');
    if (order.taxAmount > 0) {
      buffer.writeln('${_t.taxLabel}: ${_formatCurrency(order.taxAmount)}');
    }
    buffer.writeln('*${_t.receiptTotalLabel}: ${_formatCurrency(order.totalAmount)}*');
    buffer.writeln('');
    buffer.writeln('${_t.receiptPaymentMethodLabel}: ${_paymentMethodLabel(order.paymentMethodRaw)}');
    buffer.writeln('${_t.receiptPaymentStatusLabel}: ${_getPaymentStatusLabel(order.paymentStatus)}');
    buffer.writeln('${_t.paidAmountLabel}: ${_formatCurrency(order.paidAmount)}');
    if (order.remainingAmount > 0) {
      buffer.writeln('${_t.remainingBillLabel}: ${_formatCurrency(order.remainingAmount)}');
    }
    buffer.writeln('');
    buffer.writeln(_t.receiptThankYouMessage);

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
        _showSnack(_t.receiptImageGenerationError, isError: true);
        return;
      }

      final fileName = 'struk_${order.orderNumber.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_')}.png';

      if (kIsWeb) {
        // Web: belum ada API "galeri" di browser, jadi paksa download
        // file biasa. (Implementasi web di-skip di sini biar file utama
        // tetap ringan - kalau butuh testing di Chrome, pakai package
        // `universal_html` terpisah. Di HP asli, baris di bawah (mobile)
        // yang jalan.)
        _showSnack(_t.receiptDownloadWebUnsupported);
        return;
      }

      await Gal.putImageBytes(bytes, name: fileName);
      _showSnack(_t.receiptSavedToGallery);
    } catch (e) {
      if (mounted) {
        _showSnack(_t.receiptDownloadError(e.toString()), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isGeneratingReceipt = false);
    }
  }

  /// Dialog batalkan pesanan - selalu minta alasan (dipakai baik buat
  /// pembatalan langsung maupun pengajuan). Tombol konfirmasi & pesan
  /// menyesuaikan role: Admin/Owner/Manager -> "Ya, Batalkan" (langsung),
  /// Employee -> "Ajukan Pembatalan" (butuh approval).
  void _confirmCancelOrder() {
    final directCancel = _canCancelDirectly;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_rLg)),
            title: Text(
              directCancel ? _t.cancelOrderDialogTitle : _t.requestCancellationDialogTitle,
              style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, color: _cOnSurface),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  directCancel ? _t.cancelOrderDialogContent : _t.requestCancellationDialogContent,
                  style: GoogleFonts.beVietnamPro(fontSize: 13, color: _cOnSurfaceVariant),
                ),
                const SizedBox(height: AppTheme.md),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  style: GoogleFonts.beVietnamPro(fontSize: 13.5),
                  decoration: InputDecoration(
                    labelText: _t.cancellationReasonFieldLabel,
                    labelStyle: GoogleFonts.beVietnamPro(fontSize: 12.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(_t.noButtonLabel, style: GoogleFonts.beVietnamPro(color: _cOnSurfaceVariant)),
              ),
              TextButton(
                onPressed: () {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) {
                    _showSnack(_t.cancellationReasonRequiredError, isError: true);
                    return;
                  }
                  Navigator.pop(dialogContext);
                  if (directCancel) {
                    _cancelOrderDirectly(reason);
                  } else {
                    _submitCancellationRequest(reason);
                  }
                },
                child: Text(
                  directCancel ? _t.yesCancelButtonLabel : _t.submitCancellationRequestButtonLabel,
                  style: GoogleFonts.beVietnamPro(color: _cError, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Admin/Owner/Manager membatalkan langsung: status pesanan berubah jadi
  /// 'cancelled' saat itu juga. Tetap nyimpen cancellation_request (status
  /// 'approved') buat jejak audit siapa & kenapa.
  Future<void> _cancelOrderDirectly(String reason) async {
    if (_order == null) return;
    setState(() => _isSubmittingCancelAction = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final requestData = _CancellationRequestData(
        requestedByUid: uid,
        requestedByName: _currentUserName,
        requestedByRole: _currentUserRole ?? 'owner',
        reason: reason,
        requestedAt: DateTime.now(),
        status: 'approved',
      );
      final requestMap = requestData.toMap();
      requestMap['reviewed_by_name'] = _currentUserName;
      requestMap['reviewed_at'] = FieldValue.serverTimestamp();

      // 1 update atomik: cancellation_request DAN status berubah bareng,
      // gak dipisah 2 write. Firestore rules (`allow update`) cuma
      // meng-cek ada `status`/`status_history`/dst di antara affectedKeys
      // -- kalau ini dipecah jadi write terpisah yang cuma nyentuh
      // `cancellation_request`, tulisan itu bakal ditolak rules.
      await _ordersRef.doc(widget.orderId).update({
        'status': 'cancelled',
        'status_history': FieldValue.arrayUnion([
          {
            'status': 'cancelled',
            'timestamp': Timestamp.now(),
            'note': _t.orderCancelledNoteTemplate(reason),
          }
        ]),
        'updated_at': FieldValue.serverTimestamp(),
        'cancellation_request': requestMap,
      });

      if (mounted) _showSnack(_t.statusUpdateSuccess(_getStatusLabel('cancelled')));
      await _fetchOrder();
    } catch (e) {
      if (mounted) _showSnack(_t.cancelOrderError(e.toString()), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmittingCancelAction = false);
    }
  }

  /// Employee mengajukan pembatalan: TIDAK mengubah status pesanan, cuma
  /// nyimpen pengajuan (status 'pending') menunggu di-review.
  Future<void> _submitCancellationRequest(String reason) async {
    if (_order == null) return;
    setState(() => _isSubmittingCancelAction = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final requestData = _CancellationRequestData(
        requestedByUid: uid,
        requestedByName: _currentUserName,
        requestedByRole: _currentUserRole ?? 'employee',
        reason: reason,
        requestedAt: DateTime.now(),
        status: 'pending',
      );
      await _ordersRef.doc(widget.orderId).update({
        'cancellation_request': requestData.toMap(),
        'status_history': FieldValue.arrayUnion([
          {
            'status': _order!.status,
            'timestamp': Timestamp.now(),
            'note': _t.cancellationRequestedNoteTemplate(_currentUserName, reason),
          }
        ]),
      });
      if (mounted) _showSnack(_t.cancellationRequestSubmitted);
      await _fetchOrder();
    } catch (e) {
      if (mounted) _showSnack(_t.cancellationRequestSubmitError(e.toString()), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmittingCancelAction = false);
    }
  }

  /// Admin/Owner/Manager menyetujui pengajuan employee -> status pesanan
  /// baru berubah jadi 'cancelled' di titik ini.
  Future<void> _approveCancellationRequest(_OrderDetailData order) async {
    setState(() => _isSubmittingCancelAction = true);
    try {
      // 1 update atomik, sama alasannya kayak _cancelOrderDirectly di atas.
      await _ordersRef.doc(widget.orderId).update({
        'status': 'cancelled',
        'status_history': FieldValue.arrayUnion([
          {
            'status': 'cancelled',
            'timestamp': Timestamp.now(),
            'note': _t.cancellationApprovedNoteTemplate(_currentUserName),
          }
        ]),
        'updated_at': FieldValue.serverTimestamp(),
        'cancellation_request.status': 'approved',
        'cancellation_request.reviewed_by_name': _currentUserName,
        'cancellation_request.reviewed_at': FieldValue.serverTimestamp(),
      });
      if (mounted) _showSnack(_t.cancellationRequestApproved);
      await _fetchOrder();
    } catch (e) {
      if (mounted) _showSnack(_t.cancellationRequestApproveError(e.toString()), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmittingCancelAction = false);
    }
  }

  /// Admin/Owner/Manager menolak pengajuan employee -> status pesanan
  /// TETAP jalan seperti biasa, cuma pengajuannya ditandai ditolak.
  Future<void> _rejectCancellationRequest(_OrderDetailData order) async {
    setState(() => _isSubmittingCancelAction = true);
    try {
      await _ordersRef.doc(widget.orderId).update({
        'cancellation_request.status': 'rejected',
        'cancellation_request.reviewed_by_name': _currentUserName,
        'cancellation_request.reviewed_at': FieldValue.serverTimestamp(),
        'status_history': FieldValue.arrayUnion([
          {
            'status': order.status,
            'timestamp': Timestamp.now(),
            'note': _t.cancellationRejectedNoteTemplate(_currentUserName),
          }
        ]),
      });
      if (mounted) _showSnack(_t.cancellationRequestRejected);
      await _fetchOrder();
    } catch (e) {
      if (mounted) _showSnack(_t.cancellationRequestRejectError(e.toString()), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmittingCancelAction = false);
    }
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
                          _order != null && _errorMessage == null && !_isLoading ? 150 : 24,
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
                                      if (_order!.hasPendingCancellationRequest) ...[
                                        const SizedBox(height: AppTheme.md),
                                        _buildCancellationRequestBanner(context, _order!),
                                      ] else if (_canCancelForStatus(_order!.status)) ...[
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
            _laundryName != null && _laundryName!.isNotEmpty ? _laundryName! : _t.receiptFallbackSubtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(fontSize: 12.5, color: _cOnSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Divider(color: _cOutlineVariant),
          const SizedBox(height: 12),
          _receiptRow(_t.receiptOrderNumberLabel, order.orderNumber),
          _receiptRow(_t.receiptDateLabel, _formatDate(order.orderDate)),
          _receiptRow(_t.receiptCustomerLabel, order.customerName),
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
          _receiptRow(_t.subtotalLabel, _formatCurrency(order.subtotal)),
          if (order.taxAmount > 0) _receiptRow(_t.taxLabel, _formatCurrency(order.taxAmount)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_t.totalLabel, style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w700, color: _cOnSurface)),
              Text(
                _formatCurrency(order.totalAmount),
                style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.w700, color: _cPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: _cOutlineVariant),
          const SizedBox(height: 12),
          _receiptRow(_t.receiptPaymentMethodLabel, _paymentMethodLabel(order.paymentMethodRaw)),
          _receiptRow(_t.receiptPaymentStatusLabel, _getPaymentStatusLabel(order.paymentStatus)),
          _receiptRow(_t.paidAmountLabel, _formatCurrency(order.paidAmount)),
          if (order.remainingAmount > 0) _receiptRow(_t.remainingBillLabel, _formatCurrency(order.remainingAmount)),
          const SizedBox(height: 20),
          Text(
            _t.receiptThankYouMessage,
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
                    _order != null ? _order!.orderNumber : _t.orderDetailTitle,
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
              child: Text(_t.orderRetryButtonLabel, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, color: _cPrimary)),
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
    final deliveryTypeLabel = order.isDelivery ? _t.orderDeliveryDelivery : _t.orderDeliverySelfPickup;
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
                      _t.orderStatusSectionLabel.toUpperCase(),
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
                        deliveryTypeLabel,
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
                  _t.orderCancelledTitle,
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
            _t.trackProgressTitle,
            style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w500, color: _cOnSurfaceVariant),
          ),
          if (order.assignedEmployeeName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _cPrimaryFixed.withOpacity(0.5),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_pin_circle_outlined, size: 14, color: _cOnPrimaryFixedVariant),
                  const SizedBox(width: 4),
                  Text(
                    _t.currentOperatorLabel(order.assignedEmployeeName),
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _cOnPrimaryFixedVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                              order.operatorForStatus(status) != null
                                  ? '${_formatDate(ts)}, ${_formatTime(ts)} · ${_t.activityLogByOperatorLabel(order.operatorForStatus(status)!)}'
                                  : '${_formatDate(ts)}, ${_formatTime(ts)}',
                              style: GoogleFonts.beVietnamPro(fontSize: 11, color: _cOnSurfaceVariant),
                            ),
                          ] else if (isCurrent) ...[
                            const SizedBox(height: 2),
                            Text(
                              order.assignedEmployeeName.isNotEmpty && _stagesRequiringOperator.contains(status)
                                  ? '${_activeStepNote(status)} · ${_t.activityLogByOperatorLabel(order.assignedEmployeeName)}'
                                  : _activeStepNote(status),
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
                _t.customerInfoSectionLabel.toUpperCase(),
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
                          _t.registeredBranchLabel.toUpperCase(),
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
        Expanded(child: _miniStatCard(icon: Icons.shopping_bag_outlined, label: _t.itemCountLabel, value: _t.itemCountValueTemplate(order.totalItemCount))),
        const SizedBox(width: AppTheme.sm),
        Expanded(child: _miniStatCard(icon: Icons.category_outlined, label: _t.serviceLabel, value: order.serviceSummary(_t.orderServiceMoreSuffix))),
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
              _miniStatCard(icon: Icons.shopping_bag_outlined, label: _t.itemCountLabel, value: _t.itemCountValueTemplate(order.totalItemCount)),
              const SizedBox(height: AppTheme.sm),
              _miniStatCard(icon: Icons.category_outlined, label: _t.serviceLabel, value: order.serviceSummary(_t.orderServiceMoreSuffix)),
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
            _t.costBreakdownSectionLabel.toUpperCase(),
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
                    Text(_t.subtotalLabel, style: GoogleFonts.beVietnamPro(fontSize: 13, color: _cSecondary)),
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
                      Text(_t.taxLabel, style: GoogleFonts.beVietnamPro(fontSize: 13, color: _cSecondary)),
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
                      Text(_t.totalBillLabel, style: GoogleFonts.beVietnamPro(fontSize: 13.5, fontWeight: FontWeight.w700, color: _cPrimary)),
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
                      _t.paymentSectionLabel.toUpperCase(),
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
                Text(_t.paidAmountLabel, style: GoogleFonts.beVietnamPro(fontSize: 13, color: _cOnSurfaceVariant)),
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
              Text(_t.remainingBillLabel, style: GoogleFonts.beVietnamPro(fontSize: 13, color: _cOnSurfaceVariant)),
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
                label: Text(_t.confirmPaymentButtonLabel, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 13)),
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
                  label: Text(_t.downloadReceiptButtonLabel, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 12.5)),
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
                  label: Text(_t.sendReceiptWhatsappButtonLabel, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 12.5)),
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
                _t.paymentHistorySectionLabel.toUpperCase(),
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
            _t.notesSectionLabel.toUpperCase(),
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
    final busy = _isUpdatingStatus || _isSubmittingCancelAction;
    return Center(
      child: TextButton.icon(
        onPressed: busy ? null : _confirmCancelOrder,
        icon: const Icon(Icons.cancel_outlined, size: 18, color: _cError),
        label: Text(
          _canCancelDirectly ? _t.cancelOrderButtonLabel : _t.submitCancellationRequestButtonLabel,
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 13.5, color: _cError),
        ),
      ),
    );
  }

  /// Banner pengajuan pembatalan yang masih menunggu approval. Buat
  /// Admin/Owner/Manager: tampil tombol Setujui/Tolak. Buat yang
  /// mengajukan (employee) atau role lain: cuma info status, gak ada
  /// tombol aksi.
  Widget _buildCancellationRequestBanner(BuildContext context, _OrderDetailData order) {
    final request = order.cancellationRequest;
    if (request == null) return const SizedBox.shrink();
    final busy = _isUpdatingStatus || _isSubmittingCancelAction;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cYellowBg,
        borderRadius: BorderRadius.circular(_rLg),
        border: Border.all(color: _cYellowText.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hourglass_top_rounded, size: 18, color: _cYellowText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _t.pendingCancellationApprovalTitle,
                  style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 13.5, color: _cYellowText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _t.requestedByLabel(request.requestedByName.isNotEmpty ? request.requestedByName : _t.employeeFallbackLabel),
            style: GoogleFonts.beVietnamPro(fontSize: 12.5, fontWeight: FontWeight.w600, color: _cOnSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            _t.reasonLabel(request.reason),
            style: GoogleFonts.beVietnamPro(fontSize: 12.5, color: _cOnSurfaceVariant, height: 1.5),
          ),
          if (_canCancelDirectly) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : () => _rejectCancellationRequest(order),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _cOnSurfaceVariant,
                      side: BorderSide(color: _cOutlineVariant),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_rXl)),
                    ),
                    child: Text(_t.rejectButtonLabel, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: busy ? null : () => _approveCancellationRequest(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cError,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_rXl)),
                    ),
                    child: busy
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_t.approveButtonLabel, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Buka CreateDeliveryScheduleScreen buat bikin RENCANA jadwal
  /// pengantaran (tanggal, jam, kurir, alamat) untuk order ini - status
  /// order TETAP 'ready', BELUM 'completed'. Order baru beneran ditandai
  /// selesai nanti kalau kurir klik "Tandai Sudah Diantar" di
  /// PickupDeliveryScreen (ConfirmDeliverySheet ->
  /// markDelivered(markAsCompleted:true)), bukan di titik ini.
  ///
  /// Order-nya udah pasti (dari widget.orderId), jadi dikirim lewat
  /// preselectedOrderId supaya CreateDeliveryScheduleScreen tidak perlu
  /// nyari/milih order lagi dari daftar - mode juga otomatis terkunci ke
  /// 'pengantaran'.
  Future<void> _openScheduleDeliverySheet(_OrderDetailData order, {bool isEditing = false}) async {
    final scheduled = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateDeliveryScheduleScreen(
          preselectedOrderId: widget.orderId,
        ),
      ),
    );

    if (scheduled == true) {
      _showSnack(isEditing ? _t.deliveryScheduleUpdateSuccess : _t.deliveryScheduleSuccess);
      await _fetchOrder();
    }
  }

  Widget _buildBottomActionBar(BuildContext context, _OrderDetailData order) {
    final nextStatus = _nextStatus(order.status);
    final nextLabel = _nextStatusButtonLabel(order.status);
    // Gating pembayaran - selama status 'ready' tapi belum lunas
    // (masih DP sebagian / paymentStatus != 'paid'), tombol aksi ready
    // (jadwalkan antar / kabari siap ambil) belum boleh dipencet.
    final isFullyPaid = order.paymentStatus == 'paid';
    final blockedByUnpaidAtReady = order.status == 'ready' && !isFullyPaid;
    // Khusus ready + delivery: tombol maju status diganti "Jadwalkan
    // Pengantaran" (buka CreateDeliveryScheduleScreen buat isi tanggal/jam
    // rencana antar), bukan "Tandai Selesai" biasa - penyelesaiannya baru
    // terjadi belakangan di PickupDeliveryScreen begitu kurir konfirmasi.
    final showScheduleDeliveryButton = order.status == 'ready' && order.isDelivery;
    // Order pickup yang barangnya belum beneran dijemput gak boleh
    // dimajukan lewat 'confirmed' - belum ada item/berat yang bisa
    // diproses sampai kurir menandai "Sudah Dijemput" di layar Antar
    // Jemput.
    final blockedByAwaitingPickup = order.isAwaitingPickup && order.status == 'confirmed';
    // Self-pickup di tahap 'ready' - HARUS kabarin pelanggan dulu lewat WA
    // sebelum bisa ditandai selesai. Begitu readyNotified == true (sudah
    // pernah tap tombol ini), baris ini jadi false, dan tombol otomatis
    // fallback ke tombol maju status normal ("Tandai Selesai").
    final showNotifyReadyPickupButton = order.status == 'ready' && !order.isDelivery && !order.readyNotified;

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
                        order.isDelivery ? _t.notifyReadyForDeliveryButtonLabel : _t.notifyViaWhatsappButtonLabel,
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
                else if (blockedByUnpaidAtReady)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _cYellowBg,
                      borderRadius: BorderRadius.circular(_rXl),
                      border: Border.all(color: _cYellowText.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.payments_outlined, size: 18, color: _cYellowText),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            order.isDelivery
                                ? 'Selesaikan pembayaran dulu sebelum bisa dijadwalkan diantar'
                                : 'Selesaikan pembayaran dulu sebelum bisa dikabari siap diambil',
                            style: GoogleFonts.beVietnamPro(fontSize: 12.5, fontWeight: FontWeight.w600, color: _cYellowText, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (showScheduleDeliveryButton)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: (_isUpdatingStatus || order.hasPendingCancellationRequest)
                          ? null
                          : () => _openScheduleDeliverySheet(order, isEditing: order.hasLogisticsSchedule),
                      icon: Icon(
                        order.hasLogisticsSchedule ? Icons.edit_calendar_outlined : Icons.local_shipping_outlined,
                        size: 18,
                      ),
                      label: Text(
                        order.hasLogisticsSchedule ? _t.editDeliveryScheduleButtonLabel : _t.scheduleDeliveryButtonLabel,
                        style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        // Warna beda dikit begitu udah dijadwalkan - biar
                        // sekilas kelihatan ini mode "ubah", bukan "buat
                        // baru", tanpa mesti baca teksnya dulu.
                        backgroundColor: order.hasLogisticsSchedule ? _cSecondary : _cPrimaryContainer,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_rXl)),
                      ),
                    ),
                  )
                else if (showNotifyReadyPickupButton)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: (_isUpdatingStatus || order.hasPendingCancellationRequest)
                          ? null
                          : () => _notifyReadyForPickup(order),
                      icon: const Icon(Icons.chat_outlined, size: 18),
                      label: Text(_t.notifyReadyForPickupButtonLabel, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cPrimaryContainer,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_rXl)),
                      ),
                    ),
                  )
                else if (nextStatus != null && nextLabel != null && blockedByAwaitingPickup)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _cYellowBg,
                      borderRadius: BorderRadius.circular(_rXl),
                      border: Border.all(color: _cYellowText.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined, size: 18, color: _cYellowText),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Menunggu baju dijemput dulu dari pelanggan',
                            style: GoogleFonts.beVietnamPro(fontSize: 12.5, fontWeight: FontWeight.w600, color: _cYellowText, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (nextStatus != null && nextLabel != null)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: (_isUpdatingStatus || order.hasPendingCancellationRequest)
                          ? null
                          : () => _handleAdvanceStatus(nextStatus, nextLabel),
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
                if (nextLabel != null || order.status == 'completed' || showScheduleDeliveryButton || blockedByUnpaidAtReady)
                  const SizedBox(height: AppTheme.sm),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _contactCustomerWhatsapp(order),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: Text(_t.contactCustomerButtonLabel, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 13.5)),
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
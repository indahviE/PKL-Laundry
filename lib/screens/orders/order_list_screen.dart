import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/themes/app_theme.dart';
import '../../l10n/app_localizations.dart';

// ============================================
// DESIGN TOKENS (dari DESIGN.md / code.html referensi)
// Di-hardcode di sini biar tampilan layar ini benar-benar presisi
// sama referensi desain, terlepas dari nilai di AppTheme.
// ============================================
const Color _cSurface = Color(0xFFFBF9F8);
const Color _cCard = Color(0xFFFFFFFF);
const Color _cOnSurface = Color(0xFF1B1C1C);
const Color _cOnSurfaceVariant = Color(0xFF404752);
const Color _cOutlineVariant = Color(0xFFBFC7D4);
const Color _cPrimary = Color(0xFF0061A4); // teks/aksen di atas card
const Color _cPrimaryContainer = Color(0xFF2196F3); // tombol/aksi
const Color _cSurfaceContainerHighest = Color(0xFFE4E2E1); // chip "Semua"
const Color _cSecondaryContainer = Color(0xFFE0E3E6); // empty state bg
const Color _cOnSecondaryContainer = Color(0xFF626567); // empty state icon
const Color _cError = Color(0xFFBA1A1A);

/// Palet status: dipetakan ke warna Tailwind (yellow/blue/purple/green/red)
/// sesuai referensi HTML (filter chip status & status pill di order card).
class _StatusStyle {
  final Color chipBg; // dipakai untuk filter chip (versi -50)
  final Color chipBorder; // filter chip (versi -200)
  final Color chipText; // filter chip (versi -800)
  final Color pillBg; // status pill di card (versi -100)
  final Color pillText; // status pill di card (versi -700)

  const _StatusStyle({
    required this.chipBg,
    required this.chipBorder,
    required this.chipText,
    required this.pillBg,
    required this.pillText,
  });
}

const _statusYellow = _StatusStyle(
  chipBg: Color(0xFFFEFCE8),
  chipBorder: Color(0xFFFEF08A),
  chipText: Color(0xFF854D0E),
  pillBg: Color(0xFFFEF9C3),
  pillText: Color(0xFFA16207),
);
const _statusBlue = _StatusStyle(
  chipBg: Color(0xFFEFF6FF),
  chipBorder: Color(0xFFBFDBFE),
  chipText: Color(0xFF1E40AF),
  pillBg: Color(0xFFDBEAFE),
  pillText: Color(0xFF1D4ED8),
);
const _statusPurple = _StatusStyle(
  chipBg: Color(0xFFFAF5FF),
  chipBorder: Color(0xFFE9D5FF),
  chipText: Color(0xFF6B21A8),
  pillBg: Color(0xFFF3E8FF),
  pillText: Color(0xFF7E22CE),
);
const _statusGreen = _StatusStyle(
  chipBg: Color(0xFFF0FDF4),
  chipBorder: Color(0xFFBBF7D0),
  chipText: Color(0xFF166534),
  pillBg: Color(0xFFDCFCE7),
  pillText: Color(0xFF15803D),
);
const _statusRed = _StatusStyle(
  chipBg: Color(0xFFFEF2F2),
  chipBorder: Color(0xFFFECACA),
  chipText: Color(0xFF991B1B),
  pillBg: Color(0xFFFEE2E2),
  pillText: Color(0xFFB91C1C),
);

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
  final String orderType; // 'walk_in' / 'pickup' -> cara baju MASUK
  final String deliveryType; // 'self_pickup' / 'delivery' -> cara baju KELUAR
  final String laundryId; // cabang tempat order ini dibuat
  final String serviceSummary; // ringkasan nama layanan, dari items[].service_name
  final int serviceCount; // jumlah unique services untuk suffix "+X lainnya"

  OrderItem({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.status,
    required this.amount,
    required this.itemCount,
    required this.date,
    required this.customerPhone,
    required this.orderType,
    required this.deliveryType,
    required this.laundryId,
    required this.serviceSummary,
    required this.serviceCount,
  });

  /// Mapping dari dokumen Firestore users/{uid}/orders/{orderId}
  /// sesuai skema di PRD (bagian 3.4.1 Struktur Data Pesanan)
  factory OrderItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final orderDate = data['order_date'];

    // Nama layanan disimpan per-baris di dalam array `items`
    // (items[].service_name), bukan field terpisah di level order -
    // sama persis skema yang dipakai OrderDetailScreen (_OrderLineItem).
    final rawItems = (data['items'] as List?) ?? [];
    final serviceNames = rawItems
        .map((e) => (Map<String, dynamic>.from(e as Map)['service_name'] ?? '') as String)
        .where((name) => name.isNotEmpty)
        .toList();
    // Hanya simpan nama layanan pertama (untuk tampilan di card)
    // Suffix "+X lainnya" akan dihandle di UI dengan localization
    final serviceSummary = serviceNames.isEmpty
        ? '-'
        : serviceNames.first;

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
      orderType: (data['order_type'] ?? 'walk_in') as String,
      deliveryType: (data['delivery_type'] ?? 'self_pickup') as String,
      laundryId: (data['laundry_id'] ?? '') as String,
      serviceSummary: serviceSummary,
      serviceCount: serviceNames.length,
    );
  }

  bool get isPickup => orderType == 'pickup';
  bool get isDelivery => deliveryType == 'delivery';

  String orderTypeLabel(AppLocalizations t) => isPickup ? t.orderTypePickup : t.orderTypeWalkIn;
  IconData get orderTypeIcon => isPickup ? Icons.call_received_rounded : Icons.storefront_outlined;

  String deliveryTypeLabel(AppLocalizations t) => isDelivery ? t.orderDeliveryDelivery : t.orderDeliverySelfPickup;
  IconData get deliveryTypeIcon => isDelivery ? Icons.call_made_rounded : Icons.storefront_outlined;
}

/// Opsi cabang buat filter chip, di-fetch dari users/{uid}/laundries
/// (sesuai Blueprint §3.2.3), sama pola dengan CreateOrderScreen.
class _LaundryOption {
  final String id;
  final String name;

  _LaundryOption({required this.id, required this.name});

  factory _LaundryOption.fromFirestore(DocumentSnapshot doc, AppLocalizations t) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return _LaundryOption(
      id: doc.id,
      name: (data['name'] ?? t.unnamedBranchFallback) as String,
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

  // Filter cabang - 'all' berarti tampilkan semua cabang sekaligus
  // (termasuk order lama yang laundry_id-nya masih kosong). Chip
  // filter cuma ditampilkan kalau owner punya > 1 cabang aktif (lihat
  // _showLaundryFilter), sama pola persis dengan CustomersListScreen.
  List<_LaundryOption> _laundriesList = [];
  String _selectedLaundryId = 'all';

  bool get _showLaundryFilter => _laundriesList.length > 1;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _fetchLaundries();
    _listenToOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _ordersSubscription?.cancel();
    super.dispose();
  }

  /// Ambil semua cabang aktif milik company ini, buat isi chip filter
  /// (cuma ditampilkan kalau > 1, lihat _showLaundryFilter) dan juga
  /// buat resolve nama cabang yang ditampilkan di tiap order card.
  Future<void> _fetchLaundries() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      final companiesSnap = await userDocRef.collection('companies').limit(1).get();
      if (companiesSnap.docs.isEmpty) return;
      final companyId = companiesSnap.docs.first.id;

      final laundriesSnap = await userDocRef
          .collection('laundries')
          .where('company_id', isEqualTo: companyId)
          .where('is_active', isEqualTo: true)
          .get();

      if (mounted) {
        final t = AppLocalizations.of(context)!;
        setState(() {
          _laundriesList = laundriesSnap.docs.map((d) => _LaundryOption.fromFirestore(d, t)).toList();
        });
      }
    } catch (_) {
      // Diamkan - kalau gagal, filter cabang cuma gak muncul (tetap
      // fallback ke "Semua Cabang" karena _selectedLaundryId null).
      // List order utama tidak terganggu oleh kegagalan ini.
    }
  }

  /// Resolve nama cabang dari laundryId, buat ditampilkan di order card.
  /// Fallback ke '-' kalau kosong / belum ke-load.
  String _laundryNameFor(String laundryId) {
    if (laundryId.isEmpty) return '-';
    for (final l in _laundriesList) {
      if (l.id == laundryId) return l.name;
    }
    return '-';
  }

  /// Subscribe realtime ke users/{uid}/orders di Firestore.
  /// Begitu CreateOrderScreen nulis dokumen baru, list ini
  /// otomatis ke-update tanpa perlu manual refresh.
  void _listenToOrders() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = AppLocalizations.of(context)!.sessionExpiredError;
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

  /// Status-status mentah (dari OrderStatus enum) yang masuk kelompok
  /// "Diproses" di UI - staff gak perlu breakdown per tahap (dicuci/
  /// dikeringkan/disetrika/dst), cukup tau order lagi "diproses".
  static const List<String> _inProgressStatuses = [
    'inProgress',
    'washing',
    'drying',
    'ironing',
    'qualityCheck',
  ];

  /// Filter dan search orders
  void _applyFiltersAndSearch() {
    _filteredOrders = _allOrders.where((order) {
      bool statusMatch;
      if (_selectedFilter == 'all') {
        statusMatch = true;
      } else if (_selectedFilter == 'inProgress') {
        statusMatch = _inProgressStatuses.contains(order.status);
      } else {
        statusMatch = order.status == _selectedFilter;
      }

      // 'all' -> "Semua Cabang", jadi semua order lolos filter cabang.
      bool laundryMatch = _selectedLaundryId == 'all' || order.laundryId == _selectedLaundryId;

      bool searchMatch = _searchController.text.isEmpty ||
          order.customerName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          order.orderNumber.toLowerCase().contains(_searchController.text.toLowerCase());
      return statusMatch && laundryMatch && searchMatch;
    }).toList();
    setState(() {});
  }

  /// Buka Create Order screen. List sudah realtime lewat
  /// snapshots(), jadi begitu order baru tersimpan, dia
  /// otomatis muncul di sini tanpa perlu logic refresh manual.
  Future<void> _openCreateOrder(BuildContext context) async {
    await context.push<bool>('/orders/create');
  }

  /// Palet status (chip filter + status pill) - disamain sama referensi
  /// desain (yellow/blue/purple/green/red).
  _StatusStyle _statusStyle(String status) {
    switch (status) {
      case 'pending':
        return _statusYellow;
      case 'confirmed':
        return _statusPurple;
      case 'inProgress':
      case 'washing':
      case 'drying':
      case 'ironing':
      case 'qualityCheck':
        return _statusBlue;
      case 'ready':
        return _statusPurple;
      case 'completed':
        return _statusGreen;
      case 'cancelled':
        return _statusRed;
      default:
        return _statusBlue;
    }
  }

  /// Get status label
  String _getStatusLabel(String status, AppLocalizations t) {
    switch (status) {
      case 'pending':
        return t.orderStatusWaiting;
      case 'confirmed':
        return t.orderStatusConfirmed;
      case 'inProgress':
        return t.orderStatusProcessing;
      case 'washing':
        return t.orderStatusWashing;
      case 'drying':
        return t.orderStatusDrying;
      case 'ironing':
        return t.orderStatusIroning;
      case 'qualityCheck':
        return t.orderStatusQualityCheck;
      case 'ready':
        return t.orderStatusReady;
      case 'completed':
        return t.orderCompletedStatus;
      case 'cancelled':
        return t.orderCancelledStatus;
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
                        _buildHeader(context, isMobile),
                        const SizedBox(height: AppTheme.lg),
                        _buildSearchBar(context),
                        const SizedBox(height: AppTheme.md),
                        if (_showLaundryFilter) ...[
                          _buildLaundryFilterButtons(context),
                          const SizedBox(height: AppTheme.sm),
                        ],
                        _buildFilterButtons(context),
                        const SizedBox(height: AppTheme.lg),
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

  /// Header - versi flat sesuai referensi: icon outline + judul, warna
  /// primary, tanpa kotak/box di belakang icon, tanpa subtitle. Tombol
  /// tambah bulat (primary-container) di kanan.
  Widget _buildHeader(BuildContext context, bool isMobile) {
    final t = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.local_laundry_service_outlined,
          color: _cPrimary,
          size: 24,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            t.ordersListTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.beVietnamPro(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: _cPrimary,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.md),
        _AddButton(onTap: () => _openCreateOrder(context), isMobile: isMobile, label: t.newOrderButtonLabel),
      ],
    );
  }

  /// Build search bar - tanpa tinggi container yang dipaksa, biar
  /// TextField (isDense) yang atur tinggi natural-nya sendiri (~44px),
  /// jadi ga kelihatan gemuk atau ikonnya nggak center.
  Widget _buildSearchBar(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _cCard,
        border: Border.all(color: _cOutlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => _applyFiltersAndSearch(),
        cursorColor: _cPrimary,
        style: GoogleFonts.beVietnamPro(fontSize: 13.5, color: _cOnSurface),
        decoration: InputDecoration(
          isDense: true,
          hintText: t.searchOrderHint,
          hintStyle: GoogleFonts.beVietnamPro(fontSize: 13.5, color: const Color(0xFF707883)),
          prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF707883)),
          prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
        ),
      ),
    );
  }

  /// Filter chip CABANG - pill penuh (rounded-full). Selected = solid
  /// primary + teks putih, unselected = putih + border outline-variant.
  /// Cuma dirender kalau _showLaundryFilter true (cabang > 1).
  Widget _buildLaundryFilterButtons(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildLaundryChip(
            label: t.allBranchesLabel,
            isSelected: _selectedLaundryId == 'all',
            onTap: () {
              setState(() => _selectedLaundryId = 'all');
              _applyFiltersAndSearch();
            },
          ),
          ..._laundriesList.map((laundry) {
            return Padding(
              padding: const EdgeInsets.only(left: AppTheme.sm),
              child: _buildLaundryChip(
                label: laundry.name,
                isSelected: _selectedLaundryId == laundry.id,
                onTap: () {
                  setState(() => _selectedLaundryId = laundry.id);
                  _applyFiltersAndSearch();
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLaundryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? _cPrimary : _cCard,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: isSelected ? _cPrimary : _cOutlineVariant),
          ),
          child: Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.02,
              color: isSelected ? Colors.white : _cOnSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  /// Filter chip STATUS - selalu bertona warna sesuai statusnya (persis
  /// referensi: kuning Menunggu, biru Diproses, ungu Siap Diambil, hijau
  /// Selesai, merah Dibatalkan). "Semua" pakai netral surface-container.
  /// Yang lagi aktif ditebalkan border & warna latarnya.
  Widget _buildFilterButtons(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final filters = <(String, String)>[
      ('all', t.filterAllLabel),
      ('pending', t.orderStatusWaiting),
      ('inProgress', t.orderStatusProcessing),
      ('ready', t.orderStatusReady),
      ('completed', t.orderCompletedStatus),
      ('cancelled', t.orderCancelledStatus),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTheme.sm),
        itemBuilder: (context, index) {
          final key = filters[index].$1;
          final label = filters[index].$2;
          final isSelected = _selectedFilter == key;
          final isAll = key == 'all';
          final style = isAll ? null : _statusStyle(key);

          final bg = isAll ? _cSurfaceContainerHighest : style!.chipBg;
          final border = isAll ? Colors.transparent : style!.chipBorder;
          final text = isAll ? _cOnSurface : style!.chipText;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() => _selectedFilter = key);
                _applyFiltersAndSearch();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: border,
                    width: isSelected && !isAll ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.02,
                    color: text,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppTheme.xxl),
        child: CircularProgressIndicator(color: _cPrimary),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.xxl),
        child: Column(
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
              onPressed: _listenToOrders,
              child: Text(t.orderRetryButtonLabel, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, color: _cPrimary)),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state - lingkaran secondary-container + icon, sesuai referensi.
  Widget _buildEmptyState(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    // Beda pesan kalau kosong gara-gara filter cabang lagi aktif (bukan
    // benar-benar belum ada order sama sekali), sama pola dengan
    // CustomersListScreen.
    final isFilteredByLaundry = _selectedLaundryId != 'all';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
        child: Column(
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: const BoxDecoration(
                color: _cSecondaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_basket_outlined,
                size: 56,
                color: _cOnSecondaryContainer,
              ),
            ),
            const SizedBox(height: AppTheme.lg),
            Text(
              isFilteredByLaundry ? t.orderNoOrdersInBranch : t.orderNoOrdersLabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.01,
                color: _cOnSurface,
              ),
            ),
            const SizedBox(height: AppTheme.sm),
            Text(
              isFilteredByLaundry
                  ? t.orderSuggestNewOrChangeBranch
                  : t.orderCreateOrderButtonLabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                color: _cOnSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.xl),
            ElevatedButton.icon(
              onPressed: () => _openCreateOrder(context),
              icon: const Icon(Icons.note_add_outlined, size: 18),
              label: Text(t.orderCreateOrderButtonLabel, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _cPrimaryContainer,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.xl, vertical: AppTheme.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
    final t = AppLocalizations.of(context)!;
    return Column(
      children: List.generate(
        _filteredOrders.length,
        (index) {
          final order = _filteredOrders[index];
          final style = _statusStyle(order.status);
          return Column(
            children: [
              _OrderCard(
                order: order,
                pillBg: style.pillBg,
                pillText: style.pillText,
                statusLabel: _getStatusLabel(order.status, t),
                formattedAmount: _formatCurrency(order.amount),
                formattedDate: _formatDate(order.date),
                cabangName: _laundryNameFor(order.laundryId),
                onTap: () => context.push('/orders/${order.id}'),
                t: t,
              ),
              if (index < _filteredOrders.length - 1) const SizedBox(height: AppTheme.md),
            ],
          );
        },
      ),
    );
  }
}

// ============================================
// HELPER WIDGETS
// ============================================

/// Tombol tambah pesanan. Di mobile: bulat, icon-only (persis referensi
/// desain — 40x40, bg primary-container). Di desktop: pill icon+label
/// biar lebih jelas, tetap warna primary-container.
class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isMobile;
  final String label;

  const _AddButton({required this.onTap, required this.isMobile, required this.label});

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Material(
        color: _cPrimaryContainer,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.add, color: Colors.white, size: 22),
          ),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add, size: 18),
      label: Text(label, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, fontSize: 13.5)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _cPrimaryContainer,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.lg, vertical: AppTheme.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

/// Satu baris kecil icon + label buat info grid di order card
/// (cabang, tanggal, cara masuk, cara keluar).
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool alignEnd;

  const _InfoRow({required this.icon, required this.label, this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    if (alignEnd) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.beVietnamPro(fontSize: 13, color: _cOnSurfaceVariant),
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 18, color: _cOnSurfaceVariant),
        ],
      );
    }
    return Row(
      children: [
        Icon(icon, size: 18, color: _cOnSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.beVietnamPro(fontSize: 13, color: _cOnSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// Order Card Widget - dibuat presisi sama referensi desain:
/// nomor order (primary, bold) di atas nama pelanggan (headline-md),
/// status pill bulat berwarna di kanan atas, info grid 2 kolom (cabang,
/// tanggal, cara masuk, cara keluar), lalu divider + total pembayaran,
/// dengan shadow & radius sesuai token desain.
class _OrderCard extends StatelessWidget {
  final OrderItem order;
  final Color pillBg;
  final Color pillText;
  final String statusLabel;
  final String formattedAmount;
  final String formattedDate;
  final String cabangName;
  final VoidCallback onTap;
  final AppLocalizations t;

  const _OrderCard({
    required this.order,
    required this.pillBg,
    required this.pillText,
    required this.statusLabel,
    required this.formattedAmount,
    required this.formattedDate,
    required this.cabangName,
    required this.onTap,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: no. order + nama pelanggan (kiri), status pill (kanan)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _cPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.customerName,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w600,
                          color: _cOnSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel.toUpperCase(),
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: pillText,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Info grid 2x2: cabang & tanggal, lalu cara masuk & cara keluar.
            // Kolom kanan (tanggal / item) dirender rata kanan (alignEnd)
            // biar nempel ke ujung kanan card, sesuai referensi desain
            // (bukan ngambang deket tengah).
            Row(
              children: [
                Expanded(child: _InfoRow(icon: Icons.location_on_outlined, label: cabangName)),
                const SizedBox(width: AppTheme.sm),
                Expanded(child: _InfoRow(icon: Icons.calendar_today_outlined, label: formattedDate, alignEnd: true)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _InfoRow(
                    icon: Icons.dry_cleaning_outlined,
                    label: order.serviceCount > 1
                        ? '${order.serviceSummary} +${order.serviceCount - 1} ${t.orderServiceMoreSuffix}'
                        : order.serviceSummary,
                  ),
                ),
                const SizedBox(width: AppTheme.sm),
                Expanded(
                  child: _InfoRow(
                    icon: Icons.shopping_bag_outlined,
                    label: '${order.itemCount} ${t.orderItemsLabel}',
                    alignEnd: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: _cOutlineVariant.withOpacity(0.3)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.orderTotalPaymentLabel,
                  style: GoogleFonts.beVietnamPro(fontSize: 13, color: _cOnSurfaceVariant),
                ),
                Text(
                  formattedAmount,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _cPrimary,
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
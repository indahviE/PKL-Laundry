import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/themes/app_theme.dart';
import '../../l10n/app_localizations.dart';

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
      orderType: (data['order_type'] ?? 'walk_in') as String,
      deliveryType: (data['delivery_type'] ?? 'self_pickup') as String,
      laundryId: (data['laundry_id'] ?? '') as String,
    );
  }

  // Helper buat pill "baju masuk" & "baju keluar" - style disamain
  // dengan _OrderLogisticsCard di PickupDeliveryScreen biar konsisten.
  bool get isPickup => orderType == 'pickup';
  bool get isDelivery => deliveryType == 'delivery';

  String get orderTypeLabel => isPickup ? 'Dijemput' : 'Walk-in';
  IconData get orderTypeIcon => isPickup ? Icons.call_received_rounded : Icons.storefront_outlined;
  Color get orderTypeColor => isPickup ? const Color(0xFFB197FC) : AppTheme.textTertiary;

  String get deliveryTypeLabel => isDelivery ? 'Diantar' : 'Ambil Sendiri';
  IconData get deliveryTypeIcon => isDelivery ? Icons.call_made_rounded : Icons.storefront_outlined;
  Color get deliveryTypeColor => isDelivery ? AppTheme.primaryColor : const Color(0xFF51CF66);
}

/// Opsi cabang buat filter chip, di-fetch dari users/{uid}/laundries
/// (sesuai Blueprint §3.2.3), sama pola dengan CreateOrderScreen.
class _LaundryOption {
  final String id;
  final String name;

  _LaundryOption({required this.id, required this.name});

  factory _LaundryOption.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return _LaundryOption(
      id: doc.id,
      name: (data['name'] ?? 'Cabang Tanpa Nama') as String,
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
  /// (cuma ditampilkan kalau > 1, lihat _showLaundryFilter).
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
        setState(() {
          _laundriesList = laundriesSnap.docs.map((d) => _LaundryOption.fromFirestore(d)).toList();
        });
      }
    } catch (_) {
      // Diamkan - kalau gagal, filter cabang cuma gak muncul (tetap
      // fallback ke "Semua Cabang" karena _selectedLaundryId null).
      // List order utama tidak terganggu oleh kegagalan ini.
    }
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
  String _getStatusLabel(String status, AppLocalizations t) {
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
                        if (_showLaundryFilter) ...[
                          const SizedBox(height: AppTheme.md),
                          _buildLaundryFilterButtons(context),
                        ],
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
    final t = AppLocalizations.of(context)!;
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
                t.ordersListTitle,
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
                t.ordersListSubtitle,
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
              t.newOrderButtonLabel,
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
    final t = AppLocalizations.of(context)!;
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
          hintText: t.searchOrderHint,
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

  /// Build filter chip CABANG - baris terpisah di bawah filter status,
  /// cuma dirender kalau _showLaundryFilter true (cabang > 1). Chip
  /// pertama selalu "Semua Cabang", sisanya sesuai nama cabang aktif.
  /// Pola sama persis dengan CustomersListScreen.
  Widget _buildLaundryFilterButtons(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.md),
            child: _buildLaundryChip(
              label: 'Semua Cabang',
              isSelected: _selectedLaundryId == 'all',
              onTap: () {
                setState(() => _selectedLaundryId = 'all');
                _applyFiltersAndSearch();
              },
            ),
          ),
          ..._laundriesList.map((laundry) {
            final isLast = laundry.id == _laundriesList.last.id;
            return Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : AppTheme.md),
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
    return FilterChip(
      selected: isSelected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storefront_outlined, size: 15),
          const SizedBox(width: AppTheme.sm),
          Text(label),
        ],
      ),
      backgroundColor: AppTheme.cardColor,
      selectedColor: AppTheme.primaryColor.withOpacity(0.12),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor.withOpacity(0.4) : AppTheme.borderColor,
      ),
      labelStyle: GoogleFonts.poppins(
        fontSize: 12.5,
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Build filter buttons
  Widget _buildFilterButtons(BuildContext context) {
  final filters = [
    ('all', 'Semua', Icons.all_inbox_outlined),
    ('pending', 'Menunggu', Icons.schedule_outlined),
    ('inProgress', 'Diproses', Icons.local_laundry_service_outlined),
    ('ready', 'Siap Diambil', Icons.inventory_2_outlined),
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
                  Flexible(
                    child: Text(
                      filters[index].$2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
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
    final t = AppLocalizations.of(context)!;
    final totalOrders = _filteredOrders.length;
    final totalAmount = _filteredOrders.fold<double>(
      0,
      (sum, order) => sum + order.amount,
    );

    return Row(
      children: [
        Expanded(
          child: _StatBox(
            title: t.orderTotalOrdersLabel,
            value: '$totalOrders',
            icon: Icons.receipt_outlined,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: AppTheme.lg),
        Expanded(
          child: _StatBox(
            title: t.orderTotalRevenueLabel,
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
    final t = AppLocalizations.of(context)!;
    // Beda pesan kalau kosong gara-gara filter cabang lagi aktif (bukan
    // benar-benar belum ada order sama sekali), sama pola dengan
    // CustomersListScreen.
    final isFilteredByLaundry = _selectedLaundryId != 'all';

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
              isFilteredByLaundry ? 'Belum ada pesanan di cabang ini' : t.orderNoOrdersLabel,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.sm),
            Text(
              isFilteredByLaundry
                  ? 'Coba pilih cabang lain, atau buat pesanan baru untuk cabang ini.'
                  : 'Buat pesanan baru untuk memulai',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.xl),
            ElevatedButton.icon(
              onPressed: () => _openCreateOrder(context),
              icon: const Icon(Icons.note_add_outlined, size: 18),
              label: Text(t.orderCreateOrderButtonLabel, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
    final t = AppLocalizations.of(context)!;
    return Column(
      children: List.generate(
        _filteredOrders.length,
        (index) => Column(
          children: [
            _OrderCard(
              order: _filteredOrders[index],
              statusColor: _getStatusColor(_filteredOrders[index].status),
              statusLabel: _getStatusLabel(_filteredOrders[index].status, t),
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

/// Pill kecil buat nunjukkin 1 atribut order (cara baju masuk / keluar).
/// Style disamain persis dengan _Pill di PickupDeliveryScreen supaya
/// konsisten secara visual di kedua layar.
class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Pill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.sm, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

/// Order Card Widget — sama persis gayanya dengan CustomerCard.
/// Sekarang ada tambahan 2 pill (baju masuk & baju keluar) yang
/// dibaca langsung dari order.orderType / order.deliveryType, yang
/// udah ditentuin pas order dibuat di CreateOrderScreen.
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.customerName,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.sm),
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
            const SizedBox(height: AppTheme.sm),
            // Pill "baju masuk" (walk-in/dijemput) & "baju keluar"
            // (ambil sendiri/diantar) - dibungkus Wrap biar otomatis
            // pindah baris di layar sempit.
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Pill(icon: order.orderTypeIcon, label: order.orderTypeLabel, color: order.orderTypeColor),
                _Pill(icon: order.deliveryTypeIcon, label: order.deliveryTypeLabel, color: order.deliveryTypeColor),
              ],
            ),
            const SizedBox(height: AppTheme.md),
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
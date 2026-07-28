import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/themes/app_theme.dart';
import '../../models/employee.dart';
import '../../models/order.dart';
import '../../models/service.dart';
import '../../repositories/employee_repository.dart';
import '../../repositories/order_repository.dart';
import '../../repositories/service_repository.dart';
// Reuse OrderItemForm (model form item UI-only) dari CreateOrderScreen,
// supaya logika "1 item = layanan + qty/berat + subtotal" gak perlu
// ditulis dua kali. Class-nya memang public (tanpa underscore) di file
// asalnya justru supaya bisa dipakai ulang seperti ini.
import '../orders/create_order_screen.dart' show OrderItemForm;
// Layar untuk MEMBUAT rencana jadwal jemput/antar (beda dari layar ini yang
// menandai order SUDAH BENERAN dijemput/diantar). Dipakai oleh tombol
// "Tambah Jadwal" di bawah supaya kedua alur bisa diakses dari 1 tempat.
// TODO: sesuaikan path ini kalau lokasi filenya berbeda di project kamu.
import 'create_delivery_screen.dart';

/// Local design tokens matching the new "NetWash Utility System" design.
/// Disamakan dengan ServicesListScreen supaya seluruh alur Antar Jemput
/// (daftar + jadwalkan) senada dengan Kelola Layanan: kanvas abu kebiruan,
/// kartu putih dengan shadow lembut, dan font Be Vietnam Pro.
class _DS {
  static const canvas = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const onSurface = Color(0xFF1B1C1C);
  static const onSurfaceVariant = Color(0xFF404752);
  static const outlineVariant = Color(0xFFBFC7D4);

  static const navy = Color(0xFF0B3B66);
  static const primary = Color(0xFF0061A4);
  static const error = Color(0xFFDC2626);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static TextStyle headlineMd({Color? color}) => GoogleFonts.beVietnamPro(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: color ?? onSurface,
        letterSpacing: -0.2,
      );

  static TextStyle bodyMd({Color? color, FontWeight? weight}) => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: weight ?? FontWeight.w400,
        color: color ?? onSurface,
      );

  static TextStyle bodySm({Color? color, FontWeight? weight}) => GoogleFonts.beVietnamPro(
        fontSize: 12.5,
        fontWeight: weight ?? FontWeight.w400,
        color: color ?? onSurfaceVariant,
      );
}


/// Kategori tampilan untuk 1 order di layar Antar Jemput.
/// Ini turunan dari orderType/deliveryType/status/pickupDate/deliveryDate -
/// bukan field baru di Firestore, supaya tetap 1 sumber kebenaran: orders.
/// Layar ini sifatnya READ-ONLY terhadap order_type/delivery_type - kedua
/// field itu sudah ditentukan final saat order dibuat di CreateOrderScreen.
/// Satu-satunya aksi di sini adalah menandai jemput/antar sudah selesai.
enum _LogisticsCategory {
  needsPickup, // order_type: pickup, belum ada pickup_date
  needsDelivery, // delivery_type: delivery, status ready, belum ada delivery_date
  selfService, // walk-in + self-pickup, customer urus sendiri dari awal-akhir
  other, // sisanya: masih diproses, sudah selesai, atau dibatalkan
}

class PickupDeliveryScreen extends ConsumerStatefulWidget {
  const PickupDeliveryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PickupDeliveryScreen> createState() => _PickupDeliveryScreenState();
}

class _PickupDeliveryScreenState extends ConsumerState<PickupDeliveryScreen> {
  // Warna aksen kategori - dipakai juga oleh CreateDeliveryScheduleScreen
  // (mode toggle & ringkasan jadwal di sana pakai hex yang sama persis)
  // supaya kedua layar terasa 1 tema: ungu = penjemputan, warna primer =
  // pengantaran, hijau = self-service.
  static const _pickupAccent = Color(0xFFB197FC);
  static const _selfServiceAccent = Color(0xFF51CF66);

  late TextEditingController _searchController;
  String _selectedFilter = 'all';
  String? _updatingOrderId;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Status yang dianggap "cucian sudah kelar" -> siap masuk antrean antar.
  /// Pakai `ready` DAN `completed` karena alur klik "Selesai" di detail
  /// order bisa langsung loncat ke `completed` tanpa mampir ke `ready`
  /// dulu - kalau cuma ngecek `ready`, order yang sudah completed tapi
  /// belum ada delivery_date malah hilang dari sini padahal justru itu
  /// yang paling butuh dianter.
  static const _finishedStatuses = {
    OrderStatus.ready,
    OrderStatus.completed,
  };

  _LogisticsCategory _categorize(Order order) {
    if (order.needsPickup && order.pickupDate == null) {
      return _LogisticsCategory.needsPickup;
    }
    if (order.needsDelivery &&
        _finishedStatuses.contains(order.status) &&
        order.deliveryDate == null) {
      return _LogisticsCategory.needsDelivery;
    }
    // Sama seperti needsDelivery: baru dianggap "siap diambil" kalau
    // laundry-nya sudah kelar diproses & belum ditandai selesai diambil.
    // delivery_date dipakai ulang sebagai "tanggal keluar dari toko",
    // karena field ini memang tidak dipakai driver untuk order full
    // self-service.
    if (order.isFullySelfService &&
        _finishedStatuses.contains(order.status) &&
        order.deliveryDate == null) {
      return _LogisticsCategory.selfService;
    }
    return _LogisticsCategory.other;
  }

  Color _categoryColor(_LogisticsCategory category) {
    switch (category) {
      case _LogisticsCategory.needsPickup:
        return _pickupAccent;
      case _LogisticsCategory.needsDelivery:
        return _DS.primary;
      case _LogisticsCategory.selfService:
        return _selfServiceAccent;
      case _LogisticsCategory.other:
        return _DS.onSurfaceVariant;
    }
  }

  IconData _categoryIcon(_LogisticsCategory category) {
    switch (category) {
      case _LogisticsCategory.needsPickup:
        return Icons.call_received_rounded;
      case _LogisticsCategory.needsDelivery:
        return Icons.call_made_rounded;
      case _LogisticsCategory.selfService:
        return Icons.storefront_outlined;
      case _LogisticsCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  String _categoryLabel(_LogisticsCategory category) {
    switch (category) {
      case _LogisticsCategory.needsPickup:
        return 'Menunggu dijemput';
      case _LogisticsCategory.needsDelivery:
        return 'Siap diantar';
      case _LogisticsCategory.selfService:
        return 'Siap diambil';
      case _LogisticsCategory.other:
        return _fallbackStatusLabel(null);
    }
  }

  String _fallbackStatusLabel(OrderStatus? status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Menunggu konfirmasi';
      case OrderStatus.confirmed:
        return 'Dikonfirmasi';
      case OrderStatus.inProgress:
      case OrderStatus.washing:
      case OrderStatus.drying:
      case OrderStatus.ironing:
      case OrderStatus.qualityCheck:
        return 'Dalam proses';
      case OrderStatus.ready:
        return 'Siap diambil';
      case OrderStatus.completed:
        return 'Selesai';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
      default:
        return 'Dalam proses';
    }
  }

  /// Order pickup di alur baru selalu dibuat TANPA item (lihat
  /// CreateOrderScreen: validasi item dilonggarin khusus orderType
  /// pickup). Jadi tombol "Tandai Sudah Dijemput" gak langsung nembak
  /// markPickedUp() kayak dulu - dibuka dulu bottom sheet buat isi item
  /// & berat, karena baru sekarang barangnya beneran ada di tangan
  /// karyawan dan bisa ditimbang.
  Future<void> _handlePickupTap(Order order) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ConfirmPickupSheet(order: order),
    );

    if (confirmed == true) {
      _showSnack('${order.orderNumber} ditandai sudah dijemput');
    }
  }

  /// Order dengan deliveryType == delivery butuh dicatat kurirnya dulu
  /// lewat sheet, supaya owner bisa pilih siapa yang bertugas. Order
  /// self-service (pelanggan ambil sendiri) tidak butuh kurir sama sekali,
  /// jadi langsung ditandai selesai tanpa membuka sheet.
  Future<void> _handleDeliveryTap(Order order) async {
    if (order.needsDelivery) {
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _ConfirmDeliverySheet(order: order),
      );
      if (confirmed == true) {
        _showSnack('${order.orderNumber} ditandai sudah diantar');
      }
    } else {
      await _markDelivered(order);
    }
  }

  Future<void> _markDelivered(Order order, {String? courierId, String? courierName}) async {
    setState(() => _updatingOrderId = order.id);
    try {
      await ref.read(orderRepositoryProvider).markDelivered(
            order.id,
            courierId: courierId,
            courierName: courierName,
          );
      if (mounted) {
        _showSnack('${order.orderNumber} ditandai sudah diantar');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Gagal update: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _updatingOrderId = null);
    }
  }

  /// Buka bottom sheet buat milih mode (penjemputan/pengantaran), lalu
  /// masuk ke CreateDeliveryScheduleScreen buat bikin RENCANA jadwal baru.
  /// Dipisah dari aksi "Tandai Sudah Dijemput/Diantar" di kartu order -
  /// ini murni buat menjadwalkan, bukan menandai order yang sudah ada
  /// selesai diproses.
  Future<void> _handleAddSchedule() async {
    final mode = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddScheduleModeSheet(
        pickupAccent: _pickupAccent,
        deliveryAccent: _DS.primary,
      ),
    );

    if (mode == null || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CreateDeliveryScheduleScreen(initialMode: mode)),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.beVietnamPro()),
        backgroundColor: isError ? _DS.error : null,
      ),
    );
  }

  List<Order> _applyFilters(List<Order> orders) {
    final query = _searchController.text.toLowerCase();
    return orders.where((order) {
      final category = _categorize(order);
      final filterMatch = switch (_selectedFilter) {
        'needs_pickup' => category == _LogisticsCategory.needsPickup,
        'needs_delivery' => category == _LogisticsCategory.needsDelivery,
        'self_service' => category == _LogisticsCategory.selfService,
        'other' => category == _LogisticsCategory.other,
        _ => true,
      };
      if (!filterMatch) return false;
      if (query.isEmpty) return true;
      final name = (order.customerName ?? '').toLowerCase();
      final number = order.orderNumber.toLowerCase();
      return name.contains(query) || number.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(_allOrdersStreamProvider);

    return Scaffold(
      backgroundColor: _DS.canvas,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleAddSchedule,
        backgroundColor: _DS.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: Text('Tambah Jadwal', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, fontSize: 13.5)),
      ),
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
                      // Ruang ekstra di bawah supaya konten terakhir tidak
                      // ketutup FloatingActionButton.
                      96,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, isMobile),
                        const SizedBox(height: 22),
                        _buildSearchBar(context),
                        const SizedBox(height: AppTheme.lg),
                        _buildFilterChips(context),
                        const SizedBox(height: AppTheme.xl),
                        ordersAsync.when(
                          data: (orders) => _buildContent(context, isMobile, orders),
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppTheme.xxl),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, _) => _buildErrorState(context, e.toString()),
                        ),
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

  Widget _buildContent(BuildContext context, bool isMobile, List<Order> allOrders) {
    final filtered = _applyFilters(allOrders);
    final needsPickupCount = allOrders.where((o) => _categorize(o) == _LogisticsCategory.needsPickup).length;
    final needsDeliveryCount = allOrders.where((o) => _categorize(o) == _LogisticsCategory.needsDelivery).length;
    final selfServiceCount = allOrders.where((o) => _categorize(o) == _LogisticsCategory.selfService).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsSummary(context, needsPickupCount, needsDeliveryCount, selfServiceCount),
        const SizedBox(height: AppTheme.xl),
        filtered.isEmpty ? _buildEmptyState(context) : _buildOrdersList(context, filtered),
      ],
    );
  }

  /// Header - di mobile ditumpuk vertikal (icon+judul di atas, tombol full
  /// width di bawah) supaya tidak overflow horizontal, karena subtitle
  /// tidak punya ruang wrap saat berbagi baris dengan tombol di layar sempit.
  Widget _buildHeader(BuildContext context, bool isMobile) {
    final titleRow = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _DS.surface,
              shape: BoxShape.circle,
              boxShadow: _DS.cardShadow,
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 20, color: _DS.navy),
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFD1E4FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.local_shipping_rounded, color: _DS.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Antar Jemput',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _DS.headlineMd(color: _DS.navy),
              ),
              const SizedBox(height: 2),
              Text(
                'Kelola jemput, antar & ambil sendiri',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.beVietnamPro(fontSize: 12.5, color: _DS.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );

    if (isMobile) {
      return titleRow;
    }

    return titleRow;
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [BoxShadow(color: _DS.primary.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.beVietnamPro(fontSize: 13.5, color: _DS.onSurface),
        decoration: InputDecoration(
          hintText: 'Cari nama pelanggan atau no. pesanan...',
          hintStyle: GoogleFonts.beVietnamPro(fontSize: 13.5, color: _DS.onSurfaceVariant),
          prefixIcon: Icon(Icons.search, color: _DS.onSurfaceVariant),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, size: 18, color: _DS.onSurfaceVariant),
                  onPressed: () => setState(() => _searchController.clear()),
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            borderSide: BorderSide(color: _DS.primary, width: 1.5),
          ),
          filled: true,
          fillColor: _DS.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.lg, vertical: AppTheme.md),
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final filters = [
      ('all', 'Semua', Icons.all_inbox_outlined, _DS.onSurfaceVariant),
      ('needs_pickup', 'Perlu dijemput', Icons.call_received_rounded, _pickupAccent),
      ('needs_delivery', 'Siap diantar', Icons.call_made_rounded, _DS.primary),
      ('self_service', 'Ambil sendiri', Icons.storefront_outlined, _selfServiceAccent),
      ('other', 'Lainnya', Icons.more_horiz_rounded, _DS.onSurfaceVariant),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTheme.sm),
        itemBuilder: (context, index) {
          final (id, label, icon, accent) = filters[index];
          final isSelected = _selectedFilter == id;
          return InkWell(
            onTap: () => setState(() => _selectedFilter = id),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: AppTheme.sm),
              decoration: BoxDecoration(
                color: isSelected ? accent.withOpacity(0.12) : _DS.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(
                  color: isSelected ? accent.withOpacity(0.45) : _DS.outlineVariant,
                  width: isSelected ? 1.4 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 15, color: isSelected ? accent : _DS.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? accent : _DS.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Stats pakai Wrap murni (tanpa hitung lebar manual) supaya tidak
  /// pernah overflow di layar sempit; tiap kartu punya minWidth dan akan
  /// otomatis pindah baris kalau ruangnya kurang.
  Widget _buildStatsSummary(BuildContext context, int needsPickup, int needsDelivery, int selfService) {
    final stats = [
      _StatCard(title: 'Perlu Dijemput', value: '$needsPickup', icon: Icons.call_received_rounded, color: _pickupAccent),
      _StatCard(title: 'Siap Diantar', value: '$needsDelivery', icon: Icons.call_made_rounded, color: _DS.primary),
      _StatCard(title: 'Ambil Sendiri', value: '$selfService', icon: Icons.storefront_outlined, color: _selfServiceAccent),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // 3 kolom kalau muat, kalau tidak turun ke 2 lalu 1.
        final minCardWidth = 140.0;
        final spacing = AppTheme.md;
        int columns = ((constraints.maxWidth + spacing) / (minCardWidth + spacing)).floor().clamp(1, 3);
        final cardWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: stats.map((s) => SizedBox(width: cardWidth, child: s)).toList(),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.xxl),
        child: Column(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(color: _DS.primary.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(Icons.local_shipping_outlined, size: 40, color: _DS.primary.withOpacity(0.6)),
            ),
            const SizedBox(height: AppTheme.lg),
            Text('Tidak ada pesanan', style: GoogleFonts.beVietnamPro(fontSize: 15, fontWeight: FontWeight.w600, color: _DS.onSurface)),
            const SizedBox(height: AppTheme.sm),
            Text(
              'Belum ada pesanan yang cocok dengan filter ini',
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(fontSize: 13, color: _DS.onSurfaceVariant),
            ),
            const SizedBox(height: AppTheme.lg),
            OutlinedButton.icon(
              onPressed: _handleAddSchedule,
              icon: Icon(Icons.add_rounded, size: 18, color: _DS.primary),
              label: Text('Tambah Jadwal', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, fontSize: 13, color: _DS.primary)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _DS.primary.withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.lg, vertical: AppTheme.sm),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: _DS.error),
            const SizedBox(height: AppTheme.md),
            Text(message, textAlign: TextAlign.center, style: GoogleFonts.beVietnamPro(fontSize: 13, color: _DS.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, List<Order> orders) {
    return Column(
      children: List.generate(orders.length, (index) {
        final order = orders[index];
        final category = _categorize(order);
        return Column(
          children: [
            _OrderLogisticsCard(
              order: order,
              category: category,
              categoryColor: _categoryColor(category),
              categoryIcon: _categoryIcon(category),
              categoryLabel: category == _LogisticsCategory.other ? _fallbackStatusLabel(order.status) : _categoryLabel(category),
              isUpdating: _updatingOrderId == order.id,
              onMarkPickedUp: () => _handlePickupTap(order),
              onMarkDelivered: () => _handleDeliveryTap(order),
            ),
            if (index < orders.length - 1) const SizedBox(height: AppTheme.md),
          ],
        );
      }),
    );
  }
}

/// Provider stream semua order milik user, dipakai layar ini untuk
/// dikategorikan client-side (lihat _LogisticsCategory).
final _allOrdersStreamProvider = StreamProvider.autoDispose<List<Order>>((ref) {
  return ref.watch(orderRepositoryProvider).getAllOrders();
});

/// Bottom sheet pilih mode buat tombol "Tambah Jadwal": penjemputan atau
/// pengantaran. Hasilnya (string mode) dikembalikan lewat Navigator.pop
/// supaya pemanggil bisa langsung push ke CreateDeliveryScheduleScreen
/// dengan initialMode yang sesuai.
class _AddScheduleModeSheet extends StatelessWidget {
  final Color pickupAccent;
  final Color deliveryAccent;

  const _AddScheduleModeSheet({required this.pickupAccent, required this.deliveryAccent});

  @override
  Widget build(BuildContext context) {
    // Dibungkus SingleChildScrollView + viewInsets/viewPadding bawah (sama
    // seperti _ConfirmPickupSheet & _ConfirmDeliverySheet di file ini),
    // supaya tidak overflow di layar pendek atau saat ada safe-area/gesture
    // bar di bawah (sempat overflow ~7px sebelum fix ini).
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + MediaQuery.of(context).viewPadding.bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: _DS.outlineVariant, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              Text(
                'Jadwalkan Antar Jemput',
                style: GoogleFonts.beVietnamPro(fontSize: 17, fontWeight: FontWeight.w700, color: _DS.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih mode jadwal yang mau dibuat',
                style: GoogleFonts.beVietnamPro(fontSize: 12.5, color: _DS.onSurfaceVariant),
              ),
              const SizedBox(height: AppTheme.lg),
              _modeTile(
                context,
                value: 'penjemputan',
                icon: Icons.call_received_rounded,
                accent: pickupAccent,
                title: 'Jadwalkan Penjemputan',
                subtitle: 'Untuk pesanan yang menunggu dijemput',
              ),
              const SizedBox(height: AppTheme.sm),
              _modeTile(
                context,
                value: 'pengantaran',
                icon: Icons.call_made_rounded,
                accent: deliveryAccent,
                title: 'Jadwalkan Pengantaran',
                subtitle: 'Untuk pesanan yang sudah siap diantar',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeTile(
    BuildContext context, {
    required String value,
    required IconData icon,
    required Color accent,
    required String title,
    required String subtitle,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.md),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: accent.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: accent.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.beVietnamPro(fontSize: 13.5, fontWeight: FontWeight.w700, color: _DS.onSurface)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.beVietnamPro(fontSize: 11.5, color: _DS.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: accent),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet konfirmasi jemput: pilih layanan + isi berat/qty, lalu
/// simpan lewat OrderRepository.confirmPickupWithItems() - atomic, sama
/// pola-nya dengan _EditServiceSheet & _showRecordPaymentDialog di layar
/// lain (state loading lokal, showModalBottomSheet, pop(true) kalau
/// sukses supaya pemanggil bisa nampilin snackbar).
class _ConfirmPickupSheet extends StatefulWidget {
  final Order order;

  const _ConfirmPickupSheet({required this.order});

  @override
  State<_ConfirmPickupSheet> createState() => _ConfirmPickupSheetState();
}

class _ConfirmPickupSheetState extends State<_ConfirmPickupSheet> {
  late final ServiceRepository _serviceRepository;
  List<Service> _services = [];
  List<OrderItemForm> _items = [];
  bool _isLoadingServices = true;
  String? _servicesError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _serviceRepository = ServiceRepository(userId: uid);
    _fetchServices();
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchServices() async {
    setState(() {
      _isLoadingServices = true;
      _servicesError = null;
    });
    try {
      final allServices = await _serviceRepository.streamServices().first;
      setState(() {
        _services = allServices.where((s) => s.isActive).toList();
        _isLoadingServices = false;
      });
    } catch (e) {
      setState(() {
        _servicesError = e.toString();
        _isLoadingServices = false;
      });
    }
  }

  double _servicePrice(Service service) {
    return service.pricingType == PricingType.perKg ? (service.pricePerKg ?? 0) : (service.pricePerItem ?? 0);
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  void _pickService() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text('Pilih Layanan', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, color: _DS.onSurface)),
        content: SizedBox(
          width: double.maxFinite,
          child: _services.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Belum ada layanan aktif.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.beVietnamPro(fontSize: 12.5, color: _DS.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final service = _services[index];
                    final price = _servicePrice(service);
                    final suffix = service.pricingType == PricingType.perKg ? '/kg' : '/item';
                    return ListTile(
                      title: Text(service.name, style: GoogleFonts.beVietnamPro(fontSize: 13.5, fontWeight: FontWeight.w500)),
                      subtitle: Text('${_formatCurrency(price)}$suffix', style: GoogleFonts.beVietnamPro(fontSize: 12, color: _DS.onSurfaceVariant)),
                      onTap: () {
                        setState(() {
                          _items.add(
                            OrderItemForm(
                              id: service.id,
                              name: service.name,
                              pricingType: service.pricingType,
                              quantity: 1,
                              weight: service.pricingType == PricingType.perKg ? 1.0 : 0,
                              price: price,
                            ),
                          );
                        });
                        Navigator.pop(dialogContext);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('Tutup', style: GoogleFonts.beVietnamPro())),
        ],
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.subtotal);

  double get _totalWeight =>
      _items.where((i) => i.pricingType == PricingType.perKg).fold(0, (sum, item) => sum + item.weight);

  int get _totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  Future<void> _handleConfirm() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tambahkan minimal 1 item', style: GoogleFonts.beVietnamPro()), backgroundColor: _DS.error),
      );
      return;
    }

    for (final item in _items) {
      if (item.pricingType == PricingType.perKg && item.weight <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Isi berat (kg) untuk "${item.name}"', style: GoogleFonts.beVietnamPro()),
            backgroundColor: _DS.error,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Sesi tidak ditemukan, silakan login ulang.';

      final orderItems = _items
          .map((item) => OrderItem(
                serviceTypeId: item.id,
                serviceName: item.name,
                quantity: item.pricingType == PricingType.perKg ? 1 : item.quantity,
                weight: item.pricingType == PricingType.perKg ? item.weight : 0,
                pricePerUnit: item.price,
                totalPrice: item.subtotal,
              ))
          .toList();

      await OrderRepository(userId: user.uid).confirmPickupWithItems(
        widget.order.id,
        items: orderItems,
        totalWeight: _totalWeight,
        totalItems: _totalItems,
        subtotal: _subtotal,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal konfirmasi: $e', style: GoogleFonts.beVietnamPro()), backgroundColor: _DS.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: _DS.outlineVariant, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              Text(
                'Konfirmasi Jemput',
                style: GoogleFonts.beVietnamPro(fontSize: 19, fontWeight: FontWeight.w700, color: _DS.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Catat item & berat cucian ${widget.order.customerName ?? "pelanggan"} (${widget.order.orderNumber})',
                style: GoogleFonts.beVietnamPro(fontSize: 13, color: _DS.onSurfaceVariant),
              ),
              const SizedBox(height: 22),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Item Cucian',
                    style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w700, color: _DS.onSurface),
                  ),
                  TextButton.icon(
                    onPressed: _isLoadingServices || _isSaving ? null : _pickService,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text('Tambah', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, fontSize: 12.5)),
                    style: TextButton.styleFrom(foregroundColor: _DS.primary),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.sm),

              if (_isLoadingServices)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_servicesError != null)
                Text(_servicesError!, style: GoogleFonts.beVietnamPro(fontSize: 12, color: _DS.error))
              else if (_items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppTheme.md),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _DS.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Text(
                    'Belum ada item. Tekan "Tambah" untuk memilih layanan.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.beVietnamPro(fontSize: 12.5, color: _DS.onSurfaceVariant),
                  ),
                )
              else
                ..._items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isPerKg = item.pricingType == PricingType.perKg;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.sm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.sm, horizontal: AppTheme.md),
                      decoration: BoxDecoration(
                        color: _DS.canvas,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, fontSize: 13, color: _DS.onSurface),
                                ),
                              ),
                              Text(
                                _formatCurrency(item.subtotal),
                                style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 12.5, color: _DS.primary),
                              ),
                              InkWell(
                                onTap: !_isSaving ? () => _removeItem(index) : null,
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Icon(Icons.close, size: 16, color: _DS.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isPerKg ? '${_formatCurrency(item.price)} / kg' : '${_formatCurrency(item.price)} / item',
                                style: GoogleFonts.beVietnamPro(fontSize: 11, color: _DS.onSurfaceVariant),
                              ),
                              isPerKg
                                  ? SizedBox(
                                      width: 92,
                                      height: 34,
                                      child: TextField(
                                        controller: item.weightController,
                                        enabled: !_isSaving,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w600),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          suffixText: 'kg',
                                          suffixStyle: GoogleFonts.beVietnamPro(fontSize: 11, color: _DS.onSurfaceVariant),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          filled: true,
                                          fillColor: _DS.surface,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onChanged: (val) {
                                          final parsed = double.tryParse(val.replaceAll(',', '.'));
                                          setState(() => item.weight = parsed ?? 0);
                                        },
                                      ),
                                    )
                                  : Row(
                                      children: [
                                        _MiniQtyButton(
                                          icon: Icons.remove,
                                          onTap: item.quantity > 1 ? () => setState(() => item.quantity--) : null,
                                        ),
                                        SizedBox(
                                          width: 26,
                                          child: Text(
                                            '${item.quantity}',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        _MiniQtyButton(
                                          icon: Icons.add,
                                          onTap: !_isSaving ? () => setState(() => item.quantity++) : null,
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: AppTheme.md),
              Divider(color: _DS.outlineVariant.withOpacity(0.6)),
              const SizedBox(height: AppTheme.md),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: GoogleFonts.beVietnamPro(fontSize: 14.5, fontWeight: FontWeight.w700, color: _DS.onSurface)),
                  Text(
                    _formatCurrency(_subtotal),
                    style: GoogleFonts.beVietnamPro(fontSize: 19, fontWeight: FontWeight.w700, color: _DS.primary),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.xl),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _DS.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Konfirmasi Sudah Dijemput',
                          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet konfirmasi antar: pilih kurir (opsional) lalu tandai order
/// sudah diantar. Dropdown kurir hanya menampilkan karyawan aktif dengan
/// posisi mengandung "kurir" (dicocokkan case-insensitive, karena posisi
/// karyawan diketik manual/dipilih dari dropdown teks bebas di
/// CreateEmployeeScreen). Kalau tidak ada karyawan berposisi kurir sama
/// sekali, sheet tetap bisa dikonfirmasi tanpa memilih siapa pun - supaya
/// tidak memblokir alur kerja owner yang belum sempat input data karyawan.
class _ConfirmDeliverySheet extends ConsumerStatefulWidget {
  final Order order;

  const _ConfirmDeliverySheet({required this.order});

  @override
  ConsumerState<_ConfirmDeliverySheet> createState() => _ConfirmDeliverySheetState();
}

class _ConfirmDeliverySheetState extends ConsumerState<_ConfirmDeliverySheet> {
  List<Employee> _couriers = [];
  bool _isLoadingCouriers = true;
  String? _couriersError;
  Employee? _selectedCourier;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchCouriers();
  }

  Future<void> _fetchCouriers() async {
    setState(() {
      _isLoadingCouriers = true;
      _couriersError = null;
    });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final repo = EmployeeRepository(userId: uid);
      final allEmployees = await repo.streamEmployees().first;
      setState(() {
        _couriers = allEmployees
            .where((e) => e.isActive && e.position.toLowerCase().contains('kurir'))
            .toList();
        _isLoadingCouriers = false;
      });
    } catch (e) {
      setState(() {
        _couriersError = e.toString();
        _isLoadingCouriers = false;
      });
    }
  }

  Future<void> _handleConfirm() async {
    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await OrderRepository(userId: uid).markDelivered(
        widget.order.id,
        courierId: _selectedCourier?.id,
        courierName: _selectedCourier?.fullName,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal konfirmasi: $e', style: GoogleFonts.beVietnamPro()), backgroundColor: _DS.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: _DS.outlineVariant, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              Text(
                'Konfirmasi Antar',
                style: GoogleFonts.beVietnamPro(fontSize: 19, fontWeight: FontWeight.w700, color: _DS.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Antar cucian ${widget.order.customerName ?? "pelanggan"} (${widget.order.orderNumber})',
                style: GoogleFonts.beVietnamPro(fontSize: 13, color: _DS.onSurfaceVariant),
              ),
              const SizedBox(height: 22),

              Text(
                'Kurir Bertugas (Opsional)',
                style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w700, color: _DS.onSurface),
              ),
              const SizedBox(height: AppTheme.sm),

              if (_isLoadingCouriers)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_couriersError != null)
                Text(_couriersError!, style: GoogleFonts.beVietnamPro(fontSize: 12, color: _DS.error))
              else if (_couriers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppTheme.md),
                  decoration: BoxDecoration(
                    color: _DS.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Text(
                    'Belum ada karyawan dengan posisi "Kurir". Anda tetap bisa lanjut menandai order ini sudah diantar.',
                    style: GoogleFonts.beVietnamPro(fontSize: 12.5, color: _DS.onSurfaceVariant),
                  ),
                )
              else
                DropdownButtonFormField<Employee>(
                  isExpanded: true,
                  value: _selectedCourier,
                  items: _couriers
                      .map((c) => DropdownMenuItem<Employee>(
                            value: c,
                            child: Text(
                              c.fullName.isNotEmpty ? c.fullName : c.employeeCode,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.beVietnamPro(fontSize: 13.5),
                            ),
                          ))
                      .toList(),
                  onChanged: _isSaving ? null : (val) => setState(() => _selectedCourier = val),
                  decoration: InputDecoration(
                    hintText: 'Pilih kurir',
                    hintStyle: GoogleFonts.beVietnamPro(fontSize: 13.5, color: _DS.onSurfaceVariant),
                    prefixIcon: Icon(Icons.two_wheeler_outlined, color: _DS.onSurfaceVariant, size: 20),
                    filled: true,
                    fillColor: _DS.canvas,
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide(color: _DS.primary, width: 1.5),
                    ),
                  ),
                ),

              const SizedBox(height: AppTheme.xl),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _DS.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Konfirmasi Sudah Diantar',
                          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniQtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _MiniQtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: isEnabled ? _DS.primary.withOpacity(0.1) : _DS.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 13, color: isEnabled ? _DS.primary : _DS.onSurfaceVariant),
      ),
    );
  }
}

/// Kartu ringkasan angka (perlu dijemput / siap diantar / ambil sendiri).
/// Dibuat compact & modern dengan aksen warna lembut di ikon.
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [BoxShadow(color: _DS.primary.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: AppTheme.sm),
          Text(value, style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.w700, color: _DS.onSurface)),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.beVietnamPro(fontSize: 11.5, color: _DS.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Pill kecil buat nunjukkin 1 atribut order (mis. "Jemput" atau "Antar").
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
          Text(label, style: GoogleFonts.beVietnamPro(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

/// Kartu 1 order di layar Antar Jemput. Read-only terhadap order_type/
/// delivery_type (cuma menampilkan, tidak bisa diedit dari sini). Semua
/// Text yang bisa panjang (nama pelanggan, order number, no. telepon)
/// dibungkus Expanded/Flexible + ellipsis supaya tidak overflow di layar
/// sempit. Ada aksen strip warna di kiri kartu sesuai kategori logistik.
class _OrderLogisticsCard extends StatelessWidget {
  final Order order;
  final _LogisticsCategory category;
  final Color categoryColor;
  final IconData categoryIcon;
  final String categoryLabel;
  final bool isUpdating;
  final VoidCallback onMarkPickedUp;
  final VoidCallback onMarkDelivered;

  const _OrderLogisticsCard({
    required this.order,
    required this.category,
    required this.categoryColor,
    required this.categoryIcon,
    required this.categoryLabel,
    required this.isUpdating,
    required this.onMarkPickedUp,
    required this.onMarkDelivered,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '${date.day} ${months[date.month - 1]}, $time';
  }

  bool get _showActionButton =>
      category == _LogisticsCategory.needsPickup ||
      category == _LogisticsCategory.needsDelivery ||
      category == _LogisticsCategory.selfService;

  @override
  Widget build(BuildContext context) {
    final typeLabel = order.needsPickup ? 'Jemput' : 'Walk-in';
    final typeIcon = order.needsPickup ? Icons.call_received_rounded : Icons.storefront_outlined;
    final typeColor = order.needsPickup ? const Color(0xFFB197FC) : _DS.onSurfaceVariant;

    final deliveryLabel = order.needsDelivery ? 'Antar' : 'Ambil Sendiri';
    final deliveryIcon = order.needsDelivery ? Icons.call_made_rounded : Icons.storefront_outlined;
    final deliveryColor = order.needsDelivery ? _DS.primary : const Color(0xFF51CF66);

    final hasPhone = (order.customerPhone ?? '').isNotEmpty;
    final hasCourier = (order.courierName ?? '').isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [BoxShadow(color: _DS.primary.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Aksen strip kiri sesuai kategori logistik
              Container(width: 4, color: categoryColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppTheme.md, AppTheme.lg, AppTheme.lg, AppTheme.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Baris atas: nama + order number di kiri, badge kategori di kanan
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (order.customerName?.isNotEmpty ?? false) ? order.customerName! : 'Pelanggan',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 14.5, color: _DS.onSurface),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  order.orderNumber,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.beVietnamPro(fontSize: 11.5, color: _DS.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppTheme.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppTheme.sm, vertical: 6),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(categoryIcon, size: 12, color: categoryColor),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    categoryLabel,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.beVietnamPro(fontSize: 10.5, fontWeight: FontWeight.w700, color: categoryColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (hasPhone) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.phone_outlined, size: 13, color: _DS.onSurfaceVariant),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                order.customerPhone!,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.beVietnamPro(fontSize: 12, color: _DS.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppTheme.md),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _Pill(icon: typeIcon, label: typeLabel, color: typeColor),
                          _Pill(icon: deliveryIcon, label: deliveryLabel, color: deliveryColor),
                          if (hasCourier)
                            _Pill(icon: Icons.two_wheeler_outlined, label: order.courierName!, color: const Color(0xFF51CF66)),
                        ],
                      ),
                      const SizedBox(height: AppTheme.md),
                      Divider(height: 1, color: _DS.outlineVariant.withOpacity(0.6)),
                      const SizedBox(height: AppTheme.md),
                      Row(
                        children: [
                          Icon(Icons.schedule_outlined, size: 15, color: _DS.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              switch (category) {
                                _LogisticsCategory.needsPickup => 'Dijemput: ${_formatDate(order.pickupDate)}',
                                _LogisticsCategory.selfService => 'Diambil: ${_formatDate(order.deliveryDate)}',
                                _ when order.needsDelivery => 'Diantar: ${_formatDate(order.deliveryDate)}',
                                _ => 'Dijemput: ${_formatDate(order.pickupDate)}',
                              },
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.beVietnamPro(fontSize: 11.5, color: _DS.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                      if (_showActionButton) ...[
                        const SizedBox(height: AppTheme.md),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isUpdating ? null : (category == _LogisticsCategory.needsPickup ? onMarkPickedUp : onMarkDelivered),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: categoryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                            ),
                            child: isUpdating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        category == _LogisticsCategory.needsPickup ? Icons.check_circle_outline : Icons.check_circle_outline,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          switch (category) {
                                            _LogisticsCategory.needsPickup => 'Tandai Sudah Dijemput',
                                            _LogisticsCategory.selfService => 'Tandai Sudah Diambil',
                                            _ => 'Tandai Sudah Diantar',
                                          },
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
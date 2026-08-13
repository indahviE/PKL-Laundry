import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/themes/app_theme.dart';
// TODO: sesuaikan path import ini kalau lokasi file hasil `flutter gen-l10n`
// kamu beda. Default Flutter (l10n.yaml standar) taruh di lib/l10n/.
import '../../l10n/app_localizations.dart';
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
import '../../core/widgets/app_snackbar.dart';
import '../../core/services/app_feedback.dart';

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

  // TAMBAHAN: warna aksen reminder pembayaran (oranye), dipakai di pill
  // "Belum Lunas" pada kartu order & banner peringatan di sheet konfirmasi
  // pengantaran. Sengaja disamakan persis dengan warna
  // "courierNotAssignedLabel" yang sudah ada supaya konsisten sebagai
  // "warna peringatan" di layar ini.
  static const warning = Color(0xFFE8590C);
  static const warningBg = Color(0xFFFFF3E0);

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

// TAMBAHAN: helper format currency dipakai lintas widget di file ini
// (pill reminder & banner sheet) - biar gak duplikat logic regex yang
// sama persis dengan yang sudah ada di _ConfirmPickupSheet.
String _formatCurrencyGlobal(double amount) {
  return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
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
    final l10n = AppLocalizations.of(context)!;
    switch (category) {
      case _LogisticsCategory.needsPickup:
        return l10n.waitingPickupStatus;
      case _LogisticsCategory.needsDelivery:
        return l10n.readyDeliveryStatus;
      case _LogisticsCategory.selfService:
        return l10n.readyPickupStatus;
      case _LogisticsCategory.other:
        return _fallbackStatusLabel(null);
    }
  }

  String _fallbackStatusLabel(OrderStatus? status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case OrderStatus.pending:
        return l10n.waitingConfirmationStatus;
      case OrderStatus.confirmed:
        return l10n.confirmedStatus;
      case OrderStatus.inProgress:
      case OrderStatus.washing:
      case OrderStatus.drying:
      case OrderStatus.ironing:
      case OrderStatus.qualityCheck:
        return l10n.inProgressStatus;
      case OrderStatus.ready:
        return l10n.readyPickupStatus;
      case OrderStatus.completed:
        return l10n.orderStatusCompleted;
      case OrderStatus.cancelled:
        return l10n.orderStatusCancelled;
      default:
        return l10n.inProgressStatus;
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
      _showSuccessSnack(AppLocalizations.of(context)!.markedPickedUpSnackbar(order.orderNumber));
    }
  }

  /// Order dengan deliveryType == delivery butuh dicatat kurirnya dulu
  /// lewat sheet, supaya owner bisa pilih siapa yang bertugas. Order
  /// self-service (pelanggan ambil sendiri) tidak butuh kurir sama sekali,
  /// jadi langsung ditandai selesai tanpa membuka sheet.
  ///
  /// TAMBAHAN: reminder pembayaran. Order yang belum lunas (paymentStatus
  /// != paid) SEKARANG selalu dikasih jeda konfirmasi ekstra dulu sebelum
  /// beneran ditandai selesai diambil/diantar - supaya kasir/kurir gak
  /// kelewat nyerahin baju padahal masih ada sisa tagihan. Untuk order
  /// needsDelivery, reminder-nya muncul sebagai banner di dalam
  /// ConfirmDeliverySheet. Untuk order selfService (yang sebelumnya
  /// langsung _markDelivered tanpa sheet sama sekali), reminder-nya
  /// berupa dialog konfirmasi terpisah karena memang belum ada UI
  /// perantara di jalur itu.
  Future<void> _handleDeliveryTap(Order order) async {
    if (order.needsDelivery) {
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => ConfirmDeliverySheet(
          orderId: order.id,
          customerName: order.customerName,
          orderNumber: order.orderNumber,
          // Kalau order ini sudah pernah dijadwalkan (via
          // CreateDeliveryScheduleScreen), kurirnya udah ketahuan dari
          // logisticsSchedule - dioper ke sheet supaya langsung
          // ke-prefill, gak nanya ulang dari nol.
          scheduledCourierId: order.logisticsSchedule?.courierId,
          scheduledCourierName: order.logisticsSchedule?.courierName,
          // TAMBAHAN: info pembayaran, dipakai sheet buat nampilin banner
          // peringatan kalau masih ada sisa tagihan.
          isUnpaid: order.paymentStatus != PaymentStatus.paid,
          remainingAmount: order.totalAmount - order.paidAmount,
        ),
      );
      if (confirmed == true) {
        _showSuccessSnack(AppLocalizations.of(context)!.markedDeliveredCompletedSnackbar(order.orderNumber));
      }
    } else {
      // TAMBAHAN: self-service gak pernah lewat sheet, jadi reminder-nya
      // ditaruh sebagai dialog konfirmasi tersendiri di sini - HANYA
      // muncul kalau memang belum lunas, supaya alur yang sudah lunas
      // tetap secepat sebelumnya (tanpa klik tambahan).
      if (order.paymentStatus != PaymentStatus.paid) {
        final remaining = order.totalAmount - order.paidAmount;
        final proceed = await _showUnpaidConfirmDialog(
          orderNumber: order.orderNumber,
          remainingAmount: remaining,
        );
        if (proceed != true) return;
      }
      await _markDelivered(order);
    }
  }

  /// TAMBAHAN: dialog konfirmasi "masih ada sisa tagihan, tetap
  /// lanjutkan?" - dipakai khusus jalur self-service karena jalur itu
  /// tidak melewati bottom sheet apa pun (langsung _markDelivered).
  /// Return true kalau kasir memilih tetap lanjut, false/null kalau
  /// dibatalkan.
  Future<bool?> _showUnpaidConfirmDialog({
    required String orderNumber,
    required double remainingAmount,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: _DS.warning, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Belum Lunas',
                style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, color: _DS.onSurface),
              ),
            ),
          ],
        ),
        content: Text(
          'Order $orderNumber masih punya sisa tagihan ${_formatCurrencyGlobal(remainingAmount)}. '
          'Tetap tandai sebagai sudah diambil/selesai?',
          style: GoogleFonts.beVietnamPro(fontSize: 13.5, color: _DS.onSurfaceVariant, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.closeButton, style: GoogleFonts.beVietnamPro(color: _DS.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _DS.warning,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
            ),
            child: Text('Tetap Lanjutkan', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
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
        _showSuccessSnack(AppLocalizations.of(context)!.markedDeliveredSnackbar(order.orderNumber));
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnack(AppLocalizations.of(context)!.genericUpdateError(e.toString()));
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

  /// Suara + snackbar hijau untuk aksi yang berhasil, mengikuti pola yang
  /// sama dengan CreateServiceScreen (AppFeedback.playSound + AppSnackbar).
  void _showSuccessSnack(String message) {
    if (!mounted) return;
    AppFeedback.playSound(ref, AppSound.success);
    AppSnackbar.success(context, message);
  }

  /// Suara + snackbar merah untuk aksi yang gagal, mengikuti pola yang
  /// sama dengan CreateServiceScreen.
  void _showErrorSnack(String message) {
    if (!mounted) return;
    AppFeedback.playSound(ref, AppSound.error);
    AppSnackbar.error(context, message);
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
    final l10n = AppLocalizations.of(context)!;
    final ordersAsync = ref.watch(_allOrdersStreamProvider);

    return Scaffold(
      backgroundColor: _DS.canvas,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleAddSchedule,
        backgroundColor: _DS.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addScheduleButton, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, fontSize: 13.5)),
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
    final l10n = AppLocalizations.of(context)!;
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
                l10n.pickupDeliveryTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _DS.headlineMd(color: _DS.navy),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.pickupDeliverySubtitle,
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
    final l10n = AppLocalizations.of(context)!;
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
          hintText: l10n.searchOrderCustomerHint,
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
    final l10n = AppLocalizations.of(context)!;
    final filters = [
      ('all', l10n.filterAll, Icons.all_inbox_outlined, _DS.onSurfaceVariant),
      ('needs_pickup', l10n.filterNeedsPickup, Icons.call_received_rounded, _pickupAccent),
      ('needs_delivery', l10n.filterNeedsDelivery, Icons.call_made_rounded, _DS.primary),
      ('self_service', l10n.filterSelfService, Icons.storefront_outlined, _selfServiceAccent),
      ('other', l10n.filterOthers, Icons.more_horiz_rounded, _DS.onSurfaceVariant),
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
    final l10n = AppLocalizations.of(context)!;
    final stats = [
      _StatCard(title: l10n.statNeedsPickupTitle, value: '$needsPickup', icon: Icons.call_received_rounded, color: _pickupAccent),
      _StatCard(title: l10n.statReadyDeliveryTitle, value: '$needsDelivery', icon: Icons.call_made_rounded, color: _DS.primary),
      _StatCard(title: l10n.statSelfServiceTitle, value: '$selfService', icon: Icons.storefront_outlined, color: _selfServiceAccent),
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
    final l10n = AppLocalizations.of(context)!;
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
            Text(l10n.noOrdersTitle, style: GoogleFonts.beVietnamPro(fontSize: 15, fontWeight: FontWeight.w600, color: _DS.onSurface)),
            const SizedBox(height: AppTheme.sm),
            Text(
              l10n.noOrdersFilterSubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(fontSize: 13, color: _DS.onSurfaceVariant),
            ),
            const SizedBox(height: AppTheme.lg),
            OutlinedButton.icon(
              onPressed: _handleAddSchedule,
              icon: Icon(Icons.add_rounded, size: 18, color: _DS.primary),
              label: Text(l10n.addScheduleButton, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, fontSize: 13, color: _DS.primary)),
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
    final l10n = AppLocalizations.of(context)!;
    // Dibungkus SingleChildScrollView + viewInsets/viewPadding bawah (sama
    // seperti _ConfirmPickupSheet & ConfirmDeliverySheet di file ini),
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
                l10n.scheduleDeliveryScreenTitle,
                style: GoogleFonts.beVietnamPro(fontSize: 17, fontWeight: FontWeight.w700, color: _DS.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.selectScheduleModeSubtitle,
                style: GoogleFonts.beVietnamPro(fontSize: 12.5, color: _DS.onSurfaceVariant),
              ),
              const SizedBox(height: AppTheme.lg),
              _modeTile(
                context,
                value: 'penjemputan',
                icon: Icons.call_received_rounded,
                accent: pickupAccent,
                title: l10n.schedulePickupTileTitle,
                subtitle: l10n.schedulePickupTileSubtitle,
              ),
              const SizedBox(height: AppTheme.sm),
              _modeTile(
                context,
                value: 'pengantaran',
                icon: Icons.call_made_rounded,
                accent: deliveryAccent,
                title: l10n.scheduleDeliveryTileTitle,
                subtitle: l10n.scheduleDeliveryTileSubtitle,
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
class _ConfirmPickupSheet extends ConsumerStatefulWidget {
  final Order order;

  const _ConfirmPickupSheet({required this.order});

  @override
  ConsumerState<_ConfirmPickupSheet> createState() => _ConfirmPickupSheetState();
}

class _ConfirmPickupSheetState extends ConsumerState<_ConfirmPickupSheet> {
  late final ServiceRepository _serviceRepository;
  List<Service> _services = [];
  List<OrderItemForm> _items = [];
  bool _isLoadingServices = true;
  String? _servicesError;
  bool _isSaving = false;

  // === TAMBAHAN: payment, baru diisi di sini karena subtotal riil baru
  // ketahuan setelah barang ditimbang. Polanya sama persis dengan
  // CreateOrderScreen: transfer selalu mulai dari 0 dibayar (dikonfirmasi
  // manual belakangan), method instan (cash/debit/ewallet) bisa Lunas
  // atau DP.
  String _selectedPaymentMethod = 'cash';
  bool _isFullPayment = true;
  late final TextEditingController _dpAmountController;

  bool get _isInstantMethod =>
      _selectedPaymentMethod == 'cash' ||
      _selectedPaymentMethod == 'debit' ||
      _selectedPaymentMethod == 'ewallet';

  // Label & suffix diambil dari AppLocalizations lewat method ini (bukan
  // const field lagi) karena butuh context untuk resolve bahasa aktif.
  List<Map<String, dynamic>> _paymentMethodsData(AppLocalizations l10n) => [
        {'id': 'cash', 'label': l10n.cashPaymentLabel, 'icon': Icons.payments_outlined},
        {'id': 'transfer', 'label': l10n.bankTransferLabel, 'icon': Icons.account_balance_outlined},
        {'id': 'debit', 'label': l10n.debitCardLabel, 'icon': Icons.credit_card_outlined},
        {'id': 'ewallet', 'label': l10n.eWalletLabel, 'icon': Icons.account_balance_wallet_outlined},
      ];
  // === END TAMBAHAN

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _serviceRepository = ServiceRepository(userId: uid);
    _dpAmountController = TextEditingController(); // TAMBAHAN
    _fetchServices();
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    _dpAmountController.dispose(); // TAMBAHAN
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text(l10n.selectServiceTitle, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, color: _DS.onSurface)),
        content: SizedBox(
          width: double.maxFinite,
          child: _services.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    l10n.noActiveServicesHint,
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
                    final suffix = service.pricingType == PricingType.perKg ? l10n.unitPerKgSuffix : l10n.unitPerItemSuffix;
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
                              minWeight: service.minWeight ?? 0,
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
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.closeButton, style: GoogleFonts.beVietnamPro())),
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

  // === TAMBAHAN: hitung berapa yang dibayar sekarang, sama logikanya
  // dengan CreateOrderScreen._handleSaveOrder(). Return null berarti
  // validasi gagal (pesan errornya sudah ditampilkan di dalam).
  double? _resolvePaidAmount() {
    final l10n = AppLocalizations.of(context)!;
    if (!_isInstantMethod) return 0;

    if (_isFullPayment) return _subtotal;

    final rawDp = _dpAmountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final dp = double.tryParse(rawDp) ?? 0;
    if (dp <= 0) {
      AppFeedback.playSound(ref, AppSound.error);
      AppSnackbar.error(context, l10n.dpAmountRequiredError);
      return null;
    }
    if (dp >= _subtotal) {
      AppFeedback.playSound(ref, AppSound.error);
      AppSnackbar.error(context, l10n.dpAmountTooLargeError);
      return null;
    }
    return dp;
  }
  // === END TAMBAHAN

  Future<void> _handleConfirm() async {
    final l10n = AppLocalizations.of(context)!;
    if (_items.isEmpty) {
      AppFeedback.playSound(ref, AppSound.error);
      AppSnackbar.error(context, l10n.minOneItemError);
      return;
    }

    for (final item in _items) {
      if (item.pricingType == PricingType.perKg) {
        if (item.weight <= 0) {
          AppFeedback.playSound(ref, AppSound.error);
          AppSnackbar.error(context, l10n.weightRequiredError(item.name));
          return;
        }
        if (item.minWeight > 0 && item.weight < item.minWeight) {
          AppFeedback.playSound(ref, AppSound.error);
          AppSnackbar.error(
            context,
            l10n.belowMinWeightError(item.name, item.minWeight.toStringAsFixed(1)),
          );
          return;
        }
      }
    }

    // TAMBAHAN: validasi & hitung pembayaran sebelum mulai saving
    final paidNow = _resolvePaidAmount();
    if (paidNow == null) return;

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw l10n.orderSessionNotFoundError;

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

      // TAMBAHAN: method & status pembayaran
      final paymentMethod = PaymentMethod.values.firstWhere((e) => e.name == _selectedPaymentMethod);
      final paymentStatus = paidNow <= 0
          ? PaymentStatus.pending
          : (paidNow >= _subtotal - 1 ? PaymentStatus.paid : PaymentStatus.partial);

      await OrderRepository(userId: user.uid).confirmPickupWithItems(
        widget.order.id,
        items: orderItems,
        totalWeight: _totalWeight,
        totalItems: _totalItems,
        subtotal: _subtotal,
        paymentMethod: paymentMethod, // TAMBAHAN
        paidAmount: paidNow,          // TAMBAHAN
        paymentStatus: paymentStatus, // TAMBAHAN
      );

      if (mounted) {
        AppFeedback.playSound(ref, AppSound.success);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.playSound(ref, AppSound.error);
        AppSnackbar.error(context, l10n.confirmFailedError(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // TAMBAHAN: chip kecil buat toggle Lunas/DP, style-nya nyaman disamain
  // dengan _MiniQtyButton/_Pill yang sudah ada di file ini.
  Widget _paymentOptionChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: _isSaving ? null : onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: AppTheme.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? _DS.primary.withOpacity(0.1) : _DS.canvas,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected ? _DS.primary : _DS.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? _DS.primary : _DS.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  // TAMBAHAN: section metode pembayaran, ditaruh di build() setelah
  // ringkasan Total dan sebelum tombol konfirmasi.
  Widget _buildPaymentSection() {
    final l10n = AppLocalizations.of(context)!;
    final paymentMethods = _paymentMethodsData(l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.paymentMethodLabel, style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w700, color: _DS.onSurface)),
        const SizedBox(height: AppTheme.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - AppTheme.sm) / 2;
            return Wrap(
              spacing: AppTheme.sm,
              runSpacing: AppTheme.sm,
              children: paymentMethods.map((method) {
                final isSelected = _selectedPaymentMethod == method['id'];
                return SizedBox(
                  width: itemWidth,
                  child: InkWell(
                    onTap: _isSaving ? null : () => setState(() => _selectedPaymentMethod = method['id']),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.sm, horizontal: AppTheme.sm),
                      decoration: BoxDecoration(
                        color: isSelected ? _DS.primary.withOpacity(0.1) : _DS.canvas,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: isSelected ? _DS.primary : _DS.outlineVariant, width: isSelected ? 1.5 : 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(method['icon'], size: 16, color: isSelected ? _DS.primary : _DS.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              method['label'],
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.beVietnamPro(fontSize: 11.5, fontWeight: FontWeight.w600, color: isSelected ? _DS.primary : _DS.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          _selectedPaymentMethod == 'transfer' ? l10n.transferPaymentPendingNotice : l10n.instantPaymentNotice,
          style: GoogleFonts.beVietnamPro(fontSize: 11, color: _DS.onSurfaceVariant),
        ),
        if (_isInstantMethod) ...[
          const SizedBox(height: AppTheme.md),
          Row(
            children: [
              Expanded(child: _paymentOptionChip(label: l10n.fullPaymentLabel, isSelected: _isFullPayment, onTap: () => setState(() => _isFullPayment = true))),
              const SizedBox(width: AppTheme.sm),
              Expanded(child: _paymentOptionChip(label: l10n.partialPaymentLabel, isSelected: !_isFullPayment, onTap: () => setState(() => _isFullPayment = false))),
            ],
          ),
          if (!_isFullPayment) ...[
            const SizedBox(height: AppTheme.md),
            TextField(
              controller: _dpAmountController,
              enabled: !_isSaving,
              keyboardType: TextInputType.number,
              style: GoogleFonts.beVietnamPro(fontSize: 13.5),
              decoration: InputDecoration(
                labelText: l10n.dpAmountLabel,
                labelStyle: GoogleFonts.beVietnamPro(fontSize: 12.5, color: _DS.onSurfaceVariant),
                hintText: l10n.dpAmountHint,
                hintStyle: GoogleFonts.beVietnamPro(fontSize: 12.5, color: _DS.onSurfaceVariant),
                prefixIcon: Icon(Icons.payments_outlined, color: _DS.onSurfaceVariant),
                filled: true,
                fillColor: _DS.canvas,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.remainingBalanceHint,
              style: GoogleFonts.beVietnamPro(fontSize: 11, color: _DS.onSurfaceVariant),
            ),
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              Text(l10n.confirmPickupTitle, style: GoogleFonts.beVietnamPro(fontSize: 19, fontWeight: FontWeight.w700, color: _DS.onSurface)),
              const SizedBox(height: 4),
              Text(
                l10n.confirmPickupSubtitle(
                  (widget.order.customerName?.isNotEmpty ?? false) ? widget.order.customerName! : l10n.customerFallbackLabel,
                  widget.order.orderNumber,
                ),
                style: GoogleFonts.beVietnamPro(fontSize: 13, color: _DS.onSurfaceVariant),
              ),
              const SizedBox(height: 22),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.laundryItemsLabel, style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w700, color: _DS.onSurface)),
                  TextButton.icon(
                    onPressed: _isLoadingServices || _isSaving ? null : _pickService,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(l10n.addButtonLabel, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, fontSize: 12.5)),
                    style: TextButton.styleFrom(foregroundColor: _DS.primary),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.sm),

              if (_isLoadingServices)
                const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
              else if (_servicesError != null)
                Text(_servicesError!, style: GoogleFonts.beVietnamPro(fontSize: 12, color: _DS.error))
              else if (_items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppTheme.md),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: _DS.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                  child: Text(
                    l10n.noItemsAddHint,
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
                      decoration: BoxDecoration(color: _DS.canvas, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(item.name, overflow: TextOverflow.ellipsis, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, fontSize: 13, color: _DS.onSurface)),
                              ),
                              Text(_formatCurrency(item.subtotal), style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 12.5, color: _DS.primary)),
                              InkWell(
                                onTap: !_isSaving ? () => _removeItem(index) : null,
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(padding: const EdgeInsets.only(left: 6), child: Icon(Icons.close, size: 16, color: _DS.onSurfaceVariant)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isPerKg
                                    ? '${_formatCurrency(item.price)} ${l10n.unitPerKgSuffix}'
                                    : '${_formatCurrency(item.price)} ${l10n.unitPerItemSuffix}',
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
                                        _MiniQtyButton(icon: Icons.remove, onTap: item.quantity > 1 ? () => setState(() => item.quantity--) : null),
                                        SizedBox(width: 26, child: Text('${item.quantity}', textAlign: TextAlign.center, style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w600))),
                                        _MiniQtyButton(icon: Icons.add, onTap: !_isSaving ? () => setState(() => item.quantity++) : null),
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
                  Text(l10n.totalLabel, style: GoogleFonts.beVietnamPro(fontSize: 14.5, fontWeight: FontWeight.w700, color: _DS.onSurface)),
                  Text(_formatCurrency(_subtotal), style: GoogleFonts.beVietnamPro(fontSize: 19, fontWeight: FontWeight.w700, color: _DS.primary)),
                ],
              ),

              // TAMBAHAN: section metode pembayaran
              const SizedBox(height: AppTheme.lg),
              _buildPaymentSection(),

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
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(l10n.confirmPickedUpButton, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, fontSize: 15)),
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
/// sudah diantar (dan sekaligus 'completed' - lihat markDelivered).
/// DIBUAT PUBLIC supaya bisa direuse langsung dari OrderDetailScreen
/// (tombol "Jadwalkan Pengantaran" saat status ready & deliveryType
/// delivery), bukan cuma dari layar Antar Jemput ini. Dropdown kurir
/// hanya menampilkan karyawan aktif dengan posisi mengandung "kurir"
/// (dicocokkan case-insensitive, karena posisi karyawan diketik manual/
/// dipilih dari dropdown teks bebas di CreateEmployeeScreen). Kalau
/// tidak ada karyawan berposisi kurir sama sekali, sheet tetap bisa
/// dikonfirmasi tanpa memilih siapa pun - supaya tidak memblokir alur
/// kerja owner yang belum sempat input data karyawan.
class ConfirmDeliverySheet extends ConsumerStatefulWidget {
  final String orderId;
  final String? customerName;
  final String orderNumber;
  // Kurir yang SUDAH dipilih sebelumnya di CreateDeliveryScheduleScreen
  // (dari order.logisticsSchedule) - kalau ada, dropdown di sheet ini
  // langsung ke-prefill dengan kurir itu, jadi kasir gak perlu milih
  // ulang dari nol saat konfirmasi "Sudah Diantar". Null berarti order
  // ini memang belum pernah dijadwalkan lewat sistem (langsung diproses
  // manual), jadi tetap perlu dipilih di sini.
  final String? scheduledCourierId;
  final String? scheduledCourierName;
  // TAMBAHAN: reminder + input pembayaran - true kalau order ini belum
  // lunas. Beda dari sekadar reminder pasif: kalau true, sheet ini
  // nampilin SECTION PEMBAYARAN (metode + nominal) supaya driver bisa
  // langsung catat uang yang diterima di lapangan saat serah terima -
  // sama pola atomic-nya dengan OrderRepository.recordPayment() yang
  // sudah dipakai _showRecordPaymentDialog di OrderDetailScreen. Kalau
  // order sudah lunas, section ini tidak pernah ditampilkan sama sekali.
  final bool isUnpaid;
  final double remainingAmount;

  const ConfirmDeliverySheet({
    Key? key,
    required this.orderId,
    this.customerName,
    required this.orderNumber,
    this.scheduledCourierId,
    this.scheduledCourierName,
    this.isUnpaid = false, // TAMBAHAN
    this.remainingAmount = 0, // TAMBAHAN
  }) : super(key: key); 

  @override
  ConsumerState<ConfirmDeliverySheet> createState() => _ConfirmDeliverySheetState();
}

class _ConfirmDeliverySheetState extends ConsumerState<ConfirmDeliverySheet> {
  List<Employee> _couriers = [];
  bool _isLoadingCouriers = true;
  String? _couriersError;
  Employee? _selectedCourier;
  bool _isSaving = false;

  // === TAMBAHAN: state pembayaran, cuma relevan kalau widget.isUnpaid.
  // TIDAK ADA lagi toggle Lunas/DP di sheet ini (lihat alasan di
  // _buildPaymentSection) - satu-satunya pilihan driver adalah metode
  // pembayarannya, nominal narik full otomatis.
  String _selectedPaymentMethod = 'cash';

  bool get _isInstantMethod =>
      _selectedPaymentMethod == 'cash' ||
      _selectedPaymentMethod == 'debit' ||
      _selectedPaymentMethod == 'ewallet';

  List<Map<String, dynamic>> _paymentMethodsData(AppLocalizations l10n) => [
        {'id': 'cash', 'label': l10n.cashPaymentLabel, 'icon': Icons.payments_outlined},
        {'id': 'transfer', 'label': l10n.bankTransferLabel, 'icon': Icons.account_balance_outlined},
        {'id': 'debit', 'label': l10n.debitCardLabel, 'icon': Icons.credit_card_outlined},
        {'id': 'ewallet', 'label': l10n.eWalletLabel, 'icon': Icons.account_balance_wallet_outlined},
      ];
  // === END TAMBAHAN

  @override
  void initState() {
    super.initState();
    _fetchCouriers();
  }

  @override
  void dispose() {
    super.dispose();
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
      _prefillScheduledCourier();
    } catch (e) {
      setState(() {
        _couriersError = e.toString();
        _isLoadingCouriers = false;
      });
    }
  }

  /// Cocokkan widget.scheduledCourierId ke daftar _couriers yang baru
  /// dimuat - begitu ketemu, langsung set sebagai _selectedCourier supaya
  /// dropdown udah terisi begitu sheet ini kebuka, gak nyuruh kasir pilih
  /// ulang kurir yang sebenarnya udah ditentukan sejak jadwal dibuat.
  void _prefillScheduledCourier() {
    final courierId = widget.scheduledCourierId;
    if (courierId == null || courierId.isEmpty || _couriers.isEmpty) return;
    final match = _couriers.where((c) => c.id == courierId);
    if (match.isNotEmpty && mounted) {
      setState(() => _selectedCourier = match.first);
    }
  }

  // === TAMBAHAN: hitung berapa yang dibayar sekarang. Beda dari
  // _ConfirmPickupSheet - di sini TIDAK ADA opsi DP (lihat alasan di
  // _buildPaymentSection), jadi metode instan selalu narik FULL sisa
  // tagihan, gak perlu validasi nominal apa pun.
  double _resolvePaidAmount() {
    if (!widget.isUnpaid) return 0; // sudah lunas dari awal, gak ada apa-apa buat dicatat
    if (!_isInstantMethod) return 0; // transfer: nunggu konfirmasi manual kasir belakangan
    return widget.remainingAmount;
  }
  // === END TAMBAHAN

  Future<void> _handleConfirm() async {
    final paidNow = _resolvePaidAmount();

    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final repo = OrderRepository(userId: uid);

      // TAMBAHAN: catat pembayaran DULU (kalau ada uang yang beneran
      // diterima sekarang), baru markDelivered - urutan ini penting
      // supaya kalau recordPayment gagal, order TIDAK terlanjur
      // ditandai selesai diantar padahal duitnya belum tercatat.
      if (paidNow > 0) {
        final paymentMethod = PaymentMethod.values.firstWhere((e) => e.name == _selectedPaymentMethod);
        await repo.recordPayment(
          widget.orderId,
          amount: paidNow,
          method: paymentMethod,
        );
      }

      await repo.markDelivered(
        widget.orderId,
        courierId: _selectedCourier?.id,
        courierName: _selectedCourier?.fullName,
        markAsCompleted: true,
      );
      if (mounted) {
        AppFeedback.playSound(ref, AppSound.success);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        AppFeedback.playSound(ref, AppSound.error);
        AppSnackbar.error(context, l10n.confirmFailedError(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // TAMBAHAN: section pembayaran - HANYA dipanggil dari build() kalau
  // widget.isUnpaid true. Driver cuma pilih metode; nominal narik full
  // otomatis (lihat _resolvePaidAmount) - gak ada input manual di sini.
  Widget _buildPaymentSection() {
    final l10n = AppLocalizations.of(context)!;
    final paymentMethods = _paymentMethodsData(l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.paymentMethodLabel, style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w700, color: _DS.onSurface)),
        const SizedBox(height: AppTheme.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - AppTheme.sm) / 2;
            return Wrap(
              spacing: AppTheme.sm,
              runSpacing: AppTheme.sm,
              children: paymentMethods.map((method) {
                final isSelected = _selectedPaymentMethod == method['id'];
                return SizedBox(
                  width: itemWidth,
                  child: InkWell(
                    onTap: _isSaving ? null : () => setState(() => _selectedPaymentMethod = method['id']),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.sm, horizontal: AppTheme.sm),
                      decoration: BoxDecoration(
                        color: isSelected ? _DS.primary.withOpacity(0.1) : _DS.canvas,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: isSelected ? _DS.primary : _DS.outlineVariant, width: isSelected ? 1.5 : 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(method['icon'], size: 16, color: isSelected ? _DS.primary : _DS.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              method['label'],
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.beVietnamPro(fontSize: 11.5, fontWeight: FontWeight.w600, color: isSelected ? _DS.primary : _DS.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          _selectedPaymentMethod == 'transfer' ? l10n.transferPaymentPendingNotice : l10n.instantPaymentNotice,
          style: GoogleFonts.beVietnamPro(fontSize: 11, color: _DS.onSurfaceVariant),
        ),
        // TAMBAHAN: sengaja TIDAK ada toggle Lunas/DP di sheet ini (beda
        // dari _ConfirmPickupSheet). Begitu barang diserahin ke
        // pelanggan, itu kesempatan terakhir buat nagih - kalau dibolehin
        // DP di sini, sisa tagihannya jadi susah ditagih karena toko
        // udah gak punya leverage (barang udah lepas). Jadi metode
        // instan (tunai/debit/e-wallet) SELALU narik FULL sisa tagihan,
        // gak ada opsi bayar sebagian. Transfer tetap pending seperti
        // biasa, dikonfirmasi manual belakangan oleh kasir.
        if (_isInstantMethod) ...[
          const SizedBox(height: AppTheme.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: AppTheme.sm),
            decoration: BoxDecoration(
              color: _DS.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ditagih sekarang (lunas)',
                  style: GoogleFonts.beVietnamPro(fontSize: 12.5, fontWeight: FontWeight.w600, color: _DS.onSurface),
                ),
                Text(
                  _formatCurrencyGlobal(widget.remainingAmount),
                  style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w700, color: _DS.primary),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                l10n.confirmDeliveryTitle,
                style: GoogleFonts.beVietnamPro(fontSize: 19, fontWeight: FontWeight.w700, color: _DS.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.confirmDeliverySubtitle(
                  (widget.customerName?.isNotEmpty ?? false) ? widget.customerName! : l10n.customerFallbackLabel,
                  widget.orderNumber,
                ),
                style: GoogleFonts.beVietnamPro(fontSize: 13, color: _DS.onSurfaceVariant),
              ),
              const SizedBox(height: 22),

              // TAMBAHAN: banner ringkas "belum lunas" - tampil paling atas
              // (sebelum form kurir), sekadar penanda kenapa section
              // pembayaran di bawah muncul. Detail nominal & input-nya
              // ada di _buildPaymentSection(), jadi banner ini sengaja
              // gak diulang nominalnya biar gak duplikat info.
              if (widget.isUnpaid) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: AppTheme.sm),
                  margin: const EdgeInsets.only(bottom: AppTheme.lg),
                  decoration: BoxDecoration(
                    color: _DS.warningBg,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: _DS.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 16, color: _DS.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Order ini masih ada sisa tagihan ${_formatCurrencyGlobal(widget.remainingAmount)} - catat pembayaran yang diterima di bawah.',
                          style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w600, color: _DS.warning, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              Text(
                l10n.assignedCourierLabel,
                style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w700, color: _DS.onSurface),
              ),
              if (_selectedCourier != null && widget.scheduledCourierId == _selectedCourier!.id) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 11, color: _DS.primary),
                    const SizedBox(width: 4),
                    Text(
                      l10n.courierMatchesScheduleHint,
                      style: GoogleFonts.beVietnamPro(fontSize: 11, color: _DS.primary, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ],
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
                    l10n.noCourierEmployeeDeliverHint,
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
                    hintText: l10n.selectCourierHint,
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

              // TAMBAHAN: section pembayaran - HANYA muncul kalau order
              // ini belum lunas. Driver isi metode + nominal yang
              // diterima di sini, dicatat atomic lewat recordPayment()
              // di _handleConfirm sebelum markDelivered dieksekusi.
              if (widget.isUnpaid) ...[
                const SizedBox(height: AppTheme.lg),
                _buildPaymentSection(),
              ],

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
                          widget.isUnpaid ? 'Catat Bayar & Tandai Diantar' : l10n.confirmDeliveredButton,
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

  String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) return '-';
    final l10n = AppLocalizations.of(context)!;
    final months = [
      l10n.monthJan, l10n.monthFeb, l10n.monthMar, l10n.monthApr, l10n.monthMay, l10n.monthJun,
      l10n.monthJul, l10n.monthAug, l10n.monthSep, l10n.monthOct, l10n.monthNov, l10n.monthDec,
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
    final l10n = AppLocalizations.of(context)!;

    final typeLabel = order.needsPickup ? l10n.pickupTypeLabel : l10n.walkInTypeLabel;
    final typeIcon = order.needsPickup ? Icons.call_received_rounded : Icons.storefront_outlined;
    final typeColor = order.needsPickup ? const Color(0xFFB197FC) : _DS.onSurfaceVariant;

    final deliveryLabel = order.needsDelivery ? l10n.deliveryTypeLabel : l10n.selfPickupTypeLabel;
    final deliveryIcon = order.needsDelivery ? Icons.call_made_rounded : Icons.storefront_outlined;
    final deliveryColor = order.needsDelivery ? _DS.primary : const Color(0xFF51CF66);

    final hasPhone = (order.customerPhone ?? '').isNotEmpty;
    final hasCourier = (order.courierName ?? '').isNotEmpty;

    // TAMBAHAN: reminder pembayaran - dicek di SEMUA kategori (bukan
    // cuma yang lagi bisa ditandai selesai) supaya kelihatan dari awal
    // pas nge-scan daftar, bukan cuma pas mau konfirmasi aksi.
    // TODO: sesuaikan nama getter `paymentStatus`/`paidAmount`/`totalAmount`
    // kalau nama field di models/order.dart kamu beda dari ini.
    final isUnpaid = order.paymentStatus != PaymentStatus.paid;
    final remainingAmount = (order.totalAmount - order.paidAmount).clamp(0, double.infinity).toDouble();

    // Info kurir khusus kategori "Perlu Dijemput" - beda sumber data dari
    // hasCourier di atas (itu dari order.courierName, cuma keisi setelah
    // beneran diantar via markDelivered). Ini dari rencana jadwal
    // (logisticsSchedule) yang bisa udah diisi sejak CreateOrderScreen,
    // atau dilengkapi belakangan lewat CreateDeliveryScheduleScreen.
    final pickupSchedule = order.logisticsSchedule;
    final hasPickupCourier = category == _LogisticsCategory.needsPickup && (pickupSchedule?.hasCourier ?? false);
    final needsCourierAssignment = category == _LogisticsCategory.needsPickup && !hasPickupCourier;
    // TAMBAHAN: kalau kategori masih perlu dijemput TAPI belum ada kurir yang
    // ditugaskan, tombol "Tandai Sudah Dijemput" harus dikunci - jangan sampai
    // barang ditandai udah dijemput padahal belum jelas siapa yang jemput.
    final isPickupBlocked = category == _LogisticsCategory.needsPickup && needsCourierAssignment;

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
                                  (order.customerName?.isNotEmpty ?? false) ? order.customerName! : l10n.customerFallbackLabel,
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
                          if (hasPickupCourier)
                            _Pill(
                              icon: Icons.two_wheeler_outlined,
                              label: pickupSchedule!.courierName ?? l10n.genericCourierLabel,
                              color: const Color(0xFF51CF66),
                            ),
                          if (needsCourierAssignment)
                            _Pill(
                              icon: Icons.person_off_outlined,
                              label: l10n.courierNotAssignedLabel,
                              color: const Color(0xFFE8590C),
                            ),
                          // TAMBAHAN: pill reminder pembayaran - selalu
                          // ditampilkan kalau masih ada sisa tagihan,
                          // terlepas dari kategori logistiknya apa.
                          if (isUnpaid)
                            _Pill(
                              icon: Icons.priority_high_rounded,
                              label: 'Belum Lunas · ${_formatCurrencyGlobal(remainingAmount)}',
                              color: _DS.warning,
                            ),
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
                                _LogisticsCategory.needsPickup => pickupSchedule?.scheduledAt != null
                                    ? l10n.plannedPickupLabel(_formatDate(context, pickupSchedule!.scheduledAt))
                                    : l10n.notScheduledLabel,
                                _LogisticsCategory.selfService => l10n.selfServicePickedUpLabel(_formatDate(context, order.deliveryDate)),
                                _ when order.needsDelivery => l10n.deliveredAtLabel(_formatDate(context, order.deliveryDate)),
                                _ => l10n.pickedUpFromCustomerLabel(_formatDate(context, order.pickupDate)),
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
                            onPressed: (isUpdating || isPickupBlocked)
                                ? null
                                : (category == _LogisticsCategory.needsPickup ? onMarkPickedUp : onMarkDelivered),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPickupBlocked ? _DS.outlineVariant.withOpacity(0.5) : categoryColor,
                              disabledBackgroundColor: _DS.outlineVariant.withOpacity(0.5),
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
                                        isPickupBlocked ? Icons.person_off_outlined : Icons.check_circle_outline,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          isPickupBlocked
                                              ? l10n.courierNotAssignedLabel
                                              : switch (category) {
                                                  _LogisticsCategory.needsPickup => l10n.markPickedUpButton,
                                                  _LogisticsCategory.selfService => l10n.markSelfPickedUpButton,
                                                  _ => l10n.markDeliveredButton,
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
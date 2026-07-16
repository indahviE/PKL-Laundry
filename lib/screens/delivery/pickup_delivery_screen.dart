import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/themes/app_theme.dart';
import '../../models/order.dart';
import '../../repositories/order_repository.dart';

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
        return const Color(0xFFB197FC);
      case _LogisticsCategory.needsDelivery:
        return AppTheme.primaryColor;
      case _LogisticsCategory.selfService:
        return const Color(0xFF51CF66);
      case _LogisticsCategory.other:
        return AppTheme.textTertiary;
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

  Future<void> _markPickedUp(Order order) async {
    setState(() => _updatingOrderId = order.id);
    try {
      await ref.read(orderRepositoryProvider).markPickedUp(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${order.orderNumber} ditandai sudah dijemput', style: GoogleFonts.poppins())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update: $e', style: GoogleFonts.poppins()), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingOrderId = null);
    }
  }

  Future<void> _markDelivered(Order order) async {
    setState(() => _updatingOrderId = order.id);
    try {
      await ref.read(orderRepositoryProvider).markDelivered(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${order.orderNumber} ditandai sudah diantar', style: GoogleFonts.poppins())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update: $e', style: GoogleFonts.poppins()), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingOrderId = null);
    }
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
          borderRadius: BorderRadius.circular(11),
          child: Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.only(right: 12),
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
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF51CF66).withOpacity(0.18),
                const Color(0xFF51CF66).withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF51CF66), size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Antar Jemput',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                'Kelola jemput, antar & ambil sendiri',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textSecondary),
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
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Cari nama pelanggan atau no. pesanan...',
          hintStyle: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textTertiary),
          prefixIcon: Icon(Icons.search, color: AppTheme.textTertiary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, size: 18, color: AppTheme.textTertiary),
                  onPressed: () => setState(() => _searchController.clear()),
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
          ),
          filled: true,
          fillColor: AppTheme.cardColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.lg, vertical: AppTheme.md),
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final filters = [
      ('all', 'Semua', Icons.all_inbox_outlined, AppTheme.textSecondary),
      ('needs_pickup', 'Perlu dijemput', Icons.call_received_rounded, const Color(0xFFB197FC)),
      ('needs_delivery', 'Siap diantar', Icons.call_made_rounded, AppTheme.primaryColor),
      ('self_service', 'Ambil sendiri', Icons.storefront_outlined, const Color(0xFF51CF66)),
      ('other', 'Lainnya', Icons.more_horiz_rounded, AppTheme.textTertiary),
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
                color: isSelected ? accent.withOpacity(0.12) : AppTheme.cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(
                  color: isSelected ? accent.withOpacity(0.45) : AppTheme.borderColor,
                  width: isSelected ? 1.4 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 15, color: isSelected ? accent : AppTheme.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? accent : AppTheme.textSecondary,
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
      _StatCard(title: 'Perlu Dijemput', value: '$needsPickup', icon: Icons.call_received_rounded, color: const Color(0xFFB197FC)),
      _StatCard(title: 'Siap Diantar', value: '$needsDelivery', icon: Icons.call_made_rounded, color: AppTheme.primaryColor),
      _StatCard(title: 'Ambil Sendiri', value: '$selfService', icon: Icons.storefront_outlined, color: const Color(0xFF51CF66)),
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
              decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(Icons.local_shipping_outlined, size: 40, color: AppTheme.primaryColor.withOpacity(0.6)),
            ),
            const SizedBox(height: AppTheme.lg),
            Text('Tidak ada pesanan', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: AppTheme.sm),
            Text(
              'Belum ada pesanan yang cocok dengan filter ini',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
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
            Icon(Icons.error_outline_rounded, size: 40, color: AppTheme.errorColor),
            const SizedBox(height: AppTheme.md),
            Text(message, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
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
              onMarkPickedUp: () => _markPickedUp(order),
              onMarkDelivered: () => _markDelivered(order),
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
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 5))],
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
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.textTertiary),
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
          Text(label, style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
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
    final typeColor = order.needsPickup ? const Color(0xFFB197FC) : AppTheme.textTertiary;

    final deliveryLabel = order.needsDelivery ? 'Antar' : 'Ambil Sendiri';
    final deliveryIcon = order.needsDelivery ? Icons.call_made_rounded : Icons.storefront_outlined;
    final deliveryColor = order.needsDelivery ? AppTheme.primaryColor : const Color(0xFF51CF66);

    final hasPhone = (order.customerPhone ?? '').isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6))],
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
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppTheme.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  order.orderNumber,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.textTertiary),
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
                                    style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: categoryColor),
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
                            Icon(Icons.phone_outlined, size: 13, color: AppTheme.textTertiary),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                order.customerPhone!,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
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
                        ],
                      ),
                      const SizedBox(height: AppTheme.md),
                      Divider(height: 1, color: AppTheme.borderColor.withOpacity(0.6)),
                      const SizedBox(height: AppTheme.md),
                      Row(
                        children: [
                          Icon(Icons.schedule_outlined, size: 15, color: AppTheme.textTertiary),
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
                              style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.textTertiary),
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
                                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
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
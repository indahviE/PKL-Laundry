import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/themes/app_theme.dart';

/// Model jadwal antar/jemput
class DeliveryItem {
  final String id;
  final String customerName;
  final String customerPhone;
  final String address;
  final String type; // 'pickup' (jemput) atau 'delivery' (antar)
  final String status; // 'scheduled', 'on_the_way', 'completed', 'cancelled'
  final DateTime scheduledTime;
  final String? driverName;

  DeliveryItem({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.type,
    required this.status,
    required this.scheduledTime,
    this.driverName,
  });
}

/// Pickup & Delivery Screen (Antar Jemput)
class PickupDeliveryScreen extends StatefulWidget {
  const PickupDeliveryScreen({Key? key}) : super(key: key);

  @override
  State<PickupDeliveryScreen> createState() => _PickupDeliveryScreenState();
}

class _PickupDeliveryScreenState extends State<PickupDeliveryScreen> {
  late TextEditingController _searchController;

  String _selectedFilter = 'all'; // all, scheduled, on_the_way, completed, cancelled
  late List<DeliveryItem> _allDeliveries;
  late List<DeliveryItem> _filteredDeliveries;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _initializeSampleDeliveries();
    _filteredDeliveries = _allDeliveries;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializeSampleDeliveries() {
    final now = DateTime.now();
    _allDeliveries = [
      DeliveryItem(
        id: '#JMP-1001',
        customerName: 'Budi Santoso',
        customerPhone: '081234567890',
        address: 'Jl. Merdeka No. 45, Bandung',
        type: 'pickup',
        status: 'on_the_way',
        scheduledTime: now.add(const Duration(minutes: 30)),
        driverName: 'Andi',
      ),
      DeliveryItem(
        id: '#ANT-1002',
        customerName: 'Siti Nurhaliza',
        customerPhone: '082345678901',
        address: 'Jl. Sudirman No. 12, Bandung',
        type: 'delivery',
        status: 'scheduled',
        scheduledTime: now.add(const Duration(hours: 2)),
        driverName: null,
      ),
      DeliveryItem(
        id: '#JMP-1000',
        customerName: 'Ahmad Wijaya',
        customerPhone: '083456789012',
        address: 'Jl. Asia Afrika No. 8, Bandung',
        type: 'pickup',
        status: 'completed',
        scheduledTime: now.subtract(const Duration(hours: 3)),
        driverName: 'Andi',
      ),
      DeliveryItem(
        id: '#ANT-0998',
        customerName: 'Rina Gunawan',
        customerPhone: '084567890123',
        address: 'Jl. Dago No. 100, Bandung',
        type: 'delivery',
        status: 'completed',
        scheduledTime: now.subtract(const Duration(days: 1)),
        driverName: 'Joko',
      ),
      DeliveryItem(
        id: '#JMP-0995',
        customerName: 'Doni Hermawan',
        customerPhone: '085678901234',
        address: 'Jl. Riau No. 20, Bandung',
        type: 'pickup',
        status: 'cancelled',
        scheduledTime: now.subtract(const Duration(days: 2)),
        driverName: null,
      ),
    ];
  }

  void _applyFiltersAndSearch() {
    _filteredDeliveries = _allDeliveries.where((item) {
      bool statusMatch = _selectedFilter == 'all' || item.status == _selectedFilter;
      bool searchMatch = _searchController.text.isEmpty ||
          item.customerName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          item.address.toLowerCase().contains(_searchController.text.toLowerCase());
      return statusMatch && searchMatch;
    }).toList();
    setState(() {});
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.orange;
      case 'on_the_way':
        return AppTheme.primaryColor;
      case 'completed':
        return const Color(0xFF51CF66);
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'scheduled':
        return 'Dijadwalkan';
      case 'on_the_way':
        return 'Dalam Perjalanan';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    if (isToday) return 'Hari ini, $hour:$minute';
    return '${date.day}/${date.month}/${date.year}, $hour:$minute';
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
                        _buildHeader(context),
                        const SizedBox(height: 22),
                        _buildSearchBar(context),
                        const SizedBox(height: AppTheme.lg),
                        _buildFilterChips(context),
                        const SizedBox(height: AppTheme.xl),
                        _buildStatsSummary(context, isMobile),
                        const SizedBox(height: AppTheme.xl),
                        _filteredDeliveries.isEmpty
                            ? _buildEmptyState(context)
                            : _buildDeliveriesList(context),
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

  /// Build header — sama gayanya dengan Orders/Customers List Screen
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF51CF66).withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                color: Color(0xFF51CF66),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Antar Jemput',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kelola jadwal antar & jemput pelanggan',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Navigasi ke Jadwal Baru akan ditambahkan')),
            );
          },
          icon: const Icon(Icons.add, size: 18),
          label: Text(
            'Jadwal',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF51CF66),
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
          hintText: 'Cari nama pelanggan atau alamat...',
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

  /// Build filter chips
  Widget _buildFilterChips(BuildContext context) {
    final filters = [
      ('all', 'Semua', Icons.all_inbox_outlined),
      ('scheduled', 'Dijadwalkan', Icons.schedule_outlined),
      ('on_the_way', 'Dalam Perjalanan', Icons.local_shipping_outlined),
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
                setState(() => _selectedFilter = filters[index].$1);
                _applyFiltersAndSearch();
              },
              showCheckmark: false,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(filters[index].$3, size: 16),
                  const SizedBox(width: AppTheme.sm),
                  Text(filters[index].$2),
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
    final total = _filteredDeliveries.length;
    final onTheWay = _filteredDeliveries.where((d) => d.status == 'on_the_way').length;

    return Row(
      children: [
        Expanded(
          child: _StatBox(
            title: 'Total Jadwal',
            value: '$total',
            icon: Icons.event_note_outlined,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: AppTheme.lg),
        Expanded(
          child: _StatBox(
            title: 'Sedang Berjalan',
            value: '$onTheWay',
            icon: Icons.local_shipping_outlined,
            color: const Color(0xFF51CF66),
          ),
        ),
      ],
    );
  }

  /// Build empty state
  Widget _buildEmptyState(BuildContext context) {
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
                Icons.local_shipping_outlined,
                size: 40,
                color: AppTheme.primaryColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppTheme.lg),
            Text(
              'Tidak ada jadwal',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: AppTheme.sm),
            Text(
              'Buat jadwal antar/jemput baru untuk memulai',
              style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  /// Build deliveries list
  Widget _buildDeliveriesList(BuildContext context) {
    return Column(
      children: List.generate(
        _filteredDeliveries.length,
        (index) => Column(
          children: [
            _DeliveryCard(
              item: _filteredDeliveries[index],
              statusColor: _getStatusColor(_filteredDeliveries[index].status),
              statusLabel: _getStatusLabel(_filteredDeliveries[index].status),
              formattedTime: _formatTime(_filteredDeliveries[index].scheduledTime),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Detail jadwal ${_filteredDeliveries[index].id}')),
                );
              },
            ),
            if (index < _filteredDeliveries.length - 1) const SizedBox(height: AppTheme.lg),
          ],
        ),
      ),
    );
  }
}

// ============================================
// HELPER WIDGETS
// ============================================

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
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppTheme.md),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// Kartu jadwal antar/jemput
class _DeliveryCard extends StatelessWidget {
  final DeliveryItem item;
  final Color statusColor;
  final String statusLabel;
  final String formattedTime;
  final VoidCallback onTap;

  const _DeliveryCard({
    required this.item,
    required this.statusColor,
    required this.statusLabel,
    required this.formattedTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPickup = item.type == 'pickup';

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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.sm, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isPickup ? const Color(0xFFB197FC) : const Color(0xFF4DABF7)).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPickup ? Icons.call_received_rounded : Icons.call_made_rounded,
                            size: 12,
                            color: isPickup ? const Color(0xFFB197FC) : const Color(0xFF4DABF7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPickup ? 'Jemput' : 'Antar',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isPickup ? const Color(0xFFB197FC) : const Color(0xFF4DABF7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTheme.sm),
                    Text(
                      item.id,
                      style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.textTertiary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.md),
            Text(
              item.customerName,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined, size: 15, color: AppTheme.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.address,
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.lg),
            Divider(height: 1, color: AppTheme.borderColor.withOpacity(0.6)),
            const SizedBox(height: AppTheme.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule_outlined, size: 15, color: AppTheme.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      formattedTime,
                      style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.textTertiary),
                    ),
                  ],
                ),
                if (item.driverName != null)
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 15, color: AppTheme.textTertiary),
                      const SizedBox(width: 6),
                      Text(
                        item.driverName!,
                        style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.textTertiary),
                      ),
                    ],
                  )
                else
                  Text(
                    'Belum ada driver',
                    style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.textTertiary, fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
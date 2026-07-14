import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/themes/app_theme.dart';
import 'create_customer_screen.dart';

/// Customer Model
class CustomerItem {
  final String id;
  final String name;
  final String phone;
  final String email;
  final int totalOrders;
  final double totalSpent;
  final DateTime joinDate;
  final DateTime? lastOrderDate;
  final bool isActive;

  CustomerItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.totalOrders,
    required this.totalSpent,
    required this.joinDate,
    this.lastOrderDate,
    required this.isActive,
  });
}

/// Customers List Screen
class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({Key? key}) : super(key: key);

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  // Controllers
  late TextEditingController _searchController;

  // State
  String _selectedFilter = 'all'; // all, active, inactive
  late List<CustomerItem> _allCustomers;
  late List<CustomerItem> _filteredCustomers;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _initializeSampleCustomers();
    _filteredCustomers = _allCustomers;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Initialize sample customers
  void _initializeSampleCustomers() {
    _allCustomers = [
      CustomerItem(
        id: '1',
        name: 'Budi Santoso',
        phone: '081234567890',
        email: 'budi.santoso@email.com',
        totalOrders: 24,
        totalSpent: 3600000,
        joinDate: DateTime.now().subtract(const Duration(days: 210)),
        lastOrderDate: DateTime.now().subtract(const Duration(hours: 5)),
        isActive: true,
      ),
      CustomerItem(
        id: '2',
        name: 'Siti Nurhaliza',
        phone: '082345678901',
        email: 'siti.nurhaliza@email.com',
        totalOrders: 15,
        totalSpent: 1350000,
        joinDate: DateTime.now().subtract(const Duration(days: 130)),
        lastOrderDate: DateTime.now().subtract(const Duration(days: 1)),
        isActive: true,
      ),
      CustomerItem(
        id: '3',
        name: 'Ahmad Wijaya',
        phone: '083456789012',
        email: 'ahmad.wijaya@email.com',
        totalOrders: 8,
        totalSpent: 1760000,
        joinDate: DateTime.now().subtract(const Duration(days: 95)),
        lastOrderDate: DateTime.now(),
        isActive: true,
      ),
      CustomerItem(
        id: '4',
        name: 'Rina Gunawan',
        phone: '084567890123',
        email: 'rina.gunawan@email.com',
        totalOrders: 32,
        totalSpent: 5600000,
        joinDate: DateTime.now().subtract(const Duration(days: 400)),
        lastOrderDate: DateTime.now().subtract(const Duration(days: 2)),
        isActive: true,
      ),
      CustomerItem(
        id: '5',
        name: 'Doni Hermawan',
        phone: '085678901234',
        email: 'doni.hermawan@email.com',
        totalOrders: 3,
        totalSpent: 960000,
        joinDate: DateTime.now().subtract(const Duration(days: 60)),
        lastOrderDate: DateTime.now().subtract(const Duration(days: 45)),
        isActive: false,
      ),
      CustomerItem(
        id: '6',
        name: 'Eka Putri',
        phone: '086789012345',
        email: 'eka.putri@email.com',
        totalOrders: 1,
        totalSpent: 110000,
        joinDate: DateTime.now().subtract(const Duration(days: 20)),
        lastOrderDate: DateTime.now().subtract(const Duration(days: 20)),
        isActive: false,
      ),
    ];
  }

  /// Filter dan search customers
  void _applyFiltersAndSearch() {
    _filteredCustomers = _allCustomers.where((customer) {
      bool statusMatch = _selectedFilter == 'all' ||
          (_selectedFilter == 'active' && customer.isActive) ||
          (_selectedFilter == 'inactive' && !customer.isActive);
      bool searchMatch = _searchController.text.isEmpty ||
          customer.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          customer.phone.contains(_searchController.text);
      return statusMatch && searchMatch;
    }).toList();
    setState(() {});
  }

  /// Format currency
  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  /// Format relative last order date
  String _formatLastOrder(DateTime? date) {
    if (date == null) return 'Belum pernah order';
    final diff = DateTime.now().difference(date);
    if (diff.inHours < 1) return 'Baru saja';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 30) return '${diff.inDays} hari lalu';
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Buka Create Customer screen, refresh list kalau berhasil disimpan
  Future<void> _openCreateCustomer(BuildContext context) async {
    final result = await context.push<bool>('/customers/create');
    if (result == true && mounted) {
      // TODO: refresh dari Firestore begitu backend-nya siap
      _applyFiltersAndSearch();
    }
  }

  /// Get initials for avatar
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
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
                        _buildFilterButtons(context),
                        const SizedBox(height: AppTheme.xl),
                        _buildStatsSummary(context, isMobile),
                        const SizedBox(height: AppTheme.xl),
                        _filteredCustomers.isEmpty
                            ? _buildEmptyState(context)
                            : _buildCustomersList(context, isMobile),
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

  /// Build header (solid, no gradient)
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.people_alt_rounded,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pelanggan',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kelola data pelanggan laundry Anda',
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
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _openCreateCustomer(context),
          icon: const Icon(Icons.person_add_outlined, size: 18),
          label: Text(
            'Baru',
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
          hintText: 'Cari nama atau nomor telepon...',
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

  /// Build filter buttons
  Widget _buildFilterButtons(BuildContext context) {
    final filters = [
      ('all', 'Semua', Icons.people_outline),
      ('active', 'Aktif', Icons.check_circle_outline),
      ('inactive', 'Tidak Aktif', Icons.pause_circle_outline),
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
    final totalCustomers = _filteredCustomers.length;
    final totalSpent = _filteredCustomers.fold<double>(
      0,
      (sum, customer) => sum + customer.totalSpent,
    );

    return Row(
      children: [
        Expanded(
          child: _StatBox(
            title: 'Total Pelanggan',
            value: '$totalCustomers',
            icon: Icons.people_outline,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: AppTheme.lg),
        Expanded(
          child: _StatBox(
            title: 'Total Transaksi',
            value: _formatCurrency(totalSpent),
            icon: Icons.payments_outlined,
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
                Icons.people_outline,
                size: 40,
                color: AppTheme.primaryColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppTheme.lg),
            Text(
              'Tidak ada pelanggan',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.sm),
            Text(
              'Tambahkan pelanggan baru untuk memulai',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.xl),
            ElevatedButton.icon(
              onPressed: () => _openCreateCustomer(context),
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: Text('Tambah Pelanggan', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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

  /// Build customers list
  Widget _buildCustomersList(BuildContext context, bool isMobile) {
    return Column(
      children: List.generate(
        _filteredCustomers.length,
        (index) => Column(
          children: [
            _CustomerCard(
              customer: _filteredCustomers[index],
              initials: _getInitials(_filteredCustomers[index].name),
              formattedSpent: _formatCurrency(_filteredCustomers[index].totalSpent),
              formattedLastOrder: _formatLastOrder(_filteredCustomers[index].lastOrderDate),
              onTap: () => context.push('/customers/${_filteredCustomers[index].id}'),
            ),
            if (index < _filteredCustomers.length - 1)
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

/// Stat Box Widget
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

/// Customer Card Widget
class _CustomerCard extends StatelessWidget {
  final CustomerItem customer;
  final String initials;
  final String formattedSpent;
  final String formattedLastOrder;
  final VoidCallback onTap;

  const _CustomerCard({
    required this.customer,
    required this.initials,
    required this.formattedSpent,
    required this.formattedLastOrder,
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
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                  child: Text(
                    initials,
                    style: GoogleFonts.poppins(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        customer.phone,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.md,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (customer.isActive ? const Color(0xFF51CF66) : Colors.grey)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Text(
                    customer.isActive ? 'Aktif' : 'Tidak Aktif',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: customer.isActive ? const Color(0xFF51CF66) : Colors.grey.shade600,
                    ),
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
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 15,
                      color: AppTheme.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${customer.totalOrders} pesanan',
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
                      Icons.schedule_outlined,
                      size: 15,
                      color: AppTheme.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formattedLastOrder,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
                Text(
                  formattedSpent,
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
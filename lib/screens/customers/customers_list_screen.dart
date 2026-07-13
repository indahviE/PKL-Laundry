import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';

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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? AppTheme.lg : AppTheme.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with action button
              _buildHeader(context),

              const SizedBox(height: AppTheme.xl),

              // Search bar
              _buildSearchBar(context),

              const SizedBox(height: AppTheme.lg),

              // Filter buttons
              _buildFilterButtons(context),

              const SizedBox(height: AppTheme.xl),

              // Stats summary
              _buildStatsSummary(context, isMobile),

              const SizedBox(height: AppTheme.xl),

              // Customers list
              _filteredCustomers.isEmpty
                  ? _buildEmptyState(context)
                  : _buildCustomersList(context, isMobile),

              const SizedBox(height: AppTheme.lg),
            ],
          ),
        ),
      ),
    );
  }

  /// Build App Bar
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'Pelanggan',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    );
  }

  /// Build header
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daftar Pelanggan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.sm),
            Text(
              'Kelola data pelanggan laundry Anda',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.gray600,
                  ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Navigasi ke Create Customer akan ditambahkan'),
              ),
            );
          },
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Pelanggan Baru'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5DADE2),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.lg,
              vertical: AppTheme.md,
            ),
          ),
        ),
      ],
    );
  }

  /// Build search bar
  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      controller: _searchController,
      onChanged: (value) => _applyFiltersAndSearch(),
      decoration: InputDecoration(
        hintText: 'Cari nama atau nomor telepon...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: const BorderSide(color: Color(0xFF5DADE2), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.lg,
          vertical: AppTheme.md,
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
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(filters[index].$3, size: 16),
                  const SizedBox(width: AppTheme.sm),
                  Text(filters[index].$2),
                ],
              ),
              backgroundColor: Colors.grey.shade100,
              selectedColor: const Color(0xFF5DADE2).withOpacity(0.2),
              labelStyle: TextStyle(
                color: _selectedFilter == filters[index].$1
                    ? const Color(0xFF5DADE2)
                    : AppTheme.gray600,
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
            color: const Color(0xFF5DADE2),
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
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: AppTheme.lg),
            Text(
              'Tidak ada pelanggan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.sm),
            Text(
              'Tambahkan pelanggan baru untuk memulai',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.gray600,
                  ),
            ),
            const SizedBox(height: AppTheme.xl),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Tambah Pelanggan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5DADE2),
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
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Detail pelanggan ${_filteredCustomers[index].name}'),
                  ),
                );
              },
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

/// Stat Box Widget (sama seperti di OrdersListScreen)
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.sm),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
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
                  backgroundColor: const Color(0xFF5DADE2).withOpacity(0.15),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Color(0xFF5DADE2),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              customer.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        customer.phone,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.md,
                    vertical: AppTheme.sm,
                  ),
                  decoration: BoxDecoration(
                    color: (customer.isActive ? const Color(0xFF51CF66) : Colors.grey)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Text(
                    customer.isActive ? 'Aktif' : 'Tidak Aktif',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: customer.isActive ? const Color(0xFF51CF66) : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.lg),
            const Divider(height: 1),
            const SizedBox(height: AppTheme.md),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: AppTheme.sm),
                    Text(
                      '${customer.totalOrders} pesanan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: AppTheme.sm),
                    Text(
                      formattedLastOrder,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Text(
                  formattedSpent,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5DADE2),
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
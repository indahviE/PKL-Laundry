import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/themes/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../customers/create_customer_screen.dart';

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

  /// Mapping dari dokumen Firestore users/{uid}/customers/{customerId}
  /// sesuai skema di PRD (bagian 3.3.1 Manajemen Pelanggan)
  factory CustomerItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime? _toDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return CustomerItem(
      id: doc.id,
      name: (data['full_name'] ?? '') as String,
      phone: (data['phone'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      totalOrders: (data['total_orders'] ?? 0) is int
          ? data['total_orders'] as int
          : ((data['total_orders'] ?? 0) as num).toInt(),
      totalSpent: ((data['total_spent'] ?? 0) as num).toDouble(),
      joinDate: _toDate(data['created_at']) ?? DateTime.now(),
      lastOrderDate: _toDate(data['last_order_date']),
      isActive: (data['is_active'] ?? true) as bool,
    );
  }
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
  List<CustomerItem> _allCustomers = [];
  List<CustomerItem> _filteredCustomers = [];

  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<QuerySnapshot>? _customersSubscription;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _listenToCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customersSubscription?.cancel();
    super.dispose();
  }

  /// Subscribe realtime ke users/{uid}/customers di Firestore.
  /// Begitu CreateCustomerScreen nulis dokumen baru, list ini
  /// otomatis ke-update tanpa perlu manual refresh.
  void _listenToCustomers() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sesi tidak ditemukan, silakan login ulang.';
      });
      return;
    }

    final customersRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('customers')
        .orderBy('created_at', descending: true);

    _customersSubscription?.cancel();
    _customersSubscription = customersRef.snapshots().listen(
      (snapshot) {
        _allCustomers =
            snapshot.docs.map((doc) => CustomerItem.fromFirestore(doc)).toList();
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
  String _formatLastOrder(AppLocalizations l10n, DateTime? date) {
    if (date == null) return l10n.neverOrderedLabel;
    final diff = DateTime.now().difference(date);
    if (diff.inHours < 1) return l10n.justNowLabel;
    if (diff.inHours < 24) return l10n.hoursAgoLabel(diff.inHours);
    if (diff.inDays < 30) return l10n.daysAgoLabel(diff.inDays);
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Buka Create Customer screen. List sudah realtime lewat
  /// snapshots(), jadi begitu dokumen baru tersimpan, dia
  /// otomatis muncul di sini tanpa perlu logic refresh manual.
  Future<void> _openCreateCustomer(BuildContext context) async {
    await context.push<bool>('/customers/create');
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
    final l10n = AppLocalizations.of(context)!;
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
                        _buildHeader(context, l10n, isMobile),
                        const SizedBox(height: 22),
                        _buildSearchBar(context, l10n),
                        const SizedBox(height: AppTheme.lg),
                        _buildFilterButtons(context, l10n),
                        const SizedBox(height: AppTheme.xl),
                        _buildStatsSummary(context, l10n, isMobile),
                        const SizedBox(height: AppTheme.xl),
                        if (_isLoading)
                          _buildLoadingState(context)
                        else if (_errorMessage != null)
                          _buildErrorState(context, l10n)
                        else if (_filteredCustomers.isEmpty)
                          _buildEmptyState(context, l10n)
                        else
                          _buildCustomersList(context, l10n, isMobile),
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
  ///
  /// FIX overflow mobile: judul + subtitle sebelumnya nggak dibungkus
  /// Expanded, jadi kalau lebar layar sempit dan teksnya panjang, Row
  /// (badge + judul + tombol "+ Baru") jadi lebih lebar dari layar ->
  /// overflow. Sekarang blok judul dibungkus Expanded (otomatis ellipsis
  /// kalau kepanjangan), dan khusus mobile tombolnya diringkas jadi
  /// icon-only (bulat) biar nggak makan tempat.
  Widget _buildHeader(BuildContext context, AppLocalizations l10n, bool isMobile) {
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
            Icons.people_alt_rounded,
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
                l10n.customersTitle,
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
                l10n.customersSubtitle,
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
          _CompactAddButton(onTap: () => _openCreateCustomer(context))
        else
          ElevatedButton.icon(
            onPressed: () => _openCreateCustomer(context),
            icon: const Icon(Icons.person_add_outlined, size: 18),
            label: Text(
              l10n.newCustomerButton,
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
  Widget _buildSearchBar(BuildContext context, AppLocalizations l10n) {
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
          hintText: l10n.searchCustomerHint,
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
  Widget _buildFilterButtons(BuildContext context, AppLocalizations l10n) {
    final filters = [
      ('all', l10n.filterAll, Icons.people_outline),
      ('active', l10n.customerActiveLabel, Icons.check_circle_outline),
      ('inactive', l10n.customerInactiveLabel, Icons.pause_circle_outline),
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
  Widget _buildStatsSummary(BuildContext context, AppLocalizations l10n, bool isMobile) {
    final totalCustomers = _filteredCustomers.length;
    final totalSpent = _filteredCustomers.fold<double>(
      0,
      (sum, customer) => sum + customer.totalSpent,
    );

    return Row(
      children: [
        Expanded(
          child: _StatBox(
            title: l10n.totalCustomersLabel,
            value: '$totalCustomers',
            icon: Icons.people_outline,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: AppTheme.lg),
        Expanded(
          child: _StatBox(
            title: l10n.totalTransactionsLabel,
            value: _formatCurrency(totalSpent),
            icon: Icons.payments_outlined,
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
  Widget _buildErrorState(BuildContext context, AppLocalizations l10n) {
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
              onPressed: _listenToCustomers,
              child: Text('Coba lagi', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
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
              l10n.emptyCustomersTitle,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.sm),
            Text(
              l10n.emptyCustomersSubtitle,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.xl),
            ElevatedButton.icon(
              onPressed: () => _openCreateCustomer(context),
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: Text(l10n.addCustomerButton, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
  Widget _buildCustomersList(BuildContext context, AppLocalizations l10n, bool isMobile) {
    return Column(
      children: List.generate(
        _filteredCustomers.length,
        (index) => Column(
          children: [
            _CustomerCard(
              customer: _filteredCustomers[index],
              l10n: l10n,
              initials: _getInitials(_filteredCustomers[index].name),
              formattedSpent: _formatCurrency(_filteredCustomers[index].totalSpent),
              formattedLastOrder: _formatLastOrder(l10n, _filteredCustomers[index].lastOrderDate),
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

/// Tombol "+ Baru" versi ringkas (icon-only, bulat) khusus mobile,
/// biar header nggak overflow saat layar sempit.
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
          child: Icon(Icons.person_add_outlined, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

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
  final AppLocalizations l10n;
  final String initials;
  final String formattedSpent;
  final String formattedLastOrder;
  final VoidCallback onTap;

  const _CustomerCard({
    required this.customer,
    required this.l10n,
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
                    customer.isActive ? l10n.customerActiveLabel : l10n.customerInactiveLabel,
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
                      l10n.ordersCountLabel(customer.totalOrders),
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
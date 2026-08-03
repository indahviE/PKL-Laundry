import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/themes/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../customers/create_customer_screen.dart';

// ============================================
// DESIGN TOKENS — disalin persis dari order_list_screen.dart supaya
// filter cabang & filter status di sini punya bentuk dan warna yang
// sama persis dengan halaman Order List.
// ============================================
const Color _cCard = Color(0xFFFFFFFF);
const Color _cOnSurface = Color(0xFF1B1C1C);
const Color _cOnSurfaceVariant = Color(0xFF404752);
const Color _cOutlineVariant = Color(0xFFBFC7D4);
// FIX: sebelumnya sempat kepakai _cPrimaryContainer (#2196F3, terlalu
// terang). Chip cabang terpilih di order_list_screen.dart pakai _cPrimary
// (#0061A4, lebih gelap/pekat) — disamain ke situ.
const Color _cPrimary = Color(0xFF0061A4);
const Color _cSurfaceContainerHighest = Color(0xFFE4E2E1); // chip "Semua"

/// Warna chip status "Aktif" — hijau, sama persis dengan _statusGreen
/// (status Selesai) di order_list_screen.dart.
const Color _cActiveChipBg = Color(0xFFF0FDF4);
const Color _cActiveChipBorder = Color(0xFFBBF7D0);
const Color _cActiveChipText = Color(0xFF166534);

/// Warna chip status "Tidak Aktif" — merah, sama persis dengan
/// _statusRed (status Dibatalkan) di order_list_screen.dart. Selaras
/// dengan DESIGN.md: "Red: ... or inactive accounts."
const Color _cInactiveChipBg = Color(0xFFFEF2F2);
const Color _cInactiveChipBorder = Color(0xFFFECACA);
const Color _cInactiveChipText = Color(0xFF991B1B);

/// Opsi cabang buat filter, di-fetch dari users/{uid}/laundries
/// (sesuai Blueprint §3.2.3). Pola sama persis dengan _LaundryOption di
/// CreateOrderScreen / CreateCustomerScreen.
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
  // Cabang tempat pelanggan ini terdaftar (field tambahan di luar skema
  // PRD §3.3.1, lihat CreateCustomerScreen). Bisa null buat pelanggan
  // lama yang dibuat sebelum field ini ada.
  final String? laundryId;

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
    this.laundryId,
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
      laundryId: data['laundry_id'] as String?,
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

  // Filter cabang - CUMA ditampilkan kalau owner punya lebih dari 1
  // cabang aktif (_showLaundryFilter). 'all' berarti tampilkan semua
  // cabang sekaligus (termasuk pelanggan lama yang laundry_id-nya masih
  // null / belum di-assign).
  List<_LaundryOption> _laundriesList = [];
  String _selectedLaundryId = 'all';

  bool get _showLaundryFilter => _laundriesList.length > 1;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _listenToCustomers();
    _fetchLaundries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customersSubscription?.cancel();
    super.dispose();
  }

  /// Ambil semua cabang aktif milik company ini, buat filter chip cabang.
  /// Kalau cabang cuma 1 (mis. paket Starter), filter ini gak ditampilkan
  /// sama sekali - percuma difilter wong cuma ada 1 pilihan.
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

      if (!mounted) return;
      setState(() {
        _laundriesList = laundriesSnap.docs.map((d) => _LaundryOption.fromFirestore(d)).toList();
      });
    } catch (e) {
      // Gagal ambil cabang bukan error fatal buat halaman ini - filter
      // cabang cuma gak akan muncul, list pelanggan tetap jalan normal.
      debugPrint('Gagal memuat data cabang: $e');
    }
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

  /// Filter dan search customers - sekarang ditambah filter cabang.
  /// Filter cabang cuma dipakai kalau _selectedLaundryId != 'all'.
  void _applyFiltersAndSearch() {
    _filteredCustomers = _allCustomers.where((customer) {
      bool statusMatch = _selectedFilter == 'all' ||
          (_selectedFilter == 'active' && customer.isActive) ||
          (_selectedFilter == 'inactive' && !customer.isActive);
      bool laundryMatch =
          _selectedLaundryId == 'all' || customer.laundryId == _selectedLaundryId;
      bool searchMatch = _searchController.text.isEmpty ||
          customer.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          customer.phone.contains(_searchController.text);
      return statusMatch && laundryMatch && searchMatch;
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

  /// Cari nama cabang dari laundryId, buat ditampilkan sebagai badge kecil
  /// di kartu pelanggan (mirip badge "Menteng"/"Sudirman" di code.html).
  /// Null kalau customer belum di-assign ke cabang manapun atau cabangnya
  /// sudah tidak ada di _laundriesList.
  String? _branchNameFor(String? laundryId) {
    if (laundryId == null) return null;
    for (final laundry in _laundriesList) {
      if (laundry.id == laundryId) return laundry.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      // Disamain persis dengan _DS.canvas di services_list_screen.dart
      // (#F5F7FA) — sebelumnya sempat disamain ke #FBF9F8 (order_list),
      // sekarang diganti ke referensi services sesuai permintaan terbaru.
      backgroundColor: const Color(0xFFF5F7FA),
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
                        _buildHeader(context, l10n),
                        const SizedBox(height: 22),
                        _buildSearchBar(context, l10n),
                        const SizedBox(height: AppTheme.lg),
                        if (_showLaundryFilter) ...[
                          _buildLaundryFilterButtons(context),
                          const SizedBox(height: AppTheme.md),
                        ],
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
  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
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
        // Disamain dengan services_list_screen.dart: tombol bulat 40x40,
        // background biru muda (#D1E4FF) + ikon warna navy (#0B3B66)
        // (sebelumnya sempat disamain ke gaya laundries_list_screen.dart
        // yang bg primaryColor solid + ikon putih).
        InkWell(
          onTap: () => _openCreateCustomer(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF2196F3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
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

  /// Build filter buttons (status: all/active/inactive) — sekarang
  /// bentuknya segmented control (tab pill di dalam 1 container abu-abu),
  /// meniru pola "Semua / Aktif / Tidak Aktif" di code.html.
  /// Filter status "Semua/Aktif/Tidak Aktif" — disamain persis sama
  /// _buildFilterButtons di order_list_screen.dart: chip persegi
  /// (radius 8) bertona warna sesuai statusnya, "Semua" pakai netral
  /// surface-container-highest.
  Widget _buildFilterButtons(BuildContext context, AppLocalizations l10n) {
    final filters = [
      ('all', l10n.filterAll),
      ('active', l10n.customerActiveLabel),
      ('inactive', l10n.customerInactiveLabel),
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

          final Color bg;
          final Color border;
          final Color text;
          if (isAll) {
            bg = _cSurfaceContainerHighest;
            border = Colors.transparent;
            text = _cOnSurface;
          } else if (key == 'active') {
            bg = _cActiveChipBg;
            border = _cActiveChipBorder;
            text = _cActiveChipText;
          } else {
            bg = _cInactiveChipBg;
            border = _cInactiveChipBorder;
            text = _cInactiveChipText;
          }

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

  /// Build filter chip CABANG - baris terpisah DI ATAS filter status,
  /// cuma dirender kalau _showLaundryFilter true (cabang > 1). Chip
  /// pertama selalu "Semua Cabang", sisanya sesuai nama cabang aktif.
  Widget _buildLaundryFilterButtons(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.sm),
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
              padding: EdgeInsets.only(right: isLast ? 0 : AppTheme.sm),
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

  /// Chip pill cabang — disamain persis sama _buildLaundryChip di
  /// order_list_screen.dart (bentuk pill penuh, warna solid _cPrimary
  /// yang lebih gelap/pekat saat terpilih, putih+border saat tidak).
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
    // Beda pesan kalau kosong gara-gara filter cabang lagi aktif (bukan
    // benar-benar belum ada pelanggan sama sekali).
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
                Icons.people_outline,
                size: 40,
                color: AppTheme.primaryColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppTheme.lg),
            Text(
              isFilteredByLaundry ? 'Belum ada pelanggan di cabang ini' : l10n.emptyCustomersTitle,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.sm),
            Text(
              isFilteredByLaundry
                  ? 'Coba pilih cabang lain, atau tambahkan pelanggan baru ke cabang ini.'
                  : l10n.emptyCustomersSubtitle,
              textAlign: TextAlign.center,
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
                backgroundColor: const Color(0xFF2196F3),
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
              branchName: _branchNameFor(_filteredCustomers[index].laundryId),
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

/// Customer Card Widget — layout mengikuti code.html: avatar inisial warna
/// variatif, nama + dot indikator aktif/nonaktif, badge cabang kecil + jumlah
/// order, dan label "Total Spent" di kanan.
class _CustomerCard extends StatelessWidget {
  final CustomerItem customer;
  final AppLocalizations l10n;
  final String initials;
  final String? branchName;
  final String formattedSpent;
  final String formattedLastOrder;
  final VoidCallback onTap;

  const _CustomerCard({
    required this.customer,
    required this.l10n,
    required this.initials,
    required this.branchName,
    required this.formattedSpent,
    required this.formattedLastOrder,
    required this.onTap,
  });

  // Palet warna avatar inisial, dipilih otomatis dari huruf pertama nama
  // supaya kartu terlihat variatif — meniru variasi warna avatar
  // (blue/orange/gray/purple) di code.html.
  static final List<Color> _avatarPalette = [
    AppTheme.primaryColor,
    const Color(0xFFE67E22),
    const Color(0xFF8E44AD),
    const Color(0xFF16A085),
    const Color(0xFFEB74A8),
    const Color(0xFF5499C7),
  ];

  Color _avatarColorFor(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return _avatarPalette[0];
    return _avatarPalette[trimmed.codeUnitAt(0) % _avatarPalette.length];
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = _avatarColorFor(customer.name);

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: avatarColor.withOpacity(0.14),
              child: Text(
                initials,
                style: GoogleFonts.poppins(
                  color: avatarColor,
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          customer.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.5,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Dot kecil hijau/abu-abu menggantikan badge besar
                      // Aktif/Nonaktif, meniru pola indikator di code.html.
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: customer.isActive ? const Color(0xFF51CF66) : AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    customer.phone,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      if (branchName != null) ...[
                        Flexible  (
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              branchName!.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Icon(Icons.receipt_long_outlined, size: 13, color: AppTheme.textTertiary),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          l10n.ordersCountLabel(customer.totalOrders),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.sm),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TOTAL SPENT',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formattedSpent,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_outlined, size: 11, color: AppTheme.textTertiary),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          formattedLastOrder,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
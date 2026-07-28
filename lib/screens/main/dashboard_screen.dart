import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/themes/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Dashboard Screen - NetWash
/// Terintegrasi dengan Firebase Firestore (Real-time Streams)
/// Mengimplementasikan Fitur Gating / Limit Paket Langganan secara Asli
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Warna sekarang mengikuti AppTheme supaya tema dashboard
  // konsisten dengan halaman lain (mis. OrdersListScreen).
  static Color get primaryBlue => AppTheme.primaryColor;
  static Color get deepBlue => AppTheme.primaryColor.withOpacity(0.85);
  static Color get textBlue => AppTheme.primaryColor;
  // Disamain dengan _DS.canvas di services_list_screen.dart (#F5F7FA),
  // supaya warna canvas dashboard konsisten sama halaman Layanan —
  // sebelumnya pakai #FBF9F8 yang keliatan agak krem/beda nuansa.
  static const Color bgColor = Color(0xFFF5F7FA);
  // Disamain dengan _DS.surface di services_list_screen.dart (Colors.white),
  // supaya card di dashboard & halaman Layanan senada persis.
  static const Color cardColor = Colors.white;
  static Color get textPrimary => AppTheme.textPrimary;
  static Color get textSecondary => AppTheme.textSecondary;
  static Color get textTertiary => AppTheme.textTertiary;
  static Color get borderColor => AppTheme.borderColor;

  // Status dismiss checklist onboarding secara lokal
  bool _setupDismissed = false;

  // Cabang yang lagi dipilih di selector atas. 'all' = tampilkan semua
  // cabang. Dipakai buat filter query 'orders' lewat _ordersBaseQuery()
  // di bawah (balance card, notifikasi, chart mingguan, & timeline).
  String _selectedBranchId = 'all';
  String _selectedBranchName = 'Semua Cabang';

  /// FIX: sebelumnya ini `final String _currentUserId = ...` yang dibaca
  /// SEKALI saat State dibuat. Kalau widget ini sempat ke-build sebelum
  /// FirebaseAuth kelar restore session (race condition umum saat startup),
  /// nilainya nyangkut jadi "placeholder_uid" selamanya untuk instance ini —
  /// semua stream Firestore (termasuk chart mingguan) jadi query ke user
  /// yang salah dan datanya keliatan kosong terus.
  /// Sekarang jadi getter, jadi selalu baca currentUser terbaru tiap dipakai.
  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? "placeholder_uid";

  /// Base query buat collection 'orders' milik user aktif, otomatis
  /// ke-filter sesuai cabang yang lagi dipilih (_selectedBranchId).
  /// Kalau 'all', tidak ada filter tambahan (nampilin semua cabang).
  ///
  /// Dipakai di SEMUA tempat yang query 'orders' di dashboard ini
  /// (balance card, notification bell, weekly chart, timeline) supaya
  /// begitu user ganti cabang di selector atas, seluruh dashboard
  /// ikut ke-filter secara konsisten — bukan cuma label-nya doang.
  ///
  /// CATATAN: field 'laundry_id' harus ada di tiap dokumen order
  /// (diisi dari _selectedLaundryId saat order dibuat di
  /// CreateOrderScreen). Kombinasi where('laundry_id', ...) dengan
  /// where('status', ...) / where('order_date', ...) kemungkinan
  /// butuh composite index baru di Firestore — kalau muncul error
  /// FAILED_PRECONDITION di log/console, klik link yang disediakan
  /// Firebase buat generate index-nya otomatis.
  Query<Map<String, dynamic>> _ordersBaseQuery() {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('orders');

    if (_selectedBranchId != 'all') {
      q = q.where('laundry_id', isEqualTo: _selectedBranchId);
    }
    return q;
  }

  /// Format angka jadi "Rp X.XXX.XXX" - dipakai di kartu Pesanan Terbaru.
  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isDesktop = width >= 1024;
    final maxContentWidth = isDesktop ? 1100.0 : double.infinity;

    return Scaffold(
      backgroundColor: bgColor,
      body: DefaultTextStyle.merge(
        // Menerapkan font Poppins ke seluruh teks di dalam dashboard ini,
        // sama seperti font yang dipakai di OrdersListScreen.
        style: GoogleFonts.poppins(),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              children: [
                // ==== Bagian TETAP (pinned) saat konten di-scroll ====
                // Cuma selector cabang aktif + bell notifikasi.
                _buildPinnedSelectorBar(context, isMobile, t),
                // ==== Konten yang bisa di-scroll ====
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? AppTheme.lg : AppTheme.xxl,
                        0,
                        isMobile ? AppTheme.lg : AppTheme.xxl,
                        AppTheme.xxl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGreeting(t),
                          const SizedBox(height: AppTheme.xl),
                          _buildBalanceCardRealtime(t),
                          const SizedBox(height: AppTheme.xl),
                          _buildSetupChecklistRealtime(t),
                          const SizedBox(height: AppTheme.xl),
                          _buildQuickActions(context, t),
                          const SizedBox(height: AppTheme.xl),
                          _buildWeeklyChartRealtime(t),
                          const SizedBox(height: AppTheme.xl),
                          _buildOrdersHeader(context, t),
                          const SizedBox(height: AppTheme.md),
                          _buildTimelineRealtime(t),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // PINNED SELECTOR BAR (Cabang Selector + Notifikasi) — TETAP saat scroll
  // ============================================
  Widget _buildPinnedSelectorBar(BuildContext context, bool isMobile, AppLocalizations t) {
    return Container(
      width: double.infinity,
      color: bgColor,
      padding: EdgeInsets.fromLTRB(
        isMobile ? AppTheme.lg : AppTheme.xxl,
        AppTheme.md + MediaQuery.of(context).padding.top,
        isMobile ? AppTheme.lg : AppTheme.xxl,
        AppTheme.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Selector cabang - tap membuka bottom sheet daftar cabang
          // yang di-fetch dari users/{uid}/laundries.
          InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            onTap: () => _showBranchSelector(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CABANG AKTIF',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _selectedBranchName,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: textPrimary),
                  ],
                ),
              ],
            ),
          ),
          _buildNotificationBell(context, t),
        ],
      ),
    );
  }

  // ============================================
  // SAPAAN (Selamat Pagi/Siang/Malam) — ikut SCROLL
  // ============================================
  Widget _buildGreeting(AppLocalizations t) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? t.greetingMorning
        : (hour < 17 ? t.greetingAfternoon : t.greetingEvening);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 21,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          t.dashboardSubtitle,
          style: TextStyle(color: textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  // ============================================
  // BRANCH SELECTOR (Firestore Stream - users/{uid}/laundries)
  // ============================================
  void _showBranchSelector(BuildContext context) {
    // Query pencarian lokal buat bottom sheet ini aja (di-reset tiap kali
    // sheet dibuka ulang). Berguna kalau jumlah cabang banyak (mis. paket
    // dengan kuota cabang unlimited) supaya user nggak perlu scroll manual.
    String branchSearchQuery = '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: borderColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppTheme.lg, AppTheme.lg, AppTheme.lg, AppTheme.md),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pilih Cabang',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => Navigator.of(sheetContext).pop(),
                              child: Icon(Icons.close_rounded, size: 20, color: textTertiary),
                            ),
                          ],
                        ),
                      ),
                      // ==== Search cabang - biar gampang dicari kalau
                      // cabangnya banyak (mis. paket cabang unlimited) ====
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppTheme.lg, 0, AppTheme.lg, AppTheme.md),
                        child: TextField(
                          onChanged: (value) => setModalState(() => branchSearchQuery = value),
                          style: TextStyle(fontSize: 13.5, color: textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Cari nama cabang...',
                            hintStyle: TextStyle(fontSize: 13.5, color: textTertiary),
                            prefixIcon: Icon(Icons.search, color: textTertiary, size: 20),
                            isDense: true,
                            filled: true,
                            fillColor: bgColor,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              borderSide: BorderSide(color: primaryBlue, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(_currentUserId)
                              .collection('laundries')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final allDocs = snapshot.data?.docs ?? [];
                            final query = branchSearchQuery.trim().toLowerCase();

                            // "Semua Cabang" tetap muncul selama belum ada
                            // pencarian aktif - begitu user ngetik, opsi ini
                            // ikut ke-filter berdasarkan query juga.
                            final showAllOption = query.isEmpty || 'semua cabang'.contains(query);

                            final docs = query.isEmpty
                                ? allDocs
                                : allDocs.where((doc) {
                                    final data = doc.data() as Map<String, dynamic>? ?? {};
                                    final name = (data['name'] ?? data['branch_name'] ?? '') as String;
                                    return name.toLowerCase().contains(query);
                                  }).toList();

                            final isEmptyResult = docs.isEmpty && !showAllOption;

                            return ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(AppTheme.lg, 0, AppTheme.lg, AppTheme.xl),
                              children: [
                                if (showAllOption) ...[
                                  _buildBranchOption(
                                    sheetContext,
                                    id: 'all',
                                    name: 'Semua Cabang',
                                    isSelected: _selectedBranchId == 'all',
                                  ),
                                  const SizedBox(height: AppTheme.sm),
                                ],
                                ...docs.map((doc) {
                                  final data = doc.data() as Map<String, dynamic>? ?? {};
                                  final name = (data['name'] ?? data['branch_name'] ?? 'Cabang') as String;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: AppTheme.sm),
                                    child: _buildBranchOption(
                                      sheetContext,
                                      id: doc.id,
                                      name: name,
                                      isSelected: _selectedBranchId == doc.id,
                                    ),
                                  );
                                }),
                                if (allDocs.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: AppTheme.xl),
                                    child: Column(
                                      children: [
                                        Icon(Icons.storefront_outlined, size: 36, color: textTertiary),
                                        const SizedBox(height: AppTheme.md),
                                        Text(
                                          'Belum ada cabang terdaftar',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                                        ),
                                      ],
                                    ),
                                  )
                                else if (isEmptyResult)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: AppTheme.xl),
                                    child: Column(
                                      children: [
                                        Icon(Icons.search_off_rounded, size: 36, color: textTertiary),
                                        const SizedBox(height: AppTheme.md),
                                        Text(
                                          'Cabang tidak ditemukan',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Satu baris opsi cabang di bottom sheet selector.
  Widget _buildBranchOption(
    BuildContext sheetContext, {
    required String id,
    required String name,
    required bool isSelected,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      onTap: () {
        setState(() {
          _selectedBranchId = id;
          _selectedBranchName = name;
        });
        Navigator.of(sheetContext).pop();
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.md),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue.withOpacity(0.08) : bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: isSelected ? primaryBlue.withOpacity(0.4) : borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.storefront_outlined, size: 18, color: textBlue),
            ),
            const SizedBox(width: AppTheme.md),
            Expanded(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: textPrimary),
              ),
            ),
            if (isSelected) Icon(Icons.check_circle_rounded, size: 20, color: primaryBlue),
          ],
        ),
      ),
    );
  }

  // ============================================
  // NOTIFICATION BELL (Firestore Stream - pending orders di cabang aktif)
  // ============================================
  // Badge angka = jumlah pesanan berstatus 'pending' saat ini (real-time),
  // sudah ke-filter sesuai cabang yang lagi dipilih lewat _ordersBaseQuery().
  // Tap => buka bottom sheet berisi list pesanan pending tsb.
  Widget _buildNotificationBell(BuildContext context, AppLocalizations t) {
    final pendingQuery = _ordersBaseQuery().where('status', isEqualTo: 'pending');

    return StreamBuilder<QuerySnapshot>(
      stream: pendingQuery.snapshots(),
      builder: (context, snapshot) {
        final pendingCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: () => _showPendingOrdersSheet(context, t),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(Icons.notifications_none_rounded, color: textBlue, size: 20),
                if (pendingCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: bgColor, width: 1.5),
                      ),
                      child: Text(
                        pendingCount > 9 ? '9+' : '$pendingCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPendingOrdersSheet(BuildContext context, AppLocalizations t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppTheme.lg, AppTheme.lg, AppTheme.lg, AppTheme.md),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _ordersBaseQuery().where('status', isEqualTo: 'pending').snapshots(),
                      builder: (context, snapshot) {
                        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              t.notificationsPanelTitle,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                            ),
                            if (count > 0)
                              Text(
                                t.pendingOrdersNotifSubtitle(count),
                                style: TextStyle(fontSize: 11.5, color: textSecondary),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _ordersBaseQuery().where('status', isEqualTo: 'pending').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppTheme.lg),
                              child: Text(
                                '${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: textSecondary),
                              ),
                            ),
                          );
                        }

                        // Sort di client (bukan pakai .orderBy() di query) supaya
                        // query where('status')+orderBy('order_date') tidak butuh
                        // composite index tambahan di Firestore.
                        var docs = snapshot.data?.docs ?? [];
                        docs = [...docs]..sort((a, b) {
                          final ad = (a.data() as Map<String, dynamic>)['order_date'] as Timestamp?;
                          final bd = (b.data() as Map<String, dynamic>)['order_date'] as Timestamp?;
                          if (ad == null || bd == null) return 0;
                          return bd.compareTo(ad); // descending
                        });

                        if (docs.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppTheme.lg),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.notifications_off_outlined, size: 40, color: textTertiary),
                                  const SizedBox(height: AppTheme.md),
                                  Text(
                                    t.noNewNotifications,
                                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    t.noNewNotificationsSubtitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(AppTheme.lg, 0, AppTheme.lg, AppTheme.xl),
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppTheme.md),
                          itemBuilder: (context, i) {
                            final data = docs[i].data() as Map<String, dynamic>;
                            final id = data['order_number'] ?? '#ORD-UNKNOWN';
                            final customerName = data['customer_name'] ?? t.defaultCustomerName;
                            final detail = t.orderDetailSummary(
                              '${data['total_items'] ?? 0}',
                              (data['total_amount'] ?? 0).toString(),
                            );

                            return InkWell(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                context.push('/orders');
                              },
                              child: Container(
                                padding: const EdgeInsets.all(AppTheme.md),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.schedule_outlined, color: Colors.orange, size: 18),
                                    ),
                                    const SizedBox(width: AppTheme.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  customerName,
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                id,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontSize: 11, color: textTertiary),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(detail, style: TextStyle(fontSize: 11.5, color: textSecondary)),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded, size: 20, color: textTertiary),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================
  // REAL-TIME SUMMARY CARD (Firestore Stream, ter-filter per cabang)
  // ============================================
  Widget _buildBalanceCardRealtime(AppLocalizations t) {
    return StreamBuilder<QuerySnapshot>(
      stream: _ordersBaseQuery().snapshots(),
      builder: (context, orderSnapshot) {
        int activeOrders = 0;
        double totalRevenueThisMonth = 0;
        double totalRevenueLastMonth = 0;

        if (orderSnapshot.hasData) {
          final now = DateTime.now();
          final startOfThisMonth = DateTime(now.year, now.month, 1);
          final startOfLastMonth = DateTime(now.year, now.month - 1, 1);

          for (var doc in orderSnapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            String status = data['status'] ?? 'pending';

            // Menghitung pesanan yang belum selesai/dibatalkan
            if (['pending', 'processing'].contains(status)) {
              activeOrders++;
            }

            // Menghitung pendapatan dari transaksi sukses (paid), dipisah
            // bulan ini vs bulan lalu supaya bisa hitung persentase
            // pertumbuhan (badge "+X% dari bln lalu").
            Timestamp? orderDate = data['order_date'] as Timestamp?;
            if (orderDate != null && data['payment_status'] == 'paid') {
              final date = orderDate.toDate();
              final amount = (data['total_amount'] ?? 0).toDouble();
              if (!date.isBefore(startOfThisMonth)) {
                totalRevenueThisMonth += amount;
              } else if (!date.isBefore(startOfLastMonth) && date.isBefore(startOfThisMonth)) {
                totalRevenueLastMonth += amount;
              }
            }
          }
        }

        double? growthPercent;
        if (totalRevenueLastMonth > 0) {
          growthPercent = ((totalRevenueThisMonth - totalRevenueLastMonth) / totalRevenueLastMonth) * 100;
        } else if (totalRevenueThisMonth > 0) {
          growthPercent = 100;
        }
        final isPositiveGrowth = (growthPercent ?? 0) >= 0;

        // Memformat visual ke UI Card asli — solid primary blue dengan
        // elemen dekoratif lingkaran blur di pojok, sesuai code.html.
        return Container(
          decoration: BoxDecoration(
            color: primaryBlue,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Elemen dekoratif: lingkaran putih transparan di pojok
              // kanan-atas, meniru "absolute -right-4 -top-4 ... blur-2xl"
              Positioned(
                right: -16,
                top: -16,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppTheme.lg),
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      t.revenueThisMonthLabel,
                      style: const TextStyle(fontSize: 12.5, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sync_rounded, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          t.autoSyncLabel,
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _formatCurrency(totalRevenueThisMonth),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: AppTheme.lg),
              Container(height: 1, color: Colors.white.withOpacity(0.2)),
              const SizedBox(height: AppTheme.md),
              Row(
                children: [
                  Icon(Icons.receipt_long_rounded, size: 16, color: Colors.white.withOpacity(0.85)),
                  const SizedBox(width: 6),
                  Text(
                    '$activeOrders ${t.activeOrdersLabel}',
                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  if (growthPercent != null) ...[
                    Icon(
                      isPositiveGrowth ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 16,
                      color: isPositiveGrowth ? const Color(0xFF7BE0A0) : const Color(0xFFFFB4B4),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositiveGrowth ? '+' : ''}${growthPercent.toStringAsFixed(0)}% dari bln lalu',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isPositiveGrowth ? const Color(0xFF7BE0A0) : const Color(0xFFFFB4B4),
                      ),
                    ),
                  ],
                ],
              ),
            ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================
  // REAL-TIME SETUP ONBOARDING CHECKLIST
  // ============================================
  Widget _buildSetupChecklistRealtime(AppLocalizations t) {
    if (_setupDismissed) return const SizedBox.shrink();

    final userRef = FirebaseFirestore.instance.collection('users').doc(_currentUserId);

    return StreamBuilder<QuerySnapshot>(
      stream: userRef.collection('laundries').snapshots(),
      builder: (context, laundrySnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: userRef.collection('employees').snapshots(),
          builder: (context, employeeSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: userRef.collection('service_types').snapshots(),
              builder: (context, serviceSnap) {

                bool hasBranch = laundrySnap.hasData && laundrySnap.data!.docs.isNotEmpty;
                bool hasEmployee = employeeSnap.hasData && employeeSnap.data!.docs.isNotEmpty;
                bool hasService = serviceSnap.hasData && serviceSnap.data!.docs.isNotEmpty;

                final List<_SetupStep> steps = [
                  _SetupStep(
                    title: t.setupBranchTitle,
                    subtitle: t.setupBranchSubtitle,
                    icon: Icons.store_mall_directory_outlined,
                    completed: hasBranch,
                    // Langsung ke CRUD asli (CreateLaundryScreen), bukan
                    // '/setup/branch' yang tidak terdaftar di routes.dart.
                    route: '/laundries/create',
                  ),
                  _SetupStep(
                    title: t.setupEmployeeTitle,
                    subtitle: t.setupEmployeeSubtitle,
                    icon: Icons.person_add_alt_1_rounded,
                    completed: hasEmployee,
                    // Langsung ke CRUD asli (CreateEmployeeScreen).
                    route: '/employees/create',
                  ),
                  _SetupStep(
                    title: t.setupServiceTitle,
                    subtitle: t.setupServiceSubtitle,
                    icon: Icons.local_laundry_service_rounded,
                    completed: hasService,
                    // CRUD layanan masih PlaceholderScreen di routes.dart,
                    // tapi setidaknya path-nya valid dan tidak error.
                    // Ganti PlaceholderScreen di routes.dart begitu
                    // CreateServiceScreen sudah jadi.
                    route: '/services/create',
                  ),
                ];

                // Jika semua langkah setup selesai dilakukan, sembunyikan card secara otomatis
                if (steps.every((s) => s.completed)) return const SizedBox.shrink();

                int done = steps.where((s) => s.completed).length;
                double progress = done / steps.length;

                return Container(
                  padding: const EdgeInsets.all(AppTheme.lg),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            child: Icon(Icons.rocket_launch_rounded, color: textBlue, size: 18),
                          ),
                          const SizedBox(width: AppTheme.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.completeBranchSetupTitle,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  t.setupStepsProgress(done, steps.length),
                                  style: TextStyle(fontSize: 11.5, color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            color: textTertiary,
                            onPressed: () => setState(() => _setupDismissed = true),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.md),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: borderColor,
                          valueColor: AlwaysStoppedAnimation(primaryBlue),
                        ),
                      ),
                      const SizedBox(height: AppTheme.lg),
                      ...List.generate(steps.length, (i) {
                        final step = steps[i];
                        final isLast = i == steps.length - 1;
                        return InkWell(
                          onTap: () => context.push(step.route),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          child: Padding(
                            padding: EdgeInsets.only(bottom: isLast ? 0 : AppTheme.md),
                            child: Row(
                              children: [
                                Container(
                                  width: 30, height: 30,
                                  decoration: BoxDecoration(
                                    color: step.completed ? const Color(0xFF27AE60).withOpacity(0.12) : borderColor.withOpacity(0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    step.completed ? Icons.check_rounded : step.icon,
                                    size: 16,
                                    color: step.completed ? const Color(0xFF27AE60) : textTertiary,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        step.title,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: step.completed ? textTertiary : textPrimary,
                                          decoration: step.completed ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                      Text(step.subtitle, style: TextStyle(fontSize: 11, color: textSecondary)),
                                    ],
                                  ),
                                ),
                                if (!step.completed)
                                  Icon(Icons.chevron_right_rounded, size: 20, color: textTertiary),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ============================================
  // QUICK ACTIONS
  // ============================================
  // Catatan: "Pesanan Baru" dan "Karyawan Baru" sudah dihapus dari sini
  // sesuai permintaan (tetap bisa dibuat lewat menu Kelola Karyawan /
  // tombol "Baru" di halaman Pesanan).
  Widget _buildQuickActions(BuildContext context, AppLocalizations t) {
    final actions = [
      (Icons.storefront_outlined, t.manageBranchAction, const Color(0xFF00A896), '/laundries', '', 0),
      (Icons.badge_outlined, t.manageEmployeesAction, deepBlue, '/employees', '', 0),
      (Icons.local_laundry_service_outlined, t.manageServicesAction, const Color(0xFF9C27B0), '/services', '', 0),
      (Icons.local_shipping_outlined, t.pickupDeliveryAction, const Color(0xFF27AE60), '/antar-jemput', '', 0),
      (Icons.bar_chart_rounded, t.reportAction, const Color(0xFFE67E22), '/laporan', '', 0),
      (Icons.settings_outlined, t.settingsAction, textSecondary, '/settings', '', 0),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: actions.map((action) {
          final (icon, label, color, route, collectionToCheck, limit) = action;
          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.lg),
            child: SizedBox(
              width: 68,
              child: InkWell(
                onTap: () async {
                  if (collectionToCheck.isNotEmpty) {
                    final snap = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(_currentUserId)
                        .collection(collectionToCheck)
                        .count()
                        .get();

                    // Mengantisipasi nilai null safety pada properti count
                    if ((snap.count ?? 0) >= limit) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(t.quotaLimitReached(label.replaceAll('\n', ' '))),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }
                  }
                  context.push(route);
                },
                borderRadius: BorderRadius.circular(40),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: textPrimary, height: 1.15),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================
  // REAL-TIME WEEKLY REVENUE CHART (ter-filter per cabang)
  // ============================================
  /// FIX: sebelumnya `startOfWeek = DateTime.now().subtract(Duration(days: 7))`
  /// tidak dibulatkan ke tengah malam, jadi rentang 7-hari-nya kepotong di
  /// tengah hari. Akibatnya hari yang posisinya sama di kolom `weekday` bisa
  /// numpuk data dari 2 hari kalender berbeda (sebagian hari-X minggu lalu +
  /// sebagian hari-X minggu ini ke-sum jadi satu bar).
  ///
  /// Sekarang pakai calendar week yang benar: Senin 00:00 minggu ini s.d.
  /// Minggu 23:59:59, sesuai urutan label (dayMon..daySun). Index bar dihitung
  /// dari selisih hari terhadap Senin (bukan `.weekday - 1` dari tanggal order),
  /// jadi tiap bar cuma berisi data dari satu hari kalender yang jelas.
  Widget _buildWeeklyChartRealtime(AppLocalizations t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Senin = weekday 1 ... Minggu = weekday 7 -> mundur ke Senin minggu ini.
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7)); // exclusive, awal Senin depan

    final days = [t.dayMon, t.dayTue, t.dayWed, t.dayThu, t.dayFri, t.daySat, t.daySun];

    return StreamBuilder<QuerySnapshot>(
      stream: _ordersBaseQuery()
          .where('order_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .where('order_date', isLessThan: Timestamp.fromDate(endOfWeek))
          .snapshots(),
      builder: (context, snapshot) {
        List<double> values = List.filled(7, 0.0);

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            Timestamp? orderDate = data['order_date'] as Timestamp?;
            if (orderDate != null && data['payment_status'] == 'paid') {
              final orderDay = orderDate.toDate();
              // Index berdasarkan selisih hari kalender dari Senin minggu ini,
              // bukan `.weekday` dari order_date (menghindari duplikasi/salah
              // kolom akibat rentang tidak align tengah malam).
              final dayOffset = DateTime(orderDay.year, orderDay.month, orderDay.day)
                  .difference(startOfWeek)
                  .inDays;
              if (dayOffset >= 0 && dayOffset < 7) {
                values[dayOffset] += (data['total_amount'] ?? 0).toDouble();
              }
            }
          }
        }

        double maxVal = values.reduce((a, b) => a > b ? a : b);
        List<double> scaledValues = values.map((v) => maxVal > 0 ? (v / maxVal) : 0.0).toList();

        return Container(
          padding: const EdgeInsets.all(AppTheme.lg),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t.weeklyRevenueTitle, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(t.sevenDaysLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textBlue)),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.lg),
              SizedBox(
                height: 110,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(scaledValues.length, (i) {
                    final isPeak = scaledValues[i] == scaledValues.reduce((a, b) => a > b ? a : b) && scaledValues[i] > 0;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              height: 80 * scaledValues[i],
                              decoration: BoxDecoration(
                                color: isPeak ? primaryBlue : primaryBlue.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(days[i], style: TextStyle(fontSize: 10.5, color: textSecondary)),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================
  // ORDERS HEADER
  // ============================================
  Widget _buildOrdersHeader(BuildContext context, AppLocalizations t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(t.mainOrdersTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
        TextButton(
          onPressed: () => context.push('/orders'),
          child: Text(t.viewAllLabel, style: TextStyle(color: textBlue, fontWeight: FontWeight.w600, fontSize: 12.5)),
        ),
      ],
    );
  }

  // ============================================
  // REAL-TIME TIMELINE PESANAN — "Pesanan Utama"
  // ============================================
  // Dashboard cuma nunjukin pesanan yang MASIH BUTUH PERHATIAN: status
  // menunggu (pending), baru dikonfirmasi (confirmed), atau baru mulai
  // diproses (inProgress) — belum masuk tahap pencucian fisik (washing,
  // drying, ironing, qualityCheck, ready). Begitu order masuk tahap
  // pencucian atau lebih jauh, otomatis "lulus" dari list ini dan cuma
  // bisa dipantau lewat halaman Pesanan (/orders) atau detail order.
  //
  // Kombinasi where('laundry_id', ...) + where('status', whereIn: ...)
  // + orderBy('order_date') di bawah ini KEMUNGKINAN BESAR butuh
  // composite index baru di Firestore — kalau muncul error
  // FAILED_PRECONDITION di log/console, klik link yang disediakan
  // Firebase buat generate index-nya otomatis.
  static const List<String> _dashboardActiveStatuses = ['pending', 'confirmed', 'inProgress'];

  Widget _buildTimelineRealtime(AppLocalizations t) {
    final query = _ordersBaseQuery()
        .where('status', whereIn: _dashboardActiveStatuses)
        .orderBy('order_date', descending: true)
        .limit(5);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('${snapshot.error}', style: TextStyle(fontSize: 12, color: textSecondary)),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(t.noOrdersData)));
        }

        final docs = snapshot.data!.docs;

        return Column(
          children: List.generate(docs.length, (i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final customerName = data['customer_name'] ?? t.defaultCustomerName;
            final detail = t.orderDetailSummary(
              '${data['total_items'] ?? 0}',
              (data['total_amount'] ?? 0).toString(),
            );
            final amount = (data['total_amount'] ?? 0).toDouble();
            final status = data['status'] ?? 'pending';
            final isLast = i == docs.length - 1;

            // Warna & label status disamakan dengan istilah di
            // OrderDetailScreen (_getStatusLabel) — hanya 3 status yang
            // mungkin muncul di sini (lihat _dashboardActiveStatuses).
            Color statusColor;
            String statusLabel;
            switch (status) {
              case 'pending':
                statusColor = Colors.orange;
                statusLabel = 'Menunggu';
                break;
              case 'confirmed':
                statusColor = primaryBlue;
                statusLabel = 'Dikonfirmasi';
                break;
              case 'inProgress':
                statusColor = primaryBlue;
                statusLabel = 'Diproses';
                break;
              default:
                statusColor = textTertiary;
                statusLabel = status;
            }

            // Kartu ala "Pesanan Terbaru": avatar bulat berisi huruf
            // pertama nama pelanggan (bukan foto profil), nama + ringkasan
            // item di kiri, badge status + nominal di kanan.
            return Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : AppTheme.md),
              padding: const EdgeInsets.all(AppTheme.md),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _InitialAvatar(name: customerName, size: 42),
                  const SizedBox(width: AppTheme.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: textPrimary),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.sm, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatCurrency(amount),
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textBlue),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

/// Avatar bulat berisi huruf pertama nama pelanggan, dipakai sebagai
/// pengganti foto profil di kartu "Pesanan Terbaru". Warna latar
/// dipilih otomatis dari huruf pertama nama supaya tiap pelanggan
/// terlihat sedikit berbeda tanpa perlu upload foto.
class _InitialAvatar extends StatelessWidget {
  final String name;
  final double size;

  const _InitialAvatar({required this.name, this.size = 42});

  static const List<Color> _palette = [
    Color(0xFF5DADE2),
    Color(0xFFAF7AC5),
    Color(0xFF48C9B0),
    Color(0xFFF5B041),
    Color(0xFFEC7063),
    Color(0xFF5499C7),
    Color(0xFF52BE80),
    Color(0xFFEB74A8),
  ];

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';
    final colorIndex = trimmed.isNotEmpty ? trimmed.codeUnitAt(0) % _palette.length : 0;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _palette[colorIndex],
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

class _SetupStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool completed;
  final String route;

  _SetupStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.completed,
    required this.route,
  });
}
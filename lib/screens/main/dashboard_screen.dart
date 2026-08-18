import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/themes/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_feedback.dart';
import '../../models/subscription.dart';
import '../../repositories/subscription_repository.dart';
import '../../services/subscription_service.dart';
import '../../services/subscription_reminder_service.dart';
import '../../core/widgets/trial_paywall_dialog.dart';

/// Dashboard Screen - NetWash
/// Terintegrasi dengan Firebase Firestore (Real-time Streams)
/// Mengimplementasikan Fitur Gating / Limit Paket Langganan secara Asli
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  /// Menandai subscription id mana yang sudah pernah ditampilkan paywall
  /// "Trial Habis"-nya SELAMA screen ini hidup - sama seperti pola
  /// _reminderCheckedForSubId, supaya StreamBuilder yang rebuild
  /// berkali-kali nggak numpuk showDialog() berulang-ulang buat
  /// subscription yang sama.
  String? _paywallShownForSubId;

  // Disamain PERSIS sama _DS di services_list_screen.dart ("NetWash
  // Utility System") — primary #0061A4, navy #0B3B66, card pakai shadow
  // (bukan border), font Be Vietnam Pro. Supaya Dashboard & halaman
  // Layanan senada, bukan cuma warna canvas/surface-nya doang.
  static const Color primaryBlue = Color(0xFF0061A4);
  static const Color deepBlue = Color(0xFF0B3B66);
  static const Color textBlue = Color(0xFF0061A4);
  static const Color bgColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1B1C1C);
  static const Color textSecondary = Color(0xFF404752);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color borderColor = Color(0xFFBFC7D4);

  /// Warna banner subscription (poin 8) - dipisah dari palet _DS
  /// biasa karena artinya berbeda (peringatan, bukan brand color).
  /// error = sama dengan _DS.error di screen lain (#BA1A1A), grace =
  /// oranye (sama dengan status 'pending' di timeline & notif bell).
  static const Color subscriptionErrorColor = Color(0xFFBA1A1A);
  static const Color subscriptionGraceColor = Colors.orange;

  /// Shadow buat card, ngegantiin border tipis — sama kayak _DS.cardShadow
  /// di services_list_screen.dart.
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  // Status dismiss checklist onboarding secara lokal
  bool _setupDismissed = false;

  // Jumlah pending order terakhir yang sudah "diketahui". null = belum
  // pernah dapat data sama sekali (baru buka dashboard) -> jangan bunyi
  // di load pertama, cuma bunyi kalau count-nya NAIK dari nilai ini.
  int? _lastKnownPendingCount;
  // Cabang yang lagi dipilih di selector atas. 'all' = tampilkan semua
  // cabang. Dipakai buat filter query 'orders' lewat _ordersBaseQuery()
  // di bawah (balance card, notifikasi, chart mingguan, & timeline).
  //
  // CATATAN LOKALISASI: nama cabang "Semua Cabang" TIDAK lagi disimpan
  // sebagai string statis di _selectedBranchName. Kalau _selectedBranchId
  // == 'all', kita simpan _selectedBranchName = null dan resolve label-nya
  // dari t.allBranchesLabel saat build — supaya kalau user ganti bahasa
  // aplikasi, label "All Branches" / "Semua Cabang" ikut berubah juga
  // (bukan nyangkut ke bahasa yang aktif waktu cabang dipilih).
  String _selectedBranchId = 'all';
  String? _selectedBranchName;

  /// Menandai subscription id mana yang sudah pernah dicek reminder
  /// H-3/H-1-nya SELAMA screen ini hidup, supaya SubscriptionReminderService
  /// .checkDue() (yang baca/tulis SharedPreferences, async) tidak
  /// dipanggil berkali-kali tiap kali StreamBuilder subscription rebuild
  /// (mis. setiap kali dokumen subscription berubah sedikit pun).
  /// SharedPreferences sendiri yang jadi sumber kebenaran final soal
  /// "sudah pernah ditampilkan hari ini apa belum" -- flag ini cuma
  /// optimasi supaya tidak spam pemanggilan async yang sama.
  String? _reminderCheckedForSubId;

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
        // Font Be Vietnam Pro, disamain sama services_list_screen.dart
        // (bagian dari NetWash Utility System design).
        style: GoogleFonts.beVietnamPro(),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              children: [
                // FIX: guard tak-terlihat yang mantau apakah cabang yang lagi
                // dipilih (_selectedBranchId) masih aktif. Kalau ternyata
                // dinonaktifkan (is_active == false) atau dokumennya sudah
                // dihapus, otomatis reset selector balik ke 'all' supaya
                // dashboard nggak nyangkut nge-filter ke cabang yang mati.
                _buildActiveBranchGuard(),
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
                          // Banner status subscription (poin 8) - render
                          // nothing (SizedBox.shrink) kalau subscription
                          // aktif & bukan grace period, jadi spacing di
                          // bawah tidak berubah saat banner tidak tampil.
                          // Padding bawahnya sendiri sudah termasuk di
                          // dalam widget saat memang tampil.
                          _buildSubscriptionBanner(context, t),
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
  // POIN 8: BANNER STATUS SUBSCRIPTION (expired / grace period)
  // ============================================
  // Sama seperti gating administrative di create_employee_screen/
  // create_laundry_screen/create_service_screen: pakai
  // streamSubscriptionForCompany() (BUKAN streamActiveSubscription())
  // karena banner ini butuh tahu status apa pun dokumennya (termasuk
  // past_due), bukan cuma "null vs aktif".
  //
  // - Subscription aktif/trialing, ATAU tidak ada company sama sekali ->
  //   tidak render apa-apa (SizedBox.shrink).
  // - Masih dalam grace period (past_due, belum lewat gracePeriodDays) ->
  //   banner oranye, kasih tau sisa hari + CTA upgrade. TIDAK memblok
  //   apa pun di dashboard sendiri - ini cuma info, gating aslinya ada
  //   di masing-masing screen administrative (create_employee_screen dkk).
  // - Sudah lewat grace period / tidak pernah subscribe -> banner merah
  //   (lebih tegas), CTA upgrade.
  //
  // CATATAN: rute CTA "Upgrade" sementara diarahkan ke '/settings' (rute
  // yang sudah pasti valid, dipakai juga di _buildQuickActions) - ganti
  // ke path subscription_screen langsung begitu rute itu sudah jelas
  // (lihat poin 9: subscription_screen countdown).
  Widget _buildSubscriptionBanner(BuildContext context, AppLocalizations t) {
    final userRef = FirebaseFirestore.instance.collection('users').doc(_currentUserId);

    return StreamBuilder<QuerySnapshot>(
      stream: userRef.collection('companies').limit(1).snapshots(),
      builder: (context, companySnap) {
        if (!companySnap.hasData || companySnap.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final companyId = companySnap.data!.docs.first.id;
        final subscriptionRepo = SubscriptionRepository(userId: _currentUserId);

        return StreamBuilder<Subscription?>(
          stream: subscriptionRepo.streamSubscriptionForCompany(companyId),
          builder: (context, subSnap) {
            if (!subSnap.hasData) return const SizedBox.shrink();

            final subscription = subSnap.data;
            if (subscription != null) {
              _maybeCheckRenewalReminder(subscription);
            }

            final subscriptionService = SubscriptionService(currentSubscription: subSnap.data);
            final access = subscriptionService.checkAccess(SubscriptionActionType.administrative);

            // Trial abis (status 'trialing' tapi sudah lewat
            // current_period_end, alias !access.allowed) -> munculin
            // paywall "Nonton Iklan / Upgrade" alih-alih cuma banner
            // pasif. Cuma buat status 'trialing' spesifik, BUKAN
            // past_due/grace period paket berbayar (itu sudah ditangani
            // banner oranye + _showRenewalReminderDialog yang ada).
            if (subscription != null &&
                subscription.status == 'trialing' &&
                !access.allowed &&
                _paywallShownForSubId != subscription.id) {
              _paywallShownForSubId = subscription.id;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  TrialPaywallDialog.show(
                    context,
                    onWatchAdSuccess: () async {
                      final subscriptionRepo = SubscriptionRepository(userId: _currentUserId);
                      await subscriptionRepo.extendTrial(
                        subscription.id,
                        currentPeriodEnd: subscription.currentPeriodEnd,
                        days: 1,
                      );
                      if (mounted) {
                        // Reset guard supaya kalau trial abis lagi besok,
                        // paywall bisa muncul lagi buat subscription id
                        // yang sama (belum ganti dokumen).
                        _paywallShownForSubId = null;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🎉 Akses ditambah 1 hari!')),
                        );
                      }
                    },
                  );
                }
              });
            }

            // Aktif/trialing DAN bukan grace period -> tidak ada yang
            // perlu ditampilkan sama sekali.
            if (access.allowed && !access.isInGracePeriod) {
              return const SizedBox.shrink();
            }

            final isExpired = !access.allowed;
            final bannerColor = isExpired ? subscriptionErrorColor : subscriptionGraceColor;
            final title = isExpired ? t.subscriptionExpiredTitle : t.gracePeriodBannerTitle;
            final message = isExpired
                ? t.subscriptionExpiredWarning
                : t.gracePeriodWarning(access.graceDaysRemaining ?? 0);

            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.lg),
              child: Container(
                padding: const EdgeInsets.all(AppTheme.md),
                decoration: BoxDecoration(
                  color: bannerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: bannerColor.withOpacity(0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 20, color: bannerColor),
                    const SizedBox(width: AppTheme.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: bannerColor),
                          ),
                          const SizedBox(height: 2),
                          Text(message, style: TextStyle(fontSize: 12, color: textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTheme.sm),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () => context.go('/settings'),
                      child: Text(
                        t.upgradePlanAction,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: bannerColor),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================
  // REMINDER H-3/H-1 SEBELUM currentPeriodEnd (client-side, lihat
  // SubscriptionReminderService untuk alasan kenapa bukan Cloud Function
  // terjadwal -- project masih di plan Spark).
  // ============================================
  // Dipanggil dari dalam builder StreamBuilder<Subscription?> di
  // _buildSubscriptionBanner (sudah dapat data subscription-nya di sana,
  // tidak perlu listener terpisah). Guard _reminderCheckedForSubId supaya
  // checkDue() (async, baca/tulis SharedPreferences) tidak dipanggil
  // berkali-kali untuk subscription id yang sama selama screen ini hidup.
  void _maybeCheckRenewalReminder(Subscription subscription) {
    if (_reminderCheckedForSubId == subscription.id) return;
    _reminderCheckedForSubId = subscription.id;

    SubscriptionReminderService.checkDue(subscription).then((due) {
      if (due == null || !mounted) return;
      // Ditunda ke akhir frame ini -- kita sedang di tengah build() lewat
      // StreamBuilder, jadi tidak aman manggil showDialog() secara
      // langsung di sini.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showRenewalReminderDialog(due);
      });
    });
  }

  void _showRenewalReminderDialog(SubscriptionReminderDue due) {
    final t = AppLocalizations.of(context)!;
    // Overdue (past_due, lewat currentPeriodEnd) pakai teks "expired"
    // yang sudah ada (sama dengan banner merah), supaya jelas beda dari
    // reminder H-3/H-1 yang masih "akan berakhir". Warna icon juga
    // dibedain (merah utk overdue, oranye utk H-3/H-1) biar konsisten
    // sama _buildSubscriptionBanner.
    final title = due.isOverdue
        ? t.subscriptionExpiredTitle
        : t.subscriptionRenewalReminderTitle;
    final message = due.isOverdue
        ? t.subscriptionExpiredWarning
        : t.subscriptionRenewalReminderMessage(due.days);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          Icons.event_busy_rounded,
          color: due.isOverdue ? subscriptionErrorColor : subscriptionGraceColor,
          size: 32,
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13.5, color: textSecondary),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.remindLaterAction, style: const TextStyle(color: textTertiary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: primaryBlue),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go('/settings/subscription');
            },
            child: Text(t.renewNowAction),
          ),
        ],
      ),
    );
  }

  // ============================================
  // FIX: GUARD CABANG AKTIF (auto-reset kalau cabang terpilih dinonaktifkan)
  // ============================================
  // Widget ini nggak render apa-apa (SizedBox.shrink) — cuma dengerin
  // dokumen cabang yang lagi dipilih. Kalau 'all' dipilih, nggak perlu
  // dengerin apa-apa. Kalau cabang spesifik dipilih tapi field is_active
  // == false (atau dokumennya udah dihapus), otomatis setState balik ke
  // 'all' + reset nama cabang, supaya semua query di dashboard (balance
  // card, chart, timeline) nggak kejebak nge-filter ke cabang yang sudah
  // nonaktif/dihapus.
  Widget _buildActiveBranchGuard() {
    if (_selectedBranchId == 'all') return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .collection('laundries')
          .doc(_selectedBranchId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final stillActive = snapshot.data?.exists == true && (data?['is_active'] ?? true) == true;

        if (!stillActive) {
          // Dijalankan setelah frame ini selesai supaya nggak setState()
          // di tengah-tengah proses build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedBranchId != 'all') {
              setState(() {
                _selectedBranchId = 'all';
                _selectedBranchName = null;
              });
            }
          });
        }

        return const SizedBox.shrink();
      },
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
            onTap: () => _showBranchSelector(context, t),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.activeBranchLabel,
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
                      _selectedBranchName ?? t.allBranchesLabel,
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
  void _showBranchSelector(BuildContext context, AppLocalizations t) {
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
                              t.selectBranchTitle,
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
                            hintText: t.searchBranchHint,
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
                          // FIX: sebelumnya nggak ada filter sama sekali di sini,
                          // jadi cabang yang sudah dinonaktifkan (is_active ==
                          // false) tetap ikut muncul di dropdown selector.
                          // Sekarang cuma cabang dengan is_active == true yang
                          // ditampilkan sebagai opsi yang bisa dipilih.
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(_currentUserId)
                              .collection('laundries')
                              .where('is_active', isEqualTo: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final allDocs = snapshot.data?.docs ?? [];
                            final query = branchSearchQuery.trim().toLowerCase();

                            // "Semua Cabang" / "All Branches" tetap muncul selama
                            // belum ada pencarian aktif - begitu user ngetik, opsi
                            // ini ikut ke-filter berdasarkan query juga. Label-nya
                            // diambil dari t.allBranchesLabel supaya ikut bahasa
                            // aplikasi yang sedang aktif.
                            final allBranchesLabelLower = t.allBranchesLabel.toLowerCase();
                            final showAllOption = query.isEmpty || allBranchesLabelLower.contains(query);

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
                                    name: t.allBranchesLabel,
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
                                          t.noBranchesRegistered,
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
                                          t.branchNotFoundSearch,
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
          // Untuk opsi 'all', simpan null (bukan string statis) supaya
          // labelnya selalu di-resolve ulang dari t.allBranchesLabel sesuai
          // bahasa yang lagi aktif, bukan nyangkut ke bahasa saat dipilih.
          _selectedBranchName = id == 'all' ? null : name;
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

        // Bunyiin suara notif HANYA kalau count pending naik dibanding
        // yang terakhir diketahui - bukan tiap kali snapshot lewat (bisa
        // ke-trigger juga oleh perubahan field lain di order yang match
        // query). Load pertama (_lastKnownPendingCount masih null) juga
        // sengaja tidak dibunyikan, supaya order lama yang udah nunggu
        // dari sebelum dashboard dibuka nggak ikut kebunyi.
        if (snapshot.hasData) {
          final previousCount = _lastKnownPendingCount;
          if (previousCount != null && pendingCount > previousCount) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) AppFeedback.playSound(ref, AppSound.success);
            });
          }
          if (previousCount != pendingCount) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _lastKnownPendingCount = pendingCount);
            });
          }
        }

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
                                // '/orders' branch shell -> go(), bukan push().
                                context.go('/orders');
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
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: cardShadow,
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
                  // '/settings' adalah branch dari StatefulShellRoute yang sama
                  // dengan Dashboard (lihat routes.dart), BUKAN route biasa.
                  // context.push() untuk route branch lain di shell yang sama
                  // hanya akan nge-push di atas Navigator branch saat ini
                  // (currentIndex tidak ikut berubah -> bottom nav nyangkut di
                  // Dashboard). context.go() yang benar: dia switch branch
                  // shell-nya sekaligus update currentIndex, jadi bottom nav
                  // ikut ke-highlight ke tab Settings.
                  if (route == '/settings') {
                    context.go(route);
                  } else {
                    context.push(route);
                  }
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
            borderRadius: BorderRadius.circular(20),
            boxShadow: cardShadow,
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
          // '/orders' juga branch shell (sama kayak '/settings') -> pakai
          // context.go() supaya bottom nav ikut ke-highlight ke tab Orders.
          onPressed: () => context.go('/orders'),
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
            // Label diambil dari AppLocalizations supaya ikut bahasa
            // aplikasi yang sedang aktif (bukan hardcoded 'Menunggu' dst).
            Color statusColor;
            String statusLabel;
            switch (status) {
              case 'pending':
                statusColor = Colors.orange;
                statusLabel = t.orderStatusPending;
                break;
              case 'confirmed':
                statusColor = primaryBlue;
                statusLabel = t.orderStatusConfirmed;
                break;
              case 'inProgress':
                statusColor = primaryBlue;
                statusLabel = t.orderStatusInProgress;
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
                borderRadius: BorderRadius.circular(16),
                boxShadow: cardShadow,
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
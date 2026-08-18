import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/themes/app_theme.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/subscription_repository.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/services/app_feedback.dart';

/// Pricing Model
class PricingPlan {
  final String name;
  final String description;
  final double monthlyPrice;
  final double yearlyPrice;
  final List<String> features;
  final bool isPopular;
  final Color color;

  /// Limit numerik sesuai `limits.max_laundries` / `limits.max_employees`
  /// di skema `subscriptions` (PRD 3.6.2). -1 artinya unlimited. Dipakai
  /// buat validasi downgrade — lihat `_planBlockReason` di
  /// _ChoosePlanScreenState.
  final int maxLaundries;
  final int maxEmployees;

  PricingPlan({
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
    required this.isPopular,
    required this.color,
    required this.maxLaundries,
    required this.maxEmployees,
  });
}

/// Choose Plan Screen — Step 5 dari onboarding, DAN juga dipakai ulang
/// buat flow "Upgrade Paket" dari Settings > Subscription.
///
/// isUpgrade = false (default): mode onboarding normal.
///   Alur: Setup Perusahaan → [halaman ini] → Pembayaran (Stripe) → Dashboard.
/// isUpgrade = true: dipanggil dari SubscriptionScreen ketika user yang
///   SUDAH aktif langganan mau ganti/upgrade paket.
///   - Step indicator onboarding disembunyikan (bukan bagian onboarding lagi)
///   - Header & tombol pilih paket teksnya disesuaikan
///   - Tombol back balik ke /settings/subscription, bukan /setup-company
///   - Flag isUpgrade diteruskan ke halaman /payment lewat extra
///
/// Harga & limit paket di bawah ini WAJIB sinkron dengan tabel 3.6.1
/// "Paket Berlangganan (Pre-defined)" di PRD (netwash.md):
///   Starter:      Rp99.000/bln   · Rp990.000/thn   · 1 cabang · 5 karyawan · 500 order/bln
///   Professional: Rp199.000/bln  · Rp1.990.000/thn · 5 cabang · 25 karyawan · 2.000 order/bln
///   Enterprise:   Rp399.000/bln  · Rp3.990.000/thn · Unlimited cabang · Unlimited karyawan · Unlimited order/bln
/// Kalau harga di PRD berubah, update juga `subscription_plans` di
/// Firestore (dibaca `createCheckoutSession` lewat `stripe_price_id`)
/// supaya harga yang ditampilkan di sini match dengan yang ditagih Stripe.
class ChoosePlanScreen extends ConsumerStatefulWidget {
  final bool isUpgrade;

  const ChoosePlanScreen({
    Key? key,
    this.isUpgrade = false,
  }) : super(key: key);

  @override
  ConsumerState<ChoosePlanScreen> createState() => _ChoosePlanScreenState();
}

class _ChoosePlanScreenState extends ConsumerState<ChoosePlanScreen> {
  // State
  bool _isYearly = false;
  String? _selectedPlan;

  // Nama paket & periode billing yang SEDANG aktif dipakai user (cuma
  // relevan pas widget.isUpgrade == true). Dipakai buat nge-disable
  // card paket yang BENAR-BENAR sama (nama DAN periode) dengan yang
  // udah dia pakai sekarang -- FIX: sebelumnya cuma bandingin nama
  // paket, jadi kalau lagi di paket Tahunan terus toggle lihat harga
  // Bulanan, kartu Bulanan-nya ikut ke-mark "Paket Saat Ini" padahal
  // periode billing-nya beda.
  String? _currentPlanName;
  String? _currentBillingCycle; // 'monthly' / 'yearly', dari dokumen subscription Stripe
  bool _loadingCurrentPlan = false;

  // true kalau subscription yang lagi aktif statusnya 'past_due' (udah
  // lewat currentPeriodEnd) ATAU currentPeriodEnd-nya <= H-3. Dipakai
  // supaya user tetap bisa "Perpanjang" paket yang sama persis (nama +
  // periode) walau isCurrentPlan true -- sebelumnya tombol paket aktif
  // SELALU disabled tanpa peduli sisa waktunya, jadi nggak ada cara
  // renew paket yang sama dari halaman ini.
  bool _currentSubNeedsRenewal = false;

  // Jumlah cabang & karyawan AKTUAL milik user (cuma relevan pas
  // widget.isUpgrade == true). Dipakai buat memblokir user pindah ke
  // paket yang limitnya lebih kecil dari data yang udah dia punya —
  // mis. user di Enterprise (unlimited) sudah punya 8 cabang, nggak
  // boleh pindah ke Starter yang cuma boleh 1 cabang.
  int _currentLaundryCount = 0;
  int _currentEmployeeCount = 0;

  // Pricing plans
  late final List<PricingPlan> _plans;

  @override
  void initState() {
    super.initState();
    _initializePlans();
    if (widget.isUpgrade) {
      _loadCurrentPlan();
      _loadUsageCounts();
    }
  }

  Future<void> _loadCurrentPlan() async {
    setState(() => _loadingCurrentPlan = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);

      // Field users/{uid}.subscription.plan cuma nyimpen NAMA paket yang
      // TERAKHIR dipilih (bisa saja belum tentu ke-charge/aktif kalau
      // pembayaran gagal), jadi tetap dipakai buat fallback nama. Tapi
      // buat periode billing & status aktif/expired yang AKURAT, ambil
      // langsung dari dokumen subscription (ditulis Stripe webhook) lewat
      // SubscriptionRepository -- sama seperti yang dipakai dashboard
      // buat banner grace period.
      final profile = await authRepo.getUserProfile();
      final subscriptionField = profile?['subscription'] as Map<String, dynamic>?;
      String? planName = subscriptionField?['plan'] as String?;
      String? billingCycle;
      bool needsRenewal = false;

      final uid = authRepo.currentUser?.uid;
      final companyId = await authRepo.getPrimaryCompanyId();
      if (uid != null && companyId != null) {
        final subscriptionRepo = SubscriptionRepository(userId: uid);
        final subscription =
            await subscriptionRepo.streamSubscriptionForCompany(companyId).first;

        if (subscription != null) {
          // Dokumen subscription yang beneran aktif/pernah aktif lebih
          // bisa dipercaya soal nama & periode paket dibanding field
          // users/{uid}.subscription (yang cuma "niat pilih", belum
          // tentu ke-charge).
          planName = subscription.planName.isNotEmpty
              ? subscription.planName
              : planName;
          billingCycle = subscription.billingCycle;

          final now = DateTime.now();
          final daysLeft = subscription.currentPeriodEnd.difference(now).inDays;
          needsRenewal = subscription.status == 'past_due' || daysLeft <= 3;
        }
      }

      if (mounted) {
        setState(() {
          _currentPlanName = planName;
          _currentBillingCycle = billingCycle;
          _currentSubNeedsRenewal = needsRenewal;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loadingCurrentPlan = false);
      }
    }
  }

  Future<void> _loadUsageCounts() async {
    final authRepo = ref.read(authRepositoryProvider);
    final results = await Future.wait([
      authRepo.getLaundryCount(),
      authRepo.getEmployeeCount(),
    ]);
    if (mounted) {
      setState(() {
        _currentLaundryCount = results[0];
        _currentEmployeeCount = results[1];
      });
    }
  }

  /// Null kalau `plan` aman dipilih. Kalau tidak, balikin pesan yang
  /// jelasin field mana yang kelebihan (dipakai buat badge & tooltip di
  /// kartu paket, dan buat validasi terakhir sebelum _handleSelectPlan
  /// lanjut ke pembayaran).
  String? _planBlockReason(PricingPlan plan) {
    if (!widget.isUpgrade) return null;

    final overLaundries = plan.maxLaundries != -1 &&
        _currentLaundryCount > plan.maxLaundries;
    final overEmployees = plan.maxEmployees != -1 &&
        _currentEmployeeCount > plan.maxEmployees;

    if (!overLaundries && !overEmployees) return null;

    final parts = <String>[];
    if (overLaundries) {
      parts.add('$_currentLaundryCount cabang (maks ${plan.maxLaundries})');
    }
    if (overEmployees) {
      parts.add('$_currentEmployeeCount karyawan (maks ${plan.maxEmployees})');
    }
    return 'Data Anda saat ini punya ${parts.join(' & ')}. '
        'Kurangi datanya dulu sebelum pindah ke paket ini.';
  }

  /// true kalau [plan] BENAR-BENAR persis paket yang lagi aktif dipakai
  /// user SEKARANG -- nama paket DAN periode billing-nya sama-sama cocok
  /// dengan _isYearly (posisi toggle Bulanan/Tahunan yang lagi dilihat).
  ///
  /// FIX: sebelumnya cuma bandingin nama paket (`_currentPlanName ==
  /// plan.name`), jadi kalau user aktif di paket Tahunan lalu toggle ke
  /// tampilan Bulanan, kartu Bulanan paket yang sama ikut ke-mark
  /// "Paket Saat Ini" & ke-disable -- padahal itu bukan paket yang lagi
  /// dia pakai, harusnya tetap bisa dipilih (ganti periode).
  bool _isExactCurrentPlan(PricingPlan plan) {
    if (!widget.isUpgrade) return false;
    if (_currentPlanName != plan.name) return false;
    // Periode belum diketahui (masih loading / belum pernah ada dokumen
    // subscription) -> fallback ke match nama saja, lebih aman daripada
    // tidak menandai current plan sama sekali.
    if (_currentBillingCycle == null) return true;
    final currentIsYearly = _currentBillingCycle == 'yearly';
    return currentIsYearly == _isYearly;
  }

  /// Initialize pricing plans.
  /// Angka harga & limit di sini disamain persis sama tabel 3.6.1 PRD —
  /// lihat catatan di atas class.
  void _initializePlans() {
    _plans = [
      PricingPlan(
        name: 'Free',
        description: 'Trial 14 hari + Iklan',
        monthlyPrice: 0,
        yearlyPrice: 0,
        maxLaundries: 1,
        maxEmployees: 5,
        features: [
          '1 Cabang (per 14 hari trial)',
          'Hingga 5 Karyawan (per 14 hari trial)',
          'Maksimal 100 Order/Bulan (per 14 hari trial)',
          'Dashboard Dasar',
          'Manajemen Pesanan',
          'Customer Management',
          'Trial 14 Hari',
          'Gratis',
        ],
        isPopular: false,
        color: const Color(0xFF95A5A6),
      ),
      PricingPlan(
        name: 'Starter',
        description: 'Untuk bisnis laundry kecil',
        monthlyPrice: 99000,
        yearlyPrice: 990000,
        maxLaundries: 2,
        maxEmployees: 10,
        features: [
          '2 Cabang',
          'Hingga 10 Karyawan',
          'Maksimal 600 Order/Bulan (300/Cabang)',
          'Dashboard Dasar',
          'Manajemen Pesanan',
          'Customer Management',
          'Email Support',
        ],
        isPopular: false,
        color: const Color(0xFF3498DB),
      ),
      PricingPlan(
        name: 'Professional',
        description: 'Untuk bisnis laundry berkembang',
        monthlyPrice: 199000,
        yearlyPrice: 1990000,
        maxLaundries: 5,
        maxEmployees: 25,
        features: [
          'Hingga 5 Cabang',
          'Hingga 25 Karyawan',
          'Maksimal 2.000 Order/Bulan (400/Cabang)',
          'Advanced Analytics',
          'Manajemen Pesanan Lanjutan',
          'Customer Loyalty Program',
          'Priority Email & Chat Support',
          'Invoice & Laporan',
          'API Access',
        ],
        isPopular: true,
        color: AppTheme.primaryColor,
      ),
      PricingPlan(
        name: 'Enterprise',
        description: 'Untuk bisnis laundry besar',
        monthlyPrice: 399000,
        yearlyPrice: 3990000,
        maxLaundries: -1,
        maxEmployees: -1,
        features: [
          'Unlimited Cabang',
          'Unlimited Karyawan',
          'Unlimited Order/Bulan',
          'Full Analytics & Reporting',
          'Custom Workflow',
          'Advanced Security',
          'Dedicated Account Manager',
          'Phone & Email Support 24/7',
          'Custom Integration',
          'White Label Option',
        ],
        isPopular: false,
        color: const Color(0xFF1E5A7A),
      ),
    ];
  }

  bool _isNavigating = false;

  /// Handle select plan.
  /// Simpan pilihan paket SEKARANG (planChosen: true) supaya redirect
  /// logic di routes.dart mengizinkan user masuk ke /payment — kalau
  /// baru disimpan setelah bayar, router akan terus menendang user balik
  /// ke /choose-plan karena planChosen masih false.
  /// Status pembayaran AKTUAL (sudah bayar atau belum) tetap dicek
  /// terpisah lewat AuthRepository.hasActiveSubscription() /
  /// watchActiveSubscription(), bukan lewat flag ini.
  /// Sesuai PRD Step 5 → Step 6: Pilih Paket → lanjut ke Pembayaran.
  ///
  /// Kalau widget.isUpgrade true, savePlanChoice tetap dipanggil (biar
  /// planChosen konsisten), tapi flag isUpgrade ikut diteruskan ke
  /// /payment supaya PaymentScreen tau ini proration/upgrade, bukan
  /// pembayaran pertama kali.
  Future<void> _handleSelectPlan(PricingPlan plan) async {
    if (_isNavigating) return;

    // Jaga-jaga: harusnya tombol udah disabled di _PricingCard kalau
    // plan ini diblokir usage, tapi dicek ulang di sini juga.
    final blockReason = _planBlockReason(plan);
    if (blockReason != null) {
      AppFeedback.playSound(ref, AppSound.error);
      AppSnackbar.error(context, blockReason);
      return;
    }

    setState(() {
      _selectedPlan = plan.name;
      _isNavigating = true;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.savePlanChoice(
        planName: plan.name,
        isYearly: _isYearly,
      );

      // WAJIB: companyId ini yang bakal disertakan di metadata Stripe
      // Checkout Session, supaya webhook tahu company mana yang harus
      // ditulis di dokumen subscription. Tanpa ini, pembayaran tetap
      // sukses di Stripe tapi webhook gagal mengaktifkan limit paket baru.
      final companyId = await authRepo.getPrimaryCompanyId();
      if (companyId == null) {
        throw Exception(
          'Data perusahaan belum ditemukan. Selesaikan setup perusahaan terlebih dahulu.',
        );
      }

      if (!mounted) return;
      context.push(
        '/payment',
        extra: {
          'planName': plan.name,
          'isYearly': _isYearly,
          'price': _getDisplayPrice(plan),
          'isUpgrade': widget.isUpgrade,
          'companyId': companyId,
        },
      );
    } catch (e) {
      if (mounted) {
        AppFeedback.playSound(ref, AppSound.error);
        AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else if (widget.isUpgrade) {
      context.go('/settings/subscription');
    } else {
      context.go('/setup-company');
    }
  }

  /// Format currency
  String _formatCurrency(double amount) {
    return 'Rp ${(amount / 1000).toStringAsFixed(0)}K';
  }

  /// Get display price
  double _getDisplayPrice(PricingPlan plan) {
    return _isYearly ? plan.yearlyPrice : plan.monthlyPrice;
  }

  /// Calculate discount percentage
  int _getDiscountPercentage() {
    return 17; // Approximately 17% discount for yearly
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 40,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopRow(),
                  const SizedBox(height: 20),
                  if (!widget.isUpgrade) ...[
                    _buildStepIndicator(),
                    const SizedBox(height: 28),
                  ],
                  _buildHeader(),
                  const SizedBox(height: 28),
                  Center(child: _buildPeriodToggle()),
                  const SizedBox(height: 28),
                  _buildPricingCards(isMobile),
                  const SizedBox(height: 36),
                  _buildFAQSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        Material(
          color: AppTheme.cardColor,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _handleBack,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Step indicator — 7 langkah sesuai PRD. Posisi saat ini: 5.
  /// Cuma dipanggil kalau bukan mode upgrade (lihat build()).
  Widget _buildStepIndicator() {
    const totalSteps = 7;
    const currentStep = 5;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps * 2 - 1, (index) {
        if (index.isOdd) {
          final stepBefore = (index + 1) ~/ 2;
          final isDone = stepBefore < currentStep;
          return Container(
            width: 16,
            height: 2,
            color: isDone ? AppTheme.primaryColor : AppTheme.borderColor,
          );
        }
        final step = (index ~/ 2) + 1;
        final isActive = step == currentStep;
        final isDone = step < currentStep;
        return Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: (isActive || isDone)
                ? AppTheme.primaryColor
                : AppTheme.borderColor,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          widget.isUpgrade
              ? 'Upgrade Paket Anda'
              : 'Pilih Paket yang Sesuai',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.isUpgrade
              ? 'Pilih paket baru — perhitungan proration akan ditampilkan sebelum Anda konfirmasi'
              : 'Setiap paket dirancang untuk memenuhi kebutuhan bisnis laundry Anda',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              label: 'Bulanan',
              isSelected: !_isYearly,
              onTap: () => setState(() => _isYearly = false),
            ),
          ),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildToggleButton(
                  label: 'Tahunan',
                  isSelected: _isYearly,
                  onTap: () => setState(() => _isYearly = true),
                ),
                if (_isYearly)
                  Positioned(
                    top: -10,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Hemat ${_getDiscountPercentage()}%',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPricingCards(bool isMobile) {
    if (isMobile) {
      return Column(
        children: List.generate(
          _plans.length,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index < _plans.length - 1 ? 16 : 0),
            child: _PricingCard(
              plan: _plans[index],
              price: _getDisplayPrice(_plans[index]),
              period: _isYearly ? 'tahun' : 'bulan',
              isSelected: _selectedPlan == _plans[index].name,
              isLoading: _isNavigating && _selectedPlan == _plans[index].name,
              isUpgrade: widget.isUpgrade,
              isCurrentPlan: _isExactCurrentPlan(_plans[index]),
              needsRenewal: _currentSubNeedsRenewal,
              blockReason: _planBlockReason(_plans[index]),
              formatCurrency: _formatCurrency,
              onSelect: () => _handleSelectPlan(_plans[index]),
            ),
          ),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(
          _plans.length,
          (index) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index < _plans.length - 1 ? 16 : 0,
              ),
              child: _PricingCard(
                plan: _plans[index],
                price: _getDisplayPrice(_plans[index]),
                period: _isYearly ? 'tahun' : 'bulan',
                isSelected: _selectedPlan == _plans[index].name,
                isLoading:
                    _isNavigating && _selectedPlan == _plans[index].name,
                isUpgrade: widget.isUpgrade,
                isCurrentPlan: _isExactCurrentPlan(_plans[index]),
                needsRenewal: _currentSubNeedsRenewal,
                blockReason: _planBlockReason(_plans[index]),
                formatCurrency: _formatCurrency,
                onSelect: () => _handleSelectPlan(_plans[index]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: AppTheme.borderColor, height: 1),
        const SizedBox(height: 24),
        Text(
          'Pertanyaan Umum',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _FAQItem(
          question: 'Bisakah saya mengubah paket setelah memilih?',
          answer:
              'Ya, Anda dapat meningkatkan, menurunkan, atau membatalkan paket kapan saja dari dashboard pengaturan.',
        ),
        const SizedBox(height: 12),
        if (!widget.isUpgrade)
          _FAQItem(
            question: 'Apakah ada uji coba gratis?',
            answer:
                'Ya, Anda mendapatkan akses 14 hari gratis untuk semua paket sebelum pembayaran pertama.',
          ),
        if (!widget.isUpgrade) const SizedBox(height: 12),
        _FAQItem(
          question: 'Bagaimana dengan dukungan pelanggan?',
          answer:
              'Semua paket mendapatkan dukungan email. Paket Professional dan Enterprise mendapatkan dukungan prioritas.',
        ),
      ],
    );
  }
}

// ============================================
// HELPER WIDGETS
// ============================================

/// Pricing Card Widget
class _PricingCard extends StatelessWidget {
  final PricingPlan plan;
  final double price;
  final String period;
  final bool isSelected;
  final bool isLoading;
  final bool isUpgrade;
  final bool isCurrentPlan;
  // true kalau paket yang lagi aktif (isCurrentPlan) statusnya past_due
  // atau mendekati currentPeriodEnd (<= H-3). Kalau true DAN
  // isCurrentPlan true, tombol tetap AKTIF berlabel "Perpanjang" alih-alih
  // permanen ter-disable -- sebelumnya paket aktif selalu di-disable tanpa
  // peduli sisa waktunya, jadi nggak ada cara renew paket yang sama persis
  // dari halaman ini.
  final bool needsRenewal;
  final String? blockReason;
  final String Function(double) formatCurrency;
  final VoidCallback onSelect;

  const _PricingCard({
    required this.plan,
    required this.price,
    required this.period,
    required this.isSelected,
    this.isLoading = false,
    this.isUpgrade = false,
    this.isCurrentPlan = false,
    this.needsRenewal = false,
    this.blockReason,
    required this.formatCurrency,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isBlocked = blockReason != null;
    // Paket aktif TAPI sedang mau/sudah expired -> masih bisa dipilih
    // lagi buat renew, walau isCurrentPlan true.
    final isRenewable = isCurrentPlan && needsRenewal;
    final isDisabledCurrentPlan = isCurrentPlan && !needsRenewal;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? plan.color : AppTheme.borderColor,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? plan.color.withOpacity(0.15)
                : Colors.black.withOpacity(0.03),
            blurRadius: isSelected ? 20 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrentPlan)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: (isRenewable ? Colors.orange : Colors.grey)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isRenewable ? 'Perlu Diperpanjang' : 'Paket Saat Ini',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isRenewable ? Colors.orange[800] : Colors.grey[700],
                    ),
                  ),
                )
              else if (isBlocked)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Melebihi Limit',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                    ),
                  ),
                )
              else if (plan.isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: plan.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Populer',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: plan.color,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: formatCurrency(price),
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: plan.color,
                  ),
                ),
                TextSpan(
                  text: '/$period',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isBlocked) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                blockReason!,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: Colors.red[700],
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          ...List.generate(
            plan.features.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, color: plan.color, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      plan.features[index],
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: (!isLoading && !isDisabledCurrentPlan && !isBlocked)
                  ? onSelect
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDisabledCurrentPlan
                    ? AppTheme.borderColor
                    : (isSelected
                        ? plan.color
                        : (isRenewable ? Colors.orange : AppTheme.backgroundColor)),
                foregroundColor: isDisabledCurrentPlan
                    ? AppTheme.textSecondary
                    : (isSelected
                        ? Colors.white
                        : (isRenewable ? Colors.white : AppTheme.textPrimary)),
                disabledBackgroundColor: AppTheme.borderColor,
                disabledForegroundColor: AppTheme.textSecondary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isSelected ? Colors.white : plan.color,
                        ),
                      ),
                    )
                  : Text(
                      isDisabledCurrentPlan
                          ? 'Paket Saat Ini'
                          : (isBlocked
                              ? 'Kurangi Data Dulu'
                              : (isSelected
                                  ? 'Paket Dipilih'
                                  : (isRenewable
                                      ? 'Perpanjang Paket Ini'
                                      : (isUpgrade
                                          ? 'Upgrade ke Paket Ini'
                                          : 'Pilih Paket')))),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// FAQ Item Widget
class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FAQItem({
    required this.question,
    required this.answer,
  });

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  @override
  Widget build(BuildContext context) {
    // Pakai Material (bukan Container) sebagai pembungkus warna, supaya
    // ink splash dari ListTile internal ExpansionTile ikut ter-render di
    // lapisan yang sama dengan warnanya — kalau warnanya ditaruh di
    // Container biasa di atas Material, splash-nya ketutup dan Flutter
    // melempar warning "ink splashes may be invisible".
    return Material(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(
              widget.question,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: AppTheme.textPrimary,
              ),
            ),
            iconColor: AppTheme.primaryColor,
            collapsedIconColor: AppTheme.textSecondary,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  widget.answer,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary,
                    height: 1.6,
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
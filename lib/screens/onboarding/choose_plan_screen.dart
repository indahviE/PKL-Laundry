import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/themes/app_theme.dart';
import '../../repositories/auth_repository.dart';

/// Pricing Model
class PricingPlan {
  final String name;
  final String description;
  final double monthlyPrice;
  final double yearlyPrice;
  final List<String> features;
  final bool isPopular;
  final Color color;

  PricingPlan({
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
    required this.isPopular,
    required this.color,
  });
}

/// Choose Plan Screen — Step 5 dari onboarding.
/// Sesuai PRD section 5.1 User Flow, Step 5: Pilih Paket.
/// Alur: Setup Perusahaan → [halaman ini] → Pembayaran/Dashboard.
/// Desain disamakan dengan screen onboarding lain (tanpa AppBar biru
/// bawaan, warna & font konsisten AppTheme + GoogleFonts.poppins).
class ChoosePlanScreen extends ConsumerStatefulWidget {
  const ChoosePlanScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChoosePlanScreen> createState() => _ChoosePlanScreenState();
}

class _ChoosePlanScreenState extends ConsumerState<ChoosePlanScreen> {
  // State
  bool _isYearly = false;
  bool _isLoading = false;
  String? _selectedPlan;

  // Pricing plans
  late final List<PricingPlan> _plans;

  @override
  void initState() {
    super.initState();
    _initializePlans();
  }

  /// Initialize pricing plans
  void _initializePlans() {
    _plans = [
      PricingPlan(
        name: 'Starter',
        description: 'Untuk bisnis laundry kecil',
        monthlyPrice: 99000,
        yearlyPrice: 990000,
        features: [
          '1 Cabang',
          'Hingga 10 Karyawan',
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
        monthlyPrice: 299000,
        yearlyPrice: 2990000,
        features: [
          'Hingga 5 Cabang',
          'Hingga 50 Karyawan',
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
        monthlyPrice: 999000,
        yearlyPrice: 9990000,
        features: [
          'Unlimited Cabang',
          'Unlimited Karyawan',
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

  /// Handle select plan — simpan pilihan paket lalu masuk ke dashboard.
  /// (Step Pembayaran belum diimplementasikan; untuk MVP, pilih paket
  /// langsung menandai onboarding selesai. Sambungkan ke halaman
  /// pembayaran Stripe nanti kalau sudah siap.)
  Future<void> _handleSelectPlan(String planName) async {
    setState(() {
      _selectedPlan = planName;
      _isLoading = true;
    });

    try {
      final router = GoRouter.of(context);
      final authRepo = ref.read(authRepositoryProvider);

      await authRepo.savePlanChoice(
        planName: planName,
        isYearly: _isYearly,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Paket $planName dipilih!',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }

      // TODO: Ganti ke halaman pembayaran Stripe kalau sudah siap:
      // router.go('/onboarding/payment', extra: {...});
      router.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
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
                  _buildStepIndicator(),
                  const SizedBox(height: 28),
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
            onTap: !_isLoading ? _handleBack : null,
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
          'Pilih Paket yang Sesuai',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Setiap paket dirancang untuk memenuhi kebutuhan bisnis laundry Anda',
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
              isLoading: _isLoading,
              formatCurrency: _formatCurrency,
              onSelect: () => _handleSelectPlan(_plans[index].name),
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
                isLoading: _isLoading,
                formatCurrency: _formatCurrency,
                onSelect: () => _handleSelectPlan(_plans[index].name),
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
        _FAQItem(
          question: 'Apakah ada uji coba gratis?',
          answer:
              'Ya, Anda mendapatkan akses 14 hari gratis untuk semua paket sebelum pembayaran pertama.',
        ),
        const SizedBox(height: 12),
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
  final String Function(double) formatCurrency;
  final VoidCallback onSelect;

  const _PricingCard({
    required this.plan,
    required this.price,
    required this.period,
    required this.isSelected,
    required this.isLoading,
    required this.formatCurrency,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
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
              if (plan.isPopular)
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
              onPressed: !isLoading ? onSelect : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isSelected ? plan.color : AppTheme.backgroundColor,
                foregroundColor:
                    isSelected ? Colors.white : AppTheme.textPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
              ),
              child: isLoading && isSelected
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      isSelected ? 'Paket Dipilih' : 'Pilih Paket',
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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
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
    );
  }
}
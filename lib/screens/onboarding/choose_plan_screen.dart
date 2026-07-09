import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';

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

/// Choose Plan Screen - Step 5 dari onboarding
class ChoosePlanScreen extends StatefulWidget {
  const ChoosePlanScreen({Key? key}) : super(key: key);

  @override
  State<ChoosePlanScreen> createState() => _ChoosePlanScreenState();
}

class _ChoosePlanScreenState extends State<ChoosePlanScreen> {
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
        color: const Color(0xFF5DADE2),
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

  /// Handle select plan
  Future<void> _handleSelectPlan(String planName) async {
    setState(() {
      _selectedPlan = planName;
      _isLoading = true;
    });

    try {
      // TODO: Save selected plan ke Firebase
      // final subscriptionService = ref.read(subscriptionServiceProvider);
      // await subscriptionService.selectPlan(
      //   planName: planName,
      //   period: _isYearly ? 'yearly' : 'monthly',
      // );

      // TODO: Navigate ke payment screen
      // context.go('/onboarding/payment', extra: {
      //   'planName': planName,
      //   'isYearly': _isYearly,
      // });

      // Simulasi delay
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paket $planName dipilih! (Testing mode)'),
            backgroundColor: const Color(0xFF51CF66),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? AppTheme.lg : AppTheme.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Indicator
              _buildProgressIndicator(context),

              const SizedBox(height: AppTheme.xxl),

              // Header
              _buildHeader(context),

              const SizedBox(height: AppTheme.xl),

              // Period Toggle
              _buildPeriodToggle(context),

              const SizedBox(height: AppTheme.xxl),

              // Pricing Cards
              _buildPricingCards(context, isMobile),

              const SizedBox(height: AppTheme.xxl),

              // FAQ Section
              _buildFAQSection(context),

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
      title: const Text('Pilih Paket'),
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: !_isLoading ? () => Navigator.pop(context) : null,
      ),
    );
  }

  /// Build Progress Indicator
  Widget _buildProgressIndicator(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        Row(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF5DADE2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.sm),
            Expanded(
              flex: 2,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.md),

        // Step indicator
        Text(
          'Step 5 dari 7',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF5DADE2),
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  /// Build Header
  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Paket yang Sesuai',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.darkColor,
              ),
        ),
        const SizedBox(height: AppTheme.md),
        Text(
          'Setiap paket dirancang untuk memenuhi kebutuhan bisnis laundry Anda',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.gray600,
              ),
        ),
      ],
    );
  }

  /// Build Period Toggle
  Widget _buildPeriodToggle(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      padding: const EdgeInsets.all(AppTheme.sm),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              label: 'Bulanan',
              isSelected: !_isYearly,
              onTap: () => setState(() => _isYearly = false),
            ),
          ),
          const SizedBox(width: AppTheme.sm),
          Expanded(
            child: Stack(
              children: [
                _buildToggleButton(
                  label: 'Tahunan',
                  isSelected: _isYearly,
                  onTap: () => setState(() => _isYearly = true),
                ),
                if (_isYearly)
                  Positioned(
                    top: -12,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF51CF66),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Text(
                        'Hemat ${_getDiscountPercentage()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
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

  /// Build Toggle Button
  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF5DADE2) : AppTheme.gray600,
          ),
        ),
      ),
    );
  }

  /// Build Pricing Cards
  Widget _buildPricingCards(BuildContext context, bool isMobile) {
    return Column(
      children: List.generate(
        _plans.length,
        (index) => Column(
          children: [
            _PricingCard(
              plan: _plans[index],
              price: _getDisplayPrice(_plans[index]),
              period: _isYearly ? 'tahun' : 'bulan',
              isSelected: _selectedPlan == _plans[index].name,
              isLoading: _isLoading,
              onSelect: () => _handleSelectPlan(_plans[index].name),
            ),
            if (index < _plans.length - 1)
              const SizedBox(height: AppTheme.lg),
          ],
        ),
      ),
    );
  }

  /// Build FAQ Section
  Widget _buildFAQSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: AppTheme.xxl),
        const SizedBox(height: AppTheme.lg),
        Text(
          'Pertanyaan Umum',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppTheme.lg),
        _FAQItem(
          question: 'Bisakah saya mengubah paket setelah memilih?',
          answer:
              'Ya, Anda dapat meningkatkan, menurunkan, atau membatalkan paket kapan saja dari dashboard pengaturan.',
        ),
        const SizedBox(height: AppTheme.lg),
        _FAQItem(
          question: 'Apakah ada uji coba gratis?',
          answer:
              'Ya, Anda mendapatkan akses 14 hari gratis untuk semua paket sebelum pembayaran pertama.',
        ),
        const SizedBox(height: AppTheme.lg),
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
  final VoidCallback onSelect;

  const _PricingCard({
    required this.plan,
    required this.price,
    required this.period,
    required this.isSelected,
    required this.isLoading,
    required this.onSelect,
  });

  String _formatCurrency(double amount) {
    return 'Rp ${(amount / 1000).toStringAsFixed(0)}K';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: isSelected ? plan.color : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? plan.color.withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
            blurRadius: isSelected ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with popular badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.sm),
                  Text(
                    plan.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              if (plan.isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.md,
                    vertical: AppTheme.sm,
                  ),
                  decoration: BoxDecoration(
                    color: plan.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Text(
                    'Populer',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: plan.color,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppTheme.xl),

          // Price
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: _formatCurrency(price),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: plan.color,
                  ),
                ),
                TextSpan(
                  text: '/$period',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.lg),

          // Features
          ...List.generate(
            plan.features.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.md),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: plan.color,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.md),
                  Expanded(
                    child: Text(
                      plan.features[index],
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.darkColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.xl),

          // Select Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: !isLoading ? onSelect : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? plan.color : Colors.grey.shade200,
                foregroundColor: isSelected ? Colors.white : AppTheme.darkColor,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
              ),
              child: isLoading && isSelected
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      isSelected ? 'Paket Dipilih' : 'Pilih Paket',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
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
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        onExpansionChanged: (value) {
          setState(() => _isExpanded = value);
        },
        title: Text(
          widget.question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppTheme.darkColor,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.lg),
            child: Text(
              widget.answer,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
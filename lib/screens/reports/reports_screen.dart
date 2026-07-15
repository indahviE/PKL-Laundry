import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/themes/app_theme.dart';

/// Model breakdown pendapatan per jenis layanan
class _ServiceBreakdown {
  final String name;
  final double revenue;
  final int orderCount;
  final Color color;

  _ServiceBreakdown({
    required this.name,
    required this.revenue,
    required this.orderCount,
    required this.color,
  });
}

/// Reports Screen
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedPeriod = 2; // 0: Hari Ini, 1: Minggu Ini, 2: Bulan Ini, 3: Tahun Ini
  final List<String> _periods = ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Tahun Ini'];

  // ============================================
  // DUMMY DATA (ganti dengan fetch Firestore nanti)
  // ============================================
  double get _totalRevenue => 24500000;
  int get _totalOrders => 186;
  int get _newCustomers => 32;
  double get _avgOrderValue => _totalRevenue / _totalOrders;
  double get _growthRate => 12.5;
  double get _completionRate => 94.5;
  double get _customerRating => 4.8;

  final List<double> _weeklyValues = const [0.45, 0.6, 0.5, 0.8, 0.65, 1.0, 0.7];
  final List<String> _weeklyDays = const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  List<_ServiceBreakdown> get _serviceBreakdown => [
        _ServiceBreakdown(name: 'Cuci Kering', revenue: 9800000, orderCount: 72, color: AppTheme.primaryColor),
        _ServiceBreakdown(name: 'Cuci Setrika', revenue: 7200000, orderCount: 54, color: const Color(0xFF51CF66)),
        _ServiceBreakdown(name: 'Setrika Saja', revenue: 4100000, orderCount: 38, color: const Color(0xFFFFA94D)),
        _ServiceBreakdown(name: 'Dry Clean', revenue: 3400000, orderCount: 22, color: const Color(0xFFB197FC)),
      ];

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  String _formatCurrencyShort(double amount) {
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    }
    return _formatCurrency(amount);
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
                        _buildPeriodChips(context),
                        const SizedBox(height: AppTheme.lg),
                        _buildMainKPICards(context, isMobile),
                        const SizedBox(height: AppTheme.lg),
                        _buildGrowthIndicator(context),
                        const SizedBox(height: AppTheme.lg),
                        _buildRevenueChart(context),
                        const SizedBox(height: AppTheme.lg),
                        _buildServiceBreakdownSection(context),
                        const SizedBox(height: AppTheme.lg),
                        _buildAdditionalMetrics(context),
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

  /// Build header — sama persis gayanya dengan PickupDeliveryScreen/OrdersListScreen
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
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.bar_chart_rounded,
                color: AppTheme.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Laporan',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pantau performa bisnis laundry Anda',
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
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Export laporan akan ditambahkan')),
            );
          },
          icon: const Icon(Icons.file_download_outlined, size: 18),
          label: Text(
            'Export',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            side: BorderSide(color: AppTheme.primaryColor),
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

  /// Build period filter chips
  Widget _buildPeriodChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          _periods.length,
          (index) => Padding(
            padding: EdgeInsets.only(right: index < _periods.length - 1 ? AppTheme.md : 0),
            child: ChoiceChip(
              selected: _selectedPeriod == index,
              onSelected: (_) => setState(() => _selectedPeriod = index),
              showCheckmark: false,
              label: Text(_periods[index]),
              backgroundColor: AppTheme.cardColor,
              selectedColor: AppTheme.primaryColor.withOpacity(0.12),
              side: BorderSide(
                color: _selectedPeriod == index
                    ? AppTheme.primaryColor.withOpacity(0.4)
                    : AppTheme.borderColor,
              ),
              labelStyle: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _selectedPeriod == index ? AppTheme.primaryColor : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build main KPI cards — dirampingkan: padding & font lebih kecil, card lebih pendek
  Widget _buildMainKPICards(BuildContext context, bool isMobile) {
    final stats = [
      (icon: Icons.payments_outlined, label: 'Total Pendapatan', value: _formatCurrencyShort(_totalRevenue), color: AppTheme.primaryColor),
      (icon: Icons.shopping_bag_outlined, label: 'Total Pesanan', value: '$_totalOrders', color: const Color(0xFF51CF66)),
      (icon: Icons.person_add_alt_1_outlined, label: 'Pelanggan Baru', value: '$_newCustomers', color: const Color(0xFFFFA94D)),
      (icon: Icons.trending_up_rounded, label: 'Rata-rata Order', value: _formatCurrencyShort(_avgOrderValue), color: const Color(0xFFB197FC)),
    ];

    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      crossAxisSpacing: AppTheme.md,
      mainAxisSpacing: AppTheme.md,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isMobile ? 1.6 : 1.35,
      children: stats.map((stat) {
        return _StatCard(icon: stat.icon, label: stat.label, value: stat.value, color: stat.color);
      }).toList(),
    );
  }

  /// Build growth indicator — dirampingkan jadi satu baris ringkas
  Widget _buildGrowthIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.lg, vertical: AppTheme.md),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF51CF66).withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.trending_up_rounded, color: Color(0xFF51CF66), size: 17),
          ),
          const SizedBox(width: AppTheme.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pertumbuhan Periode Ini',
                  style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Naik $_growthRate% dari periode sebelumnya',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.sm, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF51CF66).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+$_growthRate%',
              style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF51CF66)),
            ),
          ),
        ],
      ),
    );
  }

  /// Build revenue chart
  Widget _buildRevenueChart(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.lg),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tren Pendapatan',
                style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '7 hari terakhir',
                  style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.lg),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_weeklyValues.length, (i) {
                final isPeak = _weeklyValues[i] == _weeklyValues.reduce((a, b) => a > b ? a : b);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: 78 * _weeklyValues[i],
                          decoration: BoxDecoration(
                            color: isPeak ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _weeklyDays[i],
                          style: GoogleFonts.poppins(fontSize: 10.5, color: AppTheme.textTertiary),
                        ),
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
  }

  /// Build breakdown pendapatan per layanan
  Widget _buildServiceBreakdownSection(BuildContext context) {
    final maxRevenue = _serviceBreakdown.map((s) => s.revenue).reduce((a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.lg),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pendapatan per Layanan',
            style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: AppTheme.lg),
          ..._serviceBreakdown.asMap().entries.map((entry) {
            final i = entry.key;
            final service = entry.value;
            final isLast = i == _serviceBreakdown.length - 1;
            final percentage = (service.revenue / maxRevenue * 100).toStringAsFixed(0);

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppTheme.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: service.color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: AppTheme.sm),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.name,
                                style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${service.orderCount} pesanan',
                                style: GoogleFonts.poppins(fontSize: 10.5, color: AppTheme.textTertiary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatCurrency(service.revenue),
                            style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$percentage%',
                            style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: service.color),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: service.revenue / maxRevenue,
                      minHeight: 6,
                      backgroundColor: AppTheme.backgroundColor,
                      valueColor: AlwaysStoppedAnimation(service.color),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Build additional metrics — dirampingkan
  Widget _buildAdditionalMetrics(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.check_circle_outline,
            label: 'Completion Rate',
            value: '$_completionRate%',
            caption: 'dari seluruh pesanan',
            color: const Color(0xFF51CF66),
          ),
        ),
        const SizedBox(width: AppTheme.md),
        Expanded(
          child: _MetricCard(
            icon: Icons.star_outline_rounded,
            label: 'Customer Rating',
            value: '$_customerRating/5.0',
            caption: 'dari $_totalOrders review',
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }
}

// ============================================
// HELPER WIDGETS
// ============================================

/// Kartu KPI utama — ukuran diperkecil, ikon & teks lebih ringkas
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10.5, color: AppTheme.textTertiary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Kartu metrik tambahan (completion rate, rating) — ringkas & konsisten
class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 15),
              ),
              const SizedBox(width: AppTheme.sm),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.md),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: GoogleFonts.poppins(fontSize: 10.5, color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }
}
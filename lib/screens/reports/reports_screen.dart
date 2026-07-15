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
  int _selectedPeriod = 2;
  final List<String> _periods = ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Tahun Ini'];

  double get _totalRevenue => 24500000;
  int get _totalOrders => 186;
  int get _newCustomers => 32;
  double get _avgOrderValue => _totalRevenue / _totalOrders;
  double get _growtRate => 12.5;

  final List<double> _weeklyValues = const [0.45, 0.6, 0.5, 0.8, 0.65, 1.0, 0.7];
  final List<String> _weeklyDays = const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  List<_ServiceBreakdown> get _serviceBreakdown => [
    _ServiceBreakdown(name: 'Cuci Kering', revenue: 9800000, orderCount: 72, color: const Color(0xFF5DADE2)),
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
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Laporan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(context),
                    const SizedBox(height: 24),
                    _buildPeriodChips(context),
                    const SizedBox(height: 24),
                    _buildMainKPICards(context, isMobile),
                    const SizedBox(height: 24),
                    _buildGrowthIndicator(context),
                    const SizedBox(height: 24),
                    _buildRevenueChart(context),
                    const SizedBox(height: 24),
                    _buildServiceBreakdownSection(context),
                    const SizedBox(height: 24),
                    _buildAdditionalMetrics(context, isMobile),
                    const SizedBox(height: AppTheme.lg),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build header section
  Widget _buildHeaderSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pantau Performa',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Analisis mendalam performa bisnis laundry Anda',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.grey.shade600),
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
          label: Text('Export', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF5DADE2),
            side: const BorderSide(color: Color(0xFF5DADE2)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            padding: EdgeInsets.only(right: index < _periods.length - 1 ? 12 : 0),
            child: ChoiceChip(
              selected: _selectedPeriod == index,
              onSelected: (_) => setState(() => _selectedPeriod = index),
              showCheckmark: false,
              label: Text(_periods[index]),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF5DADE2).withOpacity(0.12),
              side: BorderSide(
                color: _selectedPeriod == index ? const Color(0xFF5DADE2).withOpacity(0.4) : Colors.grey.shade300,
              ),
              labelStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _selectedPeriod == index ? const Color(0xFF5DADE2) : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build main KPI cards
  Widget _buildMainKPICards(BuildContext context, bool isMobile) {
    final stats = [
      (icon: Icons.payments_outlined, label: 'Total Pendapatan', value: _formatCurrencyShort(_totalRevenue), color: const Color(0xFF5DADE2)),
      (icon: Icons.shopping_bag_outlined, label: 'Total Pesanan', value: '$_totalOrders', color: const Color(0xFF51CF66)),
      (icon: Icons.people_outline, label: 'Pelanggan Baru', value: '$_newCustomers', color: const Color(0xFFFFA94D)),
      (icon: Icons.trending_up_outlined, label: 'Rata-rata Order', value: _formatCurrencyShort(_avgOrderValue), color: const Color(0xFFB197FC)),
    ];

    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: stats.map((stat) {
        return _StatCard(icon: stat.icon, label: stat.label, value: stat.value, color: stat.color);
      }).toList(),
    );
  }

  /// Build growth indicator
  Widget _buildGrowthIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF5DADE2).withOpacity(0.08), const Color(0xFF5DADE2).withOpacity(0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5DADE2).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF51CF66).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.trending_up, color: Color(0xFF51CF66), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pertumbuhan Periode Ini',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pendapatan meningkat $_growtRate% dibanding periode sebelumnya',
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF51CF66).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+$_growtRate%',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF51CF66)),
            ),
          ),
        ],
      ),
    );
  }

  /// Build revenue chart
  Widget _buildRevenueChart(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: const Color(0xFF5DADE2).withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tren Pendapatan', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('7 hari terakhir', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400, color: Colors.grey.shade600)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF5DADE2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('↑ 15% dari minggu lalu', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF5DADE2))),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
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
                          height: 100 * _weeklyValues[i],
                          decoration: BoxDecoration(
                            color: isPeak ? const Color(0xFF5DADE2) : const Color(0xFF5DADE2).withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(_weeklyDays[i], style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
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

  /// Build service breakdown section
  Widget _buildServiceBreakdownSection(BuildContext context) {
    final maxRevenue = _serviceBreakdown.map((s) => s.revenue).reduce((a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: const Color(0xFF5DADE2).withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pendapatan per Layanan', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          ..._serviceBreakdown.asMap().entries.map((entry) {
            final i = entry.key;
            final service = entry.value;
            final isLast = i == _serviceBreakdown.length - 1;
            final percentage = (service.revenue / maxRevenue * 100).toStringAsFixed(0);

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: service.color, shape: BoxShape.circle)),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(service.name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 3),
                              Text('${service.orderCount} pesanan', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400, color: Colors.grey.shade600)),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_formatCurrency(service.revenue), style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text('$percentage%', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: service.color)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: service.revenue / maxRevenue,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
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

  /// Build additional metrics
  Widget _buildAdditionalMetrics(BuildContext context, bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF51CF66).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.check_circle_outline, color: Color(0xFF51CF66), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text('Completion Rate', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),
                Text('94.5%', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF51CF66))),
                const SizedBox(height: 4),
                Text('dari seluruh pesanan', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5DADE2).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.star_outline, color: Color(0xFF5DADE2), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text('Customer Rating', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),
                Text('4.8/5.0', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF5DADE2))),
                const SizedBox(height: 4),
                Text('dari 186 review', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Stat Card Widget
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

/// Opsi cabang buat filter, di-fetch dari users/{uid}/laundries
/// (sesuai Blueprint §3.2.3). Pola sama persis dengan _LaundryOption di
/// OrdersListScreen / CustomersListScreen.
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

/// Reports Screen
///
/// UPDATED: berbeda dari PickupDeliveryScreen (yang sengaja TIDAK
/// dipisah per cabang karena sifatnya operasional harian), laporan di
/// sini justru butuh breakdown per cabang - owner dengan banyak cabang
/// perlu tahu "cabang mana yang paling untung", bukan cuma angka gabungan.
/// Filter cabang cuma muncul kalau owner punya > 1 cabang aktif (lihat
/// _showLaundryFilter), sama pola auto-hide di semua layar list lainnya.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedPeriod = 2; // 0: Hari Ini, 1: Minggu Ini, 2: Bulan Ini, 3: Tahun Ini
  final List<String> _periods = ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Tahun Ini'];
  bool _isExporting = false;

  // Filter cabang - 'all' berarti gabungan semua cabang (behavior lama,
  // tetap jadi default). Chip filter cuma ditampilkan kalau owner punya
  // > 1 cabang aktif (_showLaundryFilter).
  List<_LaundryOption> _laundriesList = [];
  String _selectedLaundryId = 'all';

  bool get _showLaundryFilter => _laundriesList.length > 1;

  // Real data dari Firebase (bukan dummy lagi)
  double _totalRevenue = 0;
  int _totalOrders = 0;
  int _newCustomers = 0;
  double _avgOrderValue = 0;
  double _growthRate = 0;
  double _completionRate = 0;

  List<double> _weeklyValues = List.filled(7, 0.0);
  final List<String> _weeklyDays = const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  List<_ServiceBreakdown> _serviceBreakdown = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLaundries();
    _fetchReportsData();
  }

  /// Ambil semua cabang aktif milik company ini, buat isi chip filter
  /// (cuma ditampilkan kalau > 1, lihat _showLaundryFilter). Gagal fetch
  /// bukan error fatal - laporan tetap jalan dengan data gabungan semua
  /// cabang, cuma filter chip-nya gak muncul.
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
      debugPrint('Gagal memuat data cabang: $e');
    }
  }

  /// Fetch semua data dari Firebase sesuai period & cabang yang dipilih.
  ///
  /// NOTE PENTING: menambahkan filter laundry_id di atas range query
  /// order_date butuh composite index di Firestore. Kalau muncul error
  /// "failed-precondition" pas pertama kali jalan dengan filter cabang
  /// aktif, buka link yang Firestore kasih di error tersebut - itu akan
  /// otomatis bikinkan index yang dibutuhkan, tidak perlu dibuat manual.
  Future<void> _fetchReportsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Sesi tidak ditemukan, silakan login ulang';
          _isLoading = false;
        });
        return;
      }

      final now = DateTime.now();
      late DateTime startDate;
      late DateTime endDate;

      // Tentukan range tanggal berdasarkan period
      if (_selectedPeriod == 0) {
        // Hari Ini
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
      } else if (_selectedPeriod == 1) {
        // Minggu Ini
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = startDate.add(const Duration(days: 7));
      } else if (_selectedPeriod == 2) {
        // Bulan Ini
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1);
      } else {
        // Tahun Ini
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year + 1, 1, 1);
      }

      // Query dasar orders, ditambah filter cabang kalau bukan "Semua Cabang"
      Query ordersQuery = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .where('order_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('order_date', isLessThan: Timestamp.fromDate(endDate));
      if (_selectedLaundryId != 'all') {
        ordersQuery = ordersQuery.where('laundry_id', isEqualTo: _selectedLaundryId);
      }
      final ordersSnap = await ordersQuery.get();

      // Query dasar customers, ditambah filter cabang yang sama - supaya
      // "Pelanggan Baru" juga menghitung pelanggan cabang yang dipilih
      // saja (customer.laundry_id, lihat CreateCustomerScreen).
      Query customersQuery = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('customers')
          .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('created_at', isLessThan: Timestamp.fromDate(endDate));
      if (_selectedLaundryId != 'all') {
        customersQuery = customersQuery.where('laundry_id', isEqualTo: _selectedLaundryId);
      }
      final customersSnap = await customersQuery.get();

      // Calculate metrics dari orders
      double totalRevenue = 0;
      int completedOrders = 0;
      int totalOrdersCount = ordersSnap.docs.length;

      Map<String, double> serviceRevenue = {};
      Map<String, int> serviceOrderCount = {};

      for (var doc in ordersSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = ((data['total_amount'] ?? 0) as num).toDouble();
        final status = data['status'] ?? 'pending';

        totalRevenue += amount;

        if (status == 'completed') {
          completedOrders++;
        }

        // Service breakdown -> nama layanan disimpan di dalam array `items`,
        // satu order bisa punya lebih dari 1 jenis layanan sekaligus.
        final items = (data['items'] as List?) ?? [];
        if (items.isEmpty) {
          const fallbackName = 'Lainnya';
          serviceRevenue[fallbackName] = (serviceRevenue[fallbackName] ?? 0) + amount;
          serviceOrderCount[fallbackName] = (serviceOrderCount[fallbackName] ?? 0) + 1;
        } else {
          for (final rawItem in items) {
            final item = Map<String, dynamic>.from(rawItem as Map);
            final serviceName = (item['service_name'] ?? 'Lainnya') as String;
            final itemTotal = ((item['total_price'] ?? 0) as num).toDouble();
            serviceRevenue[serviceName] = (serviceRevenue[serviceName] ?? 0) + itemTotal;
            serviceOrderCount[serviceName] = (serviceOrderCount[serviceName] ?? 0) + 1;
          }
        }
      }

      // Build service breakdown list
      final serviceList = <_ServiceBreakdown>[];
      final colors = [
        AppTheme.primaryColor,
        const Color(0xFF51CF66),
        const Color(0xFFFFA94D),
        const Color(0xFFB197FC),
      ];
      int colorIndex = 0;

      serviceRevenue.forEach((service, revenue) {
        serviceList.add(
          _ServiceBreakdown(
            name: service,
            revenue: revenue,
            orderCount: serviceOrderCount[service] ?? 0,
            color: colors[colorIndex % colors.length],
          ),
        );
        colorIndex++;
      });

      // Sort by revenue descending
      serviceList.sort((a, b) => b.revenue.compareTo(a.revenue));

      // Calculate weekly breakdown (7 hari terakhir)
      final weeklyData = await _calculateWeeklyData(user.uid, startDate, endDate);

      // Calculate growth rate (bandingkan dengan periode sebelumnya)
      final previousPeriodRevenue = await _getPreviousPeriodRevenue(user.uid, startDate, endDate);
      final growthPercentage = previousPeriodRevenue > 0
          ? ((totalRevenue - previousPeriodRevenue) / previousPeriodRevenue * 100)
          : 0.0;

      if (!mounted) return;
      setState(() {
        _totalRevenue = totalRevenue;
        _totalOrders = totalOrdersCount;
        _newCustomers = customersSnap.docs.length;
        _avgOrderValue = totalOrdersCount > 0 ? totalRevenue / totalOrdersCount : 0.0;
        _growthRate = growthPercentage;
        _completionRate = totalOrdersCount > 0 ? (completedOrders / totalOrdersCount * 100) : 0.0;
        _serviceBreakdown = serviceList.isEmpty ? [] : serviceList;
        _weeklyValues = weeklyData;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  /// Calculate weekly revenue breakdown - ikut filter cabang yang aktif.
  ///
  /// NOTE: maxRevenue dihitung dari TOTAL pendapatan per hari (bukan dari
  /// amount per order), supaya rasio tinggi bar (revenue / maxRevenue) di
  /// _buildRevenueChart selalu berada di rentang 0.0-1.0. Kalau dihitung
  /// dari amount per order, hari dengan banyak order kecil bisa punya
  /// total lebih besar dari "order tunggal terbesar", bikin rasio > 1.0
  /// dan bar overflow keluar dari SizedBox(height: 110).
  Future<List<double>> _calculateWeeklyData(String uid, DateTime startDate, DateTime endDate) async {
    final weeklyRevenue = <int, double>{}; // day of week -> revenue

    Query ordersQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('orders')
        .where('order_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('order_date', isLessThan: Timestamp.fromDate(endDate));
    if (_selectedLaundryId != 'all') {
      ordersQuery = ordersQuery.where('laundry_id', isEqualTo: _selectedLaundryId);
    }
    final ordersSnap = await ordersQuery.get();

    for (var doc in ordersSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = ((data['total_amount'] ?? 0) as num).toDouble();
      final orderDate = (data['order_date'] as Timestamp).toDate();
      final dayOfWeek = orderDate.weekday; // 1 = Monday, 7 = Sunday

      weeklyRevenue[dayOfWeek] = (weeklyRevenue[dayOfWeek] ?? 0) + amount;
    }

    // Cari max dari TOTAL per hari, bukan dari amount per order
    double maxRevenue = 0;
    for (final total in weeklyRevenue.values) {
      if (total > maxRevenue) maxRevenue = total;
    }

    // Convert to list format (Monday to Sunday)
    final result = <double>[];
    for (int i = 1; i <= 7; i++) {
      final revenue = weeklyRevenue[i] ?? 0;
      result.add(maxRevenue > 0 ? revenue / maxRevenue : 0.0);
    }

    return result;
  }

  /// Get revenue dari periode sebelumnya untuk calculate growth - ikut
  /// filter cabang yang aktif, supaya growth rate dihitung apple-to-apple
  /// (cabang yang sama, bukan dibandingkan ke gabungan semua cabang).
  Future<double> _getPreviousPeriodRevenue(String uid, DateTime currentStart, DateTime currentEnd) async {
    final duration = currentEnd.difference(currentStart);
    final prevStart = currentStart.subtract(duration);
    final prevEnd = currentStart;

    Query ordersQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('orders')
        .where('order_date', isGreaterThanOrEqualTo: Timestamp.fromDate(prevStart))
        .where('order_date', isLessThan: Timestamp.fromDate(prevEnd));
    if (_selectedLaundryId != 'all') {
      ordersQuery = ordersQuery.where('laundry_id', isEqualTo: _selectedLaundryId);
    }
    final ordersSnap = await ordersQuery.get();

    double totalRevenue = 0;
    for (var doc in ordersSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalRevenue += ((data['total_amount'] ?? 0) as num).toDouble();
    }

    return totalRevenue;
  }

  /// Nama cabang yang lagi difilter, buat ditampilin di judul PDF.
  /// "Semua Cabang" kalau _selectedLaundryId == 'all'.
  String get _selectedLaundryLabel {
    if (_selectedLaundryId == 'all') return 'Semua Cabang';
    final match = _laundriesList.where((l) => l.id == _selectedLaundryId);
    return match.isNotEmpty ? match.first.name : 'Semua Cabang';
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  String _formatCurrencyShort(double amount) {
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    }
    return _formatCurrency(amount);
  }

  // Tema warna PDF — biru langit cerah, senada dengan tema aplikasi
  static const PdfColor _pdfPrimary = PdfColor.fromInt(0xFF38BDF8); // sky blue cerah
  static const PdfColor _pdfPrimaryDark = PdfColor.fromInt(0xFF0284C7); // untuk teks/judul biar tetap kebaca
  static const PdfColor _pdfPrimaryTint = PdfColor.fromInt(0xFFE0F2FE); // background header tabel
  static const PdfColor _pdfBorderLight = PdfColor.fromInt(0xFFBAE6FD); // border tabel, biru muda

  /// Generate & bagikan/print laporan sebagai PDF
  Future<void> _exportToPdf(BuildContext context) async {
    setState(() => _isExporting = true);

    try {
      final doc = pw.Document();
      final periodLabel = _periods[_selectedPeriod];
      final laundryLabel = _selectedLaundryLabel;
      final now = DateTime.now();
      final generatedAt = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final maxRevenue = _serviceBreakdown.isEmpty
          ? 1.0
          : _serviceBreakdown.map((s) => s.revenue).reduce((a, b) => a > b ? a : b);

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Laporan Bisnis Laundry',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _pdfPrimaryDark),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Periode: $periodLabel   |   Cabang: $laundryLabel   |   Dibuat: $generatedAt',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 12),
              pw.Divider(color: _pdfPrimary, thickness: 1.2),
            ],
          ),
          build: (context) => [
            // Ringkasan KPI utama
            pw.Text('Ringkasan', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _pdfPrimaryDark)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: _pdfBorderLight),
              children: [
                _pdfTableRow(['Total Pendapatan', _formatCurrency(_totalRevenue)]),
                _pdfTableRow(['Total Pesanan', '$_totalOrders']),
                _pdfTableRow(['Pelanggan Baru', '$_newCustomers']),
                _pdfTableRow(['Rata-rata Order', _formatCurrency(_avgOrderValue)]),
                _pdfTableRow(['Pertumbuhan', '+${_growthRate.toStringAsFixed(1)}% dari periode sebelumnya']),
                _pdfTableRow(['Completion Rate', '${_completionRate.toStringAsFixed(1)}%']),
              ],
            ),
            pw.SizedBox(height: 20),

            // Tren mingguan
            pw.Text('Tren Pendapatan (7 hari terakhir)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _pdfPrimaryDark)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: _pdfBorderLight),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _pdfPrimaryTint),
                  children: _weeklyDays
                      .map((d) => pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(d, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          ))
                      .toList(),
                ),
                pw.TableRow(
                  children: _weeklyValues
                      .map((v) => pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('${(v * 100).toStringAsFixed(0)}%', style: const pw.TextStyle(fontSize: 10)),
                          ))
                      .toList(),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Breakdown per layanan
            pw.Text('Pendapatan per Layanan', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _pdfPrimaryDark)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: _pdfBorderLight),
              columnWidths: const {
                0: pw.FlexColumnWidth(2.5),
                1: pw.FlexColumnWidth(1.5),
                2: pw.FlexColumnWidth(2),
                3: pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _pdfPrimaryTint),
                  children: [
                    _pdfCell('Layanan', bold: true),
                    _pdfCell('Pesanan', bold: true),
                    _pdfCell('Pendapatan', bold: true),
                    _pdfCell('Persentase', bold: true),
                  ],
                ),
                ..._serviceBreakdown.map((service) {
                  final percentage = (service.revenue / maxRevenue * 100).toStringAsFixed(0);
                  return pw.TableRow(
                    children: [
                      _pdfCell(service.name),
                      _pdfCell('${service.orderCount}'),
                      _pdfCell(_formatCurrency(service.revenue)),
                      _pdfCell('$percentage%'),
                    ],
                  );
                }),
              ],
            ),
          ],
          footer: (context) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Halaman ${context.pageNumber} dari ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: _pdfPrimaryDark),
            ),
          ),
        ),
      );

      final Uint8List bytes = await doc.save();
      final fileName = 'laporan_${periodLabel.toLowerCase().replaceAll(' ', '_')}_${now.millisecondsSinceEpoch}.pdf';

      // Menampilkan preview + opsi share/print/save menggunakan package printing
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  pw.TableRow _pdfTableRow(List<String> cells) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(cells[0], style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(cells[1], style: const pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  pw.Widget _pdfCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
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
                        _buildTopBar(context),
                        const SizedBox(height: AppTheme.lg),
                        _buildHeader(context),
                        const SizedBox(height: 22),
                        _buildPeriodChips(context),
                        if (_showLaundryFilter) ...[
                          const SizedBox(height: AppTheme.md),
                          _buildLaundryFilterChips(context),
                        ],
                        const SizedBox(height: AppTheme.lg),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_errorMessage != null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: AppTheme.xxl),
                              child: Column(
                                children: [
                                  Text(
                                    _errorMessage ?? 'Error',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(color: Colors.red),
                                  ),
                                  const SizedBox(height: AppTheme.lg),
                                  TextButton(
                                    onPressed: _fetchReportsData,
                                    child: Text('Coba lagi', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else ...[
                          _buildMainKPICards(context, isMobile),
                          const SizedBox(height: AppTheme.lg),
                          _buildGrowthIndicator(context),
                          const SizedBox(height: AppTheme.lg),
                          _buildRevenueChart(context),
                          const SizedBox(height: AppTheme.lg),
                          _buildServiceBreakdownSection(context),
                          const SizedBox(height: AppTheme.lg),
                          _buildAdditionalMetrics(context),
                        ],
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

  /// Tombol back di paling atas, gaya sama dengan top bar di
  /// CreateOrderScreen/OrderDetailScreen (biar konsisten, karena
  /// /laporan juga route full-page di luar shell/bottom-nav).
  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(11),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }

  /// Build header — Row luar dibungkus Expanded di sisi judul & Flexible
  /// implicit di tombol Export, biar gak overflow pas layar sempit
  /// (mobile). Label tombol Export disembunyikan di mobile, cuma nyisain
  /// icon-nya, karena ruang horizontal terbatas.
  Widget _buildHeader(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Laporan',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pantau performa bisnis laundry Anda',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _isExporting ? null : () => _exportToPdf(context),
          icon: _isExporting
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                )
              : const Icon(Icons.file_download_outlined, size: 18),
          label: Text(
            isMobile ? '' : (_isExporting ? 'Membuat PDF...' : 'Export'),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            side: BorderSide(color: AppTheme.primaryColor),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? AppTheme.md : AppTheme.lg,
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
              onSelected: (_) {
                setState(() => _selectedPeriod = index);
                _fetchReportsData();
              },
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

  /// Build filter chip CABANG - baris terpisah di bawah filter periode,
  /// cuma dirender kalau _showLaundryFilter true (cabang > 1). Chip
  /// pertama selalu "Semua Cabang", sisanya sesuai nama cabang aktif.
  /// Pola sama persis dengan OrdersListScreen/CustomersListScreen.
  Widget _buildLaundryFilterChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.md),
            child: _buildLaundryChip(
              label: 'Semua Cabang',
              isSelected: _selectedLaundryId == 'all',
              onTap: () {
                setState(() => _selectedLaundryId = 'all');
                _fetchReportsData();
              },
            ),
          ),
          ..._laundriesList.map((laundry) {
            final isLast = laundry.id == _laundriesList.last.id;
            return Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : AppTheme.md),
              child: _buildLaundryChip(
                label: laundry.name,
                isSelected: _selectedLaundryId == laundry.id,
                onTap: () {
                  setState(() => _selectedLaundryId = laundry.id);
                  _fetchReportsData();
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLaundryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      selected: isSelected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storefront_outlined, size: 15),
          const SizedBox(width: AppTheme.sm),
          Text(label),
        ],
      ),
      backgroundColor: AppTheme.cardColor,
      selectedColor: AppTheme.primaryColor.withOpacity(0.12),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor.withOpacity(0.4) : AppTheme.borderColor,
      ),
      labelStyle: GoogleFonts.poppins(
        fontSize: 12.5,
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
        fontWeight: FontWeight.w600,
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
    final isPositive = _growthRate >= 0;
    final growthColor = isPositive ? const Color(0xFF51CF66) : Colors.red;

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
              color: growthColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: growthColor,
              size: 17,
            ),
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
                  '${isPositive ? "Naik" : "Turun"} ${_growthRate.abs().toStringAsFixed(1)}% dari periode sebelumnya',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.sm, vertical: 5),
            decoration: BoxDecoration(
              color: growthColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${isPositive ? "+" : "-"}${_growthRate.abs().toStringAsFixed(1)}%',
              style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: growthColor),
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
                final maxVal = _weeklyValues.reduce((a, b) => a > b ? a : b);
                final isPeak = maxVal > 0 && _weeklyValues[i] == maxVal;
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
    if (_serviceBreakdown.isEmpty) {
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
            Text(
              'Belum ada data pesanan pada periode ini.',
              style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

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
            final percentage = maxRevenue > 0 ? (service.revenue / maxRevenue * 100).toStringAsFixed(0) : '0';

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
                      value: maxRevenue > 0 ? service.revenue / maxRevenue : 0,
                      minHeight: 6,
                      backgroundColor: AppTheme.backgroundColor,
                      valueColor: AlwaysStoppedAnimation(service.color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Build additional metrics — sekarang cuma Completion Rate (rating dihapus,
  /// fitur customer rating belum ada di app)
  Widget _buildAdditionalMetrics(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.check_circle_outline,
            label: 'Completion Rate',
            value: '${_completionRate.toStringAsFixed(1)}%',
            caption: 'dari seluruh pesanan',
            color: const Color(0xFF51CF66),
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

/// Kartu metrik tambahan (completion rate) — ringkas & konsisten
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
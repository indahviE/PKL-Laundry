import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/themes/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Local design tokens — DISAMAIN PERSIS dengan _DS di services_list_screen.dart
/// biar Reports & Services satu tema (Be Vietnam Pro, navy/primary NetWash,
/// pill chip, card putih shadow tipis). Tetap lokal di file ini (bukan
/// dipindah ke app_theme.dart) mengikuti pola yang sudah dipakai di layar
/// lain, jadi gak ada layar lain yang ikut berubah tampilannya.
///
/// AppTheme.* masih dipakai di file ini, tapi CUMA untuk token spacing
/// (sm/md/lg/xxl) — semua token WARNA sekarang lewat _DS.
class _DS {
  static const canvas = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const onSurface = Color(0xFF1B1C1C);
  static const onSurfaceVariant = Color(0xFF404752);
  static const outlineVariant = Color(0xFFBFC7D4);

  static const navy = Color(0xFF0B3B66);
  static const primary = Color(0xFF0061A4);

  static const success = Color(0xFF51CF66);
  static const warning = Color(0xFFFFA94D);
  static const purple = Color(0xFFB197FC);
  static const danger = Color(0xFFE03131);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static TextStyle headlineMd({Color? color}) => GoogleFonts.beVietnamPro(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: color ?? onSurface,
        letterSpacing: -0.2,
      );

  static TextStyle titleSm({Color? color, FontWeight? weight}) => GoogleFonts.beVietnamPro(
        fontSize: 13.5,
        fontWeight: weight ?? FontWeight.w700,
        color: color ?? onSurface,
      );

  static TextStyle bodyMd({Color? color, FontWeight? weight}) => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: weight ?? FontWeight.w400,
        color: color ?? onSurface,
      );

  static TextStyle bodySm({Color? color, FontWeight? weight}) => GoogleFonts.beVietnamPro(
        fontSize: 12.5,
        fontWeight: weight ?? FontWeight.w400,
        color: color ?? onSurfaceVariant,
      );

  static TextStyle labelBold({Color? color}) => GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color ?? onSurfaceVariant,
      );
}

/// Jenis error yang bisa terjadi saat fetch data laporan. Disimpan
/// sebagai kode (bukan String siap-tampil) supaya pesannya bisa
/// diterjemahkan sesuai locale aktif saat di-render di build(),
/// bukan "dibekukan" dalam Bahasa Indonesia saat fetch terjadi.
enum _ReportsErrorType { none, session, generic }

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

  factory _LaundryOption.fromFirestore(DocumentSnapshot doc, AppLocalizations t) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return _LaundryOption(
      id: doc.id,
      name: (data['name'] ?? t.unnamedBranchLabel) as String,
    );
  }
}

/// BARU (v5): satu opsi minggu di dalam dropdown "Minggu Ini" —
/// merepresentasikan satu blok 7-hari (atau sisa hari terakhir kalau
/// bulan gak habis dibagi 7 rata) di dalam sebuah bulan. `start` dan
/// `end` sama-sama INCLUSIVE (end = hari terakhir minggu itu, BUKAN
/// exclusive upper-bound query Firestore — konversi ke exclusive
/// dilakukan di _fetchReportsData saat query dibangun).
class _WeekOption {
  final int index; // 1-based: Minggu 1, Minggu 2, dst.
  final DateTime start;
  final DateTime end;

  _WeekOption({required this.index, required this.start, required this.end});
}

/// Reports Screen
///
/// UPDATED: berbeda dari PickupDeliveryScreen (yang sengaja TIDAK
/// dipisah per cabang karena sifatnya operasional harian), laporan di
/// sini justru butuh breakdown per cabang - owner dengan banyak cabang
/// perlu tahu "cabang mana yang paling untung", bukan cuma angka gabungan.
/// Filter cabang cuma muncul kalau owner punya > 1 cabang aktif (lihat
/// _showLaundryFilter), sama pola auto-hide di semua layar list lainnya.
///
/// UPDATED (v2): period "Bulan Ini" sekarang jadi "Per Bulan" — gak
/// dikunci ke bulan berjalan lagi. Chip-nya sendiri berfungsi sebagai
/// tombol dropdown (_buildMonthDropdownChip -> _openMonthPicker): tap
/// buka popup nav tahun + grid 12 bulan (_MonthYearPickerCard), bulan
/// yang belum terjadi otomatis abu-abu & gak bisa dipilih. Tema visual
/// disamain ke _DS (lihat komentar di atas class).
///
/// UPDATED (v3): dropdown bulan sebelumnya kepotong di layar sempit
/// karena lebarnya fixed 264px + offset horizontal statis (0). Sekarang
/// card-nya diperkecil jadi _monthPickerWidth (216px, lebih minimalis)
/// dan posisinya dihitung dinamis di _openMonthPicker berdasarkan posisi
/// chip vs lebar layar (_monthChipKey), supaya kalau bakal nabrak tepi
/// kanan layar, card digeser ke kiri secukupnya.
///
/// UPDATED (v6): dropdown bulan & minggu ternyata masih kelebaran di HP
/// (screenshot user nunjukkin card sampe kepotong keluar layar 400px).
/// Diperketat lagi: _monthPickerWidth 132 -> 108, _weekPickerWidth
/// 168 -> 140, plus padding internal & font di kedua card dikecilin dikit
/// supaya proporsinya pas — lebar card sekarang beneran ngepas sama teks
/// nama bulan/rentang minggu, bukan lebar kosong nganggur kayak sebelumnya.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedPeriod = 2; // 0: Hari Ini, 1: Minggu Ini, 2: Per Bulan, 3: Tahun Ini
  bool _isExporting = false;

  // Bulan yang lagi difilter saat _selectedPeriod == 2. Default bulan
  // berjalan, bisa diganti lewat dropdown _openMonthPicker.
  late DateTime _selectedMonth;

  // Filter cabang - 'all' berarti gabungan semua cabang (behavior lama,
  // tetap jadi default). Chip filter cuma ditampilkan kalau owner punya
  // > 1 cabang aktif (_showLaundryFilter).
  List<_LaundryOption> _laundriesList = [];
  String _selectedLaundryId = 'all';

  bool get _showLaundryFilter => _laundriesList.length > 1;

  /// Anchor buat dropdown bulan — dipakai pasangan CompositedTransformTarget
  /// (di chip) + CompositedTransformFollower (di kartu dropdown), supaya
  /// posisinya selalu nempel persis di bawah chip "Per Bulan" walau layar
  /// di-scroll. Dropdown-nya sendiri dipasang manual via Overlay (BUKAN
  /// showMenu/PopupMenuItem) karena PopupMenuItem punya InkWell pembungkus
  /// yang suka "nyerok" tap sebelum sampai ke tombol bulan di dalamnya.
  final LayerLink _monthPickerLink = LayerLink();

  /// Key buat nge-track posisi global chip "Per Bulan" di layar, dipakai
  /// _openMonthPicker buat menghitung apakah dropdown bakal kepotong di
  /// tepi kanan layar (lihat catatan v3 di atas class).
  final GlobalKey _monthChipKey = GlobalKey();

  OverlayEntry? _monthPickerBarrier;
  OverlayEntry? _monthPickerCard;

  /// Lebar dropdown bulan — dipakai bareng di overlay (_openMonthPicker)
  /// dan di isinya (_MonthYearPickerCard) biar gak ada dua angka beda yang
  /// harus disinkron manual.
  ///
  /// UPDATED (v5): masih kelebaran di v4 (152px kerasa lebar buat 1 baris
  /// nama bulan). Diperketat lagi ke 132px, DAN sekarang dibungkus
  /// ClipRRect di overlay-nya (lihat _openMonthPicker/_openWeekPicker)
  /// supaya lebar tampilan dijamin gak pernah bisa "bocor" melebihi
  /// angka ini, apapun yang terjadi di dalam list-nya.
  ///
  /// UPDATED (v7): nebak angka fixed (108px dst) ternyata gak pernah pas
  /// di semua kondisi (font rendering beda-beda per device/browser).
  /// Sekarang card dibungkus IntrinsicWidth di _openMonthPicker — lebar
  /// beneran ngikutin teks bulan terpanjang secara otomatis. Konstanta
  /// ini sekarang cuma jadi CAP maksimum (jaring pengaman) buat dx
  /// overflow-check & ConstrainedBox, bukan target lebar lagi.
  static const double _monthPickerWidth = 160;

  /// Tinggi maksimum area scroll daftar bulan (12 bulan, 1 kolom) di
  /// dalam _MonthYearPickerCard, supaya card gak jadi kepanjangan ke
  /// bawah layar — dibuat scrollable begitu melebihi tinggi ini.
  static const double _monthPickerListMaxHeight = 220;

  /// BARU (v5): dropdown "Minggu Ini" sekarang juga bisa dibuka buat
  /// milih minggu spesifik (Minggu 1, Minggu 2, ... sampai minggu
  /// terakhir di bulan yang lagi jadi acuan _selectedMonth) — pola
  /// Overlay-nya identik dengan dropdown bulan di atas, cuma kontennya
  /// beda (_WeekPickerCard, bukan _MonthYearPickerCard).
  final LayerLink _weekPickerLink = LayerLink();
  final GlobalKey _weekChipKey = GlobalKey();
  OverlayEntry? _weekPickerBarrier;
  OverlayEntry? _weekPickerCard;

  // Sedikit lebih lebar dari month picker karena tiap baris minggu
  // nampilin juga rentang tanggalnya (mis. "1 - 7 Agu"), bukan cuma nama.
  //
  // UPDATED (v7): sama kayak month picker — sekarang dibungkus
  // IntrinsicWidth di _openWeekPicker, lebar ngikutin teks "Minggu X" +
  // rentang tanggal terpanjang secara otomatis. Konstanta ini cuma CAP
  // maksimum (jaring pengaman), bukan target lebar.
  static const double _weekPickerWidth = 190;
  static const double _weekPickerListMaxHeight = 220;

  // Minggu spesifik yang dipilih lewat dropdown (null = belum pilih
  // spesifik, fallback ke "minggu berjalan" seperti behavior lama).
  // Direset kalau bulan acuan (_selectedMonth) diganti, supaya gak ada
  // minggu "nyasar" dari bulan lain yang kepilih diam-diam.
  _WeekOption? _selectedWeek;

  // Real data dari Firebase (bukan dummy lagi)
  double _totalRevenue = 0;
  int _totalOrders = 0;
  int _newCustomers = 0;
  double _avgOrderValue = 0;
  double _growthRate = 0;
  double _completionRate = 0;

  List<double> _weeklyValues = List.filled(7, 0.0);
  List<_ServiceBreakdown> _serviceBreakdown = [];

  bool _isLoading = true;
  _ReportsErrorType _errorType = _ReportsErrorType.none;
  String? _errorDetail;

  /// Label periode, dibangun dari AppLocalizations supaya ikut locale
  /// aktif (index sama dengan _selectedPeriod: 0 Hari Ini, 1 Minggu Ini,
  /// 2 Per Bulan, 3 Tahun Ini).
  List<String> _periodLabels(AppLocalizations t) => [
        t.periodToday,
        t.periodThisWeek,
        t.periodThisMonth,
        t.periodThisYear,
      ];

  /// Label hari Senin-Minggu, dibangun dari AppLocalizations (dayMon..daySun)
  /// supaya konsisten dengan singkatan hari yang dipakai di layar lain.
  List<String> _weekdayLabels(AppLocalizations t) => [
        t.dayMon,
        t.dayTue,
        t.dayWed,
        t.dayThu,
        t.dayFri,
        t.daySat,
        t.daySun,
      ];

  /// Label "Agustus 2026" dst untuk _selectedMonth, ikut bahasa aktif app
  /// (id/en) lewat locale dari context.
  String _monthYearLabel(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat.yMMMM(locale).format(_selectedMonth);
  }

  /// BARU (v5): pecah satu bulan (`month`) jadi daftar minggu 7-harian
  /// berurutan — Minggu 1 = tanggal 1-7, Minggu 2 = 8-14, dst. Minggu
  /// terakhir otomatis lebih pendek dari 7 hari kalau bulannya gak habis
  /// dibagi rata (mis. bulan 30 hari -> minggu ke-5 cuma tanggal 29-30).
  /// Dipakai buat isi dropdown "Minggu Ini" (_WeekPickerCard).
  List<_WeekOption> _weeksOfMonth(DateTime month) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final weeks = <_WeekOption>[];
    int startDay = 1;
    int index = 1;
    while (startDay <= daysInMonth) {
      final endDay = (startDay + 6) > daysInMonth ? daysInMonth : startDay + 6;
      weeks.add(_WeekOption(
        index: index,
        start: DateTime(month.year, month.month, startDay),
        end: DateTime(month.year, month.month, endDay),
      ));
      startDay = endDay + 1;
      index++;
    }
    return weeks;
  }

  // Dipakai supaya fetch pertama cuma jalan sekali. Dipanggil dari
  // didChangeDependencies (bukan initState) karena kedua fetch di bawah
  // butuh AppLocalizations.of(context) SEBELUM await pertama — dan
  // memanggil dependOnInheritedWidgetOfExactType (dipakai AppLocalizations.of)
  // selama initState() masih berjalan itu dilarang Flutter ("was called
  // before _ReportsScreenState.initState() completed"). didChangeDependencies
  // dijamin berjalan setelah widget ter-mount penuh, jadi aman.
  bool _didInitialFetch = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
  }

  @override
  void dispose() {
    _closeMonthPicker();
    _closeWeekPicker();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitialFetch) {
      _didInitialFetch = true;
      _fetchLaundries();
      _fetchReportsData();
    }
  }

  /// Buka dropdown pemilih bulan, nempel persis di bawah chip "Per Bulan"
  /// lewat _monthPickerLink. Dipasang manual via Overlay (dua OverlayEntry:
  /// barrier transparan buat nutup pas tap di luar, dan kartu pickernya
  /// sendiri) — bukan showMenu, supaya tombol bulan di dalamnya pasti bisa
  /// di-tap (lihat catatan di field _monthPickerLink).
  ///
  /// UPDATED (v3): sebelum insert overlay, cek dulu posisi global chip
  /// (_monthChipKey) vs lebar layar. Kalau card selebar _monthPickerWidth
  /// bakal nabrak/kepotong tepi kanan layar kalau nempel rata kiri chip,
  /// geser ke kiri (dx negatif) secukupnya biar mepet tepi layar
  /// (minus edgePadding) — posisi vertikal (dy) tetap gak berubah.
  ///
  /// UPDATED (v5): dibungkus ClipRRect di luar Container-nya — jaring
  /// pengaman tambahan supaya lebar tampilan gak PERNAH bisa melebihi
  /// _monthPickerWidth, apapun penyebabnya di dalam list.
  void _openMonthPicker(BuildContext context) {
    if (_monthPickerCard != null) {
      _closeMonthPicker();
      return;
    }
    _closeWeekPicker();

    final overlay = Overlay.of(context);

    const edgePadding = 12.0;
    double dx = 0;
    final chipBox = _monthChipKey.currentContext?.findRenderObject() as RenderBox?;
    if (chipBox != null) {
      final chipGlobalX = chipBox.localToGlobal(Offset.zero).dx;
      final screenWidth = MediaQuery.of(context).size.width;
      final overflow = (chipGlobalX + _monthPickerWidth + edgePadding) - screenWidth;
      if (overflow > 0) {
        dx = -overflow;
      }
    }

    _monthPickerBarrier = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _closeMonthPicker,
        ),
      ),
    );

    _monthPickerCard = OverlayEntry(
      builder: (_) => CompositedTransformFollower(
        link: _monthPickerLink,
        showWhenUnlinked: false,
        offset: Offset(dx, 50),
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: _DS.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _DS.cardShadow,
              ),
              // IntrinsicWidth = card cuma selebar konten terlebarnya
              // (nama bulan terpanjang), BUKAN angka px yang ditebak
              // manual. ConstrainedBox di bawah cuma jaring pengaman
              // (minWidth biar gak kekecilan, maxWidth biar gak kebablasan
              // kalau ada locale dengan nama bulan super panjang).
              child: IntrinsicWidth(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 90, maxWidth: _monthPickerWidth),
                  child: _MonthYearPickerCard(
                    listMaxHeight: _monthPickerListMaxHeight,
                    initialMonth: _selectedMonth,
                    onSelected: (month) {
                      setState(() {
                        _selectedPeriod = 2;
                        _selectedMonth = month;
                        // Bulan acuan berubah -> minggu spesifik yang lagi
                        // kepilih (kalau ada) jadi gak relevan lagi.
                        _selectedWeek = null;
                      });
                      _fetchReportsData();
                      _closeMonthPicker();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_monthPickerBarrier!);
    overlay.insert(_monthPickerCard!);
  }

  void _closeMonthPicker() {
    _monthPickerBarrier?.remove();
    _monthPickerCard?.remove();
    _monthPickerBarrier = null;
    _monthPickerCard = null;
  }

  /// BARU (v5): buka dropdown pemilih MINGGU, pola & alasan desainnya
  /// identik dengan _openMonthPicker di atas (Overlay manual, hitung dx
  /// biar gak kepotong, dibungkus ClipRRect buat jaring pengaman lebar).
  /// Daftar minggunya dihitung dari _selectedMonth (_weeksOfMonth), jadi
  /// otomatis ikut bulan yang lagi jadi acuan "Per Bulan".
  void _openWeekPicker(BuildContext context) {
    if (_weekPickerCard != null) {
      _closeWeekPicker();
      return;
    }
    _closeMonthPicker();

    final overlay = Overlay.of(context);
    final weeks = _weeksOfMonth(_selectedMonth);

    const edgePadding = 12.0;
    double dx = 0;
    final chipBox = _weekChipKey.currentContext?.findRenderObject() as RenderBox?;
    if (chipBox != null) {
      final chipGlobalX = chipBox.localToGlobal(Offset.zero).dx;
      final screenWidth = MediaQuery.of(context).size.width;
      final overflow = (chipGlobalX + _weekPickerWidth + edgePadding) - screenWidth;
      if (overflow > 0) {
        dx = -overflow;
      }
    }

    _weekPickerBarrier = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _closeWeekPicker,
        ),
      ),
    );

    _weekPickerCard = OverlayEntry(
      builder: (_) => CompositedTransformFollower(
        link: _weekPickerLink,
        showWhenUnlinked: false,
        offset: Offset(dx, 50),
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: _DS.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _DS.cardShadow,
              ),
              // Sama kayak month picker: lebar ngikutin konten
              // (label "Minggu X" + rentang tanggal terpanjang), bukan
              // angka fixed yang ditebak.
              child: IntrinsicWidth(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 110, maxWidth: _weekPickerWidth),
                  child: _WeekPickerCard(
                    listMaxHeight: _weekPickerListMaxHeight,
                    monthAnchor: _selectedMonth,
                    weeks: weeks,
                    selectedWeek: _selectedWeek,
                    onSelected: (week) {
                      setState(() {
                        _selectedPeriod = 1;
                        _selectedWeek = week;
                      });
                      _fetchReportsData();
                      _closeWeekPicker();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_weekPickerBarrier!);
    overlay.insert(_weekPickerCard!);
  }

  void _closeWeekPicker() {
    _weekPickerBarrier?.remove();
    _weekPickerCard?.remove();
    _weekPickerBarrier = null;
    _weekPickerCard = null;
  }

  /// Ambil semua cabang aktif milik company ini, buat isi chip filter
  /// (cuma ditampilkan kalau > 1, lihat _showLaundryFilter). Gagal fetch
  /// bukan error fatal - laporan tetap jalan dengan data gabungan semua
  /// cabang, cuma filter chip-nya gak muncul.
  Future<void> _fetchLaundries() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final t = AppLocalizations.of(context)!;
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
        _laundriesList =
            laundriesSnap.docs.map((d) => _LaundryOption.fromFirestore(d, t)).toList();
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
      _errorType = _ReportsErrorType.none;
      _errorDetail = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorType = _ReportsErrorType.session;
          _isLoading = false;
        });
        return;
      }

      final t = AppLocalizations.of(context)!;

      final now = DateTime.now();
      late DateTime startDate;
      late DateTime endDate;

      // Tentukan range tanggal berdasarkan period
      if (_selectedPeriod == 0) {
        // Hari Ini
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
      } else if (_selectedPeriod == 1) {
        // Minggu Ini — kalau user udah pilih minggu spesifik lewat
        // dropdown (_selectedWeek), pakai rentang itu. `end` di _WeekOption
        // inclusive, jadi endDate query (exclusive) = end + 1 hari.
        // Kalau belum pilih spesifik, fallback ke perilaku lama: minggu
        // berjalan (Senin-Minggu dari hari ini).
        if (_selectedWeek != null) {
          final w = _selectedWeek!;
          startDate = DateTime(w.start.year, w.start.month, w.start.day);
          endDate = DateTime(w.end.year, w.end.month, w.end.day).add(const Duration(days: 1));
        } else {
          startDate = now.subtract(Duration(days: now.weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          endDate = startDate.add(const Duration(days: 7));
        }
      } else if (_selectedPeriod == 2) {
        // Per Bulan — pakai _selectedMonth (bisa digeser ke bulan lain,
        // bukan cuma dikunci ke bulan berjalan seperti sebelumnya).
        startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
        endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
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
          final fallbackName = t.otherServiceLabel;
          serviceRevenue[fallbackName] = (serviceRevenue[fallbackName] ?? 0) + amount;
          serviceOrderCount[fallbackName] = (serviceOrderCount[fallbackName] ?? 0) + 1;
        } else {
          for (final rawItem in items) {
            final item = Map<String, dynamic>.from(rawItem as Map);
            final serviceName = (item['service_name'] ?? t.otherServiceLabel) as String;
            final itemTotal = ((item['total_price'] ?? 0) as num).toDouble();
            serviceRevenue[serviceName] = (serviceRevenue[serviceName] ?? 0) + itemTotal;
            serviceOrderCount[serviceName] = (serviceOrderCount[serviceName] ?? 0) + 1;
          }
        }
      }

      // Build service breakdown list
      final serviceList = <_ServiceBreakdown>[];
      final colors = [
        _DS.primary,
        _DS.success,
        _DS.warning,
        _DS.purple,
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
        _errorType = _ReportsErrorType.generic;
        _errorDetail = e.toString();
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
  /// t.allBranchesLabel kalau _selectedLaundryId == 'all'.
  String _selectedLaundryLabel(AppLocalizations t) {
    if (_selectedLaundryId == 'all') return t.allBranchesLabel;
    final match = _laundriesList.where((l) => l.id == _selectedLaundryId);
    return match.isNotEmpty ? match.first.name : t.allBranchesLabel;
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
  ///
  /// PENTING soal locale: `t` DIAMBIL DI SINI (dari Flutter BuildContext
  /// yang dioper sebagai parameter `context`) SEBELUM masuk ke
  /// header/build/footer callback milik package:pdf. Di dalam callback
  /// tersebut parameter bernama `context` adalah pw.Context (beda tipe,
  /// cuma dipakai untuk context.pageNumber/pagesCount) — jadi jangan
  /// panggil AppLocalizations.of(context) di dalamnya, cukup pakai
  /// variabel `t` yang sudah ditangkap closure ini.
  Future<void> _exportToPdf(BuildContext context) async {
    setState(() => _isExporting = true);

    final t = AppLocalizations.of(context)!;

    try {
      final doc = pw.Document();
      // Kalau period-nya "Per Bulan", pakai label bulan yang lagi dipilih
      // (mis. "Agustus 2026") supaya PDF-nya jelas laporan bulan yang mana
      // — bukan cuma teks generik "Bulan Ini" yang ambigu.
      // Kalau period-nya "Minggu Ini" DAN user udah pilih minggu spesifik
      // lewat dropdown, pakai label "Minggu X (tgl - tgl)" biar jelas
      // minggu mana yang dilaporin — bukan cuma teks generik "Minggu Ini".
      final String periodLabel;
      if (_selectedPeriod == 2) {
        periodLabel = _monthYearLabel(context);
      } else if (_selectedPeriod == 1 && _selectedWeek != null) {
        final locale = Localizations.localeOf(context).languageCode;
        final dayFmt = DateFormat('d MMM', locale);
        periodLabel =
            'Minggu ${_selectedWeek!.index} (${dayFmt.format(_selectedWeek!.start)} - ${dayFmt.format(_selectedWeek!.end)})';
      } else {
        periodLabel = _periodLabels(t)[_selectedPeriod];
      }
      final laundryLabel = _selectedLaundryLabel(t);
      final weekdayLabels = _weekdayLabels(t);
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
          header: (pdfContext) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                t.pdfReportTitle,
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _pdfPrimaryDark),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                t.pdfHeaderInfo(periodLabel, laundryLabel, generatedAt),
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 12),
              pw.Divider(color: _pdfPrimary, thickness: 1.2),
            ],
          ),
          build: (pdfContext) => [
            // Ringkasan KPI utama
            pw.Text(t.pdfSummaryTitle, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _pdfPrimaryDark)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: _pdfBorderLight),
              children: [
                _pdfTableRow([t.totalRevenueLabel, _formatCurrency(_totalRevenue)]),
                _pdfTableRow([t.totalOrdersLabel, '$_totalOrders']),
                _pdfTableRow([t.newCustomersLabel, '$_newCustomers']),
                _pdfTableRow([t.avgOrderLabel, _formatCurrency(_avgOrderValue)]),
                _pdfTableRow([t.growthLabel, t.growthValueTemplate(_growthRate.toStringAsFixed(1))]),
                _pdfTableRow([t.completionRateLabel, '${_completionRate.toStringAsFixed(1)}%']),
              ],
            ),
            pw.SizedBox(height: 20),

            // Tren mingguan
            pw.Text(t.pdfWeeklyTrendTitle, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _pdfPrimaryDark)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: _pdfBorderLight),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _pdfPrimaryTint),
                  children: weekdayLabels
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
            pw.Text(t.revenuePerServiceTitle, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _pdfPrimaryDark)),
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
                    _pdfCell(t.pdfServiceColumn, bold: true),
                    _pdfCell(t.pdfOrdersColumn, bold: true),
                    _pdfCell(t.pdfRevenueColumn, bold: true),
                    _pdfCell(t.pdfPercentageColumn, bold: true),
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
          footer: (pdfContext) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              t.pdfPageOfPages(pdfContext.pageNumber, pdfContext.pagesCount),
              style: const pw.TextStyle(fontSize: 9, color: _pdfPrimaryDark),
            ),
          ),
        ),
      );

      final Uint8List bytes = await doc.save();
      final safePeriodLabel = periodLabel.toLowerCase().replaceAll(' ', '_');
      final fileName = 'laporan_${safePeriodLabel}_${now.millisecondsSinceEpoch}.pdf';

      // Menampilkan preview + opsi share/print/save menggunakan package printing
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.exportPdfError(e.toString()))),
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
    final t = AppLocalizations.of(context)!;
    final String? errorMessage = _errorType == _ReportsErrorType.session
        ? t.sessionNotFoundError
        : (_errorType == _ReportsErrorType.generic ? t.errorWithMessage(_errorDetail ?? '') : null);

    return Scaffold(
      backgroundColor: _DS.canvas,
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
                            child: Center(child: CircularProgressIndicator(color: _DS.primary)),
                          )
                        else if (errorMessage != null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: AppTheme.xxl),
                              child: Column(
                                children: [
                                  Text(
                                    errorMessage,
                                    textAlign: TextAlign.center,
                                    style: _DS.bodyMd(color: _DS.danger),
                                  ),
                                  const SizedBox(height: AppTheme.lg),
                                  TextButton(
                                    onPressed: _fetchReportsData,
                                    child: Text(t.orderRetryButtonLabel, style: _DS.bodyMd(color: _DS.primary, weight: FontWeight.w600)),
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

  /// Tombol back di paling atas — disamain persis sama tombol back di
  /// services_list_screen.dart (lingkaran putih, shadow tipis, ikon navy).
  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _DS.surface,
              shape: BoxShape.circle,
              boxShadow: _DS.cardShadow,
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 20, color: _DS.navy),
          ),
        ),
      ],
    );
  }

  /// Build header — Row luar dibungkus Expanded di sisi judul, tombol
  /// Export di kanan. Ikon avatar & tipografi disamain ke pola header di
  /// services_list_screen.dart (kotak rounded biru muda D1E4FF, ikon navy).
  Widget _buildHeader(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1E4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: _DS.navy, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.reportsTitle,
                      style: _DS.headlineMd(color: _DS.navy),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.reportsSubtitle,
                      style: _DS.bodySm(),
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
        _buildExportButton(context, t, isMobile),
      ],
    );
  }

  /// Tombol export PDF, gaya pill outline navy — senada sama chip filter.
  Widget _buildExportButton(BuildContext context, AppLocalizations t, bool isMobile) {
    return InkWell(
      onTap: _isExporting ? null : () => _exportToPdf(context),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 44,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _DS.navy),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isExporting)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: _DS.navy),
              )
            else
              const Icon(Icons.print_outlined, size: 18, color: _DS.navy),
            const SizedBox(width: 8),
            Text(
              isMobile
                  ? (_isExporting ? '...' : t.printButtonShort)
                  : (_isExporting ? t.generatingPdfButton : t.printReportButton),
              style: _DS.labelBold(color: _DS.navy),
            ),
          ],
        ),
      ),
    );
  }

  /// Build period filter chips — pill navy, disamain ke _filterChip di
  /// services_list_screen.dart. Chip index 1 ("Minggu Ini") dan index 2
  /// ("Per Bulan") beda sendiri: bukan langsung pilih, tapi buka dropdown
  /// pemilih minggu/bulan (lihat _buildWeekDropdownChip/_buildMonthDropdownChip).
  Widget _buildPeriodChips(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final periods = _periodLabels(t);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (int index = 0; index < periods.length; index++) ...[
            if (index > 0) const SizedBox(width: 10),
            if (index == 1)
              _buildWeekDropdownChip(context)
            else if (index == 2)
              _buildMonthDropdownChip(context)
            else
              _pillChip(
                label: periods[index],
                isSelected: _selectedPeriod == index,
                onTap: () {
                  setState(() => _selectedPeriod = index);
                  _fetchReportsData();
                },
              ),
          ],
        ],
      ),
    );
  }

  /// BARU (v5): Chip "Minggu Ini" — sekarang juga dropdown (sama pola
  /// kayak chip bulan), isinya daftar minggu di bulan acuan _selectedMonth
  /// (Minggu 1, Minggu 2, ... sampai minggu terakhir). Labelnya berubah
  /// jadi "Minggu X" begitu user pilih minggu spesifik.
  Widget _buildWeekDropdownChip(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isSelected = _selectedPeriod == 1;
    final label = (isSelected && _selectedWeek != null) ? 'Minggu ${_selectedWeek!.index}' : t.periodThisWeek;

    return CompositedTransformTarget(
      link: _weekPickerLink,
      child: InkWell(
        key: _weekChipKey,
        onTap: () => _openWeekPicker(context),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? _DS.navy : _DS.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: isSelected ? _DS.navy : _DS.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: _DS.bodySm(
                  color: isSelected ? Colors.white : _DS.onSurfaceVariant,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 17,
                color: isSelected ? Colors.white : _DS.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Chip "Per Bulan" — begitu di-tap langsung buka dropdown (bukan
  /// toggle select biasa). Labelnya berubah jadi nama bulan yang lagi
  /// aktif (mis. "Agustus 2026") begitu period ini yang dipilih, plus
  /// panah kecil sebagai penanda visual kalau ini bisa dibuka.
  ///
  /// _monthChipKey dipasang di InkWell ini supaya _openMonthPicker bisa
  /// baca posisi global chip buat hitung apakah dropdown-nya bakal
  /// kepotong di tepi layar (lihat catatan v3 di atas class).
  Widget _buildMonthDropdownChip(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isSelected = _selectedPeriod == 2;
    final label = isSelected ? _monthYearLabel(context) : t.periodThisMonth;

    return CompositedTransformTarget(
      link: _monthPickerLink,
      child: InkWell(
        key: _monthChipKey,
        onTap: () => _openMonthPicker(context),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? _DS.navy : _DS.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: isSelected ? _DS.navy : _DS.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: _DS.bodySm(
                  color: isSelected ? Colors.white : _DS.onSurfaceVariant,
                  weight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 17,
                color: isSelected ? Colors.white : _DS.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build filter chip CABANG - baris terpisah di bawah filter periode,
  /// cuma dirender kalau _showLaundryFilter true (cabang > 1). Chip
  /// pertama selalu "Semua Cabang", sisanya sesuai nama cabang aktif.
  /// Pola sama persis dengan OrdersListScreen/CustomersListScreen/ServicesListScreen.
  Widget _buildLaundryFilterChips(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _pillChip(
            label: t.allBranchesLabel,
            isSelected: _selectedLaundryId == 'all',
            onTap: () {
              setState(() => _selectedLaundryId = 'all');
              _fetchReportsData();
            },
          ),
          for (final laundry in _laundriesList) ...[
            const SizedBox(width: 10),
            _pillChip(
              label: laundry.name,
              isSelected: _selectedLaundryId == laundry.id,
              onTap: () {
                setState(() => _selectedLaundryId = laundry.id);
                _fetchReportsData();
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Chip pill generik — dipakai buat filter periode & filter cabang.
  /// Disamain persis sama _filterChip di services_list_screen.dart (pill
  /// penuh, navy solid saat terpilih, putih+outline saat tidak).
  Widget _pillChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? _DS.navy : _DS.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isSelected ? _DS.navy : _DS.outlineVariant),
        ),
        child: Text(
          label,
          style: _DS.bodySm(
            color: isSelected ? Colors.white : _DS.onSurfaceVariant,
            weight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Build main KPI cards
  Widget _buildMainKPICards(BuildContext context, bool isMobile) {
    final t = AppLocalizations.of(context)!;
    final stats = [
      (icon: Icons.payments_outlined, label: t.totalRevenueLabel, value: _formatCurrencyShort(_totalRevenue), color: _DS.primary),
      (icon: Icons.shopping_bag_outlined, label: t.totalOrdersLabel, value: '$_totalOrders', color: _DS.success),
      (icon: Icons.person_add_alt_1_outlined, label: t.newCustomersLabel, value: '$_newCustomers', color: _DS.warning),
      (icon: Icons.trending_up_rounded, label: t.avgOrderLabel, value: _formatCurrencyShort(_avgOrderValue), color: _DS.purple),
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

  /// Build growth indicator — satu baris ringkas
  Widget _buildGrowthIndicator(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isPositive = _growthRate >= 0;
    final growthColor = isPositive ? _DS.success : _DS.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.lg, vertical: AppTheme.md),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _DS.cardShadow,
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
                  t.growthThisPeriodLabel,
                  style: _DS.bodyMd(weight: FontWeight.w600).copyWith(fontSize: 12.5),
                ),
                const SizedBox(height: 2),
                Text(
                  '${isPositive ? t.growthUpLabel : t.growthDownLabel} ${_growthRate.abs().toStringAsFixed(1)}% ${t.fromPreviousPeriodLabel}',
                  style: _DS.bodySm(),
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
              style: _DS.bodySm(color: growthColor, weight: FontWeight.w700).copyWith(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Build revenue chart
  Widget _buildRevenueChart(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final weekdayLabels = _weekdayLabels(t);
    return Container(
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _DS.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.revenueTrendTitle, style: _DS.titleSm()),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _DS.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  t.last7DaysLabel,
                  style: _DS.bodySm(color: _DS.primary, weight: FontWeight.w600).copyWith(fontSize: 10.5),
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
                            color: isPeak ? _DS.primary : _DS.primary.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          weekdayLabels[i],
                          style: _DS.bodySm().copyWith(fontSize: 10.5),
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
    final t = AppLocalizations.of(context)!;

    if (_serviceBreakdown.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.lg),
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _DS.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.revenuePerServiceTitle, style: _DS.titleSm()),
            const SizedBox(height: AppTheme.lg),
            Text(t.noOrdersThisPeriod, style: _DS.bodySm()),
          ],
        ),
      );
    }

    final maxRevenue = _serviceBreakdown.map((s) => s.revenue).reduce((a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _DS.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.revenuePerServiceTitle, style: _DS.titleSm()),
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
                                style: _DS.bodyMd(weight: FontWeight.w600).copyWith(fontSize: 12.5),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                t.ordersCountLabel(service.orderCount),
                                style: _DS.bodySm().copyWith(fontSize: 10.5),
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
                            style: _DS.bodyMd(weight: FontWeight.w700).copyWith(fontSize: 12.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$percentage%',
                            style: _DS.bodySm(color: service.color, weight: FontWeight.w600).copyWith(fontSize: 10.5),
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
                      backgroundColor: _DS.canvas,
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
    final t = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.check_circle_outline,
            label: t.completionRateLabel,
            value: '${_completionRate.toStringAsFixed(1)}%',
            caption: t.ofAllOrdersLabel,
            color: _DS.success,
          ),
        ),
      ],
    );
  }
}

// ============================================
// HELPER WIDGETS
// ============================================

/// Kartu KPI utama
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
        color: _DS.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _DS.cardShadow,
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
            style: _DS.bodyMd(weight: FontWeight.w700).copyWith(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: _DS.bodySm().copyWith(fontSize: 10.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Isi dropdown pemilih bulan (dipasang manual lewat Overlay di
/// _openMonthPicker). Nav tahun di atas (‹ 2026 ›, gak bisa maju ke tahun
/// depan), daftar 12 bulan di bawah — bulan yang belum terjadi otomatis
/// abu-abu & gak bisa di-tap. Tap bulan valid -> panggil widget.onSelected.
///
/// UPDATED (v4): dulu bulan ditampilkan sebagai grid 3 kolom (Jan Feb Mar
/// sejajar ke samping), yang gampang kepotong di layar sempit karena
/// butuh ruang horizontal lebar. Sekarang jadi LIST VERTIKAL 1 kolom —
/// Jan, Feb, Mar, ... tersusun ke bawah — supaya card bisa jauh lebih
/// ramping (cuma selebar widget.width, ~152px) dan gak pernah kepotong
/// di layar HP manapun. Daftarnya dibungkus SizedBox+ListView supaya
/// bisa di-scroll kalau tingginya (12 bulan) melebihi listMaxHeight.
///
/// UPDATED (v6): padding luar & dalam item dikecilin (nyesuain lebar
/// card yang sekarang cuma 108px), font item diperkecil dikit juga
/// (12.5 -> 11.5) biar nama bulan terpanjang tetep muat 1 baris tanpa
/// kepotong dan gak berasa sempit/numpuk.
class _MonthYearPickerCard extends StatefulWidget {
  final double listMaxHeight;
  final DateTime initialMonth;
  final ValueChanged<DateTime> onSelected;

  const _MonthYearPickerCard({
    required this.listMaxHeight,
    required this.initialMonth,
    required this.onSelected,
  });

  @override
  State<_MonthYearPickerCard> createState() => _MonthYearPickerCardState();
}

class _MonthYearPickerCardState extends State<_MonthYearPickerCard> {
  late int _displayYear;

  @override
  void initState() {
    super.initState();
    _displayYear = widget.initialMonth.year;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).languageCode;
    final canGoNextYear = _displayYear < now.year;

    // UPDATED (v7): dulu ListView.separated di dalam SizedBox(width:
    // widget.width) — lebarnya HARUS ditebak manual karena ListView
    // (dibangun di atas Viewport) gak support intrinsic width, jadi kalau
    // dibungkus IntrinsicWidth dari parent bakal error/di-skip dan lebar
    // parent gak ke-influence oleh isinya.
    // Sekarang list-nya SingleChildScrollView + Column biasa — widget ini
    // BISA dihitung intrinsic width-nya (max dari lebar semua nama bulan),
    // jadi IntrinsicWidth di _openMonthPicker bisa "nanya" ke sini seberapa
    // lebar konten aslinya, dan card otomatis ngepas — gak perlu tebak px
    // lagi. crossAxisAlignment.stretch bikin tiap baris bulan tetep
    // selebar bulan terlebar (bukan cuma selebar teksnya sendiri-sendiri).
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => setState(() => _displayYear--),
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(Icons.chevron_left_rounded, size: 16, color: _DS.navy),
                ),
              ),
              Expanded(
                child: Text(
                  '$_displayYear',
                  textAlign: TextAlign.center,
                  style: _DS.titleSm().copyWith(fontSize: 12),
                ),
              ),
              InkWell(
                onTap: canGoNextYear ? () => setState(() => _displayYear++) : null,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: canGoNextYear ? _DS.navy : _DS.outlineVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(height: 1, thickness: 1, color: _DS.outlineVariant.withOpacity(0.4)),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.listMaxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(12, (i) {
                  final month = i + 1;
                  final monthDate = DateTime(_displayYear, month);
                  final isFuture = monthDate.isAfter(DateTime(now.year, now.month));
                  final isSelected =
                      widget.initialMonth.year == _displayYear && widget.initialMonth.month == month;
                  final label = DateFormat.MMMM(locale).format(monthDate);

                  return Padding(
                    padding: EdgeInsets.only(bottom: i == 11 ? 0 : 3),
                    child: InkWell(
                      onTap: isFuture ? null : () => widget.onSelected(DateTime(_displayYear, month, 1)),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: isSelected ? _DS.navy : (isFuture ? _DS.canvas : _DS.surface),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? _DS.navy : _DS.outlineVariant),
                        ),
                        child: Text(
                          label,
                          style: _DS.bodySm(
                            color: isSelected ? Colors.white : (isFuture ? _DS.outlineVariant : _DS.onSurfaceVariant),
                            weight: FontWeight.w600,
                          ).copyWith(fontSize: 11.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// BARU (v5): isi dropdown pemilih MINGGU (dipasang manual lewat Overlay
/// di _openWeekPicker, pola identik dengan _MonthYearPickerCard). Beda
/// dari picker bulan: gak ada nav tahun (cuma nampilin nama bulan acuan
/// sebagai header non-interaktif), dan tiap baris nampilin nomor minggu
/// PLUS rentang tanggalnya (mis. "1 - 7 Agu") biar jelas minggu itu
/// mencakup tanggal berapa aja. StatelessWidget karena gak ada state
/// internal (semua kontrol lewat parent, beda dengan month picker yang
/// punya state _displayYear buat navigasi tahun).
///
/// UPDATED (v6): padding & font item dikecilin (nyesuain lebar card yang
/// sekarang cuma 140px) supaya baris "Minggu X" + rentang tanggal tetep
/// muat rapi 1 baris tanpa kepotong.
class _WeekPickerCard extends StatelessWidget {
  final double listMaxHeight;
  final DateTime monthAnchor;
  final List<_WeekOption> weeks;
  final _WeekOption? selectedWeek;
  final ValueChanged<_WeekOption> onSelected;

  const _WeekPickerCard({
    required this.listMaxHeight,
    required this.monthAnchor,
    required this.weeks,
    required this.selectedWeek,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final locale = Localizations.localeOf(context).languageCode;
    final monthLabel = DateFormat.yMMMM(locale).format(monthAnchor);
    final dayFmt = DateFormat('d MMM', locale);

    // UPDATED (v7): sama alasan kayak _MonthYearPickerCard — Column biasa
    // (bukan ListView) supaya IntrinsicWidth di parent bisa ngukur lebar
    // konten asli (label "Minggu X" + rentang tanggal terpanjang) dan
    // card otomatis ngepas, gak perlu nebak angka px.
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            monthLabel,
            textAlign: TextAlign.center,
            style: _DS.titleSm().copyWith(fontSize: 11.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Divider(height: 1, thickness: 1, color: _DS.outlineVariant.withOpacity(0.4)),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: listMaxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(weeks.length, (i) {
                  final week = weeks[i];
                  final isFuture = week.start.isAfter(today);
                  final isSelected = selectedWeek != null &&
                      selectedWeek!.index == week.index &&
                      selectedWeek!.start.year == week.start.year &&
                      selectedWeek!.start.month == week.start.month;

                  return Padding(
                    padding: EdgeInsets.only(bottom: i == weeks.length - 1 ? 0 : 3),
                    child: InkWell(
                      onTap: isFuture ? null : () => onSelected(week),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? _DS.navy : (isFuture ? _DS.canvas : _DS.surface),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? _DS.navy : _DS.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Minggu ${week.index}',
                              style: _DS.bodySm(
                                color: isSelected ? Colors.white : (isFuture ? _DS.outlineVariant : _DS.onSurface),
                                weight: FontWeight.w700,
                              ).copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${dayFmt.format(week.start)} - ${dayFmt.format(week.end)}',
                              style: _DS.bodySm(
                                color: isSelected ? Colors.white70 : _DS.outlineVariant,
                              ).copyWith(fontSize: 9.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


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
        color: _DS.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _DS.cardShadow,
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
                  style: _DS.bodyMd(weight: FontWeight.w600).copyWith(fontSize: 11.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.md),
          Text(
            value,
            style: _DS.bodyMd(color: color, weight: FontWeight.w700).copyWith(fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: _DS.bodySm().copyWith(fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}
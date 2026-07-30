import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/themes/app_theme.dart';
import '../../models/employee.dart';
import '../../models/laundry.dart';
import '../../models/order.dart';
import '../../repositories/employee_repository.dart';
import '../../repositories/laundry_repository.dart';
import '../../repositories/order_repository.dart';
// TODO: sesuaikan path ini kalau lokasi/nama file CreateCustomerScreen di
// project kamu berbeda dari asumsi berikut.
import '../customers/create_customer_screen.dart';

/// Local design tokens matching the new "NetWash Utility System" design.
/// Disamakan dengan ServicesListScreen supaya seluruh alur Antar Jemput
/// (daftar + jadwalkan) senada dengan Kelola Layanan: kanvas abu kebiruan,
/// kartu putih dengan shadow lembut, dan font Be Vietnam Pro.
class _DS {
  static const canvas = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const onSurface = Color(0xFF1B1C1C);
  static const onSurfaceVariant = Color(0xFF404752);
  static const outlineVariant = Color(0xFFBFC7D4);

  static const navy = Color(0xFF0B3B66);
  static const primary = Color(0xFF0061A4);
  static const error = Color(0xFFDC2626);

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
}

/// "Jadwalkan Antar Jemput" - layar untuk membuat RENCANA jadwal jemput
/// atau antar untuk order yang sudah ada, lengkap dengan cabang, alamat,
/// tanggal, jam & kurir. Ini BEDA dari PickupDeliveryScreen yang menandai
/// order SUDAH BENERAN dijemput/diantar - layar ini cuma menyimpan rencana
/// (lihat OrderRepository.scheduleLogistics()), jadi tidak mengubah
/// pickup_date/delivery_date/status sama sekali.
///
/// UPDATED: nambah `preselectedOrderId` - dipakai saat layar ini dibuka
/// LANGSUNG dari OrderDetailScreen (tombol "Jadwalkan Pengantaran" saat
/// status ready & deliveryType delivery). Kalau field ini diisi:
/// - mode dikunci ke 'pengantaran' (mode toggle disembunyikan)
/// - order picker disembunyikan, diganti kartu info singkat (order sudah
///   pasti, gak perlu dicari/dipilih lagi dari daftar)
/// - cabang otomatis ke-lock sesuai laundryId order tsb, dropdown-nya
///   dikunci (disabled) supaya tidak ke-reset _selectedOrder secara tidak
///   sengaja
class CreateDeliveryScheduleScreen extends ConsumerStatefulWidget {
  /// Mode awal saat layar dibuka - 'penjemputan' atau 'pengantaran'.
  /// Diabaikan kalau [preselectedOrderId] diisi (mode dipaksa 'pengantaran').
  final String initialMode;

  /// Kalau diisi, layar ini dibuka LANGSUNG untuk 1 order tertentu (dari
  /// OrderDetailScreen). Mode dikunci ke 'pengantaran', picker order & mode
  /// toggle disembunyikan, dan cabang ikut ter-lock ke laundryId order tsb.
  final String? preselectedOrderId;

  const CreateDeliveryScheduleScreen({
    Key? key,
    this.initialMode = 'penjemputan',
    this.preselectedOrderId,
  }) : super(key: key);

  @override
  ConsumerState<CreateDeliveryScheduleScreen> createState() => _CreateDeliveryScheduleScreenState();
}

class _CreateDeliveryScheduleScreenState extends ConsumerState<CreateDeliveryScheduleScreen> {
  // Sama persis dengan warna kategori "Perlu Dijemput" di PickupDeliveryScreen
  // (ungu = penjemputan). Warna "pengantaran" sekarang ikut token _DS.primary
  // di atas, sama seperti aksen biru yang dipakai OrdersListScreen.
  static const _pickupAccent = Color(0xFFB197FC);

  Color get _modeAccent => _mode == 'penjemputan' ? _pickupAccent : _DS.primary;

  /// True kalau layar ini dibuka dengan order sudah ditentukan dari luar
  /// (OrderDetailScreen) - mode & order picker jadi read-only/disembunyikan.
  bool get _isLocked => widget.preselectedOrderId != null;

  late String _mode; // 'penjemputan' | 'pengantaran'
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  Order? _selectedOrder;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // True kalau tanggal/jam/alamat/kurir di form ini ke-isi otomatis dari
  // jadwal yang udah dibuat pas CreateOrderScreen (bukan diketik manual
  // sekarang) - dipakai buat nampilin hint kecil ke admin.
  bool _prefilledFromOrder = false;

  List<Employee> _couriers = [];
  bool _isLoadingCouriers = true;
  Employee? _selectedCourier;

  List<Laundry> _laundries = [];
  bool _isLoadingLaundries = true;
  Laundry? _selectedLaundry;

  bool _isLoadingOrders = false;
  bool _isLoadingPreselected = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.preselectedOrderId != null ? 'pengantaran' : widget.initialMode;
    _fetchCouriers();
    _fetchLaundries();
    if (widget.preselectedOrderId != null) {
      _fetchPreselectedOrder();
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchCouriers() async {
    setState(() => _isLoadingCouriers = true);
    try {
      final uid = ref.read(orderRepositoryProvider).userId;
      final repo = EmployeeRepository(userId: uid);
      final all = await repo.streamEmployees().first;
      setState(() {
        _couriers = all.where((e) => e.isActive && e.position.toLowerCase().contains('kurir')).toList();
        _isLoadingCouriers = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingCouriers = false);
    }
  }

  Future<void> _fetchLaundries() async {
    setState(() => _isLoadingLaundries = true);
    try {
      final repo = ref.read(laundryRepositoryProvider);
      final all = await repo.streamLaundries().first;
      setState(() {
        _laundries = all.where((l) => l.isActive).toList();
        _isLoadingLaundries = false;
      });
      // Kalau order sudah ke-fetch duluan (race antara dua Future async
      // ini), langsung coba lock cabang begitu daftar cabang siap.
      _lockBranchToOrder();
    } catch (_) {
      if (mounted) setState(() => _isLoadingLaundries = false);
    }
  }

  /// Ambil order yang sudah ditentukan dari OrderDetailScreen. Kalau order
  /// ini kebetulan sudah punya logisticsSchedule mode 'pengantaran' (mis.
  /// dari CreateOrderScreen), prefill tanggal/jam/alamatnya juga - sama
  /// pola prefill-nya dengan _pickOrder() di alur non-locked.
  Future<void> _fetchPreselectedOrder() async {
    setState(() => _isLoadingPreselected = true);
    try {
      final order = await ref.read(orderRepositoryProvider).getOrder(widget.preselectedOrderId!);
      if (!mounted) return;

      if (order == null) {
        _showSnack('Pesanan tidak ditemukan', isError: true);
        setState(() => _isLoadingPreselected = false);
        return;
      }

      setState(() {
        _selectedOrder = order;
        _prefilledFromOrder = false;
        _isLoadingPreselected = false;

        final schedule = order.logisticsSchedule;
        if (schedule != null && schedule.mode == 'pengantaran') {
          if (schedule.scheduledAt != null) {
            _selectedDate = schedule.scheduledAt;
            _selectedTime = TimeOfDay.fromDateTime(schedule.scheduledAt!);
            _prefilledFromOrder = true;
          }
          if ((schedule.address ?? '').isNotEmpty) {
            _addressController.text = schedule.address!;
          }
          if ((schedule.courierId ?? '').isNotEmpty) {
            final match = _couriers.where((c) => c.id == schedule.courierId);
            if (match.isNotEmpty) _selectedCourier = match.first;
          }
        }
      });

      _lockBranchToOrder();
    } catch (e) {
      if (mounted) {
        _showSnack('Gagal memuat pesanan: $e', isError: true);
        setState(() => _isLoadingPreselected = false);
      }
    }
  }

  /// Set cabang otomatis sesuai laundryId order - dipanggil dari 2 tempat
  /// (setelah order & setelah daftar cabang selesai fetch), karena
  /// keduanya async dan urutan selesainya gak pasti mana duluan.
  void _lockBranchToOrder() {
    if (!_isLocked || _selectedOrder == null || _laundries.isEmpty) return;
    final match = _laundries.where((l) => l.id == _selectedOrder!.laundryId);
    if (match.isNotEmpty && mounted) {
      setState(() => _selectedLaundry = match.first);
    }
  }

  /// Order yang relevan untuk mode & cabang saat ini - hanya yang belum
  /// selesai dijemput/diantar (pickup_date / delivery_date masih kosong),
  /// supaya tidak menjadwalkan ulang order yang sudah tuntas. Kalau ada
  /// cabang yang dipilih, order juga difilter supaya hanya menampilkan
  /// order dari cabang tersebut.
  bool _matchesMode(Order order) {
    final modeMatches = _mode == 'penjemputan'
        ? (order.needsPickup && order.pickupDate == null)
        : (order.needsDelivery && order.deliveryDate == null);
    if (!modeMatches) return false;
    if (_selectedLaundry != null && order.laundryId != _selectedLaundry!.id) return false;
    return true;
  }

  Future<void> _pickOrder() async {
    setState(() => _isLoadingOrders = true);
    List<Order> orders = [];
    String? error;
    try {
      final all = await ref.read(orderRepositoryProvider).getAllOrders().first;
      orders = all.where(_matchesMode).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoadingOrders = false);
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text('Pilih Pesanan', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, color: _DS.onSurface)),
        content: SizedBox(
          width: double.maxFinite,
          child: error != null
              ? Text(error, style: GoogleFonts.beVietnamPro(fontSize: 12.5, color: _DS.error))
              : orders.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        _mode == 'penjemputan'
                            ? 'Tidak ada pesanan yang menunggu dijemput.'
                            : 'Tidak ada pesanan yang siap diantar.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.beVietnamPro(fontSize: 12.5, color: _DS.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return ListTile(
                          title: Text(
                            (order.customerName?.isNotEmpty ?? false) ? order.customerName! : 'Pelanggan',
                            style: GoogleFonts.beVietnamPro(fontSize: 13.5, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(order.orderNumber, style: GoogleFonts.beVietnamPro(fontSize: 12, color: _DS.onSurfaceVariant)),
                          onTap: () {
                            setState(() {
                              _selectedOrder = order;
                              _prefilledFromOrder = false;

                              // Kalau order ini udah punya jadwal jemput
                              // (diisi pas CreateOrderScreen) dan mode-nya
                              // sama kayak yang lagi dibuka di sini, isi
                              // otomatis field yang relevan supaya admin
                              // tinggal melengkapi kurir + alamat.
                              final schedule = order.logisticsSchedule;
                              if (schedule != null && schedule.mode == _mode) {
                                if (schedule.scheduledAt != null) {
                                  _selectedDate = schedule.scheduledAt;
                                  _selectedTime = TimeOfDay.fromDateTime(schedule.scheduledAt!);
                                  _prefilledFromOrder = true;
                                }
                                if ((schedule.address ?? '').isNotEmpty) {
                                  _addressController.text = schedule.address!;
                                }
                                if ((schedule.courierId ?? '').isNotEmpty) {
                                  final match = _couriers.where((c) => c.id == schedule.courierId);
                                  if (match.isNotEmpty) _selectedCourier = match.first;
                                }
                              }
                            });
                            Navigator.pop(dialogContext);
                          },
                        );
                      },
                    ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('Tutup', style: GoogleFonts.beVietnamPro())),
        ],
      ),
    );
  }

  /// Buka layar tambah pelanggan baru yang sudah ada di app. Hanya relevan
  /// untuk mode penjemputan (di mode pengantaran pelanggan seharusnya sudah
  /// ada karena order-nya sudah dibuat sebelumnya).
  Future<void> _handleAddNewCustomer() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateCustomerScreen()),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '---';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleSave() async {
    if (_selectedOrder == null) {
      _showSnack('Pilih pesanan terlebih dahulu', isError: true);
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      _showSnack('Alamat wajib diisi', isError: true);
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      _showSnack('Tanggal dan jam wajib dipilih', isError: true);
      return;
    }

    final scheduledAt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    setState(() => _isSaving = true);
    try {
      await ref.read(orderRepositoryProvider).scheduleLogistics(
            _selectedOrder!.id,
            mode: _mode,
            scheduledAt: scheduledAt,
            address: _addressController.text.trim(),
            courierId: _selectedCourier?.id,
            courierName: _selectedCourier?.fullName,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );
      if (mounted) {
        _showSnack('Jadwal berhasil disimpan');
        // pop(true) - bukan maybePop() - supaya pemanggil (khususnya
        // OrderDetailScreen lewat _openScheduleDeliverySheet) tau jadwal
        // berhasil disimpan dan bisa refresh datanya.
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showSnack('Gagal menyimpan jadwal: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.beVietnamPro()),
        backgroundColor: isError ? _DS.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DS.canvas,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _isLocked ? _buildLockedOrderInfo() : _buildModeToggle(),
                          const SizedBox(height: AppTheme.xl),
                          if (!_isLocked) ...[
                            _buildOrderPicker(),
                            const SizedBox(height: AppTheme.lg),
                          ],
                          _buildBranchPicker(),
                          const SizedBox(height: AppTheme.lg),
                          _buildAddressField(),
                          const SizedBox(height: AppTheme.lg),
                          _buildDateTimeRow(),
                          const SizedBox(height: AppTheme.lg),
                          _buildCourierPicker(),
                          const SizedBox(height: AppTheme.lg),
                          _buildNotesField(),
                          const SizedBox(height: AppTheme.xl),
                          _buildSummaryCard(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: _DS.canvas,
      padding: const EdgeInsets.fromLTRB(12, 16, 20, 12),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
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
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFD1E4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_available_rounded, color: _DS.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isLocked ? 'Jadwalkan Pengantaran' : 'Jadwalkan Antar Jemput',
              style: _DS.headlineMd(color: _DS.navy),
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu info order saat mode locked (dibuka dari OrderDetailScreen) -
  /// menggantikan mode toggle, karena mode & order-nya sudah pasti dan
  /// tidak boleh diubah dari sini.
  Widget _buildLockedOrderInfo() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: _DS.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: _DS.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.call_made_rounded, color: _DS.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menjadwalkan Pengantaran',
                  style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w700, color: _DS.primary),
                ),
                const SizedBox(height: 2),
                Text(
                  _isLoadingPreselected
                      ? 'Memuat pesanan...'
                      : (_selectedOrder != null
                          ? '${_selectedOrder!.orderNumber} (${_selectedOrder!.customerName ?? "Pelanggan"})'
                          : 'Pesanan tidak ditemukan'),
                  style: GoogleFonts.beVietnamPro(fontSize: 13.5, fontWeight: FontWeight.w600, color: _DS.onSurface),
                ),
              ],
            ),
          ),
          if (_isLoadingPreselected)
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: _DS.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(child: _modeButton('penjemputan', 'Penjemputan', Icons.call_received_rounded, _pickupAccent)),
          Expanded(child: _modeButton('pengantaran', 'Pengantaran', Icons.call_made_rounded, _DS.primary)),
        ],
      ),
    );
  }

  Widget _modeButton(String value, String label, IconData icon, Color accent) {
    final isSelected = _mode == value;
    return InkWell(
      onTap: () => setState(() {
        _mode = value;
        _selectedOrder = null;
        _prefilledFromOrder = false;
      }),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isSelected ? Colors.white : _DS.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : _DS.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(text, style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w700, color: _DS.onSurfaceVariant)),
    );
  }

  BoxDecoration get _fieldBoxDecoration => BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: _DS.outlineVariant),
      );

  Widget _buildOrderPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Pilih Pesanan'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                onTap: _isLoadingOrders ? null : _pickOrder,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: 14),
                  decoration: _fieldBoxDecoration,
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, size: 20, color: _DS.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedOrder == null
                              ? 'Cari pesanan...'
                              : '${_selectedOrder!.orderNumber} (${_selectedOrder!.customerName ?? "Pelanggan"})',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 13.5,
                            color: _selectedOrder == null ? _DS.onSurfaceVariant : _DS.onSurface,
                            fontWeight: _selectedOrder == null ? FontWeight.w400 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_isLoadingOrders)
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        Icon(Icons.expand_more_rounded, color: _DS.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
            // Tombol "Baru" (tambah pelanggan) hanya relevan saat menjadwalkan
            // penjemputan - di pengantaran, order (dan pelanggannya) sudah pasti
            // ada karena dibuat sebelumnya.
            if (_mode == 'penjemputan') ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: _handleAddNewCustomer,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.md),
                  decoration: BoxDecoration(
                    color: _DS.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add_alt_1_rounded, size: 18, color: _DS.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Baru',
                        style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w700, color: _DS.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        if (_prefilledFromOrder) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 12, color: _DS.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Tanggal & jam terisi otomatis dari saat pesanan dibuat',
                  style: GoogleFonts.beVietnamPro(fontSize: 11, color: _DS.primary, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBranchPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Pilih Cabang'),
        if (_isLoadingLaundries)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: _fieldBoxDecoration,
            alignment: Alignment.center,
            child: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_laundries.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppTheme.md),
            decoration: BoxDecoration(
              color: _DS.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Text(
              'Belum ada cabang aktif. Tambahkan cabang terlebih dahulu di menu Cabang.',
              style: GoogleFonts.beVietnamPro(fontSize: 12, color: _DS.onSurfaceVariant),
            ),
          )
        else
          Container(
            decoration: _fieldBoxDecoration,
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<Laundry>(
                isExpanded: true,
                value: _selectedLaundry,
                items: _laundries
                    .map((l) => DropdownMenuItem<Laundry>(
                          value: l,
                          child: Text(
                            l.name,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.beVietnamPro(fontSize: 13.5),
                          ),
                        ))
                    .toList(),
                // Dikunci saat _isLocked - order & cabangnya sudah pasti
                // ditentukan dari OrderDetailScreen, jadi tidak boleh
                // diganti manual dari sini (kalau diganti, _selectedOrder
                // yang sudah ke-lock bisa jadi tidak konsisten lagi).
                onChanged: _isLocked
                    ? null
                    : (val) => setState(() {
                          _selectedLaundry = val;
                          // Order yang sudah dipilih mungkin dari cabang lain,
                          // jadi direset supaya konsisten dengan cabang barunya.
                          _selectedOrder = null;
                        }),
                decoration: InputDecoration(
                  hintText: 'Pilih cabang',
                  hintStyle: GoogleFonts.beVietnamPro(fontSize: 13, color: _DS.onSurfaceVariant),
                  prefixIcon: Icon(Icons.storefront_outlined, size: 20, color: _DS.onSurfaceVariant),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: 14),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text(
                'Alamat',
                style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w700, color: _DS.onSurfaceVariant),
              ),
            ),
            TextButton.icon(
              onPressed: () => _showSnack('Fitur pilih lokasi peta akan segera hadir'),
              icon: Icon(Icons.location_on_outlined, size: 15, color: _DS.primary),
              label: Text('Pakai lokasi peta', style: GoogleFonts.beVietnamPro(fontSize: 11.5, fontWeight: FontWeight.w700, color: _DS.primary)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          decoration: _fieldBoxDecoration,
          child: TextField(
            controller: _addressController,
            maxLines: 3,
            style: GoogleFonts.beVietnamPro(fontSize: 13.5),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Jl. Kebayoran Lama No. 123, Jakarta Selatan...',
              hintStyle: GoogleFonts.beVietnamPro(fontSize: 13, color: _DS.onSurfaceVariant),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AppTheme.md),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('Tanggal'),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: 14),
                  decoration: _fieldBoxDecoration,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatDate(_selectedDate),
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 13,
                            color: _selectedDate == null ? _DS.onSurfaceVariant : _DS.onSurface,
                          ),
                        ),
                      ),
                      Icon(Icons.calendar_today_outlined, size: 16, color: _DS.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppTheme.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('Jam'),
              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: 14),
                  decoration: _fieldBoxDecoration,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatTime(_selectedTime),
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 13,
                            color: _selectedTime == null ? _DS.onSurfaceVariant : _DS.onSurface,
                          ),
                        ),
                      ),
                      Icon(Icons.schedule_outlined, size: 16, color: _DS.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCourierPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Pilih Kurir'),
        if (_isLoadingCouriers)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: _fieldBoxDecoration,
            alignment: Alignment.center,
            child: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_couriers.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppTheme.md),
            decoration: BoxDecoration(
              color: _DS.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Text(
              'Belum ada karyawan dengan posisi "Kurir". Anda tetap bisa menyimpan jadwal tanpa memilih kurir.',
              style: GoogleFonts.beVietnamPro(fontSize: 12, color: _DS.onSurfaceVariant),
            ),
          )
        else
          Container(
            decoration: _fieldBoxDecoration,
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<Employee>(
                isExpanded: true,
                value: _selectedCourier,
                items: _couriers
                    .map((c) => DropdownMenuItem<Employee>(
                          value: c,
                          child: Text(
                            c.fullName.isNotEmpty ? c.fullName : c.employeeCode,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.beVietnamPro(fontSize: 13.5),
                          ),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCourier = val),
                decoration: InputDecoration(
                  hintText: 'Cari kurir terdekat...',
                  hintStyle: GoogleFonts.beVietnamPro(fontSize: 13, color: _DS.onSurfaceVariant),
                  prefixIcon: Icon(Icons.delivery_dining_outlined, size: 20, color: _DS.onSurfaceVariant),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: 14),
                ),
              ),
            ),
          ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Kurir aktif dengan posisi "Kurir" ditampilkan di daftar ini.',
            style: GoogleFonts.beVietnamPro(fontSize: 11, fontStyle: FontStyle.italic, color: _DS.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Catatan Tambahan (Opsional)'),
        Container(
          decoration: _fieldBoxDecoration,
          child: TextField(
            controller: _notesController,
            maxLines: 3,
            style: GoogleFonts.beVietnamPro(fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Contoh: Titipkan di satpam, pagar warna hitam...',
              hintStyle: GoogleFonts.beVietnamPro(fontSize: 13, color: _DS.onSurfaceVariant),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AppTheme.md),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final name = _selectedOrder == null
        ? 'Pilih atau Cari Pesanan'
        : '${_selectedOrder!.orderNumber} (${_selectedOrder!.customerName ?? "Pelanggan"})';
    final address = _addressController.text.trim().isEmpty ? 'Alamat belum ditentukan' : _addressController.text.trim();
    final schedule = (_selectedDate == null && _selectedTime == null)
        ? 'Belum dijadwalkan'
        : '${_formatDate(_selectedDate)} • ${_formatTime(_selectedTime)}';
    final modeLabel = _mode == 'penjemputan' ? 'Penjemputan' : 'Pengantaran';
    final branchLabel = _selectedLaundry?.name;

    return Container(
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: _DS.outlineVariant.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RINGKASAN JADWAL',
            style: GoogleFonts.beVietnamPro(fontSize: 11.5, fontWeight: FontWeight.w700, color: _modeAccent, letterSpacing: 0.4),
          ),
          const SizedBox(height: AppTheme.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryIcon(Icons.person_outline),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.beVietnamPro(fontSize: 13.5, fontWeight: FontWeight.w600, color: _DS.onSurface)),
                    const SizedBox(height: 2),
                    Text(address, style: GoogleFonts.beVietnamPro(fontSize: 12, color: _DS.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.md),
          Divider(color: _DS.outlineVariant.withOpacity(0.6), height: 1),
          const SizedBox(height: AppTheme.md),
          Row(
            children: [
              _summaryIcon(Icons.event_outlined, color: _modeAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(schedule, style: GoogleFonts.beVietnamPro(fontSize: 13.5, fontWeight: FontWeight.w600, color: _DS.onSurface)),
                    const SizedBox(height: 2),
                    Text(
                      branchLabel != null ? 'Mode: $modeLabel • $branchLabel' : 'Mode: $modeLabel',
                      style: GoogleFonts.beVietnamPro(fontSize: 12, color: _DS.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryIcon(IconData icon, {Color? color}) {
    final accent = color ?? _DS.primary;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: accent.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(icon, size: 18, color: accent),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.surface,
        border: Border(top: BorderSide(color: _DS.outlineVariant)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: _DS.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Simpan Jadwal', style: GoogleFonts.beVietnamPro(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }
}
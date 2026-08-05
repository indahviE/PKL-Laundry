import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/themes/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/services/app_feedback.dart';
import '../../l10n/app_localizations.dart';
import '../../models/employee.dart';
import '../../models/laundry.dart';
import '../../models/order.dart';
import '../../repositories/employee_repository.dart';
import '../../repositories/laundry_repository.dart';
import '../../repositories/order_repository.dart';
import '../customers/create_customer_screen.dart';

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
}

class CreateDeliveryScheduleScreen extends ConsumerStatefulWidget {
  final String initialMode;
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
  static const _pickupAccent = Color(0xFFB197FC);

  Color get _modeAccent => _mode == 'penjemputan' ? _pickupAccent : _DS.primary;

  bool get _isLocked => widget.preselectedOrderId != null;

  late String _mode; // 'penjemputan' | 'pengantaran'
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  Order? _selectedOrder;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

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
      _lockCourierToOrder();
    } catch (_) {
      if (mounted) setState(() => _isLoadingCouriers = false);
    }
  }

  /// Cocokkan courierId dari order.logisticsSchedule ke daftar _couriers -
  /// dipanggil di 2 tempat (akhir _fetchCouriers DAN akhir
  /// _fetchPreselectedOrder), sama pola dengan _lockBranchToOrder, supaya
  /// gak masalah siapa yang kelar duluan (race condition). Sebelumnya
  /// pencocokan kurir cuma dicoba SEKALI inline di _fetchPreselectedOrder -
  /// kalau _couriers masih kosong di titik itu (fetch-nya belum kelar),
  /// kurir yang harusnya ke-prefill jadi gak muncul, padahal datanya ada.
  void _lockCourierToOrder() {
    if (_selectedOrder == null || _couriers.isEmpty || _selectedCourier != null) return;
    final courierId = _selectedOrder!.logisticsSchedule?.courierId;
    if (courierId == null || courierId.isEmpty) return;
    final match = _couriers.where((c) => c.id == courierId);
    if (match.isNotEmpty && mounted) {
      setState(() => _selectedCourier = match.first);
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
      _lockBranchToOrder();
    } catch (_) {
      if (mounted) setState(() => _isLoadingLaundries = false);
    }
  }

  Future<void> _fetchPreselectedOrder() async {
    setState(() => _isLoadingPreselected = true);
    try {
      final order = await ref.read(orderRepositoryProvider).getOrder(widget.preselectedOrderId!);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;

      if (order == null) {
        _showErrorSnack(l10n.orderNotFoundError);
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
          // Kurir DIPINDAH ke _lockCourierToOrder() - dipanggil di bawah
          // + di akhir _fetchCouriers(), supaya aman kapan pun _couriers
          // selesai dimuat duluan.
        }
      });

      _lockBranchToOrder();
      _lockCourierToOrder();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showErrorSnack(l10n.loadOrderError(e.toString()));
        setState(() => _isLoadingPreselected = false);
      }
    }
  }

  void _lockBranchToOrder() {
    if (!_isLocked || _selectedOrder == null || _laundries.isEmpty) return;
    final match = _laundries.where((l) => l.id == _selectedOrder!.laundryId);
    if (match.isNotEmpty && mounted) {
      setState(() => _selectedLaundry = match.first);
    }
  }

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
    final l10n = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text(l10n.selectOrderTitle, style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, color: _DS.onSurface)),
        content: SizedBox(
          width: double.maxFinite,
          child: error != null
              ? Text(error, style: GoogleFonts.beVietnamPro(fontSize: 12.5, color: _DS.error))
              : orders.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        _mode == 'penjemputan' ? l10n.noOrdersWaitingPickupHint : l10n.noOrdersReadyDeliveryHint,
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
                            (order.customerName?.isNotEmpty ?? false) ? order.customerName! : l10n.customerFallbackLabel,
                            style: GoogleFonts.beVietnamPro(fontSize: 13.5, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(order.orderNumber, style: GoogleFonts.beVietnamPro(fontSize: 12, color: _DS.onSurfaceVariant)),
                          onTap: () {
                            setState(() {
                              _selectedOrder = order;
                              _prefilledFromOrder = false;

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
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.closeButton, style: GoogleFonts.beVietnamPro())),
        ],
      ),
    );
  }

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

  String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) return '---';
    final l10n = AppLocalizations.of(context)!;
    final months = [
      l10n.monthJan, l10n.monthFeb, l10n.monthMar, l10n.monthApr, l10n.monthMay, l10n.monthJun,
      l10n.monthJul, l10n.monthAug, l10n.monthSep, l10n.monthOct, l10n.monthNov, l10n.monthDec,
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleSave() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedOrder == null) {
      _showErrorSnack(l10n.selectOrderRequiredError);
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      _showErrorSnack(l10n.addressRequiredError);
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      _showErrorSnack(l10n.dateTimeRequiredError);
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
        _showSuccessSnack(l10n.scheduleSaveSuccess);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showErrorSnack(l10n.scheduleSaveError(e.toString()));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccessSnack(String message) {
    if (!mounted) return;
    AppFeedback.playSound(ref, AppSound.success);
    AppSnackbar.success(context, message);
  }

  void _showErrorSnack(String message) {
    if (!mounted) return;
    AppFeedback.playSound(ref, AppSound.error);
    AppSnackbar.error(context, message);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    AppSnackbar.info(context, message);
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
                          _isLocked ? _buildLockedOrderInfo(context) : _buildModeToggle(context),
                          const SizedBox(height: AppTheme.xl),
                          if (!_isLocked) ...[
                            _buildOrderPicker(context),
                            const SizedBox(height: AppTheme.lg),
                          ],
                          _buildBranchPicker(context),
                          const SizedBox(height: AppTheme.lg),
                          _buildAddressField(context),
                          const SizedBox(height: AppTheme.lg),
                          _buildDateTimeRow(context),
                          const SizedBox(height: AppTheme.lg),
                          _buildCourierPicker(context),
                          const SizedBox(height: AppTheme.lg),
                          _buildNotesField(context),
                          const SizedBox(height: AppTheme.xl),
                          _buildSummaryCard(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              _isLocked ? l10n.scheduleDeliveryTileTitle : l10n.scheduleDeliveryScreenTitle,
              style: _DS.headlineMd(color: _DS.navy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedOrderInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  l10n.schedulingDeliveryBadgeLabel,
                  style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w700, color: _DS.primary),
                ),
                const SizedBox(height: 2),
                Text(
                  _isLoadingPreselected
                      ? l10n.loadingOrderLabel
                      : (_selectedOrder != null
                          ? '${_selectedOrder!.orderNumber} (${_selectedOrder!.customerName ?? l10n.customerFallbackLabel})'
                          : l10n.orderNotFoundError),
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

  Widget _buildModeToggle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: _DS.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(child: _modeButton('penjemputan', l10n.pickupModeLabel, Icons.call_received_rounded, _pickupAccent)),
          Expanded(child: _modeButton('pengantaran', l10n.deliveryModeLabel, Icons.call_made_rounded, _DS.primary)),
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

  Widget _buildOrderPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(l10n.selectOrSearchOrderLabel),
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
                              ? l10n.searchOrderHint
                              : '${_selectedOrder!.orderNumber} (${_selectedOrder!.customerName ?? l10n.customerFallbackLabel})',
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
                        l10n.newCustomerButtonShort,
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
                  l10n.autoFilledScheduleHint,
                  style: GoogleFonts.beVietnamPro(fontSize: 11, color: _DS.primary, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBranchPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(l10n.selectBranchLabel),
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
              l10n.noActiveBranchesScheduleHint,
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
                onChanged: _isLocked
                    ? null
                    : (val) => setState(() {
                          _selectedLaundry = val;
                          _selectedOrder = null;
                        }),
                decoration: InputDecoration(
                  hintText: l10n.selectBranchHint,
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

  Widget _buildAddressField(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text(
                l10n.addressLabel,
                style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w700, color: _DS.onSurfaceVariant),
              ),
            ),
            TextButton.icon(
              onPressed: () => _showSnack(l10n.mapLocationComingSoon),
              icon: Icon(Icons.location_on_outlined, size: 15, color: _DS.primary),
              label: Text(l10n.useMapLocationButton, style: GoogleFonts.beVietnamPro(fontSize: 11.5, fontWeight: FontWeight.w700, color: _DS.primary)),
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
              hintText: l10n.addressFieldExampleHint,
              hintStyle: GoogleFonts.beVietnamPro(fontSize: 13, color: _DS.onSurfaceVariant),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AppTheme.md),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeRow(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel(l10n.dateLabel),
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
                          _formatDate(context, _selectedDate),
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
              _fieldLabel(l10n.timeLabel),
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

  Widget _buildCourierPicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(l10n.selectCourierLabel),
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
              l10n.noCourierEmployeeScheduleHint,
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
                  hintText: l10n.searchCourierHint,
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
            l10n.courierListHint,
            style: GoogleFonts.beVietnamPro(fontSize: 11, fontStyle: FontStyle.italic, color: _DS.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(l10n.additionalNotesLabel),
        Container(
          decoration: _fieldBoxDecoration,
          child: TextField(
            controller: _notesController,
            maxLines: 3,
            style: GoogleFonts.beVietnamPro(fontSize: 13.5),
            decoration: InputDecoration(
              hintText: l10n.notesExampleHint,
              hintStyle: GoogleFonts.beVietnamPro(fontSize: 13, color: _DS.onSurfaceVariant),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AppTheme.md),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = _selectedOrder == null
        ? l10n.selectOrSearchOrderLabel
        : '${_selectedOrder!.orderNumber} (${_selectedOrder!.customerName ?? l10n.customerFallbackLabel})';
    final address = _addressController.text.trim().isEmpty ? l10n.addressNotSetLabel : _addressController.text.trim();
    final schedule = (_selectedDate == null && _selectedTime == null)
        ? l10n.notScheduledLabel
        : '${_formatDate(context, _selectedDate)} • ${_formatTime(_selectedTime)}';
    final modeLabel = _mode == 'penjemputan' ? l10n.pickupModeLabel : l10n.deliveryModeLabel;
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
            l10n.scheduleSummaryTitle,
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
                      branchLabel != null ? l10n.modeWithBranchLabel(modeLabel, branchLabel) : l10n.modeOnlyLabel(modeLabel),
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

  Widget _buildBottomBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  : Text(l10n.saveScheduleButton, style: GoogleFonts.beVietnamPro(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }
}
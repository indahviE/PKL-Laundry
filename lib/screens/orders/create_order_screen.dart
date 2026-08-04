import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/themes/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/app_input.dart';
import '../../models/service.dart';
import '../../models/order.dart';
import '../../core/services/app_feedback.dart';
import '../../repositories/service_repository.dart';
import '../../repositories/order_repository.dart';

/// Order Item Form Model (UI-only, dikonversi ke OrderItem domain model
/// pas save)
///
/// UPDATED: nambah `pricingType` & `weight`. Sebelumnya semua item
/// (per-kg maupun per-item) dihitung pakai `quantity` doang (stepper
/// integer), padahal layanan per-kg secara bisnis butuh berat asli
/// (desimal, mis. 3.5 kg) - bukan "3 buah". Sekarang subtotal dihitung
/// beda tergantung pricingType:
/// - perKg   -> price x weight
/// - perItem -> price x quantity
class OrderItemForm {
  final String id;
  final String name;
  final PricingType pricingType;
  int quantity;
  double weight;
  double price;

  /// Controller buat input berat (khusus item perKg). Dibuat sekali per
  /// item supaya cursor/fokus TextField gak reset tiap kali setState.
  late final TextEditingController weightController;

  OrderItemForm({
    required this.id,
    required this.name,
    required this.pricingType,
    required this.quantity,
    required this.weight,
    required this.price,
  }) {
    weightController = TextEditingController(
      text: weight > 0 ? weight.toStringAsFixed(1) : '',
    );
  }

  double get subtotal => pricingType == PricingType.perKg ? weight * price : quantity * price;

  void dispose() {
    weightController.dispose();
  }
}

/// Opsi pelanggan buat dropdown, di-fetch dari
/// users/{uid}/customers
class _CustomerOption {
  final String id;
  final String name;
  final String phone;
  // Cabang tempat pelanggan ini terdaftar (field tambahan di luar skema
  // PRD §3.3.1, lihat CreateCustomerScreen). Bisa null buat pelanggan
  // lama yang dibuat sebelum field ini ada - sengaja TIDAK di-default ke
  // cabang manapun, supaya kelihatan jelas pelanggan mana yang masih
  // perlu di-assign manual (bukan ketebak otomatis, sesuai kesepakatan).
  final String? laundryId;

  _CustomerOption({required this.id, required this.name, required this.phone, this.laundryId});

  factory _CustomerOption.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return _CustomerOption(
      id: doc.id,
      name: (data['full_name'] ?? '') as String,
      phone: (data['phone'] ?? '') as String,
      laundryId: data['laundry_id'] as String?,
    );
  }
}

/// Opsi cabang buat dropdown, di-fetch dari users/{uid}/laundries
/// (sesuai Blueprint §3.2.3).
class _LaundryOption {
  final String id;
  final String name;

  _LaundryOption({required this.id, required this.name});

  factory _LaundryOption.fromFirestore(DocumentSnapshot doc, {required String unnamedFallback}) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawName = data['name'] as String?;
    return _LaundryOption(
      id: doc.id,
      name: (rawName == null || rawName.isEmpty) ? unnamedFallback : rawName,
    );
  }
}

/// Create Order Screen
class CreateOrderScreen extends ConsumerStatefulWidget {
  const CreateOrderScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  // ============================================
  // Radius lokal khusus layar ini, mengikuti pola desain baru
  // (card 16px, chip/field 12-14px, tombol utama pill). Sengaja TIDAK
  // mengubah AppTheme.radiusLg/radiusMd secara global supaya layar lain
  // yang masih pakai AppTheme apa adanya tidak ikut berubah tampilannya.
  // ============================================
  static const double _cardRadius = 16.0;
  static const double _chipRadius = 14.0;
  static const double _fieldRadius = 14.0;

  // ============================================
  // Warna netral lokal khusus layar ini, mengikuti prinsip desain baru:
  // biru cuma dipakai buat elemen "actionable" (tombol, chip aktif,
  // total harga) - bukan buat background kartu/kotak info biasa.
  // Sebelumnya banyak kotak (empty state, input fill, chip belum
  // dipilih) numpang pakai AppTheme.primaryColor/backgroundColor yang
  // sama-sama bernuansa biru, jadi kesannya "biru semua". Sekarang
  // dipisah pakai abu-abu netral, cuma canvas & shadow yang disamakan
  // sama HTML mockup (#F5F7FA, shadow hitam tipis).
  // ============================================
  static const Color _canvasColor = Color(0xFFF5F7FA);
  static const Color _neutralFill = AppTheme.gray50;
  static const Color _neutralSurface = AppTheme.gray100;

  // Controllers
  late TextEditingController _notesController;
  late TextEditingController _dpAmountController;

  // Form key
  final _formKey = GlobalKey<FormState>();

  // State
  bool _isLoading = false;
  bool _isLoadingCustomers = true;
  String? _customersError;
  bool _isLoadingServices = true;
  String? _servicesError;
  String? _selectedCustomerId;
  String? _selectedPaymentMethod = 'cash';

  // Lunas vs DP (sebagian) - hanya relevan buat metode instan
  // (cash/debit/ewallet). Transfer selalu mulai dari 0 dibayar, dikonfirmasi
  // manual belakangan di OrderDetailScreen.
  bool _isFullPayment = true;

  // Cara baju MASUK ke laundry: 'walk_in' atau 'pickup'.
  String _selectedOrderType = 'walk_in';

  // Cara baju KELUAR dari laundry: 'self_pickup' atau 'delivery'.
  String _selectedDeliveryType = 'self_pickup';

  // Jadwal jemput opsional - cuma relevan kalau _selectedOrderType == 'pickup'.
  // Diisi kasir kalau pelanggan udah kasih tau jam jemput dari awal; kalau
  // dikosongin, tetap bisa dijadwalkan belakangan lewat
  // CreateDeliveryScheduleScreen (menu Antar Jemput).
  DateTime? _pickupScheduleDate;
  TimeOfDay? _pickupScheduleTime;


  List<OrderItemForm> _orderItems = [];
  List<_CustomerOption> _customers = [];

  late final ServiceRepository _serviceRepository;
  List<Service> _services = [];

  // Business context (company & cabang) buat OrderRepository.createOrder().
  //
  // _laundriesList = SEMUA cabang aktif milik company ini. Dropdown pilih
  // cabang cuma ditampilin kalau isinya > 1 (artinya paket owner sudah
  // Professional/Enterprise dan dia sudah benar-benar nambah cabang lain).
  // Kalau cuma 1 cabang (mis. paket Starter, max 1 cabang), dropdown
  // disembunyikan dan _selectedLaundryId di-auto-pick ke cabang itu -
  // owner Starter gak akan pernah lihat dropdown sama sekali.
  //
  // Sengaja TIDAK baca plan_id dari subscriptions/ buat mutusin ini -
  // jumlah cabang aktual lebih reliable (langsung merefleksikan kondisi
  // nyata, gak perlu extra call, dan otomatis ke-update sendiri begitu
  // owner nambah/upgrade cabang tanpa perlu logic tambahan apapun).
  String? _companyId;
  List<_LaundryOption> _laundriesList = [];
  String? _selectedLaundryId;
  bool _isLoadingBusinessContext = true;
  String? _businessContextError;

  bool get _showLaundryDropdown => _laundriesList.length > 1;

  /// Order dijemput -> barang belum ada di tangan, jadi item pesanan
  /// TIDAK BISA diisi sama sekali dari layar ini (baru diisi belakangan
  /// pas konfirmasi jemput lewat PickupDeliveryScreen -> _ConfirmPickupSheet,
  /// setelah barang beneran ditimbang). Dipakai buat nyembunyikan picker
  /// layanan & daftar item, diganti box info kecil.
  bool get _isPickupOrder => _selectedOrderType == 'pickup';

  /// Pelanggan yang ditampilkan di dropdown, di-filter KETAT sesuai
  /// cabang yang lagi dipilih (_selectedLaundryId). Pelanggan lama yang
  /// belum punya laundry_id (null) sengaja TIDAK ikut muncul di manapun -
  /// harus di-assign manual dulu lewat halaman edit pelanggan.
  List<_CustomerOption> get _filteredCustomers =>
      _customers.where((c) => c.laundryId != null && c.laundryId == _selectedLaundryId).toList();

  /// Shortcut ke AppLocalizations - dipakai di seluruh method state ini
  /// (build maupun non-build, mis. handler validasi/snackbar) karena
  /// State selalu punya akses ke `context` sendiri.
  AppLocalizations get _t => AppLocalizations.of(context)!;

  /// Metode pembayaran nyata yang dipakai laundry ini:
  /// cash, transfer, debit (EDC), ewallet.
  ///
  /// cash, debit, & ewallet -> transaksi langsung (di kasir / scan QR),
  /// jadi dianggap dibayar seketika (lunas atau DP tergantung toggle
  /// _isFullPayment di bawah).
  /// transfer -> customer transfer sendiri, admin perlu cek mutasi dulu,
  /// jadi tetap 'pending' (paid_amount 0) sampai dikonfirmasi manual dari
  /// OrderDetailScreen.
  List<Map<String, dynamic>> _paymentMethods(AppLocalizations t) => [
        {'id': 'cash', 'label': t.paymentMethodCash, 'icon': Icons.payments_outlined},
        {'id': 'transfer', 'label': t.paymentMethodTransfer, 'icon': Icons.account_balance_outlined},
        {'id': 'debit', 'label': t.paymentMethodDebit, 'icon': Icons.credit_card_outlined},
        {'id': 'ewallet', 'label': t.paymentMethodEwallet, 'icon': Icons.account_balance_wallet_outlined},
      ];

  bool get _isInstantMethod =>
      _selectedPaymentMethod == 'cash' || _selectedPaymentMethod == 'debit' || _selectedPaymentMethod == 'ewallet';

  List<Map<String, dynamic>> _orderTypes(AppLocalizations t) => [
        {'id': 'walk_in', 'label': t.orderTypeSelfDropoffLabel, 'icon': Icons.storefront_outlined},
        {'id': 'pickup', 'label': t.orderTypePickup, 'icon': Icons.call_received_rounded},
      ];

  List<Map<String, dynamic>> _deliveryTypes(AppLocalizations t) => [
        {'id': 'self_pickup', 'label': t.orderDeliverySelfPickup, 'icon': Icons.storefront_outlined},
        {'id': 'delivery', 'label': t.orderDeliveryDelivery, 'icon': Icons.call_made_rounded},
      ];

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _dpAmountController = TextEditingController();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _serviceRepository = ServiceRepository(userId: uid);
    _fetchCustomers();
    _fetchServices();
    _fetchBusinessContext();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _dpAmountController.dispose();
    // Dispose semua weightController milik tiap item, biar gak ada
    // TextEditingController yang nyangkut kepegang (memory leak) begitu
    // layar ini ditutup.
    for (final item in _orderItems) {
      item.dispose();
    }
    super.dispose();
  }

  /// Ambil company_id (dari companies pertama) & SEMUA cabang aktif milik
  /// company itu, dibutuhkan OrderRepository.createOrder() buat generate
  /// order_number dan buat isi dropdown cabang (kalau > 1).
  Future<void> _fetchBusinessContext() async {
    setState(() {
      _isLoadingBusinessContext = true;
      _businessContextError = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw _t.sessionNotFoundError;
      }
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      final companiesSnap = await userDocRef.collection('companies').limit(1).get();
      if (companiesSnap.docs.isEmpty) {
        throw _t.companyNotSetupError;
      }
      final companyId = companiesSnap.docs.first.id;

      final laundriesSnap = await userDocRef
          .collection('laundries')
          .where('company_id', isEqualTo: companyId)
          .where('is_active', isEqualTo: true)
          .get();
      if (laundriesSnap.docs.isEmpty) {
        throw _t.noBranchesForOrderError;
      }

      final laundries = laundriesSnap.docs
          .map((d) => _LaundryOption.fromFirestore(d, unnamedFallback: _t.unnamedBranchFallback))
          .toList();

      setState(() {
        _companyId = companyId;
        _laundriesList = laundries;
        // Auto-pick cabang pertama. Kalau cabang cuma 1 (mis. paket
        // Starter), inilah satu-satunya pilihan dan dropdown gak
        // ditampilkan sama sekali - owner gak perlu ngapa-ngapain.
        _selectedLaundryId = laundries.first.id;
        _isLoadingBusinessContext = false;
      });
    } catch (e) {
      setState(() {
        _businessContextError = e.toString();
        _isLoadingBusinessContext = false;
      });
    }
  }

  /// Ambil daftar pelanggan dari users/{uid}/customers buat dropdown
  Future<void> _fetchCustomers() async {
    setState(() {
      _isLoadingCustomers = true;
      _customersError = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw _t.sessionNotFoundError;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('customers')
          .orderBy('full_name')
          .get();

      setState(() {
        _customers = snapshot.docs.map((d) => _CustomerOption.fromFirestore(d)).toList();
        _isLoadingCustomers = false;
      });
    } catch (e) {
      setState(() {
        _customersError = e.toString();
        _isLoadingCustomers = false;
      });
    }
  }

  /// Ambil daftar layanan aktif dari users/{uid}/service_types.
  Future<void> _fetchServices() async {
    setState(() {
      _isLoadingServices = true;
      _servicesError = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw _t.sessionNotFoundError;
      }

      final allServices = await _serviceRepository.streamServices().first;
      final activeServices = allServices.where((s) => s.isActive).toList();

      setState(() {
        _services = activeServices;
        _isLoadingServices = false;
        // Item default cuma di-auto-isi kalau order type-nya BUKAN pickup.
        // Order pickup sengaja dibiarkan kosong terus (lihat _isPickupOrder)
        // karena barangnya belum ada di tangan sama sekali saat order dibuat.
        if (_orderItems.isEmpty && activeServices.isNotEmpty && !_isPickupOrder) {
          final first = activeServices.first;
          _orderItems = [
            OrderItemForm(
              id: first.id,
              name: first.name,
              pricingType: first.pricingType,
              quantity: 1,
              // Item perKg mulai dari 1.0 kg biar TextField gak kosong
              // (gampang lupa diisi), item perItem gak butuh weight sama
              // sekali jadi tetap 0.
              weight: first.pricingType == PricingType.perKg ? 1.0 : 0,
              price: _servicePrice(first),
            ),
          ];
        }
      });
    } catch (e) {
      setState(() {
        _servicesError = e.toString();
        _isLoadingServices = false;
      });
    }
  }

  double _servicePrice(Service service) {
    if (service.pricingType == PricingType.perKg) {
      return service.pricePerKg ?? 0;
    }
    return service.pricePerItem ?? 0;
  }

  String _servicePriceLabel(Service service) {
    final price = _servicePrice(service);
    final suffix = service.pricingType == PricingType.perKg ? _t.perKgUnitSuffix : _t.unitPerItemSuffix;
    return '${_formatCurrency(price)}$suffix';
  }

  /// Tambah satu layanan sebagai item pesanan baru. Dipanggil langsung
  /// dari kartu layanan yang bisa di-scroll horizontal (bukan lewat
  /// dialog terpisah lagi) - tap kartu layanan = 1 item baru ditambahkan
  /// ke _orderItems, bisa dipanggil berkali-kali (termasuk layanan yang
  /// sama) persis seperti perilaku "Tambah" yang lama.
  void _addServiceToOrder(Service service) {
    setState(() {
      _orderItems.add(
        OrderItemForm(
          id: service.id,
          name: service.name,
          pricingType: service.pricingType,
          quantity: 1,
          weight: service.pricingType == PricingType.perKg ? 1.0 : 0,
          price: _servicePrice(service),
        ),
      );
    });
  }

  void _removeOrderItem(int index) {
    setState(() {
      _orderItems[index].dispose();
      _orderItems.removeAt(index);
    });
  }

  /// Handle ganti toggle "Baju Masuk". Dipisah dari onSelected biasa
  /// karena sekarang ada efek samping ke _orderItems:
  /// - Ganti KE 'pickup' -> kosongkan semua item (barang belum ada di
  ///   tangan, jadi apapun yang udah keisi otomatis harus dibuang, bukan
  ///   cuma disembunyikan doang - biar gak kesimpen data ngasal).
  /// - Ganti BALIK ke 'walk_in' & item masih kosong -> isi ulang layanan
  ///   pertama sebagai default, sama seperti behavior awal screen dibuka.
  void _handleOrderTypeChanged(String id) {
    setState(() {
      _selectedOrderType = id;

      if (id == 'pickup') {
        for (final item in _orderItems) {
          item.dispose();
        }
        _orderItems = [];
      } else if (_orderItems.isEmpty && _services.isNotEmpty) {
        final first = _services.first;
        _orderItems = [
          OrderItemForm(
            id: first.id,
            name: first.name,
            pricingType: first.pricingType,
            quantity: 1,
            weight: first.pricingType == PricingType.perKg ? 1.0 : 0,
            price: _servicePrice(first),
          ),
        ];
      }
    });
  }

  void _showError(String message) {
    AppFeedback.haptic(ref, type: HapticFeedbackType.heavy);
    AppFeedback.playSound(ref, AppSound.error);
    AppSnackbar.error(context, message);
  }

  /// Handle save order -> lewat OrderRepository.createOrder(), yang
  /// atomic: generate order_number, tulis order, update statistik
  /// customer, dan (kalau ada pembayaran) catat transactions/, semuanya
  /// dalam 1 Firestore transaction.
  Future<void> _handleSaveOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isPickupOrder) {
      if (_orderItems.isEmpty) {
        _showError(_t.minOneItemError);
        return;
      }
      for (final item in _orderItems) {
        if (item.pricingType == PricingType.perKg && item.weight <= 0) {
          _showError(_t.fillWeightForItemError(item.name));
          return;
        }
      }
    }

    if (_companyId == null || _selectedLaundryId == null) {
      _showError(_businessContextError ?? _t.businessContextNotReadyError);
      return;
    }

    final totalItems = _orderItems.fold<int>(0, (sum, item) => sum + item.quantity);

    // Total berat cuma dijumlah dari item yang pricingType-nya perKg -
    // item perItem gak punya berat yang relevan buat dicatat di sini.
    final totalWeight = _orderItems
        .where((item) => item.pricingType == PricingType.perKg)
        .fold<double>(0, (sum, item) => sum + item.weight);

    final subtotal = _calculateTotal();
    const discountAmount = 0.0;
    const taxAmount = 0.0;
    final totalAmount = subtotal - discountAmount + taxAmount;

    // Tentukan berapa yang dibayar sekarang.
    //
    // Order pickup SENGAJA TIDAK lewat cabang ini sama sekali: totalnya
    // masih 0 di titik ini (barang belum ditimbang, lihat _isPickupOrder),
    // jadi metode pembayaran & toggle Lunas/DP di layar ini disembunyikan
    // (lihat _buildPickupPaymentNotice) dan pembayaran baru betul-betul
    // ditentukan belakangan lewat OrderRepository.confirmPickupWithItems()
    // saat konfirmasi jemput (_ConfirmPickupSheet), setelah subtotal riil
    // diketahui.
    double paidNow = 0;
    if (!_isPickupOrder && _isInstantMethod) {
      if (_isFullPayment) {
        paidNow = totalAmount;
      } else {
        final rawDp = _dpAmountController.text.replaceAll(RegExp(r'[^0-9]'), '');
        final dp = double.tryParse(rawDp) ?? 0;
        if (dp <= 0) {
          _showError(_t.dpAmountRequiredError);
          return;
        }
        if (dp >= totalAmount) {
          _showError(_t.dpAmountTooLargeError);
          return;
        }
        paidNow = dp;
      }
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw _t.sessionNotFoundError;
      }

      // FIX: firstWhere tanpa orElse bisa lempar StateError mentah kalau
      // _selectedCustomerId somehow gak ketemu di _customers (mis. list
      // sempat ke-refresh pas user lagi isi form). Sekarang dilempar
      // sebagai String biasa, jadi ketangkep rapi sama catch di bawah
      // dan tampil sebagai snackbar merah - bukan crash gak jelas.
      final selectedCustomer = _customers.firstWhere(
        (c) => c.id == _selectedCustomerId,
        orElse: () => throw _t.selectedCustomerNotFoundError,
      );

      final PaymentStatus paymentStatus = paidNow <= 0
          ? PaymentStatus.pending
          : (paidNow >= totalAmount - 1 ? PaymentStatus.paid : PaymentStatus.partial);

      final order = Order(
        id: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: _companyId!,
        laundryId: _selectedLaundryId!,
        customerId: selectedCustomer.id,
        customerName: selectedCustomer.name,
        customerPhone: selectedCustomer.phone,
        orderNumber: '', // di-generate OrderRepository
        items: _orderItems
            .map((item) => OrderItem(
                  serviceTypeId: item.id,
                  serviceName: item.name,
                  // Item perKg -> quantity dikunci 1 (satu "paket" laundry
                  // seberat sekian kg), berat asli yang nentuin harga.
                  // Item perItem -> quantity asli dari stepper, weight 0
                  // (gak relevan).
                  quantity: item.pricingType == PricingType.perKg ? 1 : item.quantity,
                  weight: item.pricingType == PricingType.perKg ? item.weight : 0,
                  pricePerUnit: item.price,
                  totalPrice: item.subtotal,
                ))
            .toList(),
        totalWeight: totalWeight,
        totalItems: totalItems,
        subtotal: subtotal,
        discountAmount: discountAmount,
        taxAmount: taxAmount,
        totalAmount: totalAmount,
        status: OrderStatus.pending,
        statusHistory: const [],
        orderDate: DateTime.now(),
        paymentStatus: paymentStatus,
        paymentMethod: PaymentMethod.values.firstWhere((e) => e.name == _selectedPaymentMethod),
        paidAmount: paidNow,
        notes: _notesController.text.trim(),
        priorityLevel: PriorityLevel.normal,
        orderType: _selectedOrderType == 'pickup' ? OrderType.pickup : OrderType.walkIn,
        deliveryType: _selectedDeliveryType == 'delivery' ? DeliveryType.delivery : DeliveryType.selfPickup,
      );

      final repository = OrderRepository(userId: user.uid);
      final createdOrder = await repository.createOrder(order);

      // Kalau kasir udah isi jadwal jemput, simpan sekalian sebagai rencana
      // logistik (LogisticsSchedule mode 'penjemputan') - opsional. Kalau
      // gagal, order utamanya tetap sukses; admin masih bisa melengkapi
      // jadwal ini belakangan lewat menu Antar Jemput, jadi error di sini
      // sengaja tidak menggagalkan seluruh alur simpan order.
      if (_selectedOrderType == 'pickup' && _pickupScheduleDate != null && _pickupScheduleTime != null) {
        final scheduledAt = DateTime(
          _pickupScheduleDate!.year,
          _pickupScheduleDate!.month,
          _pickupScheduleDate!.day,
          _pickupScheduleTime!.hour,
          _pickupScheduleTime!.minute,
        );
        try {
          await repository.scheduleLogistics(
            createdOrder.id,
            mode: 'penjemputan',
            scheduledAt: scheduledAt,
          );
        } catch (_) {
          // Sengaja diabaikan - lihat penjelasan di atas.
        }
      }

      if (mounted) {
        AppFeedback.haptic(ref);
        AppFeedback.playSound(ref, AppSound.success);
        AppSnackbar.success(context, _t.orderCreatedSuccess);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.haptic(ref, type: HapticFeedbackType.heavy);
        AppFeedback.playSound(ref, AppSound.error);
        _showError(_t.genericErrorTemplate(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _calculateTotal() {
    return _orderItems.fold(0, (sum, item) => sum + item.subtotal);
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  Future<void> _pickPickupScheduleDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickupScheduleDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _pickupScheduleDate = picked);
  }

  Future<void> _pickPickupScheduleTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _pickupScheduleTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _pickupScheduleTime = picked);
  }

  String _formatScheduleDate(DateTime? date) {
    if (date == null) return _t.dateFieldFallbackLabel;
    final months = _t.localeName.startsWith('id')
        ? const ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des']
        : const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatScheduleTime(TimeOfDay? time) {
    if (time == null) return _t.timeFieldFallbackLabel;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvasColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
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
                        if (_businessContextError != null) ...[
                          _buildBusinessContextError(context),
                          const SizedBox(height: AppTheme.lg),
                        ],
                        // Satu card utama yang nampung SEMUA: data
                        // pesanan, item, sampai ringkasan harga.
                        // Sebelumnya ini 3-4 card terpisah yang masing-
                        // masing punya shadow sendiri (Form, tiap item
                        // pesanan, ringkasan harga) - keliatan numpuk
                        // banget kalau di-scroll. Sekarang cukup 1 card
                        // dengan pemisah section pakai label kecil +
                        // divider tipis, jauh lebih ringkas.
                        _buildMainCard(context),
                        const SizedBox(height: AppTheme.xl),
                        _buildSaveButton(context),
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

  /// Banner error kalau cabang/company belum siap (mis. belum ada cabang
  /// sama sekali). Ditaruh di atas form biar owner langsung ngeh kenapa
  /// gak bisa lanjut, alih-alih baru ketauan pas klik Simpan.
  Widget _buildBusinessContextError(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(_chipRadius),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: AppTheme.errorColor),
          const SizedBox(width: AppTheme.sm),
          Expanded(
            child: Text(
              _businessContextError!,
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.errorColor),
            ),
          ),
          TextButton(
            onPressed: _fetchBusinessContext,
            child: Text(t.orderRetryButtonLabel, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// Top bar sekaligus jadi header - tombol back, judul layar, dan
  /// subjudul singkat, tanpa kotak ikon besar & progress bar terpisah
  /// yang cuma makan tempat tanpa nambah informasi baru.
  Widget _buildTopBar(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => Navigator.pop(context, false),
          borderRadius: BorderRadius.circular(_chipRadius),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(_chipRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppTheme.textPrimary),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.createOrderAppBarTitle,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                t.createOrderSubtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Label kecil buat mulai section baru di dalam _buildMainCard,
  /// gantiin kotak/card terpisah per section.
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.md),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _sectionDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.lg),
      child: Divider(height: 1, color: AppTheme.borderColor.withOpacity(0.6)),
    );
  }

  /// Card utama - satu-satunya kotak putih ber-shadow di layar ini.
  /// Isinya 3 section (Data Pesanan, Item Pesanan, Ringkasan Harga)
  /// dipisahkan pakai divider tipis + label, bukan card terpisah lagi.
  Widget _buildMainCard(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel(t.orderDataSectionLabel),

            // Dropdown cabang - CUMA muncul kalau owner punya lebih dari
            // 1 cabang aktif (lihat _showLaundryDropdown). Owner paket
            // Starter (max 1 cabang) gak akan pernah lihat ini sama
            // sekali, ordernya otomatis nempel ke satu-satunya cabang
            // yang ada.
            if (_showLaundryDropdown) ...[
              _buildLaundryDropdown(context),
              const SizedBox(height: AppTheme.lg),
            ],

            _buildCustomerDropdown(context),

            const SizedBox(height: AppTheme.lg),

            _buildToggleGroup(
              label: t.incomingLaundryLabel,
              options: _orderTypes(t),
              selectedId: _selectedOrderType,
              onSelected: _handleOrderTypeChanged,
            ),

            // Field jadwal jemput cuma muncul kalau order type-nya pickup.
            if (_isPickupOrder) ...[
              const SizedBox(height: AppTheme.md),
              _buildPickupScheduleFields(),
            ],

            const SizedBox(height: AppTheme.lg),

            _buildToggleGroup(
              label: t.outgoingLaundryLabel,
              options: _deliveryTypes(t),
              selectedId: _selectedDeliveryType,
              onSelected: (id) => setState(() => _selectedDeliveryType = id),
            ),


            const SizedBox(height: AppTheme.lg),

            // Payment Method - disembunyikan total buat order pickup.
            // Totalnya belum bisa dihitung di layar ini (barang belum
            // ditimbang), jadi nanya metode & Lunas/DP di sini cuma bikin
            // bingung (dan sempat bikin toggle DP gagal terus karena
            // totalnya 0). Ganti box info kecil - metode & Lunas/DP yang
            // beneran dipakai baru dipilih pas konfirmasi jemput
            // (_ConfirmPickupSheet), setelah berat/qty riil diketahui.
            _isPickupOrder
                ? _buildPickupPaymentNotice(t)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${t.paymentMethodLabel} *',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.md),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final itemWidth = (constraints.maxWidth - AppTheme.sm) / 2;
                          return Wrap(
                            spacing: AppTheme.sm,
                            runSpacing: AppTheme.sm,
                            children: _paymentMethods(t).map((method) {
                              final isSelected = _selectedPaymentMethod == method['id'];
                              return SizedBox(
                                width: itemWidth,
                                child: InkWell(
                                  onTap: () => setState(() => _selectedPaymentMethod = method['id']),
                                  borderRadius: BorderRadius.circular(_chipRadius),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: AppTheme.sm, horizontal: AppTheme.sm),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.primaryColor.withOpacity(0.1)
                                          : _neutralFill,
                                      borderRadius: BorderRadius.circular(_chipRadius),
                                      border: Border.all(
                                        color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          method['icon'],
                                          size: 16,
                                          color: isSelected ? AppTheme.primaryColor : AppTheme.textTertiary,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            method['label'],
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: AppTheme.sm),
                      Text(
                        _selectedPaymentMethod == 'transfer'
                            ? t.transferPaymentPendingNotice
                            : t.instantPaymentNotice,
                        style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textTertiary),
                      ),

                      // Toggle Lunas / DP - hanya buat metode instan.
                      if (_isInstantMethod) ...[
                        const SizedBox(height: AppTheme.lg),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPaymentOptionChip(
                                label: t.fullPaymentLabel,
                                isSelected: _isFullPayment,
                                onTap: () => setState(() => _isFullPayment = true),
                              ),
                            ),
                            const SizedBox(width: AppTheme.sm),
                            Expanded(
                              child: _buildPaymentOptionChip(
                                label: t.partialPaymentLabel,
                                isSelected: !_isFullPayment,
                                onTap: () => setState(() => _isFullPayment = false),
                              ),
                            ),
                          ],
                        ),
                        if (!_isFullPayment) ...[
                          const SizedBox(height: AppTheme.md),
                          AppInput(
                            label: t.dpAmountLabel,
                            controller: _dpAmountController,
                            hintText: t.dpAmountHint,
                            prefixIcon: Icons.payments_outlined,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.remainingBillPayLaterNotice,
                            style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textTertiary),
                          ),
                        ],
                      ],
                    ],
                  ),

            const SizedBox(height: AppTheme.lg),

            AppInput(
              label: t.orderNotesFieldLabel,
              controller: _notesController,
              hintText: t.orderNotesFieldHint,
              prefixIcon: Icons.note_outlined,
              maxLines: 3,
            ),

            _sectionDivider(),

            _buildOrderItemsSection(context),

            _sectionDivider(),

            _buildPriceSummary(context),
          ],
        ),
      ),
    );
  }

  /// Info box pengganti section Metode Pembayaran, khusus order pickup.
  /// Menjelaskan kenapa pembayaran gak bisa ditentukan di layar ini -
  /// akan diminta lagi pas konfirmasi jemput setelah barang ditimbang.
  Widget _buildPickupPaymentNotice(AppLocalizations t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: _neutralSurface,
        borderRadius: BorderRadius.circular(_chipRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.textTertiary),
          const SizedBox(width: AppTheme.sm),
          Expanded(
            child: Text(
              t.pickupPaymentPendingNotice,
              style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  /// Dropdown pilih cabang. Cuma dipanggil kalau _showLaundryDropdown
  /// true (owner punya lebih dari 1 cabang aktif).
  Widget _buildLaundryDropdown(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (_isLoadingBusinessContext) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.lg),
        alignment: Alignment.center,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _laundriesList.any((l) => l.id == _selectedLaundryId) ? _selectedLaundryId : null,
      onChanged: (value) => setState(() {
        _selectedLaundryId = value;
        // Ganti cabang -> daftar pelanggan yang cocok ikut berubah,
        // jadi pelanggan yang sebelumnya kepilih (dari cabang lain)
        // harus direset supaya gak nyangkut nempel ke cabang yang salah.
        _selectedCustomerId = null;
      }),
      style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
      isExpanded: true,
      items: _laundriesList
          .map((laundry) => DropdownMenuItem(
                value: laundry.id,
                child: Text(
                  laundry.name,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 13.5),
                ),
              ))
          .toList(),
      decoration: InputDecoration(
        labelText: t.branchFieldLabel,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
        hintText: t.selectBranchForOrderHint,
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textTertiary),
        prefixIcon: Icon(Icons.storefront_outlined, color: AppTheme.textTertiary),
        filled: true,
        fillColor: _neutralFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_fieldRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_fieldRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_fieldRadius),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return t.selectBranchRequiredError;
        }
        return null;
      },
    );
  }

  Widget _buildPaymentOptionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_chipRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: AppTheme.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : _neutralFill,
          borderRadius: BorderRadius.circular(_chipRadius),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleGroup({
    required String label,
    required List<Map<String, dynamic>> options,
    required String selectedId,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: AppTheme.md),
        Row(
          children: List.generate(options.length, (index) {
            final option = options[index];
            final isSelected = selectedId == option['id'];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < options.length - 1 ? AppTheme.sm : 0),
                child: InkWell(
                  onTap: () => onSelected(option['id'] as String),
                  borderRadius: BorderRadius.circular(_chipRadius),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.md, horizontal: AppTheme.sm),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : _neutralFill,
                      borderRadius: BorderRadius.circular(_chipRadius),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          option['icon'],
                          size: 18,
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textTertiary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            option['label'],
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Field jadwal jemput - opsional, cuma tampil kalau order type-nya
  /// pickup. Kalau diisi, disimpan sebagai LogisticsSchedule (mode
  /// 'penjemputan') begitu order berhasil dibuat - lihat _handleSaveOrder.
  /// Kalau dikosongin, admin/dispatcher tetap bisa melengkapinya belakangan
  /// lewat CreateDeliveryScheduleScreen.
  Widget _buildPickupScheduleFields() {
    final t = _t;
    return Container(
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: _neutralFill,
        borderRadius: BorderRadius.circular(_chipRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_available_outlined, size: 15, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                t.pickupScheduleLabel,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.sm),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: !_isLoading ? _pickPickupScheduleDate : null,
                  borderRadius: BorderRadius.circular(_fieldRadius),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.sm, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(_fieldRadius),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 15, color: AppTheme.textTertiary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatScheduleDate(_pickupScheduleDate),
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: _pickupScheduleDate == null ? AppTheme.textTertiary : AppTheme.textPrimary,
                              fontWeight: _pickupScheduleDate == null ? FontWeight.w400 : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.sm),
              Expanded(
                child: InkWell(
                  onTap: !_isLoading ? _pickPickupScheduleTime : null,
                  borderRadius: BorderRadius.circular(_fieldRadius),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.sm, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(_fieldRadius),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule_outlined, size: 15, color: AppTheme.textTertiary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatScheduleTime(_pickupScheduleTime),
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: _pickupScheduleTime == null ? AppTheme.textTertiary : AppTheme.textPrimary,
                              fontWeight: _pickupScheduleTime == null ? FontWeight.w400 : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            t.pickupScheduleOptionalHint,
            style: GoogleFonts.poppins(fontSize: 10.5, color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDropdown(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (_isLoadingCustomers) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.lg),
        alignment: Alignment.center,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
        ),
      );
    }

    if (_customersError != null) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.md),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(_chipRadius),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, size: 18, color: AppTheme.errorColor),
            const SizedBox(width: AppTheme.sm),
            Expanded(
              child: Text(
                _customersError!,
                style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.errorColor),
              ),
            ),
            TextButton(
              onPressed: _fetchCustomers,
              child: Text(t.orderRetryButtonLabel, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    final filteredCustomers = _filteredCustomers;

    if (_customers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.md),
        decoration: BoxDecoration(
          color: _neutralSurface,
          borderRadius: BorderRadius.circular(_chipRadius),
        ),
        child: Text(
          t.noCustomersForOrderHint,
          style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textSecondary),
        ),
      );
    }

    if (filteredCustomers.isEmpty) {
      // Ada pelanggan, tapi gak ada satupun yang laundry_id-nya cocok
      // sama cabang yang lagi dipilih (atau memang belum di-assign
      // sama sekali - laundry_id-nya null).
      return Container(
        padding: const EdgeInsets.all(AppTheme.md),
        decoration: BoxDecoration(
          color: _neutralSurface,
          borderRadius: BorderRadius.circular(_chipRadius),
        ),
        child: Text(
          t.noCustomersInBranchHint,
          style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textSecondary),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedCustomerId,
      onChanged: (value) => setState(() => _selectedCustomerId = value),
      style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
      isExpanded: true,
      items: filteredCustomers
          .map((customer) => DropdownMenuItem(
                value: customer.id,
                child: Text(
                  customer.name,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 13.5),
                ),
              ))
          .toList(),
      decoration: InputDecoration(
        labelText: t.customerFieldLabel,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
        hintText: t.selectCustomerHint,
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textTertiary),
        prefixIcon: Icon(Icons.person_outline, color: AppTheme.textTertiary),
        filled: true,
        fillColor: _neutralFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_fieldRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_fieldRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_fieldRadius),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return t.selectCustomerRequiredError;
        }
        return null;
      },
    );
  }

  /// Section item pesanan - sekarang bagian dari _buildMainCard.
  ///
  /// KHUSUS order type 'pickup': picker layanan & daftar item TIDAK
  /// ditampilkan sama sekali (bukan cuma disembunyikan kosong) - diganti
  /// box info kecil. Ini disengaja: barang belum ada di tangan sama
  /// sekali saat order dibuat, jadi gak masuk akal biarin karyawan
  /// "asal pilih" layanan/qty di sini. Item baru bener-bener diisi
  /// belakangan pas konfirmasi jemput (PickupDeliveryScreen ->
  /// _ConfirmPickupSheet), setelah barang ketimbang.
  ///
  /// Untuk order type lain (walk_in): alur tetap sama seperti
  /// sebelumnya - layanan dipilih lewat kartu yang bisa di-scroll
  /// horizontal (tap kartu = 1 item baru ditambahkan). Multi-item tetap
  /// dipertahankan penuh. Logic kontrol per item TIDAK berubah: item
  /// perKg tetap pakai input berat (TextField desimal, kg), item perItem
  /// tetap pakai stepper qty (+/-).
  Widget _buildOrderItemsSection(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (_isPickupOrder) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(t.orderItemsSectionLabel),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.md),
            decoration: BoxDecoration(
              color: _neutralSurface,
              borderRadius: BorderRadius.circular(_chipRadius),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.textTertiary),
                const SizedBox(width: AppTheme.sm),
                Expanded(
                  child: Text(
                    t.itemsFilledAtPickupConfirmationHint,
                    style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(t.serviceTypeSectionLabel),
        _buildServicePicker(context),
        const SizedBox(height: AppTheme.lg),
        Text(
          t.orderItemsSectionLabel,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.sm),
        if (_orderItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppTheme.md),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _neutralSurface,
              borderRadius: BorderRadius.circular(_chipRadius),
            ),
            child: Text(
              t.noItemsTapServiceHint,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textSecondary),
            ),
          )
        else
          ..._orderItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == _orderItems.length - 1;
            final isPerKg = item.pricingType == PricingType.perKg;

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppTheme.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.sm, horizontal: AppTheme.md),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(_cardRadius),
                  border: Border.all(color: AppTheme.borderColor.withOpacity(0.7)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Baris 1: nama layanan, subtotal, tombol hapus.
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.sm),
                        Text(
                          _formatCurrency(item.subtotal),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        InkWell(
                          onTap: !_isLoading ? () => _removeOrderItem(index) : null,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Icon(Icons.close, size: 16, color: AppTheme.textTertiary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Baris 2: harga satuan (kiri) & kontrol kanan -
                    // input berat (kg) untuk item perKg, atau stepper
                    // qty untuk item perItem.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isPerKg
                              ? '${_formatCurrency(item.price)} ${t.perKgUnitSuffix}'
                              : '${_formatCurrency(item.price)}${t.unitPerItemSuffix}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                        isPerKg
                            ? SizedBox(
                                width: 92,
                                height: 34,
                                child: TextField(
                                  controller: item.weightController,
                                  enabled: !_isLoading,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    suffixText: 'kg',
                                    suffixStyle: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textTertiary),
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    filled: true,
                                    fillColor: _neutralFill,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: AppTheme.borderColor),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: AppTheme.borderColor),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    final parsed = double.tryParse(val.replaceAll(',', '.'));
                                    setState(() => item.weight = parsed ?? 0);
                                  },
                                ),
                              )
                            : Row(
                                children: [
                                  _QuantityButton(
                                    icon: Icons.remove,
                                    onTap: item.quantity > 1 ? () => setState(() => item.quantity--) : null,
                                  ),
                                  SizedBox(
                                    width: 28,
                                    child: Text(
                                      '${item.quantity}',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  _QuantityButton(
                                    icon: Icons.add,
                                    onTap: !_isLoading ? () => setState(() => item.quantity++) : null,
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  /// Kartu layanan yang bisa di-scroll horizontal, sesuai desain baru
  /// ("Jenis Layanan" di mockup). Tap kartu -> panggil _addServiceToOrder,
  /// yang menambahkan item baru ke _orderItems (logic sama persis dengan
  /// dialog "Tambah" yang lama). Loading/error/empty state dipertahankan
  /// dari implementasi sebelumnya, cuma dipindah supaya tampil inline
  /// alih-alih di dalam dialog.
  Widget _buildServicePicker(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (_isLoadingServices) {
      return Container(
        height: 96,
        alignment: Alignment.center,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
        ),
      );
    }

    if (_servicesError != null) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.md),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(_chipRadius),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, size: 18, color: AppTheme.errorColor),
            const SizedBox(width: AppTheme.sm),
            Expanded(
              child: Text(
                _servicesError!,
                style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.errorColor),
              ),
            ),
            TextButton(
              onPressed: _fetchServices,
              child: Text(t.orderRetryButtonLabel, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    if (_services.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.md),
        decoration: BoxDecoration(
          color: _neutralSurface,
          borderRadius: BorderRadius.circular(_chipRadius),
        ),
        child: Text(
          t.noActiveServicesForOrderHint,
          style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textSecondary),
        ),
      );
    }

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _services.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppTheme.sm),
        itemBuilder: (context, index) {
          final service = _services[index];
          return InkWell(
            onTap: !_isLoading ? () => _addServiceToOrder(service) : null,
            borderRadius: BorderRadius.circular(_cardRadius),
            child: Container(
              width: 148,
              padding: const EdgeInsets.all(AppTheme.md),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(_cardRadius),
                border: Border.all(color: AppTheme.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add_rounded, size: 16, color: AppTheme.primaryColor),
                  ),
                  Text(
                    service.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    _servicePriceLabel(service),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Ringkasan harga - kartu bertinta warna primary tipis, mengikuti
  /// "Summary Card" pada desain baru (bg primary/5, border primary/20).
  Widget _buildPriceSummary(BuildContext context) {
    final total = _calculateTotal();
    final t = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.subtotalLabel, style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textSecondary)),
              Text(
                _formatCurrency(total),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.sm),
          Divider(height: 1, color: AppTheme.primaryColor.withOpacity(0.12)),
          const SizedBox(height: AppTheme.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.totalLabel,
                style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              Text(
                _formatCurrency(total),
                style: GoogleFonts.poppins(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: !_isLoading ? _handleSaveOrder : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.md),
                  Text(
                    t.savingLabel,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : Text(
                t.saveOrderButton,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isEnabled ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.cardColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 14,
          color: isEnabled ? AppTheme.primaryColor : AppTheme.textTertiary,
        ),
      ),
    );
  }
}
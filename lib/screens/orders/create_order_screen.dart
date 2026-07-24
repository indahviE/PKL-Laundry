import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/themes/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/app_input.dart';
import '../../models/service.dart';
import '../../models/order.dart';
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

  factory _LaundryOption.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return _LaundryOption(
      id: doc.id,
      name: (data['name'] ?? 'Cabang Tanpa Nama') as String,
    );
  }
}

/// Create Order Screen
class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({Key? key}) : super(key: key);

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
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

  /// Pelanggan yang ditampilkan di dropdown, di-filter KETAT sesuai
  /// cabang yang lagi dipilih (_selectedLaundryId). Pelanggan lama yang
  /// belum punya laundry_id (null) sengaja TIDAK ikut muncul di manapun -
  /// harus di-assign manual dulu lewat halaman edit pelanggan.
  List<_CustomerOption> get _filteredCustomers =>
      _customers.where((c) => c.laundryId != null && c.laundryId == _selectedLaundryId).toList();

  /// Metode pembayaran nyata yang dipakai laundry ini:
  /// cash, transfer, debit (EDC), ewallet.
  ///
  /// cash, debit, & ewallet -> transaksi langsung (di kasir / scan QR),
  /// jadi dianggap dibayar seketika (lunas atau DP tergantung toggle
  /// _isFullPayment di bawah).
  /// transfer -> customer transfer sendiri, admin perlu cek mutasi dulu,
  /// jadi tetap 'pending' (paid_amount 0) sampai dikonfirmasi manual dari
  /// OrderDetailScreen.
  late final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'cash', 'label': 'Tunai', 'icon': Icons.payments_outlined},
    {'id': 'transfer', 'label': 'Transfer Bank', 'icon': Icons.account_balance_outlined},
    {'id': 'debit', 'label': 'Kartu Debit', 'icon': Icons.credit_card_outlined},
    {'id': 'ewallet', 'label': 'E-Wallet', 'icon': Icons.account_balance_wallet_outlined},
  ];

  bool get _isInstantMethod =>
      _selectedPaymentMethod == 'cash' || _selectedPaymentMethod == 'debit' || _selectedPaymentMethod == 'ewallet';

  late final List<Map<String, dynamic>> _orderTypes = [
    {'id': 'walk_in', 'label': 'Antar Sendiri', 'icon': Icons.storefront_outlined},
    {'id': 'pickup', 'label': 'Dijemput', 'icon': Icons.call_received_rounded},
  ];

  late final List<Map<String, dynamic>> _deliveryTypes = [
    {'id': 'self_pickup', 'label': 'Ambil Sendiri', 'icon': Icons.storefront_outlined},
    {'id': 'delivery', 'label': 'Diantar', 'icon': Icons.call_made_rounded},
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
        throw 'Sesi tidak ditemukan, silakan login ulang.';
      }
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      final companiesSnap = await userDocRef.collection('companies').limit(1).get();
      if (companiesSnap.docs.isEmpty) {
        throw 'Perusahaan belum diatur. Selesaikan onboarding terlebih dahulu.';
      }
      final companyId = companiesSnap.docs.first.id;

      final laundriesSnap = await userDocRef
          .collection('laundries')
          .where('company_id', isEqualTo: companyId)
          .where('is_active', isEqualTo: true)
          .get();
      if (laundriesSnap.docs.isEmpty) {
        throw 'Belum ada cabang laundry. Tambahkan cabang dulu sebelum membuat pesanan.';
      }

      final laundries = laundriesSnap.docs.map((d) => _LaundryOption.fromFirestore(d)).toList();

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
        throw 'Sesi tidak ditemukan, silakan login ulang.';
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
        throw 'Sesi tidak ditemukan, silakan login ulang.';
      }

      final allServices = await _serviceRepository.streamServices().first;
      final activeServices = allServices.where((s) => s.isActive).toList();

      setState(() {
        _services = activeServices;
        _isLoadingServices = false;
        if (_orderItems.isEmpty && activeServices.isNotEmpty) {
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
    final suffix = service.pricingType == PricingType.perKg ? '/kg' : '/item';
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
    );
  }

  /// Handle save order -> lewat OrderRepository.createOrder(), yang
  /// atomic: generate order_number, tulis order, update statistik
  /// customer, dan (kalau ada pembayaran) catat transactions/, semuanya
  /// dalam 1 Firestore transaction.
  Future<void> _handleSaveOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedOrderType != 'pickup') {
      if (_orderItems.isEmpty) {
        _showError('Tambahkan minimal 1 item pesanan');
        return;
      }
      for (final item in _orderItems) {
        if (item.pricingType == PricingType.perKg && item.weight <= 0) {
          _showError('Isi berat (kg) untuk "${item.name}" terlebih dahulu');
          return;
        }
      }
    }

    if (_companyId == null || _selectedLaundryId == null) {
      _showError(_businessContextError ?? 'Data perusahaan/cabang belum siap. Coba lagi sebentar.');
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
    double paidNow = 0;
    if (_isInstantMethod) {
      if (_isFullPayment) {
        paidNow = totalAmount;
      } else {
        final rawDp = _dpAmountController.text.replaceAll(RegExp(r'[^0-9]'), '');
        final dp = double.tryParse(rawDp) ?? 0;
        if (dp <= 0) {
          _showError('Isi nominal DP terlebih dahulu');
          return;
        }
        if (dp >= totalAmount) {
          _showError('Nominal DP harus lebih kecil dari total. Pilih "Lunas" kalau bayar penuh.');
          return;
        }
        paidNow = dp;
      }
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'Sesi tidak ditemukan, silakan login ulang.';
      }

      // FIX: firstWhere tanpa orElse bisa lempar StateError mentah kalau
      // _selectedCustomerId somehow gak ketemu di _customers (mis. list
      // sempat ke-refresh pas user lagi isi form). Sekarang dilempar
      // sebagai String biasa, jadi ketangkep rapi sama catch di bawah
      // dan tampil sebagai snackbar merah - bukan crash gak jelas.
      final selectedCustomer = _customers.firstWhere(
        (c) => c.id == _selectedCustomerId,
        orElse: () => throw 'Pelanggan yang dipilih tidak ditemukan, coba pilih ulang.',
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
      await repository.createOrder(order);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil dibuat!'),
            backgroundColor: Color(0xFF51CF66),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showError('Error: ${e.toString()}');
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
            child: Text('Coba lagi', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
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
                'Buat dan kelola pesanan laundry baru',
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
            _sectionLabel('Data Pesanan'),

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
              label: 'Baju Masuk *',
              options: _orderTypes,
              selectedId: _selectedOrderType,
              onSelected: (id) => setState(() => _selectedOrderType = id),
            ),

            const SizedBox(height: AppTheme.lg),

            _buildToggleGroup(
              label: 'Baju Keluar *',
              options: _deliveryTypes,
              selectedId: _selectedDeliveryType,
              onSelected: (id) => setState(() => _selectedDeliveryType = id),
            ),

            const SizedBox(height: AppTheme.lg),

            // Payment Method
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Metode Pembayaran *',
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
                      children: _paymentMethods.map((method) {
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
                      ? 'Status pembayaran akan "Belum Dibayar" sampai dikonfirmasi manual di halaman detail pesanan.'
                      : 'Metode ini dianggap dibayar langsung di kasir/saat itu juga.',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textTertiary),
                ),

                // Toggle Lunas / DP - hanya buat metode instan.
                if (_isInstantMethod) ...[
                  const SizedBox(height: AppTheme.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPaymentOptionChip(
                          label: 'Lunas',
                          isSelected: _isFullPayment,
                          onTap: () => setState(() => _isFullPayment = true),
                        ),
                      ),
                      const SizedBox(width: AppTheme.sm),
                      Expanded(
                        child: _buildPaymentOptionChip(
                          label: 'DP (Sebagian)',
                          isSelected: !_isFullPayment,
                          onTap: () => setState(() => _isFullPayment = false),
                        ),
                      ),
                    ],
                  ),
                  if (!_isFullPayment) ...[
                    const SizedBox(height: AppTheme.md),
                    AppInput(
                      label: 'Nominal DP',
                      controller: _dpAmountController,
                      hintText: 'Contoh: 20000',
                      prefixIcon: Icons.payments_outlined,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sisa tagihan bisa dilunasi nanti lewat halaman detail pesanan.',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textTertiary),
                    ),
                  ],
                ],
              ],
            ),

            const SizedBox(height: AppTheme.lg),

            AppInput(
              label: 'Catatan (Opsional)',
              controller: _notesController,
              hintText: 'Tulis catatan khusus untuk pesanan ini',
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

  /// Dropdown pilih cabang. Cuma dipanggil kalau _showLaundryDropdown
  /// true (owner punya lebih dari 1 cabang aktif).
  Widget _buildLaundryDropdown(BuildContext context) {
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
        labelText: 'Cabang *',
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
        hintText: 'Pilih cabang untuk pesanan ini',
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
          return 'Pilih cabang terlebih dahulu';
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
              child: Text('Coba lagi', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
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
          'Belum ada pelanggan. Tambahkan pelanggan dulu sebelum membuat pesanan.',
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
          'Belum ada pelanggan yang terdaftar di cabang ini. Tambahkan pelanggan baru, atau cek penempatan cabang pelanggan yang sudah ada.',
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
        labelText: 'Pelanggan *',
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
          return 'Pilih pelanggan terlebih dahulu';
        }
        return null;
      },
    );
  }

  /// Section item pesanan - sekarang bagian dari _buildMainCard.
  ///
  /// Alur baru mengikuti mockup: layanan dipilih lewat kartu yang bisa
  /// di-scroll horizontal (tap kartu = 1 item baru ditambahkan), bukan
  /// lewat dialog terpisah lagi. Multi-item tetap dipertahankan penuh -
  /// bisa tap kartu yang sama atau kartu berbeda berkali-kali - hanya
  /// bentuk pemilihannya yang berubah jadi kartu, sesuai desain baru.
  ///
  /// Tiap item yang sudah ditambahkan ditampilkan sebagai kartu
  /// (border + shadow tipis) alih-alih row polos. Logic kontrol per
  /// item TIDAK berubah: item perKg tetap pakai input berat (TextField
  /// desimal, kg), item perItem tetap pakai stepper qty (+/-).
  Widget _buildOrderItemsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Jenis Layanan'),
        _buildServicePicker(context),
        const SizedBox(height: AppTheme.lg),
        Text(
          'Item Pesanan',
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
              'Belum ada item. Ketuk salah satu layanan di atas untuk menambahkannya.',
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
                              ? '${_formatCurrency(item.price)} / kg'
                              : '${_formatCurrency(item.price)} / item',
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
              child: Text('Coba lagi', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
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
          'Belum ada layanan aktif. Tambahkan layanan dulu di menu Layanan sebelum membuat pesanan.',
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
                    'Sedang Menyimpan...',
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
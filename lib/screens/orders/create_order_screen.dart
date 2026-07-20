import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/themes/app_theme.dart';
import '../../widgets/common/app_input.dart';
import '../../models/service.dart';
import '../../models/order.dart';
import '../../repositories/service_repository.dart';
import '../../repositories/order_repository.dart';

/// Order Item Form Model (UI-only, dikonversi ke OrderItem domain model
/// pas save)
class OrderItemForm {
  final String id;
  final String name;
  int quantity;
  double price;

  OrderItemForm({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
  });

  double get subtotal => quantity * price;
}

/// Opsi pelanggan buat dropdown, di-fetch dari
/// users/{uid}/customers
class _CustomerOption {
  final String id;
  final String name;
  final String phone;

  _CustomerOption({required this.id, required this.name, required this.phone});

  factory _CustomerOption.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return _CustomerOption(
      id: doc.id,
      name: (data['full_name'] ?? '') as String,
      phone: (data['phone'] ?? '') as String,
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
  // NOTE: cabang di-auto-pick (cabang pertama milik company) karena
  // CreateOrderScreen belum punya UI pilih cabang. Kalau NetWash sudah
  // multi-cabang, ini perlu diganti jadi dropdown.
  String? _companyId;
  String? _laundryId;
  bool _isLoadingBusinessContext = true;
  String? _businessContextError;

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
    super.dispose();
  }

  /// Ambil company_id (dari companies pertama) & laundry_id (cabang
  /// pertama milik company itu), dibutuhkan OrderRepository.createOrder()
  /// buat generate order_number.
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
          .limit(1)
          .get();
      if (laundriesSnap.docs.isEmpty) {
        throw 'Belum ada cabang laundry. Tambahkan cabang dulu sebelum membuat pesanan.';
      }

      setState(() {
        _companyId = companyId;
        _laundryId = laundriesSnap.docs.first.id;
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
              quantity: 1,
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

  void _addOrderItem() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
            title: Text(
              'Pilih Layanan',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: _buildServiceDialogContent(context, setDialogState),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Tutup', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildServiceDialogContent(BuildContext context, StateSetter setDialogState) {
    if (_isLoadingServices) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_servicesError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 32, color: AppTheme.errorColor),
            const SizedBox(height: AppTheme.sm),
            Text(
              _servicesError!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.errorColor),
            ),
            const SizedBox(height: AppTheme.sm),
            TextButton(
              onPressed: () async {
                await _fetchServices();
                setDialogState(() {});
              },
              child: Text('Coba lagi', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    if (_services.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Belum ada layanan aktif. Tambahkan layanan dulu di menu Layanan sebelum membuat pesanan.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final service = _services[index];
        return ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          title: Text(
            service.name,
            style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
          ),
          subtitle: Text(
            _servicePriceLabel(service),
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
          ),
          onTap: () {
            setState(() {
              _orderItems.add(
                OrderItemForm(
                  id: service.id,
                  name: service.name,
                  quantity: 1,
                  price: _servicePrice(service),
                ),
              );
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _removeOrderItem(int index) {
    setState(() {
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

    if (_orderItems.isEmpty) {
      _showError('Tambahkan minimal 1 item pesanan');
      return;
    }

    if (_companyId == null || _laundryId == null) {
      _showError(_businessContextError ?? 'Data perusahaan/cabang belum siap. Coba lagi sebentar.');
      return;
    }

    final totalItems = _orderItems.fold<int>(0, (sum, item) => sum + item.quantity);
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

      final selectedCustomer = _customers.firstWhere((c) => c.id == _selectedCustomerId);

      final PaymentStatus paymentStatus = paidNow <= 0
          ? PaymentStatus.pending
          : (paidNow >= totalAmount - 1 ? PaymentStatus.paid : PaymentStatus.partial);

    final order = Order(
      id: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      companyId: _companyId!,
      laundryId: _laundryId!,
      customerId: selectedCustomer.id,
      customerName: selectedCustomer.name,
      customerPhone: selectedCustomer.phone,
      orderNumber: '', // di-generate OrderRepository
      items: _orderItems
          .map((item) => OrderItem(
                serviceTypeId: item.id,
                serviceName: item.name,
                quantity: item.quantity,
                weight: 0,
                pricePerUnit: item.price,
                totalPrice: item.subtotal,
              ))
          .toList(),
      totalWeight: 0,
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
      priorityLevel: PriorityLevel.normal, // ⬅️ TAMBAHIN INI
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
      backgroundColor: AppTheme.backgroundColor,
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
                        const SizedBox(height: AppTheme.xl),
                        _buildProgressIndicator(context),
                        const SizedBox(height: AppTheme.xxl),
                        _buildHeader(context),
                        const SizedBox(height: AppTheme.xxl),
                        _buildForm(context),
                        const SizedBox(height: AppTheme.xxl),
                        _buildOrderItemsSection(context),
                        const SizedBox(height: AppTheme.xxl),
                        _buildPriceSummary(context),
                        const SizedBox(height: AppTheme.xxl),
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

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context, false),
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
        const SizedBox(width: 14),
        Text(
          'Buat Pesanan Baru',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 6,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.sm),
            Expanded(
              flex: 1,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.md),
        Text(
          'Step 1 dari 2',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.lg),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: Icon(
            Icons.add_circle_outline_rounded,
            color: AppTheme.primaryColor,
            size: 34,
          ),
        ),
        const SizedBox(height: AppTheme.xl),
        Text(
          'Pesanan Baru',
          style: GoogleFonts.poppins(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.sm),
        Text(
          'Buat dan kelola pesanan laundry baru',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
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
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: AppTheme.md, horizontal: AppTheme.sm),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor.withOpacity(0.1)
                                    : AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                border: Border.all(
                                  color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    method['icon'],
                                    size: 20,
                                    color: isSelected ? AppTheme.primaryColor : AppTheme.textTertiary,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    method['label'],
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
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
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOptionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: AppTheme.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.md, horizontal: AppTheme.sm),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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

    if (_customers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.md),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Text(
          'Belum ada pelanggan. Tambahkan pelanggan dulu sebelum membuat pesanan.',
          style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textSecondary),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedCustomerId,
      onChanged: (value) => setState(() => _selectedCustomerId = value),
      style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
      isExpanded: true,
      items: _customers
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
        hintText: 'Pilih pelanggan',
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textTertiary),
        prefixIcon: Icon(Icons.person_outline, color: AppTheme.textTertiary),
        filled: true,
        fillColor: AppTheme.backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
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

  Widget _buildOrderItemsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Item Pesanan',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            ElevatedButton.icon(
              onPressed: !_isLoading ? _addOrderItem : null,
              icon: const Icon(Icons.add, size: 16),
              label: Text('Tambah Item', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.md,
                  vertical: AppTheme.sm,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.lg),
        if (_orderItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppTheme.lg),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Text(
              'Belum ada item. Tekan "Tambah Item" untuk memilih layanan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textSecondary),
            ),
          ),
        ..._orderItems.asMap().entries.map(
          (entry) {
            final index = entry.key;
            final item = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.lg),
              child: Container(
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatCurrency(item.price),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: !_isLoading ? () => _removeOrderItem(index) : null,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, size: 16, color: AppTheme.errorColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.md),
                    Divider(height: 1, color: AppTheme.borderColor.withOpacity(0.6)),
                    const SizedBox(height: AppTheme.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Jumlah',
                          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        Row(
                          children: [
                            _QuantityButton(
                              icon: Icons.remove,
                              onTap: item.quantity > 1
                                  ? () => setState(() => item.quantity--)
                                  : null,
                            ),
                            SizedBox(
                              width: 36,
                              child: Text(
                                '${item.quantity}',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
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
                        Text(
                          _formatCurrency(item.subtotal),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPriceSummary(BuildContext context) {
    final total = _calculateTotal();

    return Container(
      padding: const EdgeInsets.all(AppTheme.lg),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Harga',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textSecondary)),
              Text(
                _formatCurrency(total),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.md),
          Divider(color: AppTheme.borderColor),
          const SizedBox(height: AppTheme.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
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
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: !_isLoading ? _handleSaveOrder : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
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
                'Simpan Pesanan',
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isEnabled ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isEnabled ? AppTheme.primaryColor : AppTheme.textTertiary,
        ),
      ),
    );
  }
}
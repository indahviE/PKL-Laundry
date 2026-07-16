import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/themes/app_theme.dart';
import '../../widgets/common/app_input.dart';
import '../../models/service.dart';
import '../../repositories/service_repository.dart';

/// Order Item Form Model
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

  // Cara baju MASUK ke laundry: 'walk_in' (pelanggan taruh sendiri ke
  // counter) atau 'pickup' (dijemput driver ke lokasi pelanggan).
  String _selectedOrderType = 'walk_in';

  // Cara baju KELUAR dari laundry: 'self_pickup' (pelanggan ambil sendiri
  // ke counter) atau 'delivery' (diantar driver ke lokasi pelanggan).
  // Dua field ini yang dibaca PickupDeliveryScreen buat nentuin order mana
  // yang perlu masuk antrean jemput/antar.
  String _selectedDeliveryType = 'self_pickup';

  List<OrderItemForm> _orderItems = [];
  List<_CustomerOption> _customers = [];

  // Jenis layanan sekarang di-fetch dari users/{uid}/service_types
  // lewat ServiceRepository (sumber yang sama dipakai ServicesListScreen),
  // supaya perubahan CRUD layanan di sana langsung kepakai di sini juga.
  late final ServiceRepository _serviceRepository;
  List<Service> _services = [];

  late final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'cash', 'label': 'Tunai', 'icon': Icons.payments_outlined},
    {'id': 'transfer', 'label': 'Transfer Bank', 'icon': Icons.account_balance_outlined},
    {'id': 'credit', 'label': 'Kredit', 'icon': Icons.credit_card_outlined},
  ];

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
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _serviceRepository = ServiceRepository(userId: uid);
    _fetchCustomers();
    _fetchServices();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
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

  /// Ambil daftar layanan dari users/{uid}/service_types (via ServiceRepository).
  /// Hanya layanan aktif (is_active: true) yang ditampilkan sebagai opsi,
  /// selaras dengan soft-delete di ServicesListScreen.
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
        // Isi 1 item default dari layanan aktif pertama, kalau ada.
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

  /// Harga per unit dari sebuah Service, tergantung pricing_type-nya.
  double _servicePrice(Service service) {
    if (service.pricingType == PricingType.perKg) {
      return service.pricePerKg ?? 0;
    }
    return service.pricePerItem ?? 0;
  }

  /// Label satuan harga, buat ditampilin di dialog & kartu item.
  String _servicePriceLabel(Service service) {
    final price = _servicePrice(service);
    final suffix = service.pricingType == PricingType.perKg ? '/kg' : '/item';
    return '${_formatCurrency(price)}$suffix';
  }

  /// Handle add item -> pilih dari layanan aktif hasil fetch Firestore
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

  /// Isi dialog pilih layanan, dengan state loading/error/kosong,
  /// plus tombol coba lagi kalau fetch gagal.
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

  /// Handle remove item
  void _removeOrderItem(int index) {
    setState(() {
      _orderItems.removeAt(index);
    });
  }

  /// Generate order_number berikutnya, format ORD001, ORD002, dst
  /// berdasarkan jumlah order yang sudah ada.
  Future<String> _generateOrderNumber(CollectionReference ordersRef) async {
    final countSnapshot = await ordersRef.count().get();
    final nextNumber = (countSnapshot.count ?? 0) + 1;
    return 'ORD${nextNumber.toString().padLeft(4, '0')}';
  }

  /// Handle save order -> tulis ke Firestore: users/{uid}/orders
  /// sekalian update total_orders & total_spent di dokumen customer terkait.
  Future<void> _handleSaveOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan minimal 1 item pesanan'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'Sesi tidak ditemukan, silakan login ulang.';
      }

      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Ambil company_id dari subcollection users/{uid}/companies
      final companiesSnapshot = await userDocRef.collection('companies').limit(1).get();
      if (companiesSnapshot.docs.isEmpty) {
        throw 'Perusahaan belum diatur. Selesaikan onboarding terlebih dahulu.';
      }
      final companyId = companiesSnapshot.docs.first.id;

      final selectedCustomer = _customers.firstWhere((c) => c.id == _selectedCustomerId);

      final ordersRef = userDocRef.collection('orders');
      final orderNumber = await _generateOrderNumber(ordersRef);

      final totalItems = _orderItems.fold<int>(0, (sum, item) => sum + item.quantity);
      final subtotal = _calculateTotal();
      const discountAmount = 0.0;
      const taxAmount = 0.0;
      final totalAmount = subtotal - discountAmount + taxAmount;

      final itemsData = _orderItems
          .map((item) => {
                'service_type_id': item.id,
                'service_name': item.name,
                'quantity': item.quantity,
                'price_per_unit': item.price,
                'total_price': item.subtotal,
              })
          .toList();

      final orderDocRef = ordersRef.doc();
      final customerDocRef = userDocRef.collection('customers').doc(_selectedCustomerId);

      final batch = FirebaseFirestore.instance.batch();

      batch.set(orderDocRef, {
        'company_id': companyId,
        'customer_id': selectedCustomer.id,
        'customer_name': selectedCustomer.name,
        'customer_phone': selectedCustomer.phone,
        'order_number': orderNumber,
        'items': itemsData,
        'total_items': totalItems,
        'subtotal': subtotal,
        'discount_amount': discountAmount,
        'tax_amount': taxAmount,
        'total_amount': totalAmount,
        'status': 'pending',
        'status_history': [
          {
            'status': 'pending',
            'timestamp': Timestamp.now(),
            'note': 'Pesanan dibuat',
          }
        ],
        'order_date': FieldValue.serverTimestamp(),
        // pickup_date sengaja dibiarkan null di sini walau order_type-nya
        // 'pickup' - baru diisi PickupDeliveryScreen begitu driver beneran
        // jemput baju (lewat markPickedUp()), bukan pas order dibuat.
        'pickup_date': null,
        'actual_completion': null,
        'delivery_date': null,
        'payment_status': 'pending',
        'payment_method': _selectedPaymentMethod,
        'paid_amount': 0.0,
        'notes': _notesController.text.trim(),
        // Dua field ini yang dibaca PickupDeliveryScreen buat nentuin
        // order mana yang perlu masuk antrean jemput/antar.
        'order_type': _selectedOrderType,
        'delivery_type': _selectedDeliveryType,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      batch.update(customerDocRef, {
        'total_orders': FieldValue.increment(1),
        'total_spent': FieldValue.increment(totalAmount),
        // FIX: sebelumnya field ini gak pernah ditulis, jadi
        // CustomersListScreen selalu nganggep customer "belum pernah
        // order" walaupun total_orders-nya udah kehitung bertambah.
        'last_order_date': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Calculate total
  double _calculateTotal() {
    return _orderItems.fold(0, (sum, item) => sum + item.subtotal);
  }

  /// Format currency
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

  /// Build top bar (back button + title)
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

  /// Build Progress Indicator
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

  /// Build Header
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

  /// Build Form
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
            // Customer Dropdown
            _buildCustomerDropdown(context),

            const SizedBox(height: AppTheme.lg),

            // Cara baju masuk (walk-in / dijemput)
            _buildToggleGroup(
              label: 'Baju Masuk *',
              options: _orderTypes,
              selectedId: _selectedOrderType,
              onSelected: (id) => setState(() => _selectedOrderType = id),
            ),

            const SizedBox(height: AppTheme.lg),

            // Cara baju keluar (ambil sendiri / diantar)
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
                Row(
                  children: List.generate(_paymentMethods.length, (index) {
                    final method = _paymentMethods[index];
                    final isSelected = _selectedPaymentMethod == method['id'];
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index < _paymentMethods.length - 1 ? AppTheme.sm : 0,
                        ),
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
                      ),
                    );
                  }),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.lg),

            // Notes
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

  /// Toggle 2 opsi generik (dipakai buat Baju Masuk & Baju Keluar) - gaya
  /// tombolnya sengaja disamain dengan Metode Pembayaran biar konsisten.
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

  /// Build Customer Dropdown, dengan state loading & error &
  /// tombol "Tambah Pelanggan" kalau list-nya masih kosong.
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

  /// Build Order Items Section
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

  /// Build Price Summary
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

  /// Build Save Button
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

/// Tombol bulat kecil untuk stepper jumlah item
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
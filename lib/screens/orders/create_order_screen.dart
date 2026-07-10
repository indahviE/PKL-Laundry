import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';
import '../../widgets/common/app_input.dart';

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

/// Create Order Screen
class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({Key? key}) : super(key: key);

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  // Controllers
  late TextEditingController _customerController;
  late TextEditingController _notesController;

  // Form key
  final _formKey = GlobalKey<FormState>();

  // State
  bool _isLoading = false;
  String? _selectedCustomer;
  String? _selectedPaymentMethod = 'cash';
  List<OrderItemForm> _orderItems = [];

  // Sample data
  late final List<String> _customers = [
    'Budi Santoso',
    'Siti Nurhaliza',
    'Ahmad Wijaya',
    'Rina Gunawan',
  ];

  late final List<Map<String, dynamic>> _availableServices = [
    {'id': '1', 'name': 'Kemeja', 'price': 25000},
    {'id': '2', 'name': 'Celana Panjang', 'price': 30000},
    {'id': '3', 'name': 'Kaos', 'price': 15000},
    {'id': '4', 'name': 'Jaket', 'price': 50000},
    {'id': '5', 'name': 'Rok', 'price': 25000},
    {'id': '6', 'name': 'Dress', 'price': 40000},
  ];

  late final List<Map<String, String>> _paymentMethods = [
    {'id': 'cash', 'label': 'Tunai'},
    {'id': 'transfer', 'label': 'Transfer Bank'},
    {'id': 'credit', 'label': 'Kredit'},
  ];

  @override
  void initState() {
    super.initState();
    _customerController = TextEditingController();
    _notesController = TextEditingController();
    _orderItems = [
      OrderItemForm(
        id: '1',
        name: _availableServices[0]['name'],
        quantity: 1,
        price: _availableServices[0]['price'].toDouble(),
      ),
    ];
  }

  @override
  void dispose() {
    _customerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Handle add item
  void _addOrderItem() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Layanan'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableServices.length,
            itemBuilder: (context, index) {
              final service = _availableServices[index];
              return ListTile(
                title: Text(service['name']),
                subtitle: Text('Rp ${service['price']}'),
                onTap: () {
                  setState(() {
                    _orderItems.add(
                      OrderItemForm(
                        id: service['id'],
                        name: service['name'],
                        quantity: 1,
                        price: service['price'].toDouble(),
                      ),
                    );
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  /// Handle remove item
  void _removeOrderItem(int index) {
    setState(() {
      _orderItems.removeAt(index);
    });
  }

  /// Handle save order
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
      await Future.delayed(const Duration(seconds: 2));
      // TODO: Save order ke backend

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil dibuat! (Testing mode)'),
            backgroundColor: Color(0xFF51CF66),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? AppTheme.lg : AppTheme.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Indicator
              _buildProgressIndicator(context),

              const SizedBox(height: AppTheme.xxl),

              // Header
              _buildHeader(context),

              const SizedBox(height: AppTheme.xxl),

              // Form
              _buildForm(context),

              const SizedBox(height: AppTheme.xxl),

              // Order Items Section
              _buildOrderItemsSection(context),

              const SizedBox(height: AppTheme.xxl),

              // Price Summary
              _buildPriceSummary(context),

              const SizedBox(height: AppTheme.xxl),

              // Save Button
              _buildSaveButton(context),

              const SizedBox(height: AppTheme.lg),
            ],
          ),
        ),
      ),
    );
  }

  /// Build App Bar
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Buat Pesanan Baru'),
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
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
                  color: const Color(0xFF5DADE2),
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.md),
        Text(
          'Step 1 dari 2',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF5DADE2),
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
            color: const Color(0xFF5DADE2).withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: const Icon(
            Icons.add_circle_outlined,
            color: Color(0xFF5DADE2),
            size: 36,
          ),
        ),
        const SizedBox(height: AppTheme.xl),
        Text(
          'Pesanan Baru',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppTheme.md),
        Text(
          'Buat dan kelola pesanan laundry baru',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.gray600,
              ),
        ),
      ],
    );
  }

  /// Build Form
  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Customer Dropdown
          DropdownButtonFormField<String>(
            value: _selectedCustomer,
            onChanged: (value) => setState(() => _selectedCustomer = value),
            items: _customers
                .map((customer) => DropdownMenuItem(
                      value: customer,
                      child: Text(customer),
                    ))
                .toList(),
            decoration: InputDecoration(
              labelText: 'Pelanggan *',
              hintText: 'Pilih pelanggan',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Pilih pelanggan terlebih dahulu';
              }
              return null;
            },
          ),

          const SizedBox(height: AppTheme.lg),

          // Payment Method
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Metode Pembayaran *',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppTheme.md),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Column(
                  children: List.generate(
                    _paymentMethods.length,
                    (index) => Column(
                      children: [
                        RadioListTile<String>(
                          value: _paymentMethods[index]['id']!,
                          groupValue: _selectedPaymentMethod,
                          onChanged: (value) {
                            setState(
                              () => _selectedPaymentMethod = value,
                            );
                          },
                          title: Text(_paymentMethods[index]['label']!),
                          dense: true,
                        ),
                        if (index < _paymentMethods.length - 1)
                          const Divider(height: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.lg),

          // Notes
          AppInput(
            label: 'Catatan (Optional)',
            controller: _notesController,
            hintText: 'Tulis catatan khusus untuk pesanan ini',
            prefixIcon: Icons.note_outlined,
            maxLines: 3,
          ),
        ],
      ),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            ElevatedButton.icon(
              onPressed: !_isLoading ? _addOrderItem : null,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5DADE2),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.md,
                  vertical: AppTheme.sm,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.lg),
        ..._orderItems.asMap().entries.map(
          (entry) {
            final index = entry.key;
            final item = entry.value;

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: Colors.grey.shade200),
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.sm),
                                Text(
                                  _formatCurrency(item.price),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF5DADE2),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: !_isLoading
                                ? () => _removeOrderItem(index)
                                : null,
                            color: AppTheme.errorColor,
                          ),
                        ],
                      ),
                      const Divider(height: AppTheme.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Jumlah',
                            style: TextStyle(fontSize: 12),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: item.quantity > 1
                                    ? () {
                                        setState(
                                          () => item.quantity--,
                                        );
                                      }
                                    : null,
                                iconSize: 20,
                              ),
                              SizedBox(
                                width: 40,
                                child: TextField(
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  controller: TextEditingController(
                                    text: item.quantity.toString(),
                                  ),
                                  onChanged: (value) {
                                    setState(
                                      () {
                                        item.quantity =
                                            int.tryParse(value) ?? 1;
                                      },
                                    );
                                  },
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMd,
                                      ),
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      vertical: AppTheme.sm,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: !_isLoading
                                    ? () {
                                        setState(
                                          () => item.quantity++,
                                        );
                                      }
                                    : null,
                                iconSize: 20,
                              ),
                            ],
                          ),
                          Text(
                            _formatCurrency(item.subtotal),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5DADE2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.lg),
              ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Harga',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppTheme.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                _formatCurrency(total),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.md),
          const Divider(),
          const SizedBox(height: AppTheme.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                _formatCurrency(total),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5DADE2),
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
      child: ElevatedButton(
        onPressed: !_isLoading ? _handleSaveOrder : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5DADE2),
          padding: const EdgeInsets.symmetric(vertical: AppTheme.lg),
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
                  const Text(
                    'Sedang Menyimpan...',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : const Text(
                'Simpan Pesanan',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
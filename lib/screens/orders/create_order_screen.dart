import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  late final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'cash', 'label': 'Tunai', 'icon': Icons.payments_outlined},
    {'id': 'transfer', 'label': 'Transfer Bank', 'icon': Icons.account_balance_outlined},
    {'id': 'credit', 'label': 'Kredit', 'icon': Icons.credit_card_outlined},
  ];

  @override
  void initState() {
    super.initState();
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
    _notesController.dispose();
    super.dispose();
  }

  /// Handle add item
  void _addOrderItem() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text(
          'Pilih Layanan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableServices.length,
            itemBuilder: (context, index) {
              final service = _availableServices[index];
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                title: Text(
                  service['name'],
                  style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                ),
                subtitle: Text(
                  'Rp ${service['price']}',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                ),
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
            child: Text('Tutup', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
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
      // TODO: Save order ke backend (Firestore)

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil dibuat! (Testing mode)'),
            backgroundColor: Color(0xFF51CF66),
          ),
        );
        Navigator.pop(context, true);
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

  /// Build top bar (back button + title) — sama gayanya dengan CreateCustomerScreen
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
            DropdownButtonFormField<String>(
              value: _selectedCustomer,
              onChanged: (value) => setState(() => _selectedCustomer = value),
              style: GoogleFonts.poppins(fontSize: 13.5, color: AppTheme.textPrimary),
              items: _customers
                  .map((customer) => DropdownMenuItem(
                        value: customer,
                        child: Text(customer, style: GoogleFonts.poppins(fontSize: 13.5)),
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
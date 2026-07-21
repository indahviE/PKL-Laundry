import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/themes/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Model riwayat pesanan singkat untuk ditampilkan di detail pelanggan
class _OrderHistoryItem {
  final String id;
  final String orderNumber;
  final String status;
  final double amount;
  final int itemCount;
  final DateTime date;

  _OrderHistoryItem({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.amount,
    required this.itemCount,
    required this.date,
  });

  /// Mapping dari dokumen Firestore users/{uid}/orders/{orderId}
  factory _OrderHistoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final orderDate = data['order_date'];
    return _OrderHistoryItem(
      id: doc.id,
      orderNumber: (data['order_number'] ?? doc.id) as String,
      status: (data['status'] ?? 'pending') as String,
      amount: ((data['total_amount'] ?? 0) as num).toDouble(),
      itemCount: (data['total_items'] ?? 0) is int
          ? data['total_items'] as int
          : ((data['total_items'] ?? 0) as num).toInt(),
      date: orderDate is Timestamp ? orderDate.toDate() : DateTime.now(),
    );
  }
}

/// Model data pelanggan untuk halaman detail, di-fetch dari
/// users/{uid}/customers/{customerId}
class _CustomerDetailData {
  final String name;
  final String phone;
  final String email;
  final String address;
  final bool isActive;
  final DateTime joinDate;
  final int totalOrders;
  final double totalSpent;

  _CustomerDetailData({
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.isActive,
    required this.joinDate,
    required this.totalOrders,
    required this.totalSpent,
  });

  factory _CustomerDetailData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final createdAt = data['created_at'];
    return _CustomerDetailData(
      name: (data['full_name'] ?? '') as String,
      phone: (data['phone'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      address: (data['address'] ?? '') as String,
      isActive: (data['is_active'] ?? true) as bool,
      joinDate: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      totalOrders: (data['total_orders'] ?? 0) is int
          ? data['total_orders'] as int
          : ((data['total_orders'] ?? 0) as num).toInt(),
      totalSpent: ((data['total_spent'] ?? 0) as num).toDouble(),
    );
  }
}

/// Customer Detail Screen
/// Menerima [customerId] dari route (mis. '/customers/:customerId')
/// lalu fetch datanya dari Firestore: users/{uid}/customers/{customerId}
class CustomerDetailScreen extends StatefulWidget {
  final String customerId;

  const CustomerDetailScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  _CustomerDetailData? _customer;
  bool _isLoading = true;
  String? _errorMessage;

  // FIX: sebelumnya ini const [] yang di-hardcode kosong selamanya
  // (comment lama bilang "masih dummy, ganti nanti") — padahal
  // fitur order sudah jalan dan datanya sudah ada di Firestore.
  // Sekarang beneran di-fetch dari users/{uid}/orders lewat
  // _fetchOrderHistory().
  List<_OrderHistoryItem> _orderHistory = [];
  bool _isLoadingHistory = true;
  String? _historyErrorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCustomer();
    _fetchOrderHistory();
  }

  Future<void> _fetchCustomer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'Sesi tidak ditemukan, silakan login ulang.';
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('customers')
          .doc(widget.customerId)
          .get();

      if (!doc.exists) {
        throw 'Data pelanggan tidak ditemukan.';
      }

      setState(() {
        _customer = _CustomerDetailData.fromFirestore(doc);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Ambil riwayat pesanan customer ini dari users/{uid}/orders,
  /// filter customer_id == widget.customerId, diurutkan terbaru dulu.
  /// Catatan: query where + orderBy field berbeda butuh composite
  /// index di Firestore — kalau ada error "failed-precondition" pas
  /// jalan pertama kali, Firestore console biasanya kasih link
  /// langsung buat bikin index-nya otomatis.
  Future<void> _fetchOrderHistory() async {
    setState(() {
      _isLoadingHistory = true;
      _historyErrorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'Sesi tidak ditemukan, silakan login ulang.';
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .where('customer_id', isEqualTo: widget.customerId)
          .orderBy('order_date', descending: true)
          .limit(5)
          .get();

      setState(() {
        _orderHistory = snapshot.docs.map((d) => _OrderHistoryItem.fromFirestore(d)).toList();
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() {
        _historyErrorMessage = e.toString();
        _isLoadingHistory = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  /// Format tanggal gabung pakai locale aktif (id/en) lewat intl
  String _formatJoinDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('d MMM yyyy', locale).format(date);
  }

  String _formatOrderDate(AppLocalizations l10n, DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inHours < 24) return l10n.hoursAgoLabel(diff.inHours);
    if (diff.inDays < 7) return l10n.daysAgoLabel(diff.inDays);
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return AppTheme.primaryColor;
      case 'completed':
        return const Color(0xFF51CF66);
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'pending':
        return l10n.orderStatusPending;
      case 'processing':
        return l10n.orderStatusProcessing;
      case 'completed':
        return l10n.orderStatusCompleted;
      case 'cancelled':
        return l10n.orderStatusCancelled;
      default:
        return status;
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  /// Normalize nomor telepon Indonesia ke format internasional tanpa
  /// simbol, mis. "081234567890" atau "0812-3456-7890" -> "6281234567890"
  String _normalizePhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    digits = digits.replaceAll('+', '');
    if (digits.startsWith('0')) {
      digits = '62${digits.substring(1)}';
    } else if (!digits.startsWith('62')) {
      digits = '62$digits';
    }
    return digits;
  }

  Future<void> _openWhatsapp(BuildContext context, String phone, String customerName) async {
    final normalized = _normalizePhone(phone);
    final message = 'Halo kak $customerName!, ini Mintwash 😊 . '
        'Cucian kamu sudah selesai dan kering nih, '
        'Mau diantar ke alamat atau mau diambil sendiri ya?';

    final uri = Uri.https('wa.me', '/$normalized', {'text': message});
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                        _buildTopBar(context, l10n),
                        const SizedBox(height: AppTheme.xl),
                        if (_isLoading)
                          _buildLoadingState(context)
                        else if (_errorMessage != null)
                          _buildErrorState(context, l10n)
                        else if (_customer != null) ...[
                          _buildProfileCard(context, l10n, _customer!),
                          const SizedBox(height: AppTheme.xl),
                          _buildQuickActions(context, l10n, _customer!),
                          const SizedBox(height: AppTheme.xl),
                          _buildStatsRow(context, l10n, isMobile, _customer!),
                          const SizedBox(height: AppTheme.xl),
                          _buildContactInfo(context, l10n, _customer!),
                          const SizedBox(height: AppTheme.xl),
                          _buildOrderHistoryHeader(context, l10n),
                          const SizedBox(height: AppTheme.lg),
                          _buildOrderHistoryList(context, l10n),
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

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.xxl),
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.xxl),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: AppTheme.errorColor),
            const SizedBox(height: AppTheme.md),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: AppTheme.lg),
            TextButton(
              onPressed: _fetchCustomer,
              child: Text('Coba lagi', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  /// Build top bar (back button + title + menu)
  Widget _buildTopBar(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
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
            const SizedBox(width: 14),
            Text(
              l10n.customerDetailTitle,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        if (_customer != null)
          Container(
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
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: AppTheme.textPrimary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  context.push('/customers/${widget.customerId}/edit');
                } else if (value == 'delete') {
                  _showDeleteConfirmation(context, l10n);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: AppTheme.textPrimary),
                      const SizedBox(width: 10),
                      Text(l10n.editCustomerMenuItem, style: GoogleFonts.poppins(fontSize: 13.5)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      const SizedBox(width: 10),
                      Text(l10n.deleteCustomerMenuItem,
                          style: GoogleFonts.poppins(color: Colors.red, fontSize: 13.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text(l10n.deleteCustomerConfirmTitle, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          l10n.deleteCustomerConfirmContent(_customer?.name ?? ''),
          style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel,
                style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('customers')
                      .doc(widget.customerId)
                      .delete();
                }
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.deleteCustomerSuccessTesting)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor),
                  );
                }
              }
            },
            child: Text(l10n.deleteButton,
                style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// Build profile card
  Widget _buildProfileCard(BuildContext context, AppLocalizations l10n, _CustomerDetailData customer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.xl),
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
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
            child: Text(
              _getInitials(customer.name),
              style: GoogleFonts.poppins(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.md),
          Text(
            customer.name,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.joinedSinceLabel(_formatJoinDate(context, customer.joinDate)),
            style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textTertiary),
          ),
          const SizedBox(height: AppTheme.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: 6),
            decoration: BoxDecoration(
              color: (customer.isActive ? const Color(0xFF51CF66) : Colors.grey).withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Text(
              customer.isActive ? l10n.activeCustomerLabel : l10n.customerInactiveLabel,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: customer.isActive ? const Color(0xFF51CF66) : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build quick contact action (WhatsApp)
  Widget _buildQuickActions(BuildContext context, AppLocalizations l10n, _CustomerDetailData customer) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _openWhatsapp(context, customer.phone, customer.name),
        icon: const Icon(Icons.chat_outlined, size: 18),
        label: Text(l10n.whatsappButton, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13.5)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF51CF66),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
        ),
      ),
    );
  }

  /// Build stats row
  Widget _buildStatsRow(BuildContext context, AppLocalizations l10n, bool isMobile, _CustomerDetailData customer) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.receipt_long_outlined,
            label: l10n.totalOrdersLabel,
            value: '${customer.totalOrders}',
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: AppTheme.lg),
        Expanded(
          child: _StatTile(
            icon: Icons.payments_outlined,
            label: l10n.totalSpentLabel,
            value: _formatCurrency(customer.totalSpent),
            color: const Color(0xFF51CF66),
          ),
        ),
      ],
    );
  }

  /// Build contact info section
  Widget _buildContactInfo(BuildContext context, AppLocalizations l10n, _CustomerDetailData customer) {
    return Container(
      width: double.infinity,
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
            l10n.contactInfoTitle,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.lg),
          _ContactRow(icon: Icons.phone_outlined, label: l10n.phoneLabel, value: customer.phone),
          const SizedBox(height: AppTheme.md),
          _ContactRow(icon: Icons.mail_outline_rounded, label: l10n.emailLabel, value: customer.email),
          const SizedBox(height: AppTheme.md),
          _ContactRow(icon: Icons.location_on_outlined, label: l10n.addressLabel, value: customer.address),
        ],
      ),
    );
  }

  Widget _buildOrderHistoryHeader(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.orderHistoryTitle,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.viewAllOrdersComingSoon)),
            );
          },
          child: Text(
            l10n.viewAllLabel,
            style: GoogleFonts.poppins(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderHistoryList(BuildContext context, AppLocalizations l10n) {
    if (_isLoadingHistory) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.xl),
        alignment: Alignment.center,
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
        ),
      );
    }

    if (_historyErrorMessage != null) {
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
                _historyErrorMessage!,
                style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.errorColor),
              ),
            ),
            TextButton(
              onPressed: _fetchOrderHistory,
              child: Text('Coba lagi', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    if (_orderHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.xl),
        alignment: Alignment.center,
        child: Text(
          l10n.noOrderHistoryLabel,
          style: GoogleFonts.poppins(color: AppTheme.textTertiary),
        ),
      );
    }

    return Column(
      children: _orderHistory.map((order) {
        final statusColor = _getStatusColor(order.status);
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.md),
          padding: const EdgeInsets.all(AppTheme.md),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(order.orderNumber,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary)),
                        const SizedBox(width: 6),
                        Text(
                          l10n.orderItemCountLabel(order.itemCount),
                          style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.textTertiary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatOrderDate(l10n, order.date),
                      style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.textTertiary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusLabel(l10n, order.status),
                  style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: statusColor),
                ),
              ),
              const SizedBox(width: AppTheme.md),
              Text(
                _formatCurrency(order.amount),
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ============================================
// HELPER WIDGETS
// ============================================

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
          Container(
            padding: const EdgeInsets.all(AppTheme.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppTheme.md),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textTertiary),
        const SizedBox(width: AppTheme.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.textTertiary)),
              const SizedBox(height: 2),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 13.5, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}
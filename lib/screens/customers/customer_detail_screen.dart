 import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';

/// Model riwayat pesanan singkat untuk ditampilkan di detail pelanggan
class _OrderHistoryItem {
  final String id;
  final String status;
  final double amount;
  final int itemCount;
  final DateTime date;

  _OrderHistoryItem({
    required this.id,
    required this.status,
    required this.amount,
    required this.itemCount,
    required this.date,
  });
}

/// Customer Detail Screen
/// Menerima [customerId] dari route (mis. '/customers/:customerId').
/// Data di bawah ini masih dummy — ganti dengan fetch Firestore
/// berdasarkan customerId begitu backend-nya siap.
class CustomerDetailScreen extends StatelessWidget {
  final String customerId;

  const CustomerDetailScreen({Key? key, required this.customerId}) : super(key: key);

  // ============================================
  // DUMMY DATA (ganti dengan fetch Firestore nanti)
  // ============================================
  String get _name => 'Budi Santoso';
  String get _phone => '081234567890';
  String get _email => 'budi.santoso@email.com';
  String get _address => 'Jl. Merdeka No. 45, Bandung';
  bool get _isActive => true;
  DateTime get _joinDate => DateTime.now().subtract(const Duration(days: 210));
  int get _totalOrders => 24;
  double get _totalSpent => 3600000;

  List<_OrderHistoryItem> get _orderHistory => [
        _OrderHistoryItem(
          id: '#ORD-12345',
          status: 'processing',
          amount: 150000,
          itemCount: 5,
          date: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        _OrderHistoryItem(
          id: '#ORD-12290',
          status: 'completed',
          amount: 120000,
          itemCount: 4,
          date: DateTime.now().subtract(const Duration(days: 6)),
        ),
        _OrderHistoryItem(
          id: '#ORD-12180',
          status: 'completed',
          amount: 200000,
          itemCount: 7,
          date: DateTime.now().subtract(const Duration(days: 15)),
        ),
      ];

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  String _formatJoinDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatOrderDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return const Color(0xFF5DADE2);
      case 'completed':
        return const Color(0xFF51CF66);
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'processing':
        return 'Diproses';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
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
              // Profile card
              _buildProfileCard(context),

              const SizedBox(height: AppTheme.xl),

              // Quick contact actions
              _buildQuickActions(context),

              const SizedBox(height: AppTheme.xl),

              // Stats row
              _buildStatsRow(context, isMobile),

              const SizedBox(height: AppTheme.xl),

              // Contact info
              _buildContactInfo(context),

              const SizedBox(height: AppTheme.xl),

              // Order history
              _buildOrderHistoryHeader(context),
              const SizedBox(height: AppTheme.lg),
              _buildOrderHistoryList(context),

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
      title: const Text('Detail Pelanggan'),
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigasi ke Edit Pelanggan akan ditambahkan')),
              );
            } else if (value == 'delete') {
              _showDeleteConfirmation(context);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 10),
                  Text('Edit Pelanggan'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  SizedBox(width: 10),
                  Text('Hapus Pelanggan', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: const Text('Hapus Pelanggan?'),
        content: Text('Data pelanggan "$_name" akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pelanggan berhasil dihapus (Testing mode)')),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Build profile card
  Widget _buildProfileCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: const Color(0xFF5DADE2).withOpacity(0.15),
            child: Text(
              _getInitials(_name),
              style: const TextStyle(
                color: Color(0xFF5DADE2),
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.md),
          Text(
            _name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Bergabung sejak ${_formatJoinDate(_joinDate)}',
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
          ),
          const SizedBox(height: AppTheme.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: 6),
            decoration: BoxDecoration(
              color: (_isActive ? const Color(0xFF51CF66) : Colors.grey).withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Text(
              _isActive ? 'Pelanggan Aktif' : 'Tidak Aktif',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _isActive ? const Color(0xFF51CF66) : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build quick contact actions (telepon & WhatsApp)
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Membuka aplikasi telepon...')),
              );
            },
            icon: const Icon(Icons.call_outlined, size: 18),
            label: const Text('Telepon'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
              foregroundColor: const Color(0xFF5DADE2),
              side: const BorderSide(color: Color(0xFF5DADE2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.md),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Membuka WhatsApp...')),
              );
            },
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: const Text('WhatsApp'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF51CF66),
              padding: const EdgeInsets.symmetric(vertical: AppTheme.md),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
            ),
          ),
        ),
      ],
    );
  }

  /// Build stats row
  Widget _buildStatsRow(BuildContext context, bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.receipt_long_outlined,
            label: 'Total Pesanan',
            value: '$_totalOrders',
            color: const Color(0xFF5DADE2),
          ),
        ),
        const SizedBox(width: AppTheme.lg),
        Expanded(
          child: _StatTile(
            icon: Icons.payments_outlined,
            label: 'Total Belanja',
            value: _formatCurrency(_totalSpent),
            color: const Color(0xFF51CF66),
          ),
        ),
      ],
    );
  }

  /// Build contact info section
  Widget _buildContactInfo(BuildContext context) {
    return Container(
      width: double.infinity,
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
            'Informasi Kontak',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.lg),
          _ContactRow(icon: Icons.phone_outlined, label: 'Telepon', value: _phone),
          const SizedBox(height: AppTheme.md),
          _ContactRow(icon: Icons.mail_outline_rounded, label: 'Email', value: _email),
          const SizedBox(height: AppTheme.md),
          _ContactRow(icon: Icons.location_on_outlined, label: 'Alamat', value: _address),
        ],
      ),
    );
  }

  Widget _buildOrderHistoryHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Riwayat Pesanan',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Navigasi ke semua riwayat pesanan akan ditambahkan')),
            );
          },
          child: const Text(
            'Lihat Semua',
            style: TextStyle(color: Color(0xFF5DADE2), fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderHistoryList(BuildContext context) {
    if (_orderHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.xl),
        alignment: Alignment.center,
        child: Text(
          'Belum ada riwayat pesanan',
          style: TextStyle(color: Colors.grey.shade500),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(order.id, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(width: 6),
                        Text(
                          '· ${order.itemCount} item',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatOrderDate(order.date),
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
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
                  _getStatusLabel(order.status),
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: statusColor),
                ),
              ),
              const SizedBox(width: AppTheme.md),
              Text(
                _formatCurrency(order.amount),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF5DADE2)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppTheme.md),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
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
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: AppTheme.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
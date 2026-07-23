import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/themes/app_theme.dart';
import '../models/service.dart';

/// Model form untuk 1 item pesanan (UI-only), dikonversi ke `OrderItem`
/// domain model saat disimpan. Dipakai bersama oleh CreateOrderScreen
/// (isi item pas order dibuat) dan PickupDeliveryScreen (isi item pas
/// konfirmasi jemput untuk order pickup yang dibuat kosong) - supaya
/// logika "1 item = layanan + qty/berat + subtotal" cuma ditulis sekali.
class OrderItemForm {
  final String id;
  final String name;
  final PricingType pricingType;
  int quantity;
  double weight;
  double price;

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

String formatCurrency(double amount) {
  return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}

double servicePrice(Service service) {
  return service.pricingType == PricingType.perKg ? (service.pricePerKg ?? 0) : (service.pricePerItem ?? 0);
}

String servicePriceLabel(Service service) {
  final price = servicePrice(service);
  final suffix = service.pricingType == PricingType.perKg ? '/kg' : '/item';
  return '${formatCurrency(price)}$suffix';
}

/// Tombol bulat +/- buat stepper qty item perItem. Ukuran dibikin
/// parameterizable (size) karena dua pemanggil (CreateOrderScreen &
/// PickupDeliveryScreen) pakai ukuran yang sedikit beda.
class QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  const QuantityButton({super.key, required this.icon, required this.onTap, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isEnabled ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.cardColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: size * 0.58, color: isEnabled ? AppTheme.primaryColor : AppTheme.textTertiary),
      ),
    );
  }
}

/// Dialog pilih layanan buat ditambahin sebagai item pesanan. Dipakai
/// bersama CreateOrderScreen & PickupDeliveryScreen - tap salah satu
/// layanan memanggil [onSelected], pemanggil sendiri yang tanggung
/// jawab nambahin ke list OrderItemForm-nya masing-masing (widget ini
/// gak perlu tau struktur state pemanggil).
Future<void> showServicePickerDialog(
  BuildContext context, {
  required List<Service> services,
  required bool isLoading,
  String? error,
  VoidCallback? onRetry,
  required ValueChanged<Service> onSelected,
}) {
  return showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        title: Text('Pilih Layanan', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        content: SizedBox(
          width: double.maxFinite,
          child: _ServicePickerContent(
            services: services,
            isLoading: isLoading,
            error: error,
            onRetry: onRetry == null ? null : () { onRetry(); setDialogState(() {}); },
            onSelected: (service) {
              onSelected(service);
              Navigator.pop(dialogContext);
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('Tutup', style: GoogleFonts.poppins())),
        ],
      ),
    ),
  );
}

class _ServicePickerContent extends StatelessWidget {
  final List<Service> services;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final ValueChanged<Service> onSelected;

  const _ServicePickerContent({
    required this.services,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 32, color: AppTheme.errorColor),
            const SizedBox(height: AppTheme.sm),
            Text(error!, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.errorColor)),
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.sm),
              TextButton(
                onPressed: onRetry,
                child: Text('Coba lagi', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      );
    }

    if (services.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Belum ada layanan aktif. Tambahkan layanan dulu di menu Layanan.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          title: Text(service.name, style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
          subtitle: Text(servicePriceLabel(service), style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
          onTap: () => onSelected(service),
        );
      },
    );
  }
}

/// List item pesanan (nama, subtotal, tombol hapus, input berat/kg atau
/// stepper qty) - dipakai bersama CreateOrderScreen & PickupDeliveryScreen.
/// Widget ini baca-tulis langsung ke field mutable OrderItemForm yang
/// di-passing; pemanggil wajib panggil [onItemChanged] tiap ada
/// perubahan supaya bisa setState dan subtotal ke-refresh di parent.
class OrderItemsList extends StatelessWidget {
  final List<OrderItemForm> items;
  final bool enabled;
  final ValueChanged<int> onRemove;
  final VoidCallback onItemChanged;
  final double quantityButtonSize;

  const OrderItemsList({
    super.key,
    required this.items,
    required this.enabled,
    required this.onRemove,
    required this.onItemChanged,
    this.quantityButtonSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.md),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Text(
          'Belum ada item. Tekan "Tambah" untuk memilih layanan.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 12.5, color: AppTheme.textSecondary),
        ),
      );
    }

    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == items.length - 1;
        final isPerKg = item.pricingType == PricingType.perKg;

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : AppTheme.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.sm, horizontal: AppTheme.md),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary),
                      ),
                    ),
                    const SizedBox(width: AppTheme.sm),
                    Text(
                      formatCurrency(item.subtotal),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppTheme.primaryColor),
                    ),
                    InkWell(
                      onTap: enabled ? () => onRemove(index) : null,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(Icons.close, size: 16, color: AppTheme.textTertiary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isPerKg ? '${formatCurrency(item.price)} / kg' : '${formatCurrency(item.price)} / item',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textTertiary),
                    ),
                    isPerKg
                        ? SizedBox(
                            width: 92,
                            height: 34,
                            child: TextField(
                              controller: item.weightController,
                              enabled: enabled,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                              decoration: InputDecoration(
                                isDense: true,
                                suffixText: 'kg',
                                suffixStyle: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textTertiary),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                filled: true,
                                fillColor: AppTheme.cardColor,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.borderColor)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.borderColor)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5)),
                              ),
                              onChanged: (val) {
                                final parsed = double.tryParse(val.replaceAll(',', '.'));
                                item.weight = parsed ?? 0;
                                onItemChanged();
                              },
                            ),
                          )
                        : Row(
                            children: [
                              QuantityButton(
                                icon: Icons.remove,
                                size: quantityButtonSize,
                                onTap: item.quantity > 1 ? () { item.quantity--; onItemChanged(); } : null,
                              ),
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '${item.quantity}',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                ),
                              ),
                              QuantityButton(
                                icon: Icons.add,
                                size: quantityButtonSize,
                                onTap: enabled ? () { item.quantity++; onItemChanged(); } : null,
                              ),
                            ],
                          ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
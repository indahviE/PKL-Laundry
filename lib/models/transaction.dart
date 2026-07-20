import 'base_model.dart';
import 'order.dart';

enum TransactionType {
  orderPayment,
  refund,
}

/// 1 entri histori pembayaran untuk sebuah order — bisa DP, pelunasan,
/// atau refund. Disimpan di users/{uid}/transactions (top-level collection,
/// sejajar dengan orders/), dengan `order_id` sebagai referensi balik ke
/// order-nya. Satu order bisa punya banyak dokumen transaction (DP hari
/// ini, pelunasan minggu depan, dst).
class PaymentTransaction extends BaseModel {
  final String orderId;
  final double amount;
  final PaymentMethod method;
  final TransactionType type;
  final String? note;
  /// Opsional: id staff/employee yang mencatat pembayaran ini.
  final String? recordedBy;

  PaymentTransaction({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.orderId,
    required this.amount,
    required this.method,
    required this.type,
    this.note,
    this.recordedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'amount': amount,
      'method': method.name,
      'type': type.name,
      'note': note,
      'recorded_by': recordedBy,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory PaymentTransaction.fromJson(Map<String, dynamic> json, String documentId) {
    return PaymentTransaction(
      id: documentId,
      createdAt: dateTimeFromSnapshot(json['created_at']),
      updatedAt: dateTimeFromSnapshot(json['updated_at']),
      orderId: json['order_id'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => PaymentMethod.cash,
      ),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.orderPayment,
      ),
      note: json['note'],
      recordedBy: json['recorded_by'],
    );
  }
}
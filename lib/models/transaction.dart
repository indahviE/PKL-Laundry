import 'base_model.dart';

class Transaction extends BaseModel {
  final String companyId;
  final String orderId;
  final double amount;
  final String transactionType; 
  final String paymentMethod; 
  final String status; 

  Transaction({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.companyId,
    required this.orderId,
    required this.amount,
    required this.transactionType,
    required this.paymentMethod,
    required this.status,
  });

  factory Transaction.fromJson(Map<String, dynamic> json, String documentId) {
    return Transaction(
      id: documentId,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      companyId: json['company_id'] ?? '',
      orderId: json['order_id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      transactionType: json['transaction_type'] ?? 'order_payment',
      paymentMethod: json['payment_method'] ?? 'cash',
      status: json['status'] ?? 'succeeded',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_id': companyId,
      'order_id': orderId,
      'amount': amount,
      'transaction_type': transactionType,
      'payment_method': paymentMethod,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
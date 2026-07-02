// lib/models/transaction.dart
class LaundryTransaction {
  final String id;
  final String companyId;
  final String orderId;
  final double amount;
  final String transactionType; 
  final String paymentMethod; 
  final String status; 
  final String createdAt;

  LaundryTransaction({
    required this.id,
    required this.companyId,
    required this.orderId,
    required this.amount,
    required this.transactionType,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  factory LaundryTransaction.fromJson(Map<String, dynamic> json, String documentId) {
    return LaundryTransaction(
      id: documentId,
      companyId: json['company_id'] ?? '',
      orderId: json['order_id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      transactionType: json['transaction_type'] ?? 'order_payment',
      paymentMethod: json['payment_method'] ?? 'cash',
      status: json['status'] ?? 'succeeded',
      createdAt: json['created_at'] ?? '',
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
      'created_at': createdAt,
    };
  }
}
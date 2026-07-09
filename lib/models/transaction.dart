import 'base_model.dart';
 
class Transaction extends BaseModel {
  final String companyId;
  final String? orderId;
  final String? subscriptionId;
  final String? stripePaymentIntentId;
  final double amount;
  final String currency;
  final String transactionType; // order_payment, subscription_payment, refund
  final String paymentMethod;
  final String status; // pending, processing, succeeded, failed, canceled, refunded
  final Map<String, dynamic> metadata;
  final String? notes;
  final String? processedBy;
 
  Transaction({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.companyId,
    this.orderId,
    this.subscriptionId,
    this.stripePaymentIntentId,
    required this.amount,
    this.currency = 'IDR',
    required this.transactionType,
    required this.paymentMethod,
    required this.status,
    this.metadata = const {},
    this.notes,
    this.processedBy,
  });
 
  factory Transaction.fromJson(Map<String, dynamic> json, String documentId) {
    return Transaction(
      id: documentId,
      createdAt: dateTimeFromSnapshot(json['created_at']),
      updatedAt: dateTimeFromSnapshot(json['updated_at']),
      companyId: json['company_id'] ?? '',
      orderId: json['order_id'],
      subscriptionId: json['subscription_id'],
      stripePaymentIntentId: json['stripe_payment_intent_id'],
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'IDR',
      transactionType: json['transaction_type'] ?? 'order_payment',
      paymentMethod: json['payment_method'] ?? 'cash',
      status: json['status'] ?? 'succeeded',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      notes: json['notes'],
      processedBy: json['processed_by'],
    );
  }
 
  @override
  Map<String, dynamic> toJson() {
    return {
      'company_id': companyId,
      'order_id': orderId,
      'subscription_id': subscriptionId,
      'stripe_payment_intent_id': stripePaymentIntentId,
      'amount': amount,
      'currency': currency,
      'transaction_type': transactionType,
      'payment_method': paymentMethod,
      'status': status,
      'metadata': metadata,
      'notes': notes,
      'processed_by': processedBy,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
 
// lib/models/order.dart
class Order {
  final String id;
  final String companyId;
  final String laundryId;
  final String customerId;
  final String orderNumber;
  final String serviceId;
  final double weightOrQuantity;
  final double totalPrice;
  final String status; 
  final String paymentStatus; 
  final String paymentMethod; 
  final String createdAt;
  final String completedAt;

  Order({
    required this.id,
    required this.companyId,
    required this.laundryId,
    required this.customerId,
    required this.orderNumber,
    required this.serviceId,
    required this.weightOrQuantity,
    required this.totalPrice,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.createdAt,
    required this.completedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json, String documentId) {
    return Order(
      id: documentId,
      companyId: json['company_id'] ?? '',
      laundryId: json['laundry_id'] ?? '',
      customerId: json['customer_id'] ?? '',
      orderNumber: json['order_number'] ?? '',
      serviceId: json['service_id'] ?? '',
      weightOrQuantity: (json['weight_or_quantity'] ?? 0).toDouble(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      status: json['status'] ?? 'received',
      paymentStatus: json['payment_status'] ?? 'unpaid',
      paymentMethod: json['payment_method'] ?? 'cash',
      createdAt: json['created_at'] ?? '',
      completedAt: json['completed_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_id': companyId,
      'laundry_id': laundryId,
      'customer_id': customerId,
      'order_number': orderNumber,
      'service_id': serviceId,
      'weight_or_quantity': weightOrQuantity,
      'total_price': totalPrice,
      'status': status,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'created_at': createdAt,
      'completed_at': completedAt,
    };
  }
}
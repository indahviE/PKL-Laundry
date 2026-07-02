// lib/models/customer.dart
class Customer {
  final String id;
  final String fullName;
  final String phone;

  Customer({
    required this.id,
    required this.fullName,
    required this.phone,
  });

  factory Customer.fromJson(Map<String, dynamic> json, String documentId) {
    return Customer(
      id: documentId,
      fullName: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'phone': phone,
    };
  }
}
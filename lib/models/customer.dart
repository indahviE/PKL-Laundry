import 'base_model.dart';

class Customer extends BaseModel {
  final String companyId;
  final String customerCode;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String postalCode;
  final String dateOfBirth;
  final String gender;
  final String membershipType;
  final int totalOrders;
  final double totalSpent;
  final int loyaltyPoints;
  final String notes;
  final bool isActive;

  Customer({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.companyId,
    required this.customerCode,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.postalCode,
    required this.dateOfBirth,
    required this.gender,
    required this.membershipType,
    required this.totalOrders,
    required this.totalSpent,
    required this.loyaltyPoints,
    required this.notes,
    required this.isActive,
  });

  factory Customer.fromJson(Map<String, dynamic> json, String documentId) {
    return Customer(
      id: documentId,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      companyId: json['company_id'] ?? '',
      customerCode: json['customer_code'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      postalCode: json['postal_code'] ?? '',
      dateOfBirth: json['date_of_birth'] ?? '',
      gender: json['gender'] ?? '',
      membershipType: json['membership_type'] ?? 'regular',
      totalOrders: json['total_orders'] ?? 0,
      totalSpent: (json['total_spent'] ?? 0).toDouble(),
      loyaltyPoints: json['loyalty_points'] ?? 0,
      notes: json['notes'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_id': companyId,
      'customer_code': customerCode,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'postal_code': postalCode,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'membership_type': membershipType,
      'total_orders': totalOrders,
      'total_spent': totalSpent,
      'loyalty_points': loyaltyPoints,
      'notes': notes,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
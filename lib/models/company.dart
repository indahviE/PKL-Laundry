import 'base_model.dart';

class Company extends BaseModel {
  final String name;
  final String description;
  final String email;
  final String phone;
  final String address;
  final String city;
  final bool isActive;

  Company({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.name,
    required this.description,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.isActive,
  });

  factory Company.fromJson(Map<String, dynamic> json, String documentId) {
    return Company(
      id: documentId,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
import 'base_model.dart';

class Laundry extends BaseModel {
  final String companyId;
  final String name;
  final String address;
  final String phone;
  final bool isActive;

  Laundry({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.companyId,
    required this.name,
    required this.address,
    required this.phone,
    required this.isActive,
  });

  factory Laundry.fromJson(Map<String, dynamic> json, String documentId) {
    return Laundry(
      id: documentId,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      companyId: json['company_id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_id': companyId,
      'name': name,
      'address': address,
      'phone': phone,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
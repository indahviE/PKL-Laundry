import 'base_model.dart';

class Employee extends BaseModel {
  final String companyId;
  final String laundryId; 
  final String fullName;
  final String role; 
  final bool isActive;

  Employee({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.companyId,
    required this.laundryId,
    required this.fullName,
    required this.role,
    required this.isActive,
  });

  factory Employee.fromJson(Map<String, dynamic> json, String documentId) {
    return Employee(
      id: documentId,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      companyId: json['company_id'] ?? '',
      laundryId: json['laundry_id'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'cashier',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_id': companyId,
      'laundry_id': laundryId,
      'full_name': fullName,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
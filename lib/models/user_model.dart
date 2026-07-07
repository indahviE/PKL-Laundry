import 'base_model.dart';

class UserModel extends BaseModel {
  final String name;
  final String email;
  final String role; 
  final String? companyId;
  final String planId;

  UserModel({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.name,
    required this.email,
    required this.role,
    this.companyId,
    this.planId = 'starter',
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String documentId) {
    return UserModel(
      id: documentId,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'owner',
      companyId: json['company_id'],
      planId: json['plan_id'] ?? 'starter',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'company_id': companyId,
      'plan_id': planId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
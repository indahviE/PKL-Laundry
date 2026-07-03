import 'base_model.dart';

class Service extends BaseModel {
  final String companyId;
  final String name;
  final double price;
  final String unit; 
  final bool isActive;

  Service({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.companyId,
    required this.name,
    required this.price,
    required this.unit,
    required this.isActive,
  });

  factory Service.fromJson(Map<String, dynamic> json, String documentId) {
    return Service(
      id: documentId,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      companyId: json['company_id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'kilo',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_id': companyId,
      'name': name,
      'price': price,
      'unit': unit,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
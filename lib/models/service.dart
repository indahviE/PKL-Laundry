import 'base_model.dart';

enum PricingType { perKg, perItem, express }

class Service extends BaseModel {
  final String companyId;
  final String name;
  final String description;
  final double? pricePerKg;
  final double? pricePerItem;
  final PricingType pricingType;
  final int estimatedDuration; // ALWAYS in hours (canonical unit for the rest of the app)
  final String durationUnit; // 'hours' | 'days' — display unit only, used to re-populate the edit form
  final double? expressFee; // additional fee for PricingType.express
  final double? minWeight; // minimum kg for PricingType.perKg
  final List<String> branchIds; // ids of Laundry (cabang) this service is available at
  final bool isActive;
  final int sortOrder;

  Service({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.companyId,
    required this.name,
    this.description = '',
    this.pricePerKg,
    this.pricePerItem,
    required this.pricingType,
    this.estimatedDuration = 24,
    this.durationUnit = 'hours',
    this.expressFee,
    this.minWeight,
    this.branchIds = const [],
    required this.isActive,
    this.sortOrder = 0,
  });

  factory Service.fromJson(Map<String, dynamic> json, String documentId) {
    return Service(
      id: documentId,
      createdAt: dateTimeFromSnapshot(json['created_at']),
      updatedAt: dateTimeFromSnapshot(json['updated_at']),
      companyId: json['company_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      pricePerKg: json['price_per_kg'] != null
          ? (json['price_per_kg'] as num).toDouble()
          : null,
      pricePerItem: json['price_per_item'] != null
          ? (json['price_per_item'] as num).toDouble()
          : null,
      pricingType: PricingType.values.firstWhere(
        (e) => e.name == json['pricing_type'],
        orElse: () => PricingType.perKg,
      ),
      estimatedDuration: json['estimated_duration'] ?? 24,
      durationUnit: json['duration_unit'] ?? 'hours',
      expressFee: json['express_fee'] != null
          ? (json['express_fee'] as num).toDouble()
          : null,
      minWeight: json['min_weight'] != null
          ? (json['min_weight'] as num).toDouble()
          : null,
      branchIds: json['branch_ids'] != null
          ? List<String>.from(json['branch_ids'] as List)
          : const [],
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'company_id': companyId,
      'name': name,
      'description': description,
      'price_per_kg': pricePerKg,
      'price_per_item': pricePerItem,
      'pricing_type': pricingType.name,
      'estimated_duration': estimatedDuration,
      'duration_unit': durationUnit,
      'express_fee': expressFee,
      'min_weight': minWeight,
      'branch_ids': branchIds,
      'is_active': isActive,
      'sort_order': sortOrder,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
import 'base_model.dart';

class Subscription extends BaseModel {
  final String planId; // 'starter', 'professional', 'enterprise'
  final String status; // 'active', 'inactive'
  final DateTime currentPeriodEnd;

  Subscription({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.planId,
    required this.status,
    required this.currentPeriodEnd,
  });

  factory Subscription.fromJson(Map<String, dynamic> json, String documentId) {
    return Subscription(
      id: documentId,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      planId: json['plan_id'] ?? 'starter',
      status: json['status'] ?? 'inactive',
      currentPeriodEnd: json['current_period_end'] != null ? DateTime.parse(json['current_period_end']) : DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'plan_id': planId,
      'status': status,
      'current_period_end': currentPeriodEnd.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
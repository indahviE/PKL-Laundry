import 'base_model.dart';
 
/// Mirrors blueprint §3.6.2 `limits` map. -1 means unlimited, matching the
/// feature-gating logic in §3.6.3 (`if (maxLaundries == -1) return true;`).
class SubscriptionLimits {
  final int maxLaundries;
  final int maxEmployees;
  final int maxOrdersPerMonth;
 
  SubscriptionLimits({
    this.maxLaundries = 1,
    this.maxEmployees = 5,
    this.maxOrdersPerMonth = 500,
  });
 
  factory SubscriptionLimits.fromJson(Map<String, dynamic>? json) {
    if (json == null) return SubscriptionLimits();
    return SubscriptionLimits(
      maxLaundries: json['max_laundries'] ?? 1,
      maxEmployees: json['max_employees'] ?? 5,
      maxOrdersPerMonth: json['max_orders_per_month'] ?? 500,
    );
  }
 
  Map<String, dynamic> toJson() => {
        'max_laundries': maxLaundries,
        'max_employees': maxEmployees,
        'max_orders_per_month': maxOrdersPerMonth,
      };
}
 
class Subscription extends BaseModel {
  final String companyId;
  final String planId; // 'starter', 'professional', 'enterprise'
  final String planName;
  final String? stripeSubscriptionId;
  final String? stripeCustomerId;
  final String status; // trialing, active, past_due, canceled, unpaid, incomplete
  final DateTime? currentPeriodStart;
  final DateTime currentPeriodEnd;
  final DateTime? trialStart;
  final DateTime? trialEnd;
  final DateTime? canceledAt;
  final String billingCycle; // 'monthly', 'yearly'
  final List<String> features;
  final SubscriptionLimits limits;
 
  Subscription({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.companyId,
    required this.planId,
    this.planName = '',
    this.stripeSubscriptionId,
    this.stripeCustomerId,
    required this.status,
    this.currentPeriodStart,
    required this.currentPeriodEnd,
    this.trialStart,
    this.trialEnd,
    this.canceledAt,
    this.billingCycle = 'monthly',
    this.features = const [],
    SubscriptionLimits? limits,
  }) : limits = limits ?? SubscriptionLimits();
 
  factory Subscription.fromJson(Map<String, dynamic> json, String documentId) {
    return Subscription(
      id: documentId,
      createdAt: dateTimeFromSnapshot(json['created_at']),
      updatedAt: dateTimeFromSnapshot(json['updated_at']),
      companyId: json['company_id'] ?? '',
      planId: json['plan_id'] ?? 'starter',
      planName: json['plan_name'] ?? '',
      stripeSubscriptionId: json['stripe_subscription_id'],
      stripeCustomerId: json['stripe_customer_id'],
      status: json['status'] ?? 'inactive',
      currentPeriodStart: dateTimeFromSnapshotOrNull(json['current_period_start']),
      currentPeriodEnd: dateTimeFromSnapshot(json['current_period_end']),
      trialStart: dateTimeFromSnapshotOrNull(json['trial_start']),
      trialEnd: dateTimeFromSnapshotOrNull(json['trial_end']),
      canceledAt: dateTimeFromSnapshotOrNull(json['canceled_at']),
      billingCycle: json['billing_cycle'] ?? 'monthly',
      features: List<String>.from(json['features'] ?? []),
      limits: SubscriptionLimits.fromJson(json['limits']),
    );
  }
 
  @override
  Map<String, dynamic> toJson() {
    return {
      'company_id': companyId,
      'plan_id': planId,
      'plan_name': planName,
      'stripe_subscription_id': stripeSubscriptionId,
      'stripe_customer_id': stripeCustomerId,
      'status': status,
      'current_period_start': currentPeriodStart,
      'current_period_end': currentPeriodEnd,
      'trial_start': trialStart,
      'trial_end': trialEnd,
      'canceled_at': canceledAt,
      'billing_cycle': billingCycle,
      'features': features,
      'limits': limits.toJson(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
 
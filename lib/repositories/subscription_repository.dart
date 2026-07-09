import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription.dart';
import '../providers/auth_provider.dart';
class SubscriptionRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  SubscriptionRepository({required this.userId}) : _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _subscriptionsRef =>
      _firestore.collection('users').doc(userId).collection('subscriptions');

  /// Creates a new subscription record. FIX: previously this used
  /// `companyId` as the document ID and always overwrote it via
  /// SetOptions(merge: true), which means upgrading/downgrading a plan
  /// silently destroyed the history of the *previous* plan. Blueprint's
  /// schema (§3.6.2) uses an independent, auto-generated
  /// `{subscription_id}` per subscription event, same as Stripe does with
  /// each `customer.subscription.*` webhook.
  Future<Subscription> createSubscription(Subscription subscription) async {
    final docRef = _subscriptionsRef.doc();
    final now = DateTime.now();
    final newSubscription = Subscription(
      id: docRef.id,
      createdAt: now,
      updatedAt: now,
      companyId: subscription.companyId,
      planId: subscription.planId,
      planName: subscription.planName,
      stripeSubscriptionId: subscription.stripeSubscriptionId,
      stripeCustomerId: subscription.stripeCustomerId,
      status: subscription.status,
      currentPeriodStart: subscription.currentPeriodStart ?? now,
      currentPeriodEnd: subscription.currentPeriodEnd,
      trialStart: subscription.trialStart,
      trialEnd: subscription.trialEnd,
      canceledAt: subscription.canceledAt,
      billingCycle: subscription.billingCycle,
      features: subscription.features,
      limits: subscription.limits,
    );
    await docRef.set(newSubscription.toJson());
    return newSubscription;
  }

  /// The plan actually in force right now for a company: the most recent
  /// subscription with status `active` or `trialing`. Feature-gating
  /// (§3.6.3) should read from this, not from an arbitrary/oldest record.
  Stream<Subscription?> streamActiveSubscription(String companyId) {
    return _subscriptionsRef
        .where('company_id', isEqualTo: companyId)
        .where('status', whereIn: ['active', 'trialing'])
        .orderBy('created_at', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return Subscription.fromJson(doc.data(), doc.id);
    });
  }

  Stream<List<Subscription>> streamSubscriptionHistory(String companyId) {
    return _subscriptionsRef
        .where('company_id', isEqualTo: companyId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Subscription.fromJson(doc.data(), doc.id)).toList());
  }

  /// Used by the Stripe webhook handler / admin flows to reflect status
  /// changes (past_due, canceled, etc). Client apps should treat this
  /// collection as read-mostly per Security Rules (§4.5) - writes are
  /// expected to come from the Cloud Function using the Admin SDK.
  Future<void> updateSubscriptionStatus(
    String subscriptionId,
    String newStatus, {
    DateTime? currentPeriodEnd,
    DateTime? canceledAt,
  }) async {
    await _subscriptionsRef.doc(subscriptionId).update({
      'status': newStatus,
      if (currentPeriodEnd != null) 'current_period_end': currentPeriodEnd,
      if (canceledAt != null) 'canceled_at': canceledAt,
      'updated_at': DateTime.now(),
    });
  }
}

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return SubscriptionRepository(userId: userId);
});
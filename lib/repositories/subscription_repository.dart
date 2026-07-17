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

  /// Membuat data subscription baru
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

  /// FIX: Melakukan filter dan sorting di memori Dart (client-side) 
  /// untuk menghindari error "Composite Index Required" dari Firestore!
  Stream<Subscription?> streamActiveSubscription(String companyId) {
    return _subscriptionsRef
        .where('company_id', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;

      // 1. Filter data berstatus 'active' atau 'trialing' di memori
      final activeSubs = snapshot.docs
          .map((doc) => Subscription.fromJson(doc.data(), doc.id))
          .where((sub) => sub.status == 'active' || sub.status == 'trialing')
          .toList();

      if (activeSubs.isEmpty) return null;

      // 2. Urutkan berdasarkan tanggal dibuat secara descending (paling baru di awal)
      activeSubs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // 3. Ambil satu subscription teraktif yang paling baru
      return activeSubs.first;
    });
  }

  /// FIX: Pengurutan riwayat di memori untuk menghindari index crash
  Stream<List<Subscription>> streamSubscriptionHistory(String companyId) {
    return _subscriptionsRef
        .where('company_id', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Subscription.fromJson(doc.data(), doc.id))
          .toList();
      
      // Urutkan berdasarkan tanggal dibuat descending
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Update status subscription
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
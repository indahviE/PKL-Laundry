import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(FirebaseFirestore.instance);
});

class SubscriptionRepository {
  final FirebaseFirestore _firestore;

  SubscriptionRepository(this._firestore);

  CollectionReference get _subscriptionCollection => _firestore.collection('subscriptions');

  Stream<DocumentSnapshot> getSubscriptionStream(String companyId) {
    return _subscriptionCollection.doc(companyId).snapshots();
  }

  Future<void> updateSubscription({
    required String companyId,
    required String planName,
    required DateTime expiryDate,
  }) async {
    try {
      await _subscriptionCollection.doc(companyId).set({
        'planName': planName,
        'status': 'active',
        'updatedAt': DateTime.now().toIso8601String(),
        'expiryDate': expiryDate.toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Gagal memperbarui data langganan: $e');
    }
  }
}
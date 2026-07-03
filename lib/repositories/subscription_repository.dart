import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SubscriptionRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  SubscriptionRepository({required this.userId}) : _firestore = FirebaseFirestore.instance;

  CollectionReference get _subscriptionCollection => 
      _firestore.collection('users').doc(userId).collection('subscriptions');

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
        'plan_name': planName,      
        'status': 'active',
        'updated_at': DateTime.now().toIso8601String(), 
        'expiry_date': expiryDate.toIso8601String(),   
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Gagal memperbarui data langganan: $e');
    }
  }
}

final subscriptionRepositoryProvider = Provider.family<SubscriptionRepository, String>((ref, userId) {
  return SubscriptionRepository(userId: userId);
});
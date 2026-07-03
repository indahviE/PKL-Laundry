import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  DashboardRepository({required this.userId}) : _firestore = FirebaseFirestore.instance;

  Stream<int> getOrderCountByStatus(String laundryId, String status) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .where('laundry_id', isEqualTo: laundryId) // Perbaikan snake_case
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<double> getTotalRevenue(String laundryId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .where('laundry_id', isEqualTo: laundryId) 
        .where('status', isEqualTo: 'succeeded')
        .snapshots()
        .map((snapshot) {
          double total = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data();
            total += (data['amount'] ?? 0).toDouble();
          }
          return total;
        });
  }
}

final dashboardRepositoryProvider = Provider.family<DashboardRepository, String>((ref, userId) {
  return DashboardRepository(userId: userId);
});
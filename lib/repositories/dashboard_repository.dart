import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(FirebaseFirestore.instance);
});

class DashboardRepository {
  final FirebaseFirestore _firestore;

  DashboardRepository(this._firestore);

  Stream<int> getOrderCountByStatus(String laundryId, String status) {
    return _firestore
        .collection('orders')
        .where('laundryId', isEqualTo: laundryId)
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<double> getTotalRevenue(String laundryId) {
    return _firestore
        .collection('transactions')
        .where('laundryId', isEqualTo: laundryId)
        .where('status', isEqualTo: 'success')
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
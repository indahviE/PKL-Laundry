// lib/repositories/order_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';

class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createOrder(Order order) async {
    await _firestore.collection('orders').add(order.toJson());
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': newStatus,
      if (newStatus == 'completed') 'completed_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updatePaymentStatus(String orderId, String paymentStatus) async {
    await _firestore.collection('orders').doc(orderId).update({
      'payment_status': paymentStatus,
    });
  }

  Stream<List<Order>> streamOrders() {
    return _firestore.collection('orders').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Order.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});
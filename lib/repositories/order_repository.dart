import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/order.dart';

class OrderRepository {
  final FirebaseFirestore _firestore;
  final String userId; 
  OrderRepository({required this.userId}) : _firestore = FirebaseFirestore.instance;

  CollectionReference get _ordersRef =>
      _firestore.collection('users').doc(userId).collection('orders');

  Future<Order> createOrder(Order order) async {
    final docRef = _ordersRef.doc();
    final newOrder = order.copyWith(id: docRef.id);
    await docRef.set(newOrder.toJson());
    return newOrder;
  }

  Future<Order?> getOrder(String orderId) async {
    final doc = await _ordersRef.doc(orderId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Order.fromJson(doc.data() as Map<String, dynamic>, doc.id);
  }

  Stream<List<Order>> getAllOrders() {
    return _ordersRef
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Order.fromJson(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus, {String? note}) async {
    final order = await getOrder(orderId);
    if (order == null) throw Exception('Order tidak ditemukan');

    final updatedHistory = [
      ...order.statusHistory,
      StatusHistory(status: newStatus, timestamp: DateTime.now(), note: note),
    ];

    await _ordersRef.doc(orderId).update({
      'status': newStatus.name,
      'status_history': updatedHistory.map((e) => e.toJson()).toList(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
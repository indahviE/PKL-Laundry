import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
class OrderRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  OrderRepository({required this.userId}) : _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection('users').doc(userId).collection('orders');

  /// Creates a new order with an atomically-generated `order_number`.
  ///
  /// IMPORTANT: this is the CANONICAL place order numbers get generated.
  /// The `generateOrderNumber` Cloud Function is a fallback only (fires on
  /// `onCreate` and does nothing if `order_number` is already set) - having
  /// both generate numbers independently would let two different counters
  /// race and produce duplicate order numbers. If you ever remove this
  /// client-side generation, the Cloud Function's fallback logic must be
  /// promoted to the primary path.
  ///
  /// Counter path/field (`laundries/{laundryId}/order_counters/{date}` ->
  /// `sequence`) intentionally matches what the Cloud Function fallback
  /// reads, so both sides agree on where the next number comes from.
  Future<Order> createOrder(Order order) async {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyyMMdd').format(now);

    final laundryDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('laundries')
        .doc(order.laundryId)
        .get();

    if (!laundryDoc.exists) {
      throw Exception('Cabang laundry tidak ditemukan.');
    }
    final String laundryCode = laundryDoc.data()?['code'] ?? 'LOC';

    final counterRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('laundries')
        .doc(order.laundryId)
        .collection('order_counters')
        .doc(todayStr);

    return _firestore.runTransaction((transaction) async {
      final counterSnapshot = await transaction.get(counterRef);
      final currentSequence = counterSnapshot.exists
          ? ((counterSnapshot.data() as Map<String, dynamic>)['sequence'] ?? 0) as int
          : 0;
      final nextSequence = currentSequence + 1;

      transaction.set(counterRef, {
        'sequence': nextSequence,
        'updated_at': now,
      }, SetOptions(merge: true));

      final sequenceStr = nextSequence.toString().padLeft(4, '0');
      final generatedOrderNumber = '$laundryCode-$todayStr-$sequenceStr';

      final docRef = _ordersRef.doc();
      final newOrder = order.copyWith(
        id: docRef.id,
        orderNumber: generatedOrderNumber,
        createdAt: now,
        updatedAt: now,
        status: order.status,
        statusHistory: order.statusHistory.isEmpty
            ? [StatusHistory(status: order.status, timestamp: now, note: 'Pesanan dibuat')]
            : order.statusHistory,
      );

      transaction.set(docRef, newOrder.toJson());
      return newOrder;
    });
  }

  Future<Order?> getOrder(String orderId) async {
    final doc = await _ordersRef.doc(orderId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Order.fromJson(doc.data()!, doc.id);
  }

  Stream<List<Order>> getAllOrders() {
    return _ordersRef
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Order.fromJson(doc.data(), doc.id)).toList());
  }

  Stream<List<Order>> getOrdersByStatus(OrderStatus status) {
    return _ordersRef
        .where('status', isEqualTo: status.name)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Order.fromJson(doc.data(), doc.id)).toList());
  }

  Stream<List<Order>> getOrdersByCustomer(String customerId) {
    return _ordersRef
        .where('customer_id', isEqualTo: customerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Order.fromJson(doc.data(), doc.id)).toList());
  }

  /// FIX: previously wrote `updated_at` as an ISO string
  /// (`DateTime.now().toIso8601String()`), inconsistent with every other
  /// write path which now stores a raw DateTime (-> Firestore Timestamp).
  /// Also matches the Security Rule that only allows updating
  /// `['status', 'status_history', 'updated_at']` together.
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus, {String? note}) async {
    final order = await getOrder(orderId);
    if (order == null) throw Exception('Order tidak ditemukan');

    final now = DateTime.now();
    final updatedHistory = [
      ...order.statusHistory,
      StatusHistory(status: newStatus, timestamp: now, note: note),
    ];

    await _ordersRef.doc(orderId).update({
      'status': newStatus.name,
      'status_history': updatedHistory.map((e) => e.toJson()).toList(),
      'updated_at': now,
    });
  }

  /// Mirrors the Security Rule's other allowed update shape:
  /// `['payment_status', 'paid_amount', 'updated_at']`.
  Future<void> updatePaymentStatus(
    String orderId,
    PaymentStatus newStatus,
    double additionalPaidAmount,
  ) async {
    final order = await getOrder(orderId);
    if (order == null) throw Exception('Order tidak ditemukan');

    await _ordersRef.doc(orderId).update({
      'payment_status': newStatus.name,
      'paid_amount': order.paidAmount + additionalPaidAmount,
      'updated_at': DateTime.now(),
    });
  }

  Future<void> deleteOrder(String orderId) async {
    await _ordersRef.doc(orderId).delete();
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return OrderRepository(userId: userId);
});
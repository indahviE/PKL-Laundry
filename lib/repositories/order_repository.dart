import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:intl/intl.dart'; // Menghitung tanggal otomatis untuk nomor nota
import '../models/order.dart';

class OrderRepository {
  final FirebaseFirestore _firestore;
  final String userId; 
  OrderRepository({required this.userId}) : _firestore = FirebaseFirestore.instance;

  CollectionReference get _ordersRef =>
      _firestore.collection('users').doc(userId).collection('orders');

  /// FUNGSI MEMBUAT ORDER BARU DENGAN TRANSAKSI ATOMIK
  Future<Order> createOrder(Order order) async {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyyMMdd').format(now);

    // 1. Ambil kode cabang laundry (laundryCode) dari outletnya
    final laundryDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('laundries')
        .doc(order.laundryId)
        .get();
    
    final String laundryCode = laundryDoc.data()?['code'] ?? 'LOC';

    // 2. Tentukan referensi dokumen counter harian untuk outlet bersangkutan
    final counterRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('laundries')
        .doc(order.laundryId)
        .collection('order_counters')
        .doc(todayStr);

    // 3. Jalankan Transaksi Atomik ke Firestore
    return await _firestore.runTransaction((transaction) async {
      final counterSnapshot = await transaction.get(counterRef);
      int currentSequence = 0;

      if (counterSnapshot.exists && counterSnapshot.data() != null) {
        currentSequence = (counterSnapshot.data() as Map<String, dynamic>)['count'] ?? 0;
      }

      int nextSequence = currentSequence + 1;
      
      // Update data counter terbaru hari ini ke Firebase
      transaction.set(counterRef, {'count': nextSequence});

      // Format sequence menjadi 4 digit (misal: 0001, 0002)
      String sequenceStr = nextSequence.toString().padLeft(4, '0');
      
      // Susun nomor order final (Contoh: BRN-20260706-0001)
      String generatedOrderNumber = '$laundryCode-$todayStr-$sequenceStr';

      // Buat referensi ID dokumen baru di Firestore
      final docRef = _ordersRef.doc();
      
      // FIX DI SINI: Menggunakan orderCode sesuai dengan parameter fungsi copyWith di model order.dart kamu!
      final newOrder = order.copyWith(
      id: docRef.id,
      orderNumber: generatedOrderNumber,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
);

      // Eksekusi penulisan data pesanan ke Firestore
      transaction.set(docRef, newOrder.toJson());
      
      return newOrder;
    });
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
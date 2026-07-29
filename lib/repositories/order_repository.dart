import 'package:cloud_firestore/cloud_firestore.dart' hide Order, Transaction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../models/transaction.dart';
import '../providers/auth_provider.dart';

class OrderRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  OrderRepository({required this.userId}) : _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection('users').doc(userId).collection('orders');

  CollectionReference<Map<String, dynamic>> get _transactionsRef =>
      _firestore.collection('users').doc(userId).collection('transactions');

  CollectionReference<Map<String, dynamic>> get _customersRef =>
      _firestore.collection('users').doc(userId).collection('customers');

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
  ///
  /// UPDATED: sekarang dalam transaction yang sama juga (1) meng-increment
  /// statistik pelanggan (`total_orders`, `total_spent`, `last_order_date`)
  /// - dulu dilakukan lewat WriteBatch terpisah langsung di
  /// CreateOrderScreen - dan (2) mencatat 1 dokumen transactions/ kalau
  /// order ini sudah ada pembayaran sejak dibuat (paidAmount > 0), supaya
  /// histori pembayaran selalu lengkap dari order pertama kali dibuat.
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

    final customerRef = _customersRef.doc(order.customerId);

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

      transaction.update(customerRef, {
        'total_orders': FieldValue.increment(1),
        'total_spent': FieldValue.increment(newOrder.totalAmount),
        'last_order_date': now,
        'updated_at': now,
      });

      // Kalau sudah bayar (lunas atau DP) sejak order dibuat, catat sebagai
      // transaksi pertama supaya konsisten dengan pembayaran susulan lewat
      // recordPayment().
      if (newOrder.paidAmount > 0) {
        final transactionRef = _transactionsRef.doc();
        transaction.set(transactionRef, {
          'order_id': docRef.id,
          'amount': newOrder.paidAmount,
          'method': newOrder.paymentMethod?.name ?? PaymentMethod.cash.name,
          'type': TransactionType.orderPayment.name,
          'note': 'Pembayaran saat pesanan dibuat',
          'recorded_by': null,
          'created_at': now,
          'updated_at': now,
        });
      }

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

  Stream<List<Order>> getLogisticsOrders() {
    return getAllOrders().map(
      (orders) => orders.where((o) => o.needsPickup || o.needsDelivery).toList(),
    );
  }

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

  /// Mencatat pembayaran baru untuk order yang sudah ada (pelunasan DP,
  /// konfirmasi transfer manual, dst). Menulis 1 dokumen ke transactions/
  /// SEKALIGUS meng-update paid_amount & payment_status di order - dua-duanya
  /// dalam 1 Firestore transaction, jadi tidak akan pernah salah satu
  /// berhasil sementara yang lain gagal (menggantikan updatePaymentStatus
  /// lama yang baca-lalu-update terpisah, tidak atomic).
  ///
  /// Melempar Exception kalau amount <= 0 atau bikin paidAmount melebihi
  /// totalAmount (overpay).
  Future<void> recordPayment(
    String orderId, {
    required double amount,
    required PaymentMethod method,
    String? note,
    String? recordedBy,
  }) async {
    if (amount <= 0) {
      throw Exception('Nominal pembayaran harus lebih dari Rp0.');
    }

    final orderRef = _ordersRef.doc(orderId);
    final transactionRef = _transactionsRef.doc();

    await _firestore.runTransaction((txn) async {
      final orderSnap = await txn.get(orderRef);
      if (!orderSnap.exists) throw Exception('Order tidak ditemukan.');

      final order = Order.fromJson(orderSnap.data() as Map<String, dynamic>, orderSnap.id);
      final newPaidAmount = order.paidAmount + amount;

      // Guard overpay, toleransi Rp1 buat pembulatan double.
      if (newPaidAmount > order.totalAmount + 1) {
        throw Exception(
          'Nominal melebihi sisa tagihan (sisa: Rp${order.remainingAmount.toStringAsFixed(0)}).',
        );
      }

      final newStatus = newPaidAmount >= order.totalAmount - 1
          ? PaymentStatus.paid
          : PaymentStatus.partial;

      final now = DateTime.now();

      txn.set(transactionRef, {
        'order_id': orderId,
        'amount': amount,
        'method': method.name,
        'type': TransactionType.orderPayment.name,
        'note': note,
        'recorded_by': recordedBy,
        'created_at': now,
        'updated_at': now,
      });

      txn.update(orderRef, {
        'payment_status': newStatus.name,
        'payment_method': method.name,
        'paid_amount': newPaidAmount,
        'updated_at': now,
      });
    });
  }

  /// Histori pembayaran (DP + pelunasan) untuk 1 order, terbaru duluan.
  Stream<List<PaymentTransaction>> getPaymentsForOrder(String orderId) {
    return _transactionsRef
        .where('order_id', isEqualTo: orderId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => PaymentTransaction.fromJson(d.data(), d.id)).toList());
  }

  Future<void> markPickedUp(String orderId, {String? driverNote}) async {
    await _ordersRef.doc(orderId).update({
      'pickup_date': DateTime.now(),
      'updated_at': DateTime.now(),
    });
  }

  /// Konfirmasi jemput sekaligus mencatat item, berat, DAN pembayaran -
  /// dipanggil dari _ConfirmPickupSheet setelah barang beneran ditimbang.
  ///
  /// Order pickup dibuat di CreateOrderScreen TANPA item & TANPA pembayaran
  /// (subtotal 0, paid_amount 0, payment_status pending) karena totalnya
  /// belum bisa dihitung saat itu. Di sinilah baru pertama kali totalnya
  /// diketahui, jadi payment_method/paid_amount/payment_status order
  /// SETIAP KALI DITIMPA (bukan ditambah/increment seperti recordPayment)
  /// dengan nilai final dari sheet konfirmasi - order pickup tidak pernah
  /// punya paid_amount > 0 sebelum titik ini.
  ///
  /// paidAmount tetap divalidasi tidak boleh melebihi subtotal (toleransi
  /// Rp1 buat pembulatan double), sama seperti guard overpay di
  /// recordPayment().
  Future<void> confirmPickupWithItems(
    String orderId, {
    required List<OrderItem> items,
    required double totalWeight,
    required int totalItems,
    required double subtotal,
    required PaymentMethod paymentMethod,
    required double paidAmount,
    required PaymentStatus paymentStatus,
  }) async {
    if (items.isEmpty) {
      throw Exception('Item cucian tidak boleh kosong.');
    }
    if (paidAmount < 0) {
      throw Exception('Nominal pembayaran tidak valid.');
    }
    if (paidAmount > subtotal + 1) {
      throw Exception('Nominal pembayaran melebihi total pesanan.');
    }

    final orderRef = _ordersRef.doc(orderId);
    final transactionRef = _transactionsRef.doc();

    await _firestore.runTransaction((txn) async {
      final orderSnap = await txn.get(orderRef);
      if (!orderSnap.exists) throw Exception('Order tidak ditemukan.');

      final order = Order.fromJson(orderSnap.data() as Map<String, dynamic>, orderSnap.id);
      final now = DateTime.now();
      final amountDelta = subtotal - order.totalAmount;

      final updatedHistory = [
        ...order.statusHistory,
        StatusHistory(status: order.status, timestamp: now, note: 'Item, berat & pembayaran dicatat saat jemput'),
      ];

      txn.update(orderRef, {
        'items': items.map((e) => e.toJson()).toList(),
        'total_weight': totalWeight,
        'total_items': totalItems,
        'total_amount': subtotal,
        'payment_method': paymentMethod.name,
        'paid_amount': paidAmount,
        'payment_status': paymentStatus.name,
        'pickup_date': now,
        'status_history': updatedHistory.map((e) => e.toJson()).toList(),
        'updated_at': now,
      });

      if (amountDelta != 0) {
        final customerRef = _customersRef.doc(order.customerId);
        txn.update(customerRef, {
          'total_spent': FieldValue.increment(amountDelta),
          'updated_at': now,
        });
      }

      // Catat transaksi pembayaran, sama pola-nya dengan createOrder() -
      // supaya histori pembayaran (getPaymentsForOrder) tetap lengkap
      // walau pembayaran order pickup baru terjadi di titik ini, bukan
      // saat order pertama kali dibuat.
      if (paidAmount > 0) {
        txn.set(transactionRef, {
          'order_id': orderId,
          'amount': paidAmount,
          'method': paymentMethod.name,
          'type': TransactionType.orderPayment.name,
          'note': 'Pembayaran saat konfirmasi jemput',
          'recorded_by': null,
          'created_at': now,
          'updated_at': now,
        });
      }
    });
  }

  Future<void> markDelivered(
    String orderId, {
    String? driverNote,
    String? courierId,
    String? courierName,
  }) async {
    await _ordersRef.doc(orderId).update({
      'delivery_date': DateTime.now(),
      'courier_id': courierId,
      'courier_name': courierName,
      'updated_at': DateTime.now(),
    });
  }

  /// Menyimpan/melengkapi rencana jadwal jemput/antar untuk 1 order -
  /// TERPISAH dari pickup_date/delivery_date yang artinya "sudah beneran
  /// dijemput/diantar" dan dipakai kategorisasi di PickupDeliveryScreen.
  ///
  /// UPSERT: kalau order sudah punya `logistics_schedule` dengan `mode`
  /// yang SAMA (mis. dipanggil pertama kali saat CreateOrderScreen cuma
  /// ngirim tanggal/jam, terus dipanggil lagi belakangan buat ngelengkapin
  /// kurir & alamat), field yang tidak dikirim (null) TIDAK menimpa yang
  /// sudah ada - jadi aman dipanggil bertahap tanpa saling menghapus data.
  ///
  /// Kalau `mode` BEDA dari yang tersimpan (mis. order sebelumnya punya
  /// jadwal 'penjemputan', lalu sekarang dijadwalkan 'pengantaran'),
  /// datanya sengaja DIMULAI BERSIH (tidak mewarisi kurir/alamat jadwal
  /// jemput yang lama), karena itu dua kejadian logistik yang berbeda.
  ///
  /// `scheduledAt` & `address` sekarang OPSIONAL supaya bisa dipanggil dari
  /// CreateOrderScreen dengan cuma tanggal+jam (tanpa alamat/kurir dulu).
  Future<void> scheduleLogistics(
    String orderId, {
    required String mode, // 'penjemputan' | 'pengantaran'
    DateTime? scheduledAt,
    String? address,
    String? courierId,
    String? courierName,
    String? notes,
  }) async {
    final orderRef = _ordersRef.doc(orderId);
    final now = DateTime.now();

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(orderRef);
      if (!snap.exists) throw Exception('Order tidak ditemukan.');

      final data = snap.data() as Map<String, dynamic>;
      final existing = data['logistics_schedule'] as Map<String, dynamic>?;
      final sameMode = existing != null && existing['mode'] == mode;

      final merged = {
        'mode': mode,
        'scheduled_at': scheduledAt ?? (sameMode ? existing!['scheduled_at'] : null),
        'address': address ?? (sameMode ? existing!['address'] : null),
        'courier_id': courierId ?? (sameMode ? existing!['courier_id'] : null),
        'courier_name': courierName ?? (sameMode ? existing!['courier_name'] : null),
        'notes': notes ?? (sameMode ? existing!['notes'] : null),
        'created_at': sameMode ? (existing!['created_at'] ?? now) : now,
      };

      txn.update(orderRef, {
        'logistics_schedule': merged,
        'updated_at': now,
      });
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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart'; // sesuaikan path/nama file model lo
import '../providers/auth_provider.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  TransactionRepository({required this.userId}) : _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _transactionsRef =>
      _firestore.collection('users').doc(userId).collection('transactions');

  DocumentReference<Map<String, dynamic>> _orderRef(String orderId) =>
      _firestore.collection('users').doc(userId).collection('orders').doc(orderId);

  /// Nyatet transaksi pembayaran BARU, sekaligus update saldo di order terkait
  /// (paidAmount bertambah, status order ikut ke-update kalau udah lunas).
  /// Pakai Firestore transaction biar konsisten (atomic).
  Future<PaymentTransaction> addTransaction(PaymentTransaction transaction) async {
    final docRef = _transactionsRef.doc();
    final now = DateTime.now();

    final newTransaction = PaymentTransaction(
      id: docRef.id,
      createdAt: now,
      updatedAt: now,
      orderId: transaction.orderId,
      amount: transaction.amount,
      method: transaction.method,
      type: transaction.type,
      note: transaction.note,
      recordedBy: transaction.recordedBy,
    );

    await _firestore.runTransaction((tx) async {
      final orderSnap = await tx.get(_orderRef(transaction.orderId));
      if (!orderSnap.exists) {
        throw Exception('Order ${transaction.orderId} tidak ditemukan');
      }

      final orderData = orderSnap.data()!;
      final double currentPaid = (orderData['paid_amount'] ?? 0.0).toDouble();
      final double totalAmount = (orderData['total_amount'] ?? 0.0).toDouble();

      // refund ngurangin paid_amount, orderPayment nambahin
      final double delta = transaction.type == TransactionType.refund
          ? -transaction.amount
          : transaction.amount;
      final double newPaid = currentPaid + delta;

      tx.set(docRef, newTransaction.toJson());
      tx.update(_orderRef(transaction.orderId), {
        'paid_amount': newPaid,
        'payment_status': newPaid >= totalAmount ? 'paid' : 'partial',
        'updated_at': now,
      });
    });

    return newTransaction;
  }

  Future<PaymentTransaction?> getTransaction(String transactionId) async {
    final doc = await _transactionsRef.doc(transactionId).get();
    if (!doc.exists || doc.data() == null) return null;
    return PaymentTransaction.fromJson(doc.data()!, doc.id);
  }

  Stream<List<PaymentTransaction>> streamTransactions() {
    return _transactionsRef
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PaymentTransaction.fromJson(doc.data(), doc.id)).toList());
  }

  Stream<List<PaymentTransaction>> streamTransactionsByOrder(String orderId) {
    return _transactionsRef
        .where('order_id', isEqualTo: orderId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PaymentTransaction.fromJson(doc.data(), doc.id)).toList());
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return TransactionRepository(userId: userId);
});
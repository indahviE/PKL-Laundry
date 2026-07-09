import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../providers/auth_provider.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  TransactionRepository({required this.userId}) : _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _transactionsRef =>
      _firestore.collection('users').doc(userId).collection('transactions');

  /// FIX: previously dropped subscriptionId/stripePaymentIntentId/currency/
  /// metadata/notes/processedBy when re-constructing the object before
  /// save - those fields existed on the Transaction model but were never
  /// actually passed through, so they'd always be written as null/default.
  Future<Transaction> addTransaction(Transaction transaction) async {
    final docRef = _transactionsRef.doc();
    final now = DateTime.now();
    final newTransaction = Transaction(
      id: docRef.id,
      createdAt: now,
      updatedAt: now,
      companyId: transaction.companyId,
      orderId: transaction.orderId,
      subscriptionId: transaction.subscriptionId,
      stripePaymentIntentId: transaction.stripePaymentIntentId,
      amount: transaction.amount,
      currency: transaction.currency,
      transactionType: transaction.transactionType,
      paymentMethod: transaction.paymentMethod,
      status: transaction.status,
      metadata: transaction.metadata,
      notes: transaction.notes,
      processedBy: transaction.processedBy,
    );
    await docRef.set(newTransaction.toJson());
    return newTransaction;
  }

  Future<Transaction?> getTransaction(String transactionId) async {
    final doc = await _transactionsRef.doc(transactionId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Transaction.fromJson(doc.data()!, doc.id);
  }

  Stream<List<Transaction>> streamTransactions() {
    return _transactionsRef
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Transaction.fromJson(doc.data(), doc.id)).toList());
  }

  Stream<List<Transaction>> streamTransactionsByOrder(String orderId) {
    return _transactionsRef
        .where('order_id', isEqualTo: orderId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Transaction.fromJson(doc.data(), doc.id)).toList());
  }

  Future<void> updateTransactionStatus(String transactionId, String newStatus) async {
    await _transactionsRef.doc(transactionId).update({
      'status': newStatus,
      'updated_at': DateTime.now(),
    });
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return TransactionRepository(userId: userId);
});
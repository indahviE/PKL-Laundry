import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore;
  final String userId; 

  TransactionRepository({required this.userId}) : _firestore = FirebaseFirestore.instance;

  CollectionReference get _transactionsRef =>
      _firestore.collection('users').doc(userId).collection('transactions');

  Future<void> addTransaction(Transaction transaction) async {
    final docRef = _transactionsRef.doc();
    final newTransaction = Transaction(
      id: docRef.id,
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt,
      companyId: transaction.companyId,
      orderId: transaction.orderId,
      amount: transaction.amount,
      transactionType: transaction.transactionType,
      paymentMethod: transaction.paymentMethod,
      status: transaction.status,
    );
    await docRef.set(newTransaction.toJson());
  }

  Stream<List<Transaction>> streamTransactions() {
    return _transactionsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Transaction.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}

final transactionRepositoryProvider = Provider.family<TransactionRepository, String>((ref, userId) {
  return TransactionRepository(userId: userId);
});
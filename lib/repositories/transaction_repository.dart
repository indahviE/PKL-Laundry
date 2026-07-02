// lib/repositories/transaction_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addTransaction(LaundryTransaction transaction) async {
    await _firestore.collection('transactions').add(transaction.toJson());
  }

  Stream<List<LaundryTransaction>> streamTransactions() {
    return _firestore.collection('transactions').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return LaundryTransaction.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});
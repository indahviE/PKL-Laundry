// lib/repositories/customer_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';

class CustomerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addCustomer(Customer customer) async {
    await _firestore.collection('customers').add(customer.toJson());
  }

  Stream<List<Customer>> streamCustomers() {
    return _firestore.collection('customers').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Customer.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});
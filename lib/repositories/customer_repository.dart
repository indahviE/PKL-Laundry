import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';

class CustomerRepository {
  final FirebaseFirestore _firestore;
  final String userId; 

  CustomerRepository({required this.userId}) : _firestore = FirebaseFirestore.instance;

  CollectionReference get _customersRef =>
      _firestore.collection('users').doc(userId).collection('customers');

  Future<void> addCustomer(Customer customer) async {
    final docRef = _customersRef.doc();
    final newCustomer = Customer(
      id: docRef.id,
      createdAt: customer.createdAt,
      updatedAt: customer.updatedAt,
      companyId: customer.companyId,
      customerCode: customer.customerCode,
      fullName: customer.fullName,
      email: customer.email,
      phone: customer.phone,
      address: customer.address,
      city: customer.city,
      postalCode: customer.postalCode,
      dateOfBirth: customer.dateOfBirth,
      gender: customer.gender,
      membershipType: customer.membershipType,
      totalOrders: customer.totalOrders,
      totalSpent: customer.totalSpent,
      loyaltyPoints: customer.loyaltyPoints,
      notes: customer.notes,
      isActive: customer.isActive,
    );
    await docRef.set(newCustomer.toJson());
  }

  Stream<List<Customer>> streamCustomers() {
    return _customersRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Customer.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}

final customerRepositoryProvider = Provider.family<CustomerRepository, String>((ref, userId) {
  return CustomerRepository(userId: userId);
});
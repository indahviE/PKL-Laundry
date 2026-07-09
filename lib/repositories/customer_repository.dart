import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../providers/auth_provider.dart';
class CustomerRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  CustomerRepository({required this.userId}) : _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _customersRef =>
      _firestore.collection('users').doc(userId).collection('customers');

  Future<Customer> addCustomer(Customer customer) async {
    final docRef = _customersRef.doc();
    final now = DateTime.now();
    final newCustomer = Customer(
      id: docRef.id,
      createdAt: now,
      updatedAt: now,
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
    return newCustomer;
  }

  Future<Customer?> getCustomer(String customerId) async {
    final doc = await _customersRef.doc(customerId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Customer.fromJson(doc.data()!, doc.id);
  }

  Stream<List<Customer>> streamCustomers() {
    return _customersRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Customer.fromJson(doc.data(), doc.id)).toList();
    });
  }

  Future<void> updateCustomer(String customerId, Map<String, dynamic> data) async {
    await _customersRef.doc(customerId).update({
      ...data,
      'updated_at': DateTime.now(),
    });
  }

  Future<void> deleteCustomer(String customerId) async {
    await _customersRef.doc(customerId).delete();
  }

  /// Called after an order is paid so the customer's aggregate stats
  /// (§3.3.1: total_orders, total_spent, loyalty_points) stay in sync.
  /// Uses increments so concurrent orders don't overwrite each other.
  Future<void> recordCompletedOrder(String customerId, {
    required double amountSpent,
    int loyaltyPointsEarned = 0,
  }) async {
    await _customersRef.doc(customerId).update({
      'total_orders': FieldValue.increment(1),
      'total_spent': FieldValue.increment(amountSpent),
      'loyalty_points': FieldValue.increment(loyaltyPointsEarned),
      'updated_at': DateTime.now(),
    });
  }
}

// FIX: previously watched `userIdProvider` from an `app_providers.dart`
// file that was never provided/shown, and it wasn't clear it resolved to
// the same value as the rest of the app. Now watches the single shared
// `currentUserIdProvider` from auth_repository.dart, same as every other
// repository, so there's exactly one definition of "current user" app-wide.
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return CustomerRepository(userId: userId);
});
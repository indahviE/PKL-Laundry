import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/laundry.dart';

class LaundryRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  LaundryRepository({required this.userId}) : _firestore = FirebaseFirestore.instance;

  CollectionReference get _laundriesRef =>
      _firestore.collection('users').doc(userId).collection('laundries');

  Future<void> addLaundry(Laundry laundry) async {
    final docRef = _laundriesRef.doc();
    final newLaundry = Laundry(
      id: docRef.id,
      createdAt: laundry.createdAt,
      updatedAt: laundry.updatedAt,
      companyId: laundry.companyId,
      name: laundry.name,
      address: laundry.address,
      phone: laundry.phone,
      isActive: laundry.isActive,
    );
    await docRef.set(newLaundry.toJson());
  }

  Stream<List<Laundry>> streamLaundries() {
    return _laundriesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Laundry.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}

final laundryRepositoryProvider = Provider.family<LaundryRepository, String>((ref, userId) {
  return LaundryRepository(userId: userId);
});
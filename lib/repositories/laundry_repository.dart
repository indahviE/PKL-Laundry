import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/laundry.dart';
import '../providers/auth_provider.dart';
class LaundryRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  LaundryRepository({required this.userId}) : _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _laundriesRef =>
      _firestore.collection('users').doc(userId).collection('laundries');

  /// Adds a new branch. `laundry.code` is required and must be unique per
  /// user - it's what the order-number generator (`{code}-{date}-{seq}`)
  /// relies on, so this checks for a duplicate before writing.
  Future<Laundry> addLaundryBranch(Laundry laundry) async {
    final existing = await _laundriesRef.where('code', isEqualTo: laundry.code).limit(1).get();
    if (existing.docs.isNotEmpty) {
      throw Exception('Kode cabang "${laundry.code}" sudah dipakai, gunakan kode lain.');
    }

    final docRef = _laundriesRef.doc();
    final now = DateTime.now();
    final newLaundry = Laundry(
      id: docRef.id,
      createdAt: now,
      updatedAt: now,
      companyId: laundry.companyId,
      name: laundry.name,
      code: laundry.code,
      address: laundry.address,
      city: laundry.city,
      province: laundry.province,
      phone: laundry.phone,
      email: laundry.email,
      managerId: laundry.managerId,
      operatingHours: laundry.operatingHours,
      capacity: laundry.capacity,
      isActive: laundry.isActive,
      location: laundry.location,
    );
    await docRef.set(newLaundry.toJson());
    return newLaundry;
  }

  Future<Laundry?> getLaundry(String laundryId) async {
    final doc = await _laundriesRef.doc(laundryId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Laundry.fromJson(doc.data()!, doc.id);
  }

  Stream<List<Laundry>> streamLaundries() {
    return _laundriesRef
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Laundry.fromJson(doc.data(), doc.id)).toList());
  }

  Future<void> updateLaundryBranch(String laundryId, Map<String, dynamic> updatedData) async {
    await _laundriesRef.doc(laundryId).update({
      ...updatedData,
      'updated_at': DateTime.now(),
    });
  }

  Future<void> deleteLaundryBranch(String laundryId) async {
    await _laundriesRef.doc(laundryId).delete();
  }
}

final laundryRepositoryProvider = Provider<LaundryRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return LaundryRepository(userId: userId);
});
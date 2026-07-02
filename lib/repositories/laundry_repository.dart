import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/laundry.dart';

class LaundryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addLaundry(Laundry laundry) async {
    await _firestore.collection('laundries').add(laundry.toJson());
  }

  Stream<List<Laundry>> streamLaundries() {
    return _firestore.collection('laundries').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Laundry.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }
}

final laundryRepositoryProvider = Provider<LaundryRepository>((ref) {
  return LaundryRepository();
});
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service.dart';

class ServiceRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  ServiceRepository({required this.userId}) : _firestore = FirebaseFirestore.instance;

  CollectionReference get _servicesRef =>
      _firestore.collection('users').doc(userId).collection('services');

  Future<void> addService(Service service) async {
    final docRef = _servicesRef.doc();
    final newService = Service(
      id: docRef.id,
      createdAt: service.createdAt,
      updatedAt: service.updatedAt,
      companyId: service.companyId,
      name: service.name,
      price: service.price,
      unit: service.unit,
      isActive: service.isActive,
    );
    await docRef.set(newService.toJson());
  }

  Stream<List<Service>> streamServices() {
    return _servicesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Service.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}

final serviceRepositoryProvider = Provider.family<ServiceRepository, String>((ref, userId) {
  return ServiceRepository(userId: userId);
});
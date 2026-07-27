import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service.dart';
import '../providers/auth_provider.dart';

class ServiceRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  ServiceRepository({required this.userId}) : _firestore = FirebaseFirestore.instance;

  // Blueprint (§2.2, §3.3.3, Security Rules §4.5) names this collection
  // `service_types`, not `services`.
  CollectionReference<Map<String, dynamic>> get _servicesRef =>
      _firestore.collection('users').doc(userId).collection('service_types');

  Future<Service> addService(Service service) async {
    final docRef = _servicesRef.doc();
    final now = DateTime.now();
    final newService = Service(
      id: docRef.id,
      createdAt: now,
      updatedAt: now,
      companyId: service.companyId,
      name: service.name,
      description: service.description,
      pricePerKg: service.pricePerKg,
      pricePerItem: service.pricePerItem,
      pricingType: service.pricingType,
      estimatedDuration: service.estimatedDuration,
      durationUnit: service.durationUnit,
      expressFee: service.expressFee,
      minWeight: service.minWeight,
      branchIds: service.branchIds,
      isActive: service.isActive,
      sortOrder: service.sortOrder,
    );
    await docRef.set(newService.toJson());
    return newService;
  }

  Future<Service?> getService(String serviceId) async {
    final doc = await _servicesRef.doc(serviceId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Service.fromJson(doc.data()!, doc.id);
  }

  Stream<List<Service>> streamServices() {
    return _servicesRef
        .orderBy('sort_order')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Service.fromJson(doc.data(), doc.id)).toList());
  }

  Future<void> updateService(String serviceId, Map<String, dynamic> data) async {
    await _servicesRef.doc(serviceId).update({
      ...data,
      'updated_at': DateTime.now(),
    });
  }

  Future<void> deleteService(String serviceId) async {
    await _servicesRef.doc(serviceId).delete();
  }
}

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return ServiceRepository(userId: userId);
});
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company.dart';
import '../providers/auth_provider.dart';

class CompanyRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  CompanyRepository({required this.userId}) : _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _companyRef =>
      _firestore.collection('users').doc(userId).collection('companies');

  Future<Company> createCompany(Company company) async {
    final docRef = company.id.isNotEmpty ? _companyRef.doc(company.id) : _companyRef.doc();
    final now = DateTime.now();
    final newCompany = Company(
      id: docRef.id,
      createdAt: now,
      updatedAt: now,
      name: company.name,
      description: company.description,
      logoUrl: company.logoUrl,
      website: company.website,
      email: company.email,
      phone: company.phone,
      address: company.address,
      city: company.city,
      province: company.province,
      postalCode: company.postalCode,
      taxNumber: company.taxNumber,
      businessLicense: company.businessLicense,
      isActive: company.isActive,
      settings: company.settings,
    );
    await docRef.set(newCompany.toJson());
    return newCompany;
  }

  Future<Company?> getCompany(String companyId) async {
    final doc = await _companyRef.doc(companyId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Company.fromJson(doc.data()!, doc.id);
  }

  Stream<Company?> streamCompany(String companyId) {
    return _companyRef.doc(companyId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Company.fromJson(doc.data()!, doc.id);
    });
  }

  /// A user may in principle own more than one company; blueprint's
  /// onboarding flow (§5.1) only creates one, but the schema doesn't
  /// prevent more, so expose a list stream too.
  Stream<List<Company>> streamCompanies() {
    return _companyRef.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Company.fromJson(doc.data(), doc.id)).toList());
  }

  Future<void> updateCompany(String companyId, Map<String, dynamic> data) async {
    await _companyRef.doc(companyId).update({
      ...data,
      'updated_at': DateTime.now(),
    });
  }

  Future<void> deleteCompany(String companyId) async {
    await _companyRef.doc(companyId).delete();
  }
}

/// Fixed: previously used a hardcoded dummy userId, which meant every
/// account in the app shared the exact same company data - a direct
/// violation of the User-Based isolation architecture in blueprint §2.1.
/// Now derives the real signed-in uid via [currentUserIdProvider].
final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return CompanyRepository(userId: userId);
});
// lib/repositories/company_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company.dart';

class CompanyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createCompany(Company company) async {
    await _firestore.collection('companies').add(company.toJson());
  }

  Stream<Company?> streamCompany(String companyId) {
    return _firestore.collection('companies').doc(companyId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Company.fromJson(doc.data()!, doc.id);
    });
  }
}

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepository();
});
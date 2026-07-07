import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company.dart';

class CompanyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId; // Tambahkan userId untuk isolasi data sesuai PRD

  CompanyRepository({required this.userId});

  // Helper untuk mendapatkan path collection yang benar dan terisolasi
  CollectionReference<Map<String, dynamic>> get _companyRef =>
      _firestore.collection('users').doc(userId).collection('companies');

  // 1. Fungsi Create Company
  Future<void> createCompany(Company company) async {
    // Menggunakan .doc(company.id) jika ID sudah ditentukan di aplikasi, 
    // atau gunakan .add() jika ingin auto-generate ID dari Firebase.
    await _companyRef.doc(company.id).set(company.toJson());
  }

  // 2. Fungsi Stream Company (Real-time monitoring)
  Stream<Company?> streamCompany(String companyId) {
    return _companyRef.doc(companyId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Company.fromJson(doc.data()!, doc.id);
    });
  }
}

// Provider Riverpod yang memantau ID Pengguna aktif secara dinamis
final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  // TODO: Hubungkan dengan Auth State kamu untuk mendapatkan userId asli secara reaktif.
  // Contoh sementara menggunakan dummy ID:
  final currentUserId = "USER_ID_DARI_AUTHENTICATION"; 
  
  return CompanyRepository(userId: currentUserId);
});
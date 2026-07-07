    import 'package:cloud_firestore/cloud_firestore.dart';
    import 'package:flutter_riverpod/flutter_riverpod.dart';
    import 'auth_repository.dart';
    
    

    // Catatan: Jika kamu sudah membuat file models/laundry.dart, import di sini.
    // Untuk sementara, kita pakai Map<String, dynamic> terlebih dahulu.

    class LaundryRepository {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final String userId;

    LaundryRepository({required this.userId});

    // Jalur pipa data cabang laundry milik user tertentu
    CollectionReference get _laundriesRef =>
        _firestore.collection('users').doc(userId).collection('laundries');

    // 1. TAMBAH CABANG LAUNDRY BARU
    Future<void> addLaundryBranch(Map<String, dynamic> laundryData) async {
        laundryData['created_at'] = DateTime.now().toIso8601String();
        laundryData['updated_at'] = DateTime.now().toIso8601String();
        
        await _laundriesRef.add(laundryData);
    }

    // 2. AMBIL DAFTAR ALL CABANG LAUNDRY (REAL-TIME STREAM)
    Stream<QuerySnapshot> streamLaundries() {
        return _laundriesRef.orderBy('created_at', descending: true).snapshots();
    }

    // 3. UPDATE DATA OPERASIONAL CABANG
    Future<void> updateLaundryBranch(String laundryId, Map<String, dynamic> updatedData) async {
        updatedData['updated_at'] = DateTime.now().toIso8601String();
        
        await _laundriesRef.doc(laundryId).update(updatedData);
    }

    // 4. HAPUS CABANG LAUNDRY
    Future<void> deleteLaundryBranch(String laundryId) async {
        await _laundriesRef.doc(laundryId).delete();
    }
    }

    final laundryRepositoryProvider = Provider<LaundryRepository>((ref) {
    // 1. Ambil instance AuthRepository dari provider temanmu
    final authRepo = ref.watch(authRepositoryProvider);
    
    // 2. Ambil UID user yang sedang login secara dinamis
    final currentUid = authRepo.currentUser?.uid ?? '';
    
    // 3. Masukkan UID asli ke database repository
    return LaundryRepository(userId: currentUid);
    });
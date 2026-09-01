import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:netwash/models/manual_ad.dart';

class ManualAdService {
  final _db = FirebaseFirestore.instance;

  /// Ambil satu iklan aktif secara acak/pertama dari koleksi `manual_ads`.
  /// Struktur dokumen di Firestore:
  ///   videoUrl: String        - link video (mis. hasil upload Cloudinary)
  ///   durationSeconds: number - wajib ditonton berapa detik
  ///   linkUrl: String?        - opsional, link produk (Shopee dll)
  ///   title: String?          - opsional
  ///   isActive: bool          - true/false biar bisa on/off tanpa hapus data
  Future<ManualAd?> fetchActiveAd() async {
    final snapshot = await _db
        .collection('manual_ads')
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    return ManualAd.fromFirestore(doc.id, doc.data());
  }
}
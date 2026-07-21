import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(FirebaseFirestore.instance);
});

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore);

  CollectionReference get _usersCollection => _firestore.collection('users');

  Future<void> createUserProfile(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).set(user.toJson());
    } catch (e) {
      throw Exception('Gagal menyimpan profil pengguna: $e');
    }
  }

  Stream<UserModel?> getUserProfileStream(String userId) {
    return _usersCollection.doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserModel.fromJson(snapshot.data() as Map<String, dynamic>, snapshot.id);
      }
      return null;
    });
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(userId).update({
        ...data,
        'updated_at': DateTime.now().toIso8601String(),  
      });
    } catch (e) {
      throw Exception('Gagal memperbarui profil pengguna: $e');
    }
  }

  /// Simpan preferensi notifikasi user ke Firestore (sumber kebenaran
  /// yang dibaca backend/Cloud Function sebelum kirim push notification).
  /// `prefs` cukup dikirim partial, mis. {'promo': false} -- pakai dot
  /// notation biar cuma field itu yang ke-update, bukan overwrite seluruh
  /// map notif_prefs.
  Future<void> updateNotificationPrefs(
    String userId,
    Map<String, bool> prefs,
  ) async {
    try {
      final data = <String, dynamic>{
        for (final entry in prefs.entries) 'notif_prefs.${entry.key}': entry.value,
      };
      await _usersCollection.doc(userId).update({
        ...data,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Gagal menyimpan preferensi notifikasi: $e');
    }
  }

  /// Dipanggil FcmService tiap device dapat/refresh token FCM baru.
  Future<void> updateFcmToken(String userId, String token) async {
    try {
      await _usersCollection.doc(userId).update({
        'fcm_token': token,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Gagal menyimpan FCM token: $e');
    }
  }
}
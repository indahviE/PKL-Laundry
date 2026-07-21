import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../repositories/user_repository.dart';

/// Minta izin notifikasi, ambil FCM token device, lalu simpan ke
/// `users/{uid}.fcm_token` supaya Cloud Function tahu ke device mana
/// harus kirim push notification.
///
/// Dipanggil sekali di `MainScreen.initState()` -- titik ini aman karena
/// hanya ke-reach setelah user lolos semua tahap onboarding/login (lihat
/// redirect logic di routes.dart).
class FcmService {
  static final UserRepository _userRepository =
      UserRepository(FirebaseFirestore.instance);

  static Future<void> registerToken() async {
    // Dibungkus try-catch: kalau setup native FCM belum lengkap
    // (google-services.json / APNs key belum dipasang), method ini bisa
    // throw. Karena dipanggil dari MainScreen.initState(), tanpa
    // try-catch itu bisa nge-crash seluruh shell (Dashboard/Orders/
    // Customers/Settings), bukan cuma fitur notifikasinya.
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final messaging = FirebaseMessaging.instance;

      // Di iOS & web wajib minta izin dulu; di Android izin ini otomatis
      // granted untuk API < 33, dan tetap perlu diminta eksplisit di
      // Android 13+ (POST_NOTIFICATIONS permission ada di manifest).
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        // User menolak izin -- toggle di NotificationsScreen tetap
        // tersimpan, tapi backend nggak akan bisa kirim push sampai user
        // re-enable izin dari pengaturan sistem.
        return;
      }

      final token = await messaging.getToken();
      if (token != null) {
        await _userRepository.updateFcmToken(user.uid, token);
      }

      // Token FCM bisa berubah (reinstall app, restore backup, dll) --
      // pastikan Firestore selalu punya token yang terbaru.
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          _userRepository.updateFcmToken(currentUser.uid, newToken);
        }
      });
    } catch (e) {
      // Gagal registrasi token bukan error fatal -- fitur lain di app
      // (termasuk toggle preferensi notifikasi) tetap harus jalan normal.
      debugPrint('FcmService.registerToken gagal (non-fatal): $e');
    }
  }
}
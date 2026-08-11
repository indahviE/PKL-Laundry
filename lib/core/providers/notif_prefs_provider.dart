import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/user_repository.dart';

final notifPrefsProvider = StreamProvider<Map<String, bool>>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  // Dengerin authStateChanges(), BUKAN baca currentUser sekali doang -
  // di mobile (cold start), provider ini bisa ke-watch SEBELUM Firebase
  // Auth selesai restore sesi dari secure storage, bikin uid masih null
  // pas provider pertama kali dibuat. Karena StreamProvider gak
  // otomatis re-run tanpa trigger, hasilnya kejebak Stream.value({})
  // SELAMANYA - efeknya semua toggle notifikasi (termasuk in_app_sound)
  // dianggap default true terus-terusan, gak peduli disimpan apa di
  // Firestore.
  return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
    if (user == null) return Stream.value(const <String, bool>{});
    return repo.getUserProfileStream(user.uid).map((u) => u?.notifPrefs ?? const {});
  });
});
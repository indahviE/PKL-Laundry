import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/user_repository.dart';

final notifPrefsProvider = StreamProvider<Map<String, bool>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(const {});
  final repo = ref.watch(userRepositoryProvider);
  return repo.getUserProfileStream(uid).map((user) => user?.notifPrefs ?? const {});
});
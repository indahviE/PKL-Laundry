import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    FirebaseAuth.instance,
    FirebaseFirestore.instance, 
  );
});

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db; 

  AuthRepository(this._auth, this._db);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// True jika user yang sedang login sudah verifikasi email.
  /// Catatan: ambil dari cache lokal Firebase Auth, jadi kalau baru
  /// klik link verifikasi di email, panggil reloadUser() dulu sebelum
  /// cek ini biar statusnya up-to-date.
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
    String role = 'owner', 
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'phone': phone,
          'role': role, 
          'emailVerified': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Kirim email verifikasi begitu akun berhasil dibuat.
        // Sesuai PRD Step 2: Verifikasi Email — dilakukan setelah
        // registrasi, sebelum user dianggap aktif.
        await user.sendEmailVerification();
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Terjadi kesalahan saat registrasi.');
    } catch (e) {
      throw Exception('Gagal menyimpan data pengguna ke database: $e');
    }
  }

  Future<UserCredential> loginWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Email atau password salah.');
    }
  }

  /// Kirim ulang email verifikasi (dipakai di halaman verify-email
  /// kalau user belum terima email atau linknya expired).
  Future<void> resendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Tidak ada user yang sedang login.');
    }
    if (user.emailVerified) {
      throw Exception('Email sudah terverifikasi.');
    }
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Gagal mengirim ulang email verifikasi.');
    }
  }

  /// Refresh data user dari server Firebase, lalu cek status emailVerified
  /// terbaru. Panggil ini dari verify_email_screen.dart, misal lewat
  /// tombol "Saya sudah verifikasi" atau polling berkala (mis. tiap 3 detik).
  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    await user.reload();
    final refreshedUser = _auth.currentUser;
    final verified = refreshedUser?.emailVerified ?? false;

    // Sinkronkan status ke Firestore juga biar konsisten dengan data lain.
    if (verified) {
      await _db.collection('users').doc(user.uid).update({
        'emailVerified': true,
      });
    }

    return verified;
  }

  /// Simpan/update data profile user ke Firestore.
  /// Sesuai PRD Step 3: Setup Profile → users/{user_id}/profile/
  Future<void> updateUserProfile({
    required String fullName,
    required String phone,
    String? avatarUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Tidak ada user yang sedang login.');
    }

    try {
      await _db.collection('users').doc(user.uid).update({
        'name': fullName,
        'phone': phone,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update juga display name di Firebase Auth biar konsisten
      await user.updateDisplayName(fullName);
    } on FirebaseException catch (e) {
      throw Exception(e.message ?? 'Gagal menyimpan profile.');
    }
  }

  /// Ambil data profile user dari Firestore, buat prefill form.
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Gagal mengirim email reset password.');
    }
  }
}

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges;
});
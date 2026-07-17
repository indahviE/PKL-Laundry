import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
    GoogleSignIn(),
  );
});

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _googleSignIn;

  AuthRepository(this._auth, this._db, this._googleSignIn);

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

  /// Login/register otomatis pakai akun Google.
  ///
  /// Return `null` (BUKAN throw) kalau user menutup/cancel popup pilih
  /// akun — itu bukan error, jadi UI tidak perlu menampilkan dialog error
  /// untuk kasus ini. Exception hanya dilempar untuk kegagalan yang
  /// sebenarnya (network, akun disabled, dst).
  ///
  /// Kalau ini pertama kalinya user tsb sign in (dicek lewat
  /// `additionalUserInfo.isNewUser`), dokumen users/{uid} dibuat dengan
  /// schema yang SAMA dengan `registerWithEmailAndPassword` (uid, name,
  /// email, phone, role, emailVerified, createdAt) supaya redirect logic
  /// di routes.dart (cek profileCompleted/companyCompleted/dst) tetap
  /// konsisten untuk user yang masuk lewat Google.
  ///
  /// Email dari akun Google sudah pasti terverifikasi oleh Google sendiri,
  /// jadi `emailVerified` langsung diset true dan step /verify-email
  /// otomatis ke-skip oleh redirect logic (asal routes.dart membaca field
  /// ini, bukan cuma `user.emailVerified` dari Firebase Auth).
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User menutup/cancel popup pilih akun — bukan error.
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (user != null && isNewUser) {
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'phone': user.phoneNumber ?? '',
          'role': 'owner',
          'emailVerified': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Gagal login dengan Google.');
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

  /// Ambil ID company milik user, dari subcollection
  /// `users/{uid}/companies/` (BUKAN dari field `users/{uid}.company`,
  /// karena field itu cuma snapshot data tanpa ID — lihat saveCompanyData()
  /// di bawah). Dipakai buat menyertakan `companyId` ke metadata Stripe
  /// Checkout Session, supaya webhook bisa menulis `company_id` yang benar
  /// ke dokumen subscription (dibutuhkan oleh
  /// SubscriptionRepository.streamActiveSubscription()).
  ///
  /// Asumsi saat ini: satu user cuma punya satu company (sesuai
  /// saveCompanyData() yang juga cuma menjaga satu dokumen company).
  Future<String?> getPrimaryCompanyId() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final snapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('companies')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.id;
  }

  /// Hitung jumlah cabang (laundries) milik user saat ini, dari
  /// `users/{uid}/laundries/`. Dipakai ChoosePlanScreen buat validasi
  /// downgrade: kalau target paket punya `max_laundries` lebih kecil
  /// dari angka ini, downgrade harus diblokir (lihat 3.6.3
  /// Feature Gating di PRD — `canAddLaundry`).
  Future<int> getLaundryCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final snapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('laundries')
        .get();
    return snapshot.docs.length;
  }

  /// Hitung jumlah karyawan (employees) milik user saat ini, dari
  /// `users/{uid}/employees/`. Dipakai ChoosePlanScreen buat validasi
  /// downgrade: kalau target paket punya `max_employees` lebih kecil
  /// dari angka ini, downgrade harus diblokir.
  Future<int> getEmployeeCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final snapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('employees')
        .get();
    return snapshot.docs.length;
  }

  /// Simpan data perusahaan & tandai step ini selesai.
  /// Sesuai PRD Step 4: Setup Perusahaan.
  ///
  /// Ditulis ke DUA tempat sekaligus:
  /// 1. Field `company` + flag `companyCompleted` di users/{uid} — dipakai
  ///    oleh redirect logic di routes.dart untuk cek progres onboarding.
  /// 2. Subcollection users/{uid}/companies/{companyId} — dipakai oleh
  ///    layar lain (mis. CreateLaundryScreen) yang butuh dropdown daftar
  ///    perusahaan milik user. Field `name` WAJIB ada karena itu yang
  ///    dibaca CreateLaundryScreen._fetchCompaniesData().
  Future<void> saveCompanyData({
    required String companyName,
    required String address,
    required String city,
    required String phone,
    String? website,
    String? description,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Tidak ada user yang sedang login.');
    }

    try {
      final companyData = {
        'name': companyName,
        'address': address,
        'city': city,
        'phone': phone,
        'website': website,
        'description': description,
      };

      final userDocRef = _db.collection('users').doc(user.uid);
      final companiesRef = userDocRef.collection('companies');

      // Cek apakah user sudah pernah punya dokumen company sebelumnya,
      // supaya tombol "Simpan" yang dipencet berkali-kali (mis. user
      // kembali ke step ini lewat tombol back) tidak bikin dokumen
      // company duplikat di subcollection.
      final existing = await companiesRef.limit(1).get();

      final batch = _db.batch();

      if (existing.docs.isNotEmpty) {
        batch.update(existing.docs.first.reference, {
          ...companyData,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final newCompanyRef = companiesRef.doc();
        batch.set(newCompanyRef, {
          ...companyData,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      batch.update(userDocRef, {
        'company': companyData,
        'companyCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } on FirebaseException catch (e) {
      throw Exception(e.message ?? 'Gagal menyimpan data perusahaan.');
    }
  }

  /// Simpan paket yang DIPILIH user & tandai step "pilih paket" selesai.
  /// Sesuai PRD Step 5: Pilih Paket.
  ///
  /// PENTING: ini BUKAN tanda pembayaran berhasil. Ini cuma mencatat
  /// pilihan user supaya kalau dia keluar-masuk app sebelum bayar, router
  /// tahu harus arahkan ke halaman /payment (bukan balik ke /choose-plan).
  /// Status langganan AKTIF baru tercatat lewat `watchActiveSubscription()`
  /// setelah Stripe webhook menuliskan dokumen di subcollection
  /// `subscriptions` (lihat PRD 4.6 `handleSuccessfulPayment`).
  Future<void> savePlanChoice({
    required String planName,
    required bool isYearly,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Tidak ada user yang sedang login.');
    }

    try {
      await _db.collection('users').doc(user.uid).update({
        'subscription': {
          'plan': planName,
          'period': isYearly ? 'yearly' : 'monthly',
        },
        'planChosen': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception(e.message ?? 'Gagal menyimpan pilihan paket.');
    }
  }

  /// Stream real-time: true selama ada dokumen di
  /// `users/{uid}/subscriptions/` dengan `status == 'active'`.
  ///
  /// Dokumen ini ditulis oleh Cloud Function `stripeWebhook` (event
  /// `checkout.session.completed`), BUKAN oleh client. Dipakai
  /// PaymentScreen untuk mendeteksi pembayaran sukses tanpa bergantung
  /// pada user kembali ke app dari browser Stripe Checkout.
  ///
  /// Cuma balikin bool. Kalau butuh detail dokumennya (mis. tanggal
  /// perpanjangan), pakai `watchActiveSubscriptionData()` di bawah.
  Stream<bool> watchActiveSubscription() {
    return watchActiveSubscriptionData().map((data) => data != null);
  }

  /// Stream real-time dokumen subscription yang aktif (`status ==
  /// 'active'`) di `users/{uid}/subscriptions/`, null kalau nggak ada
  /// dokumen aktif.
  ///
  /// Field tanggal di dokumen ini pakai snake_case sesuai skema PRD
  /// (bagian 3.6.2 & Cloud Function `stripeWebhook`): `current_period_start`
  /// dan `current_period_end` (Timestamp), ditulis oleh
  /// `handleSuccessfulPayment` / `handleSubscriptionUpdate` di Cloud
  /// Function. Kedua field ini yang dipakai SubscriptionScreen buat
  /// nampilin rentang tanggal langganan (mis. "17 Jul 2026 - 17 Agu
  /// 2026").
  Stream<Map<String, dynamic>?> watchActiveSubscriptionData() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('subscriptions')
        .where('status', isEqualTo: 'active')
        .limit(1)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.isNotEmpty ? snapshot.docs.first.data() : null);
  }

  /// Versi one-shot dari `watchActiveSubscription()`, dipakai oleh
  /// `redirect` di GoRouter (butuh Future, bukan Stream) supaya user
  /// tidak bisa "loncat" ke dashboard sebelum pembayaran webhook masuk.
  Future<bool> hasActiveSubscription() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final query = await _db
        .collection('users')
        .doc(user.uid)
        .collection('subscriptions')
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /// Sign out dari Firebase Auth SEKALIGUS dari sesi Google (kalau user
  /// login lewat Google). Kalau cuma _auth.signOut() tanpa ini, Google
  /// Sign-In popup kadang langsung auto-pilih akun yang sama tanpa nanya
  /// lagi saat user coba login ulang.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
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
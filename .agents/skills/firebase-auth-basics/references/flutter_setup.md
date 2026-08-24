# Firebase Auth & Google Sign-In for Flutter

When integrating Firebase Authentication and Google Sign-In into Flutter apps
targeting cross-platform environments (like Mobile + Web), you must navigate
several breaking changes introduced in `google_sign_in` 7.x+ and some
platform-specific quirks.

## 1. `google_sign_in` 7.2.0 API Changes

- **Method Renamed**: The `signIn()` method is deprecated/removed and has been
  replaced with `authenticate()`.
- **Token Separation**: The `GoogleSignInAuthentication` object no longer
  packages both identity and authorization tokens together. Initial
  authentication now only provides the `idToken`. If an `accessToken` is
  required for Google APIs, you must explicitly request server authorization
  separately.

## 2. Initialization & Web Hang/Crash Pitfalls

- **Initialization Requirement**: In 7.x, you must call
  `await GoogleSignIn.instance.initialize();` globally before using the plugin.
- **Web Client ID Constraint**: On Flutter Web, if you call `initialize()`
  without passing a `clientId` argument OR specifying the
  `<meta name="google-signin-client_id" ... />` tag in `web/index.html`, the
  Dart Web Debug Service (DWDS) and the app will throw an assertion error and
  **hang infinitely**, resulting in a blank screen.
- **Common Workaround**: If you intend to use Firebase Auth's
  `signInWithPopup(GoogleAuthProvider())` for the web, you can conditionally
  skip the local `GoogleSignIn` package initialization entirely:
  ```dart
  import 'package:flutter/foundation.dart' show kIsWeb;

  if (!kIsWeb) {
    await GoogleSignIn.instance.initialize();
  }
  ```

## 3. Web Logout Crashes

- If you bypassed `GoogleSignIn` initialization on the web (as demonstrated
  above), you cannot call its `signOut()` method later. Attempting to execute
  `await GoogleSignIn.instance.signOut();` during the user's logout flow on the
  Web platform evaluates against an uninitialized context or unsupported
  environment, crashing the app.
- **Solution**: Conditionally separate the logout logic for Web to rely entirely
  on `FirebaseAuth`:
  ```dart
  if (!kIsWeb) {
      await GoogleSignIn.instance.signOut();
  }
  await FirebaseAuth.instance.signOut();
  ```

## 4. Prototyping Workaround: Bypassing Firestore Composite Indices

*Note: This is a Firestore consideration frequently encountered while fetching
user-specific auth data.*

When querying data via `FirebaseFirestore.instance`, using
`.where('userId', isEqualTo: uid)` combined with a sort on a different field
like `.orderBy('createdAt', descending: true)` mandates a custom composite
index.

- **Quick Alternative**: During local development, you can avoid defining
  indexes by pulling the data using only `.where()` and applying the `.sort()`
  operation client-side on the resulting `List` in Dart.

## 5. Robust `AuthService` Boilerplate

Here is a comprehensive `AuthService` implementation that properly handles the
initialization and platform differences between Flutter Web and Mobile:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthService() {
    if (!kIsWeb) {
      GoogleSignIn.instance.initialize();
    }
  }

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

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
  ///
  /// CATATAN: sebelumnya method ini memanggil `_googleSignIn.signOut()`
  /// tepat sebelum `signIn()`, dengan niat memaksa account picker selalu
  /// muncul. Itu dihapus karena menyebabkan race condition — signOut()
  /// mereset state internal plugin (khususnya di web/GIS), dan signIn()
  /// yang langsung dipanggil setelahnya kadang balik null padahal user
  /// sudah memilih akun dengan benar, sehingga user harus klik tombol
  /// login dua kali. Behavior "bisa ganti akun" tetap terjaga lewat
  /// method signOut() terpisah di bawah, yang sudah dipanggil saat user
  /// logout dari app.
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
  
  // Sign out
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await GoogleSignIn.instance.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      print("Error signing out: \$e");
    }
  }
}
```

## 6. Troubleshooting `auth/unauthorized-domain` on Flutter Web

When running Flutter Web locally and using `signInWithPopup`, you might
encounter a situation where the Google Sign-In popup opens and immediately
closes.

- **Symptom**: The console shows
  `Sign-in failed: [firebase_auth/unauthorized-domain] This domain is not authorized for OAuth operation for your Firebase project.`
- **Cause**: The domain (usually `localhost` during local testing) is not listed
  in the Authorized Domains in the Firebase Console.
- **Solution**: Add `localhost` to the Authorized Domains list in the Firebase
  Console (Authentication > Settings > Authorized domains) or in your
  `firebase.json` auth config.
- **CRITICAL**: Do NOT include the protocol or port number when adding the
  domain (e.g., use `localhost`, NOT `http://localhost:9090`). Flutter Web often
  runs on random ports or specific ports, but Firebase Auth only cares about the
  domain.

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Initialize Firebase untuk aplikasi
/// Harus dipanggil di main() sebelum runApp()
Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
    rethrow;
  }
}
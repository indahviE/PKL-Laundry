import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

/// Menginisialisasi Firebase untuk kebutuhan aplikasi.
/// Fungsi ini wajib dipanggil di dalam main() sebelum runApp().
Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
    rethrow;
  }
}
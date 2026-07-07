import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // TEMPLATE - Sesuaikan dengan firebase project mu di Firebase Console
    return FirebaseOptions(
      apiKey: 'YOUR_API_KEY',
      appId: 'YOUR_APP_ID',
      messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
      projectId: 'YOUR_PROJECT_ID',
      storageBucket: 'YOUR_STORAGE_BUCKET',
      iosBundleId: 'com.laundryapp.netwash',
      androidPackageName: 'com.laundryapp.netwash',
    );
  }
}

/// INSTRUCTIONS:
/// 1. Buka Firebase Console: https://firebase.google.com
/// 2. Pilih project NetWash
/// 3. Project Settings (gear icon) > General
/// 4. Scroll ke bawah, lihat "Your apps" section
/// 5. Untuk Android: download google-services.json
/// 6. Copy values dari file tersebut ke constants di atas
/// 
/// Atau lebih gampang:
/// $ flutterfire configure
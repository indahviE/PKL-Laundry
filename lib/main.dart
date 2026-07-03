import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'core/config/firebase_config.dart'; // Sesuaikan dengan folder konfigurasi kamu

void main() async {
  // Pastikan binding Flutter sudah siap
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Firebase Cloud
  await Firebase.initializeApp(
    // Jika kamu memakai manual config, masukkan opsi di bawah ini:
    // options: const FirebaseOptions(
    //   apiKey: FirebaseConfig.apiKey,
    //   appId: FirebaseConfig.appId,
    //   messagingSenderId: FirebaseConfig.messagingSenderId,
    //   projectId: FirebaseConfig.projectId,
    // ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Netwash SaaS Laundry',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const Scaffold(
        body: Center(child: Text('Backend & Firebase Terhubung 100%!')),
      ),
    );
  }
}
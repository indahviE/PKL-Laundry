import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Tambahkan ini untuk mengaktifkan offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Netwash SaaS Laundry',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // Opsional: Biar tampilan UI-nya modern ala Material 3
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            'Backend & Firebase Terhubung 100%!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
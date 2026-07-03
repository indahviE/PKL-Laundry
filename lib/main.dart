import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // Pastikan binding Flutter sudah siap
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Firebase Cloud (Otomatis membaca google-services.json di Android)
  await Firebase.initializeApp();

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
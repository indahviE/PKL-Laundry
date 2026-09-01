import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/config/routes.dart';
import 'core/providers/locale.provider.dart';
import 'core/providers/notif_prefs_provider.dart'; 
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 1.5. Preload font Poppins SEBELUM widget pertama dirender.
  //
  // Tanpa ini, GoogleFonts.poppins() di seluruh app (LoginScreen,
  // RegisterScreen, dst) baru mulai di-download saat pertama kali
  // dipanggil di build(). Selama jeda download itu, Flutter render pakai
  // font fallback sistem dulu (beda metrik/tinggi baris dibanding
  // Poppins), yang di beberapa layar dengan layout ketat (mis. LoginScreen
  // yang pakai IntrinsicHeight + Expanded) bisa memicu RenderFlex overflow
  // sesaat sebelum widget rebuild dengan font yang benar. Dengan preload9
  // di sini, font Poppins sudah pasti siap dari frame pertama, jadi
  // fase "font fallback dulu" itu ga pernah terjadi.
  await GoogleFonts.pendingFonts([
    GoogleFonts.poppins(),
    GoogleFonts.poppins(fontWeight: FontWeight.w500),
    GoogleFonts.poppins(fontWeight: FontWeight.w600),
    GoogleFonts.poppins(fontWeight: FontWeight.w700),
  ]);

  // 2. Setup Offline Persistence
  //
  // Khusus WEB: persistence dimatikan. SDK Firestore versi web punya bug
  // yang lumayan sering muncul (INTERNAL ASSERTION FAILED: Unexpected
  // state) kalau koneksi sempat putus-nyambung sementara ada listener
  // aktif — state cache lokal (IndexedDB) jadi corrupt dan SEMUA request
  // Firestore berikutnya ikut gagal sampai browser di-reload/cache
  // dibersihkan manual. Karena development sering ngetes kondisi network
  // gak stabil (throttling/offline lewat DevTools, pindah wifi, dst),
  // mendingan dimatikan aja di web daripada harus reload browser tiap
  // kali kejadian.
  //
  // Mobile (Android/iOS) TETAP pakai persistence seperti biasa - platform
  // itu implementasinya beda (native SQLite-based), jauh lebih stabil
  // dan memang untungnya besar buat UX offline-first di HP.
  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: !kIsWeb,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // 3. Bungkus dengan ProviderScope agar Riverpod aktif
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// 4. Menggunakan ConsumerWidget agar bisa memantau routing
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 5. Membaca konfigurasi router Anda
    final router = ref.watch(goRouterProvider);

    // 6. Membaca bahasa yang lagi aktif
    final locale = ref.watch(localeProvider);

    // 👇 Tambahin ini: biar notifPrefs selalu "hidup" & ke-update
    // selama app jalan, gak peduli lagi di screen mana
    ref.watch(notifPrefsProvider);

    // 7. Menggunakan .router agar sistem navigasi aktif
    return MaterialApp.router(
      title: 'Netwash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      routerConfig: router,

      // ==== Localization setup ====
      locale: locale,
      supportedLocales: const [
        Locale('id'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../widgets/common/bottom_navigation.dart';
import '../../services/fcm_service.dart';

/// Main Screen - Layout utama setelah login (Wadah / Shell Navigasi)
///
/// Dulu widget ini menerima `child` biasa dari ShellRoute, yang artinya
/// GoRouter MEMBANGUN ULANG halaman dari nol setiap kali pindah tab
/// (termasuk re-connect semua StreamBuilder ke Firestore -> kerasa lag).
///
/// Sekarang pakai `StatefulNavigationShell` dari StatefulShellRoute.indexedStack:
/// ke-4 tab (Dashboard/Orders/Customers/Settings) tetap hidup di background
/// lewat IndexedStack, jadi pindah tab tinggal ganti visibility, instan,
/// dan state/stream Firestore-nya nggak connect ulang tiap kali diklik.
class MainScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({
    Key? key,
    required this.navigationShell,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  DateTime? _lastBackPress;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;

  @override
  void initState() {
    super.initState();
    // MainScreen cuma ke-reach setelah user lolos login & onboarding
    // (lihat redirect di routes.dart), jadi titik ini aman buat
    // registrasi FCM token pertama kali.
    FcmService.registerToken();

    // FIX GAP -- sebelumnya TIDAK ADA satu pun listener untuk
    // FirebaseMessaging.onMessage di seluruh codebase. Di web (dan
    // Android/iOS saat app lagi foreground), browser/OS TIDAK otomatis
    // menampilkan system notification untuk push yang masuk selagi app
    // dibuka/fokus -- itu cuma jalan buat onBackgroundMessage di
    // web/firebase-messaging-sw.js (tab di-minimize/pindah tab lain).
    // Tanpa listener ini, notifikasi (termasuk reminder H-3/H-1
    // subscription dari sendSubscriptionRenewalReminders) DITERIMA diam-diam
    // oleh Flutter tapi TIDAK PERNAH kelihatan user kalau dia lagi
    // mantengin app-nya -- persis skenario testing manual di dashboard.
    _foregroundMessageSub =
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  /// Tampilkan notifikasi yang masuk sewaktu app lagi foreground sebagai
  /// in-app toast (AppSnackbar), karena OS/browser tidak akan
  /// menampilkannya sendiri untuk kondisi ini. Dipakai buat SEMUA jenis
  /// push (status_pesanan, subscription_renewal, promo, chat_cs, pengingat)
  /// -- generik berdasarkan title/body notification payload, bukan
  /// per-`data.type`, supaya tidak perlu disentuh lagi kalau nanti ada
  /// jenis notifikasi baru dari Cloud Functions.
  void _handleForegroundMessage(RemoteMessage message) {
    if (!mounted) return;
    final title = message.notification?.title;
    final body = message.notification?.body;
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    final text = [title, body]
        .where((s) => s != null && s.isNotEmpty)
        .join(' — ');
    AppSnackbar.info(context, text);
  }

  @override
  void dispose() {
    _foregroundMessageSub?.cancel();
    super.dispose();
  }

  /// Fungsi untuk berpindah tab saat bottom nav diklik.
  /// `initialLocation: true` kalau tab yang sama diklik lagi -> reset ke
  /// root branch itu (misal lagi di /orders/123, klik tab Orders lagi
  /// balik ke /orders). Kalau ganti ke branch lain, state branch tsb
  /// tetap dipertahankan (nggak reload).
  void _onItemTapped(int index) {
    HapticFeedback.selectionClick();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  /// Konfirmasi keluar aplikasi: tekan back dua kali dalam 2 detik.
  /// Hanya berlaku ketika berada di tab Dashboard (branch index 0).
  Future<bool> _onWillPop(BuildContext context) async {
    final isAtRoot = widget.navigationShell.currentIndex == 0;
    if (!isAtRoot) {
      widget.navigationShell.goBranch(0);
      return false;
    }

    final now = DateTime.now();
    final isWarning = _lastBackPress == null || now.difference(_lastBackPress!) > const Duration(seconds: 2);

    if (isWarning) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tekan sekali lagi untuk keluar'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: WillPopScope(
        onWillPop: () => _onWillPop(context),
        child: Scaffold(
          // extendBody dimatikan: aktifkan lagi hanya jika CustomBottomNavigation
          // memang dibuat transparan/melayang. Kalau nav bar solid (background putih
          // penuh), extendBody:true akan membuat konten paling bawah tergambar di
          // belakang nav bar sehingga terlihat seperti "tidak bisa discroll sampai habis".
          extendBody: false,
          // navigationShell sendiri sudah berupa IndexedStack dari ke-4 branch,
          // jadi tinggal ditaruh langsung sebagai body -- nggak perlu
          // AnimatedSwitcher/KeyedSubtree lagi karena bukan rebuild dari nol.
          body: widget.navigationShell,
          bottomNavigationBar: CustomBottomNavigation(
            currentIndex: widget.navigationShell.currentIndex,
            items: NetWashBottomNavItems.items,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}
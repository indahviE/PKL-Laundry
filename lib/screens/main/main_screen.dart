import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/common/bottom_navigation.dart';

/// Main Screen - Layout utama setelah login (Wadah / Shell Navigasi)
class MainScreen extends StatefulWidget {
  /// child di sini diisi otomatis oleh GoRouter (ShellRoute)
  /// berupa halaman aktif saat ini (Dashboard, Orders, dll.)
  final Widget child;

  const MainScreen({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  DateTime? _lastBackPress;

  /// Menentukan indeks tab bawah aktif berdasarkan path rute saat ini
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/orders')) return 1;
    if (location.startsWith('/customers')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0; // Default ke Dashboard ('/dashboard')
  }

  /// Fungsi untuk berpindah rute saat tab bawah diklik
  void _onItemTapped(int index, BuildContext context) {
    HapticFeedback.selectionClick();
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/orders');
        break;
      case 2:
        context.go('/customers');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }

  /// Konfirmasi keluar aplikasi: tekan back dua kali dalam 2 detik.
  /// Hanya berlaku ketika berada di tab Dashboard (halaman utama).
  Future<bool> _onWillPop(BuildContext context) async {
    final isAtRoot = _calculateSelectedIndex(context) == 0;
    if (!isAtRoot) {
      context.go('/dashboard');
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
          // Body langsung menampilkan halaman aktif yang dikirim oleh GoRouter,
          // dibungkus AnimatedSwitcher agar transisi antar tab terasa halus.
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(_calculateSelectedIndex(context)),
              child: widget.child,
            ),
          ),
          bottomNavigationBar: CustomBottomNavigation(
            currentIndex: _calculateSelectedIndex(context),
            items: NetWashBottomNavItems.items,
            onTap: (index) => _onItemTapped(index, context),
          ),
        ),
      ),
    );
  }
}
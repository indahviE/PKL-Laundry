import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/common/bottom_navigation.dart';

/// Main Screen - Layout utama setelah login (Wadah / Shell Navigasi)
class MainScreen extends StatelessWidget {
  /// child di sini diisi otomatis oleh GoRouter (ShellRoute)
  /// berupa halaman aktif saat ini (Dashboard, Orders, dll.)
  final Widget child;

  const MainScreen({
    Key? key,
    required this.child,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body langsung menampilkan halaman aktif yang dikirim oleh GoRouter
      body: child, 
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _calculateSelectedIndex(context),
        items: NetWashBottomNavItems.items,
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }
}
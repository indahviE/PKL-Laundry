import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/verify_email_screen.dart';
import '../../screens/auth/setup_profile_screen.dart';
import '../../../screens/main/main_screen.dart';
import '../../../screens/main/dashboard_screen.dart';
import '../../screens/onboarding/payment_screen.dart';
import '../../screens/onboarding/setup_company_screen.dart';
import '../../screens/onboarding/choose_plan_screen.dart';
import '../../repositories/auth_repository.dart';

/// Rute yang termasuk alur autentikasi (belum login).
const _authRoutes = ['/login', '/register'];

/// Rute yang termasuk alur onboarding (sudah login, belum lengkap datanya).
const _onboardingRoutes = [
  '/verify-email',
  '/setup-profile',
  '/setup-company',
  '/choose-plan',
  '/payment',
];

/// Konfigurasi GoRouter untuk navigasi aplikasi.
/// Dilengkapi `redirect` yang mengecek status onboarding user tiap kali
/// navigasi terjadi, supaya user tidak bisa "loncat" ke dashboard sebelum
/// menyelesaikan verifikasi email, setup profile, setup perusahaan, dan
/// pemilihan paket.
final goRouterProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authRepo.authStateChanges),
    redirect: (context, state) async {
      final user = authRepo.currentUser;
      final location = state.matchedLocation;
      final isAuthRoute = _authRoutes.contains(location);

      // Belum login sama sekali -> paksa ke login, kecuali memang
      // sedang menuju halaman login/register.
      if (user == null) {
        return isAuthRoute ? null : '/login';
      }

      // Sudah login tapi email belum diverifikasi -> paksa ke verify-email.
      if (!user.emailVerified) {
        return location == '/verify-email' ? null : '/verify-email';
      }

      // Ambil progress onboarding dari Firestore.
      final profile = await authRepo.getUserProfile();
      final profileCompleted = profile?['profileCompleted'] == true;
      final companyCompleted = profile?['companyCompleted'] == true;
      final planChosen = profile?['planChosen'] == true;

      if (!profileCompleted) {
        return location == '/setup-profile' ? null : '/setup-profile';
      }

      if (!companyCompleted) {
        return location == '/setup-company' ? null : '/setup-company';
      }

      if (!planChosen) {
        return location == '/choose-plan' ? null : '/choose-plan';
      }

      // Semua step onboarding sudah lengkap. Kalau user masih nyasar di
      // halaman auth/onboarding, lempar ke dashboard.
      if (isAuthRoute || _onboardingRoutes.contains(location)) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // Rute Autentikasi (Luar Navigasi Utama)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Rute Onboarding (Luar Navigasi Utama, belum butuh bottom nav)
      GoRoute(
        path: '/verify-email',
        name: 'verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/setup-profile',
        name: 'setup-profile',
        builder: (context, state) => const SetupProfileScreen(),
      ),
      GoRoute(
        path: '/setup-company',
        name: 'setup-company',
        builder: (context, state) => const SetupCompanyScreen(),
      ),
      GoRoute(
        path: '/choose-plan',
        name: 'choose-plan',
        builder: (context, state) => const ChoosePlanScreen(),
      ),
      GoRoute(
      path: '/payment',
      name: 'payment',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null) {
          return const ChoosePlanScreen();
        }
        return PaymentScreen(
          planName: extra['planName'] as String,
          isYearly: extra['isYearly'] as bool,
          price: extra['price'] as double,
        );
      },
      ),

      // ShellRoute: Menggunakan MainScreen sebagai wadah navigasi (Bottom Navigation Bar)
      ShellRoute(
        builder: (context, state, child) {
          // child di sini adalah halaman aktif (dashboard, orders, dll.) yang akan dimasukkan ke dalam MainScreen
          return MainScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Orders List Screen'),
          ),
          GoRoute(
            path: '/customers',
            name: 'customers',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Customers List Screen'),
          ),
          GoRoute(
            path: '/employees',
            name: 'employees',
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Employees List Screen'),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

/// Helper supaya GoRouter otomatis re-evaluate `redirect` setiap kali status
/// auth Firebase berubah (login/logout), bukan cuma pas navigasi manual.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (_) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Halaman Settings & Profil
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan & Profil'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(
                radius: 28,
                child: Icon(Icons.person, size: 32),
              ),
              title: Text(
                user?.email ?? 'User NetWash',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Role: Owner'),
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            tileColor: Colors.red.shade50,
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Keluar / Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Halaman Placeholder Sementara untuk fitur yang belum dibuat
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.work_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Screen ini akan diimplementasikan segera',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
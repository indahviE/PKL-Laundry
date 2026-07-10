import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Auth ---
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/verify_email_screen.dart';
import '../../screens/auth/setup_profile_screen.dart';

// --- Main / Shell ---
import '../../../screens/main/main_screen.dart';
import '../../../screens/main/dashboard_screen.dart';

// --- Onboarding ---
import '../../screens/onboarding/setup_company_screen.dart';
import '../../screens/onboarding/choose_plan_screen.dart';
import '../../screens/onboarding/payment_screen.dart';

// --- Settings ---
import '../../screens/settings/setting_screen.dart';

// --- Repositories ---
import '../../repositories/auth_repository.dart';

// --- Employees (sudah ada) ---
import '../../screens/employees/create_employee_screen.dart';

// --- Laundries (sudah ada) ---
import 'package:netwash/screens/laundries/create_laundry_screen.dart';

// =====================================================================
// CATATAN UNTUK TIM: Screen di bawah ini BELUM dibuat filenya, jadi rutenya
// sementara memakai PlaceholderScreen. Begitu file aslinya sudah jadi,
// tinggal:
//   1. Uncomment import yang sesuai di bagian bawah (sudah disiapkan).
//   2. Ganti `builder: (context, state) => const PlaceholderScreen(...)`
//      jadi `builder: (context, state) => const NamaScreenAsli(...)`.
// Struktur path TIDAK perlu diubah lagi, sudah final sesuai
// Lampiran B (netwash.md).
// =====================================================================

// import '../../screens/auth/forgot_password_screen.dart';
// import '../../screens/orders/orders_list_screen.dart';
// import '../../screens/orders/order_detail_screen.dart';
// import '../../screens/orders/create_order_screen.dart';
// import '../../screens/orders/update_order_status_screen.dart';
// import '../../screens/customers/customers_list_screen.dart';
// import '../../screens/customers/customer_detail_screen.dart';
// import '../../screens/customers/create_customer_screen.dart';
// import '../../screens/employees/employees_list_screen.dart';
// import '../../screens/employees/employee_detail_screen.dart';
// import '../../screens/laundries/laundries_list_screen.dart';
// import '../../screens/laundries/laundry_detail_screen.dart';
// import '../../screens/services/services_list_screen.dart';
// import '../../screens/services/create_service_screen.dart';
// import '../../screens/reports/reports_screen.dart';
// import '../../screens/reports/report_detail_screen.dart';
// import '../../screens/settings/profile_screen.dart';
// import '../../screens/settings/subscription_screen.dart';
// import '../../screens/onboarding/setup_company_screen.dart'; // dipakai ulang utk /companies/create

const _authRoutes = ['/login', '/register', '/forgot-password'];

/// Rute yang termasuk alur onboarding (sudah login, belum lengkap datanya).
const _onboardingRoutes = [
  '/verify-email',
  '/setup-profile',
  '/setup-company',
  '/choose-plan',
  '/payment',
];

/// Alias rute lama yang masih dipertahankan supaya tombol/navigasi yang
/// sudah terlanjur dipasang di layar lain tidak putus. Key = path lama,
/// Value = path kanonik baru yang dipakai di seluruh file ini.
const Map<String, String> _legacyRouteAliases = {
  '/create-employee': '/employees/create',
};

/// Konfigurasi GoRouter untuk navigasi aplikasi.
/// Dilengkapi `redirect` yang mengecek status onboarding user tiap kali
/// navigasi terjadi, supaya user tidak bisa "loncat" ke dashboard sebelum
/// menyelesaikan verifikasi email, setup profile, setup perusahaan,
/// pemilihan paket, DAN pembayaran (PRD 5.1 Step 1-6).
final goRouterProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authRepo.authStateChanges),
    redirect: (context, state) async {
      final user = authRepo.currentUser;
      final location = state.matchedLocation;

      // Alias rute lama -> rute kanonik baru, dicek paling awal.
      if (_legacyRouteAliases.containsKey(location)) {
        return _legacyRouteAliases[location];
      }

      final isAuthRoute = _authRoutes.contains(location);

      // Belum login sama sekali -> paksa ke login, kecuali memang
      // sedang menuju halaman login/register/forgot-password.
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

      // Paket sudah dipilih tapi belum tentu sudah dibayar — cek
      // subscription aktif (ditulis oleh Stripe webhook, lihat PRD 4.6).
      // Ini yang mencegah user "loncat" ke dashboard cuma dengan
      // memilih paket tanpa menyelesaikan pembayaran.
      final paymentActive = await authRepo.hasActiveSubscription();
      if (!paymentActive) {
        return location == '/payment' ? null : '/payment';
      }

      // Semua step onboarding sudah lengkap. Kalau user masih nyasar di
      // halaman auth/onboarding, lempar ke dashboard.
      if (isAuthRoute || _onboardingRoutes.contains(location)) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // =================================================================
      // AUTENTIKASI (Luar Navigasi Utama)
      // =================================================================
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
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        // TODO: ganti ke ForgotPasswordScreen() setelah file dibuat
        // (screens/auth/forgot_password_screen.dart, sesuai Lampiran B).
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Lupa Password'),
      ),

      // =================================================================
      // ONBOARDING (Luar Navigasi Utama, belum butuh bottom nav)
      // =================================================================
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
          // `extra` dikirim dari ChoosePlanScreen lewat context.push.
          // Kalau user masuk ke /payment tanpa extra (mis. refresh
          // browser atau deep link langsung), redirect balik ke
          // /choose-plan supaya dia pilih paket dulu.
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

      // =================================================================
      // PERUSAHAAN (Companies) — di luar shell, dipakai saat user
      // ingin menambah perusahaan tambahan di luar alur onboarding.
      // Direferensikan dari CreateLaundryScreen ("+ Daftarkan Perusahaan").
      // =================================================================
      GoRoute(
        path: '/companies/create',
        name: 'companies-create',
        // TODO: idealnya pakai screen dedicated utk "tambah perusahaan lain"
        // (bukan SetupCompanyScreen onboarding, karena itu biasanya
        // menandai companyCompleted=true di flow pendaftaran pertama).
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Tambah Perusahaan Baru'),
      ),

      // =================================================================
      // CABANG / LAUNDRIES (§3.2.3) — di luar shell (full page)
      // =================================================================
      GoRoute(
        path: '/laundries',
        name: 'laundries',
        // TODO: ganti ke LaundriesListScreen() setelah file dibuat
        // (screens/laundries/laundries_list_screen.dart).
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Daftar Cabang'),
      ),
      GoRoute(
        path: '/laundries/create',
        name: 'laundries-create',
        builder: (context, state) => const CreateLaundryScreen(),
      ),
      GoRoute(
        path: '/laundries/:laundryId',
        name: 'laundry-detail',
        // TODO: ganti ke LaundryDetailScreen(laundryId: ...) setelah file
        // dibuat (screens/laundries/laundry_detail_screen.dart).
        builder: (context, state) => PlaceholderScreen(
          title: 'Detail Cabang (${state.pathParameters['laundryId']})',
        ),
      ),

      // =================================================================
      // KARYAWAN / EMPLOYEES (§3.3.2) — di luar shell (full page)
      // =================================================================
      GoRoute(
        path: '/employees/create',
        name: 'employees-create',
        builder: (context, state) => const CreateEmployeeScreen(),
      ),
      GoRoute(
        path: '/employees/:employeeId',
        name: 'employee-detail',
        // TODO: ganti ke EmployeeDetailScreen(employeeId: ...) setelah file
        // dibuat (screens/employees/employee_detail_screen.dart).
        builder: (context, state) => PlaceholderScreen(
          title: 'Detail Karyawan (${state.pathParameters['employeeId']})',
        ),
      ),

      // =================================================================
      // PELANGGAN / CUSTOMERS (§3.3.1, alur §5.4) — di luar shell
      // =================================================================
      GoRoute(
        path: '/customers/create',
        name: 'customers-create',
        // TODO: ganti ke CreateCustomerScreen() setelah file dibuat
        // (screens/customers/create_customer_screen.dart).
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Tambah Pelanggan'),
      ),
      GoRoute(
        path: '/customers/:customerId',
        name: 'customer-detail',
        // TODO: ganti ke CustomerDetailScreen(customerId: ...) setelah file
        // dibuat (screens/customers/customer_detail_screen.dart).
        builder: (context, state) => PlaceholderScreen(
          title: 'Detail Pelanggan (${state.pathParameters['customerId']})',
        ),
      ),

      // =================================================================
      // PESANAN / ORDERS (§3.4, alur §5.2 & §5.3) — di luar shell
      // =================================================================
      GoRoute(
        path: '/orders/create',
        name: 'orders-create',
        // TODO: ganti ke CreateOrderScreen() setelah file dibuat
        // (screens/orders/create_order_screen.dart).
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Buat Pesanan Baru'),
      ),
      GoRoute(
        path: '/orders/:orderId',
        name: 'order-detail',
        // TODO: ganti ke OrderDetailScreen(orderId: ...) setelah file
        // dibuat (screens/orders/order_detail_screen.dart).
        builder: (context, state) => PlaceholderScreen(
          title: 'Detail Pesanan (${state.pathParameters['orderId']})',
        ),
      ),
      GoRoute(
        path: '/orders/:orderId/update-status',
        name: 'order-update-status',
        // TODO: ganti ke UpdateOrderStatusScreen(orderId: ...) setelah file
        // dibuat (screens/orders/update_order_status_screen.dart).
        builder: (context, state) => PlaceholderScreen(
          title: 'Update Status Pesanan (${state.pathParameters['orderId']})',
        ),
      ),

      // =================================================================
      // JENIS LAYANAN / SERVICE TYPES (§3.3.3) — di luar shell
      // =================================================================
      GoRoute(
        path: '/services',
        name: 'services',
        // TODO: ganti ke ServicesListScreen() setelah file dibuat
        // (screens/services/services_list_screen.dart).
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Daftar Layanan'),
      ),
      GoRoute(
        path: '/services/create',
        name: 'services-create',
        // TODO: ganti ke CreateServiceScreen() setelah file dibuat
        // (screens/services/create_service_screen.dart).
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Tambah Jenis Layanan'),
      ),

      // =================================================================
      // LAPORAN / REPORTS (§6 Metrik) — di luar shell
      // =================================================================
      GoRoute(
        path: '/reports',
        name: 'reports',
        // TODO: ganti ke ReportsScreen() setelah file dibuat
        // (screens/reports/reports_screen.dart).
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Laporan'),
      ),
      GoRoute(
        path: '/reports/:reportId',
        name: 'report-detail',
        // TODO: ganti ke ReportDetailScreen(reportId: ...) setelah file
        // dibuat (screens/reports/report_detail_screen.dart).
        builder: (context, state) => PlaceholderScreen(
          title: 'Detail Laporan (${state.pathParameters['reportId']})',
        ),
      ),

      // =================================================================
      // PENGATURAN / SETTINGS (§3.6, sub-halaman) — di luar shell
      // =================================================================
      GoRoute(
        path: '/settings/profile',
        name: 'settings-profile',
        // TODO: ganti ke ProfileScreen() setelah file dibuat
        // (screens/settings/profile_screen.dart).
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Profil Saya'),
      ),
      GoRoute(
        path: '/settings/subscription',
        name: 'settings-subscription',
        // Dirujuk oleh dialog "Batas Kuota Tercapai" di
        // CreateEmployeeScreen & CreateLaundryScreen — WAJIB ada supaya
        // tombol "Upgrade Paket" tidak crash.
        // TODO: ganti ke SubscriptionScreen() setelah file dibuat
        // (screens/settings/subscription_screen.dart).
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Upgrade Paket Langganan'),
      ),

      // =================================================================
      // ShellRoute: MainScreen sebagai wadah navigasi (Bottom Navigation)
      // =================================================================
      ShellRoute(
        builder: (context, state, child) {
          // child di sini adalah halaman aktif (dashboard, orders, dll.)
          // yang akan dimasukkan ke dalam MainScreen
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
            // TODO: ganti ke OrdersListScreen() setelah file dibuat
            // (screens/orders/orders_list_screen.dart).
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Orders List Screen'),
          ),
          GoRoute(
            path: '/customers',
            name: 'customers',
            // TODO: ganti ke CustomersListScreen() setelah file dibuat
            // (screens/customers/customers_list_screen.dart).
            builder: (context, state) =>
                const PlaceholderScreen(title: 'Customers List Screen'),
          ),
          GoRoute(
            path: '/employees',
            name: 'employees',
            // TODO: ganti ke EmployeesListScreen() setelah file dibuat
            // (screens/employees/employees_list_screen.dart).
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

/// Halaman Placeholder Sementara untuk fitur yang belum dibuat.
/// Dipakai di seluruh rute yang screen aslinya belum diimplementasikan
/// (lihat komentar TODO di masing-masing GoRoute di atas).
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
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// --- Auth ---
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/verify_email_screen.dart';
import '../../screens/auth/setup_profile_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';

// --- Main / Shell ---
import '../../../screens/main/main_screen.dart';
import '../../../screens/main/dashboard_screen.dart';

// --- Onboarding ---
import '../../screens/onboarding/setup_company_screen.dart';
import '../../screens/onboarding/choose_plan_screen.dart';
import '../../screens/onboarding/payment_screen.dart';

// --- Settings ---
import '../../screens/settings/setting_screen.dart';
import '../../screens/settings/edit_profile_screen.dart';
import '../../screens/settings/change_password_screen.dart';

// --- Repositories ---
import '../../repositories/auth_repository.dart';

// --- Employees ---
import '../../screens/employees/create_employee_screen.dart';

// --- Laundries ---
import 'package:netwash/screens/laundries/create_laundry_screen.dart';

// --- Orders ---
import '../../screens/orders/order_list_screen.dart';
import '../../screens/orders/create_order_screen.dart';
import '../../screens/orders/order_detail_screen.dart';

// --- Customers ---
import '../../screens/customers/customers_list_screen.dart';
import '../../screens/customers/customer_detail_screen.dart';
import '../../screens/customers/create_customer_screen.dart';
import '../../screens/customers/edit_customer_screen.dart';

// --- Reports ---
import '../../screens/reports/reports_screen.dart';

// --- Pickup & Delivery (Antar Jemput) ---
import '../../screens/delivery/pickup_delivery_screen.dart';


import '../../screens/employees/employees_list_screen.dart';
import '../../screens/employees/employee_detail_screen.dart';
import '../../screens/laundries/laundries_list_screen.dart';
import '../../screens/laundries/laundry_detail_screen.dart';
import '../../screens/services/services_list_screen.dart';
import '../../screens/services/create_service_screen.dart';
// import '../../screens/reports/reports_screen.dart';
// import '../../screens/reports/report_detail_screen.dart';
import '../../screens/settings/subscription_screen.dart';

const _authRoutes = ['/login', '/register', '/forgot-password'];

const _onboardingRoutes = [
  '/verify-email',
  '/setup-profile',
  '/setup-company',
  '/choose-plan',
  '/payment',
];

/// Alias rute lama -> rute kanonik baru, biar navigasi lama tidak putus.
const Map<String, String> _legacyRouteAliases = {
  '/create-employee': '/employees/create',
};

/// GlobalKey khusus untuk root ShellRoute (StatefulShellRoute) supaya
/// state tiap branch (Dashboard/Orders/Customers/Settings) tetap
/// dipertahankan oleh GoRouter selama app hidup.
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  // Pakai ref.read, BUKAN ref.watch: GoRouter di bawah ini sudah
  // dengarin perubahan auth lewat `refreshListenable:
  // GoRouterRefreshStream(...)` sendiri. Kalau pakai ref.watch, provider
  // ini (dan makanya GoRouter-nya) dibikin ULANG tiap authRepo berubah,
  // padahal navigatorKey (_rootNavigatorKey/_shellNavigatorKey) di
  // bawah itu variabel global yang sama terus -> GoRouter versi baru
  // nyoba attach ke Navigator pakai key yang sama dengan versi lama yang
  // belum sempat dibuang -> "A GlobalKey was used multiple times".
  final authRepo = ref.read(authRepositoryProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authRepo.authStateChanges),
    redirect: (context, state) async {
      final user = authRepo.currentUser;
      final location = state.matchedLocation;

      if (_legacyRouteAliases.containsKey(location)) {
        return _legacyRouteAliases[location];
      }

      final isAuthRoute = _authRoutes.contains(location);

      // Belum login -> paksa ke login, kecuali sedang menuju auth route.
      if (user == null) {
        return isAuthRoute ? null : '/login';
      }

      // Ambil profil sekali di awal, dipakai buat cek status verifikasi
      // (dari Firestore, bukan user.emailVerified bawaan FirebaseAuth yang
      // selalu false untuk akun phone-only) dan progres onboarding.
      final profile = await authRepo.getUserProfile();
      final emailVerified = profile?['emailVerified'] == true;

      if (!emailVerified) {
        return location == '/verify-email' ? null : '/verify-email';
      }

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

      final paymentActive = await authRepo.hasActiveSubscription();
      if (!paymentActive) {
        return location == '/payment' ? null : '/payment';
      }

      // Kecualikan flow upgrade: /choose-plan dan /payment memang
      // sengaja diakses ULANG oleh user yang SUDAH fully onboarded,
      // lewat SubscriptionScreen -> context.push(..., extra:
      // {'isUpgrade': true}). Tanpa pengecualian ini, redirect di atas
      // bakal langsung nendang mereka balik ke /dashboard begitu
      // /choose-plan match (karena route itu ada di _onboardingRoutes),
      // padahal /dashboard sendiri lagi aktif di layar -> dua navigasi
      // rebutan di frame yang sama -> race condition GlobalKey/Navigator
      // ("keyReservation.contains(key) is not true").
      final extra = state.extra;
      final isUpgradeFlow = extra is Map && extra['isUpgrade'] == true;
      final isUpgradeRoute =
          isUpgradeFlow && (location == '/choose-plan' || location == '/payment');

      if (!isUpgradeRoute && (isAuthRoute || _onboardingRoutes.contains(location))) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // ==================== AUTH ====================
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
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // ==================== ONBOARDING ====================
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
        // Baca flag isUpgrade dari extra (dikirim SubscriptionScreen saat
        // user yang sudah aktif mau ganti paket). Kalau diakses tanpa
        // extra (mis. langsung dari flow onboarding lewat redirect),
        // isUpgrade default false.
        builder: (context, state) {
          final extra = state.extra;
          final isUpgrade = extra is Map ? (extra['isUpgrade'] as bool? ?? false) : false;
          return ChoosePlanScreen(isUpgrade: isUpgrade);
        },
      ),
      GoRoute(
        path: '/payment',
        name: 'payment',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) return const ChoosePlanScreen();
          final companyId = extra['companyId'] as String?;
          if (companyId == null) {
            // companyId wajib ada supaya webhook Stripe bisa menulis
            // company_id yang benar ke dokumen subscription. Kalau kosong,
            // balikin ke choose-plan daripada bikin runtime error.
            return const ChoosePlanScreen();
          }
          return PaymentScreen(
            planName: extra['planName'] as String,
            isYearly: extra['isYearly'] as bool,
            price: extra['price'] as double,
            isUpgrade: extra['isUpgrade'] as bool? ?? false,
            companyId: companyId,
          );
        },
      ),

      // ==================== COMPANIES ====================
      // Sesuai PRD (5.1 & 3.6.1): 1 user = 1 perusahaan, dibuat sekali
      // lewat SetupCompanyScreen saat onboarding. Route ini BUKAN fitur
      // "multi-company" — cuma fallback kalau CreateLaundryScreen tidak
      // menemukan data company (data-inconsistency, seharusnya tidak
      // terjadi di alur normal). Pakai ulang SetupCompanyScreen yang sama
      // (isOnboarding: false) alih-alih bikin screen terpisah.
      GoRoute(
        path: '/companies/create',
        name: 'companies-create',
        builder: (context, state) =>
            const SetupCompanyScreen(isOnboarding: false),
      ),

      // ==================== LAUNDRIES ====================
      GoRoute(
        path: '/laundries',
        name: 'laundries',
        builder: (context, state) =>
            const LaundriesListScreen(),
      ),
      GoRoute(
        path: '/laundries/create',
        name: 'laundries-create',
        builder: (context, state) => const CreateLaundryScreen(),
      ),
      GoRoute(
        path: '/laundries/:laundryId',
        name: 'laundry-detail',
        builder: (context, state) => LaundryDetailScreen(
          laundryId: state.pathParameters['laundryId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/laundries/:id/edit',
        builder: (context, state) => CreateLaundryScreen(
          laundryId: state.pathParameters['id'],
        ),
      ),

      // ==================== EMPLOYEES ====================
      GoRoute(
        path: '/employees',
        name: 'employees-list',
        builder: (context, state) => const EmployeesListScreen(),
      ),

      GoRoute(
        path: '/employees/create',
        name: 'employees-create',
        builder: (context, state) => const CreateEmployeeScreen(),
      ),
     GoRoute(
        path: '/employees/:employeeId', // Tetap pakai '/' karena rute ini sejajar/independen
        name: 'employee-detail',
        builder: (context, state) {
          final id = state.pathParameters['employeeId'] ?? '';
          return EmployeeDetailScreen(employeeId: id);
        },
      ),
      GoRoute(

      path: '/employees/:employeeId/edit',
      name: 'employee-edit',
      builder: (context, state) {
        final id = state.pathParameters['employeeId'] ?? '';
        return CreateEmployeeScreen(employeeId: id);
      },
    ),

     // == ,================== CUSTOMERS ====================
      GoRoute(
        path: '/customers/create',
        name: 'customers-create',
        builder: (context, state) => const CreateCustomerScreen(),
      ),
      GoRoute(
        path: '/customers/:customerId/edit',
        name: 'customer-edit',
        builder: (context, state) => EditCustomerScreen(
          customerId: state.pathParameters['customerId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/customers/:customerId',
        name: 'customer-detail',
        builder: (context, state) => CustomerDetailScreen(
          customerId: state.pathParameters['customerId'] ?? '',
        ),
      ),

// ==================== ORDERS ====================
      GoRoute(
        path: '/create-order',
        name: 'create-order',
        builder: (context, state) => const CreateOrderScreen(),
      ),
      GoRoute(
        path: '/orders/create',
        name: 'orders-create',
        builder: (context, state) => const CreateOrderScreen(), 
      ),
      GoRoute(
        path: '/orders/:orderId',
        name: 'order-detail',
        builder: (context, state) => OrderDetailScreen( 
          orderId: state.pathParameters['orderId'] ?? '',
        ),
      ),
      // Catatan: tidak ada route terpisah untuk "update status pesanan".
      // Perubahan status (beserta status_history & actual_completion)
      // sudah ditangani langsung di dalam OrderDetailScreen di atas.

      // ==================== SERVICES ====================
      GoRoute(
        path: '/services',
        name: 'services',
        builder: (context, state) =>
            const ServicesListScreen(),
      ),
      GoRoute(
        path: '/services/create',
        name: 'services-create',
        builder: (context, state) =>
            const CreateServiceScreen(),
      ),

      // ==================== REPORTS ====================
      GoRoute(
        path: '/laporan',
        name: 'reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/laporan/:reportId',
        name: 'report-detail',
        builder: (context, state) => PlaceholderScreen(
          title: 'Detail Laporan (${state.pathParameters['reportId']})',
        ),
      ),

      // ==================== ANTAR JEMPUT (Pickup & Delivery) ====================
      GoRoute(
        path: '/antar-jemput',
        name: 'pickup-delivery',
        builder: (context, state) => const PickupDeliveryScreen(),
      ),

      // ==================== SETTINGS ====================
      GoRoute(
        path: '/settings/profile',
        name: 'settings-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
      path: '/settings/change-password',
      builder: (context, state) => const ChangePasswordScreen(),
    ),
      GoRoute(
        path: '/settings/subscription',
        name: 'settings-subscription',
        // Dirujuk dialog "Batas Kuota Tercapai" di Create Employee/Laundry,
        // dan dari menu Settings. TIDAK terdaftar di _onboardingRoutes, jadi
        // aman diakses user yang sudah fully onboarded (tidak ke-redirect
        // paksa ke /dashboard).
        //
        // Nampilin dulu plan aktif user (SubscriptionScreen). Dari situ
        // ada tombol "Upgrade Paket" yang baru masuk ke /choose-plan
        // dengan extra isUpgrade: true.
        builder: (context, state) => const SubscriptionScreen(),
      ),

      // ==================== SHELL (Bottom Navigation) ====================
      // Diganti dari ShellRoute biasa ke StatefulShellRoute.indexedStack.
      // Alasan: dengan ShellRoute biasa, tiap pindah tab GoRouter membangun
      // ULANG halaman dari nol (semua StreamBuilder Firestore connect
      // ulang -> kerasa lag/lama tiap klik bottom nav). Dengan
      // indexedStack, ke-4 tab (Dashboard/Orders/Customers/Settings)
      // dipertahankan hidup di background lewat IndexedStack, jadi pindah
      // tab instan dan stream Firestore-nya nggak connect ulang.
      //
      // Catatan: sebelumnya ada GoRoute duplikat path '/employees' di
      // dalam shell (builder: PlaceholderScreen) yang bentrok dengan
      // '/employees' asli di luar shell (EmployeesListScreen). Employees
      // memang bukan tab bottom nav (cuma diakses lewat Quick Action), jadi
      // route duplikat itu dihapus di sini.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKey,
            routes: [
              GoRoute(
                path: '/dashboard',
                name: 'dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                name: 'orders',
                builder: (context, state) => const OrdersListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customers',
                name: 'customers',
                builder: (context, state) => const CustomersListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Bikin GoRouter re-evaluate `redirect` tiap kali status auth berubah.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Placeholder untuk screen yang belum diimplementasikan.
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
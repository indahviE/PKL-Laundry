import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

// --- Reports ---
import '../../screens/reports/reports_screen.dart';


// Screen di bawah belum dibuat filenya, pakai PlaceholderScreen sementara.
// import '../../screens/auth/forgot_password_screen.dart';
// import '../../screens/orders/orders_list_screen.dart';
// import '../../screens/orders/order_detail_screen.dart';
// import '../../screens/orders/create_order_screen.dart';
// import '../../screens/orders/update_order_status_screen.dart';
// import '../../screens/customers/customers_list_screen.dart';
// import '../../screens/customers/customer_detail_screen.dart';
// import '../../screens/customers/create_customer_screen.dart';
import '../../screens/employees/employees_list_screen.dart';
import '../../screens/employees/employee_detail_screen.dart';
// import '../../screens/laundries/laundries_list_screen.dart';
// import '../../screens/laundries/laundry_detail_screen.dart';
import '../../screens/services/services_list_screen.dart';
import '../../screens/services/create_service_screen.dart';
// import '../../screens/reports/reports_screen.dart';
// import '../../screens/reports/report_detail_screen.dart';
// import '../../screens/settings/subscription_screen.dart';

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

final goRouterProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);

  return GoRouter(
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

      if (isAuthRoute || _onboardingRoutes.contains(location)) {
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
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Lupa Password'),
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
        builder: (context, state) => const ChoosePlanScreen(),
      ),
      GoRoute(
        path: '/payment',
        name: 'payment',
        builder: (context, state) {
          // extra dikirim dari ChoosePlanScreen; kalau kosong (mis. refresh
          // langsung di /payment), lempar balik ke choose-plan.
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) return const ChoosePlanScreen();
          return PaymentScreen(
            planName: extra['planName'] as String,
            isYearly: extra['isYearly'] as bool,
            price: extra['price'] as double,
          );
        },
      ),

      // ==================== COMPANIES ====================
      GoRoute(
        path: '/companies/create',
        name: 'companies-create',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Tambah Perusahaan Baru'),
      ),

      // ==================== LAUNDRIES ====================
      GoRoute(
        path: '/laundries',
        name: 'laundries',
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
        builder: (context, state) => PlaceholderScreen(
          title: 'Detail Cabang (${state.pathParameters['laundryId']})',
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

     // ==================== CUSTOMERS ====================
      GoRoute(
        path: '/customers/create',
        name: 'customers-create',
        builder: (context, state) => const CreateCustomerScreen(),
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
      GoRoute(
        path: '/orders/:orderId/update-status',
        name: 'order-update-status',
        builder: (context, state) => PlaceholderScreen(
          title: 'Update Status Pesanan (${state.pathParameters['orderId']})',
        ),
      ),

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
        // Dirujuk dialog "Batas Kuota Tercapai" di Create Employee/Laundry.
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Upgrade Paket Langganan'),
      ),

      // ==================== SHELL (Bottom Navigation) ====================
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
         GoRoute(
            path: '/orders',
            name: 'orders',
            builder: (context, state) => const OrdersListScreen(), 
          ),
          GoRoute(
            path: '/customers',
            name: 'customers',
            builder: (context, state) => const CustomersListScreen(), 
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
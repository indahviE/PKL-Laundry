import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import providers
// NOTE: Uncomment ini ketika auth_provider sudah dibuat
// import '../../providers/auth_provider.dart';

// Import screens
// NOTE: Uncomment ini ketika screens sudah dibuat
// import '../../screens/auth/login_screen.dart';
// import '../../screens/auth/register_screen.dart';
// import '../../screens/auth/forgot_password_screen.dart';
// import '../../screens/main/dashboard_screen.dart';

/// GoRouter configuration untuk navigasi aplikasi
final goRouterProvider = Provider<GoRouter>((ref) {
  // NOTE: Uncomment ini ketika auth_provider sudah dibuat
  // final isAuthenticated = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    initialLocation: '/login',
    // redirect: (context, state) {
    //   final isLoggingIn = state.matchedLocation == '/login' ||
    //       state.matchedLocation == '/register' ||
    //       state.matchedLocation == '/forgot-password';

    //   // Jika tidak authenticated dan bukan di login page, redirect ke login
    //   if (!isAuthenticated && !isLoggingIn) {
    //     return '/login';
    //   }

    //   // Jika authenticated dan di login page, redirect ke dashboard
    //   if (isAuthenticated && isLoggingIn) {
    //     return '/dashboard';
    //   }

    //   // Tidak perlu redirect
    //   return null;
    // },
    routes: [
      // ============================================
      // AUTH ROUTES
      // ============================================
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) {
          // TODO: Uncomment ketika LoginScreen sudah dibuat
          // return const LoginScreen();
          
          // Placeholder untuk sekarang
          return const PlaceholderScreen(title: 'Login Screen');
        },
        routes: [
          GoRoute(
            path: 'register',
            name: 'register',
            builder: (context, state) {
              // TODO: Uncomment ketika RegisterScreen sudah dibuat
              // return const RegisterScreen();
              
              return const PlaceholderScreen(title: 'Register Screen');
            },
          ),
          GoRoute(
            path: 'forgot-password',
            name: 'forgot-password',
            builder: (context, state) {
              // TODO: Uncomment ketika ForgotPasswordScreen sudah dibuat
              // return const ForgotPasswordScreen();
              
              return const PlaceholderScreen(title: 'Forgot Password Screen');
            },
          ),
        ],
      ),

      GoRoute(
        path: '/register',
        name: 'register-standalone',
        builder: (context, state) {
          // TODO: Uncomment ketika RegisterScreen sudah dibuat
          // return const RegisterScreen();
          
          return const PlaceholderScreen(title: 'Register Screen');
        },
      ),

      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password-standalone',
        builder: (context, state) {
          // TODO: Uncomment ketika ForgotPasswordScreen sudah dibuat
          // return const ForgotPasswordScreen();
          
          return const PlaceholderScreen(title: 'Forgot Password Screen');
        },
      ),

      // ============================================
      // MAIN ROUTES (After Authentication)
      // ============================================
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) {
          // TODO: Uncomment ketika DashboardScreen sudah dibuat
          // return const DashboardScreen();
          
          return const PlaceholderScreen(title: 'Dashboard Screen');
        },
      ),

      // ============================================
      // ORDERS ROUTES
      // ============================================
      GoRoute(
        path: '/orders',
        name: 'orders',
        builder: (context, state) {
          // TODO: Uncomment ketika OrdersListScreen sudah dibuat
          // return const OrdersListScreen();
          
          return const PlaceholderScreen(title: 'Orders List Screen');
        },
        routes: [
          GoRoute(
            path: ':orderId',
            name: 'order-detail',
            builder: (context, state) {
              final orderId = state.pathParameters['orderId'];
              // TODO: Uncomment ketika OrderDetailScreen sudah dibuat
              // return OrderDetailScreen(orderId: orderId ?? '');
              
              return PlaceholderScreen(title: 'Order Detail: $orderId');
            },
          ),
          GoRoute(
            path: 'create',
            name: 'create-order',
            builder: (context, state) {
              // TODO: Uncomment ketika CreateOrderScreen sudah dibuat
              // return const CreateOrderScreen();
              
              return const PlaceholderScreen(title: 'Create Order Screen');
            },
          ),
        ],
      ),

      // ============================================
      // CUSTOMERS ROUTES
      // ============================================
      GoRoute(
        path: '/customers',
        name: 'customers',
        builder: (context, state) {
          // TODO: Uncomment ketika CustomersListScreen sudah dibuat
          // return const CustomersListScreen();
          
          return const PlaceholderScreen(title: 'Customers List Screen');
        },
        routes: [
          GoRoute(
            path: ':customerId',
            name: 'customer-detail',
            builder: (context, state) {
              final customerId = state.pathParameters['customerId'];
              // TODO: Uncomment ketika CustomerDetailScreen sudah dibuat
              // return CustomerDetailScreen(customerId: customerId ?? '');
              
              return PlaceholderScreen(title: 'Customer Detail: $customerId');
            },
          ),
          GoRoute(
            path: 'create',
            name: 'create-customer',
            builder: (context, state) {
              // TODO: Uncomment ketika CreateCustomerScreen sudah dibuat
              // return const CreateCustomerScreen();
              
              return const PlaceholderScreen(title: 'Create Customer Screen');
            },
          ),
        ],
      ),

      // ============================================
      // EMPLOYEES ROUTES
      // ============================================
      GoRoute(
        path: '/employees',
        name: 'employees',
        builder: (context, state) {
          // TODO: Uncomment ketika EmployeesListScreen sudah dibuat
          // return const EmployeesListScreen();
          
          return const PlaceholderScreen(title: 'Employees List Screen');
        },
        routes: [
          GoRoute(
            path: ':employeeId',
            name: 'employee-detail',
            builder: (context, state) {
              final employeeId = state.pathParameters['employeeId'];
              // TODO: Uncomment ketika EmployeeDetailScreen sudah dibuat
              // return EmployeeDetailScreen(employeeId: employeeId ?? '');
              
              return PlaceholderScreen(title: 'Employee Detail: $employeeId');
            },
          ),
          GoRoute(
            path: 'create',
            name: 'create-employee',
            builder: (context, state) {
              // TODO: Uncomment ketika CreateEmployeeScreen sudah dibuat
              // return const CreateEmployeeScreen();
              
              return const PlaceholderScreen(title: 'Create Employee Screen');
            },
          ),
        ],
      ),

      // ============================================
      // LAUNDRIES ROUTES
      // ============================================
      GoRoute(
        path: '/laundries',
        name: 'laundries',
        builder: (context, state) {
          // TODO: Uncomment ketika LaundriesListScreen sudah dibuat
          // return const LaundriesListScreen();
          
          return const PlaceholderScreen(title: 'Laundries List Screen');
        },
        routes: [
          GoRoute(
            path: ':laundryId',
            name: 'laundry-detail',
            builder: (context, state) {
              final laundryId = state.pathParameters['laundryId'];
              // TODO: Uncomment ketika LaundryDetailScreen sudah dibuat
              // return LaundryDetailScreen(laundryId: laundryId ?? '');
              
              return PlaceholderScreen(title: 'Laundry Detail: $laundryId');
            },
          ),
          GoRoute(
            path: 'create',
            name: 'create-laundry',
            builder: (context, state) {
              // TODO: Uncomment ketika CreateLaundryScreen sudah dibuat
              // return const CreateLaundryScreen();
              
              return const PlaceholderScreen(title: 'Create Laundry Screen');
            },
          ),
        ],
      ),

      // ============================================
      // SERVICES ROUTES
      // ============================================
      GoRoute(
        path: '/services',
        name: 'services',
        builder: (context, state) {
          // TODO: Uncomment ketika ServicesListScreen sudah dibuat
          // return const ServicesListScreen();
          
          return const PlaceholderScreen(title: 'Services List Screen');
        },
        routes: [
          GoRoute(
            path: 'create',
            name: 'create-service',
            builder: (context, state) {
              // TODO: Uncomment ketika CreateServiceScreen sudah dibuat
              // return const CreateServiceScreen();
              
              return const PlaceholderScreen(title: 'Create Service Screen');
            },
          ),
        ],
      ),

      // ============================================
      // REPORTS ROUTES
      // ============================================
      GoRoute(
        path: '/reports',
        name: 'reports',
        builder: (context, state) {
          // TODO: Uncomment ketika ReportsScreen sudah dibuat
          // return const ReportsScreen();
          
          return const PlaceholderScreen(title: 'Reports Screen');
        },
        routes: [
          GoRoute(
            path: ':reportId',
            name: 'report-detail',
            builder: (context, state) {
              final reportId = state.pathParameters['reportId'];
              // TODO: Uncomment ketika ReportDetailScreen sudah dibuat
              // return ReportDetailScreen(reportId: reportId ?? '');
              
              return PlaceholderScreen(title: 'Report Detail: $reportId');
            },
          ),
        ],
      ),

      // ============================================
      // SETTINGS ROUTES
      // ============================================
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) {
          // TODO: Uncomment ketika SettingsScreen sudah dibuat
          // return const SettingsScreen();
          
          return const PlaceholderScreen(title: 'Settings Screen');
        },
        routes: [
          GoRoute(
            path: 'profile',
            name: 'profile',
            builder: (context, state) {
              // TODO: Uncomment ketika ProfileScreen sudah dibuat
              // return const ProfileScreen();
              
              return const PlaceholderScreen(title: 'Profile Screen');
            },
          ),
          GoRoute(
            path: 'subscription',
            name: 'subscription',
            builder: (context, state) {
              // TODO: Uncomment ketika SubscriptionScreen sudah dibuat
              // return const SubscriptionScreen();
              
              return const PlaceholderScreen(title: 'Subscription Screen');
            },
          ),
        ],
      ),
    ],
  );
});

// ============================================
// ROUTE EXTENSIONS
// ============================================

extension GoRouterExt on GoRouter {
  /// Navigate ke login
  void goToLogin() => go('/login');

  /// Navigate ke register
  void goToRegister() => go('/register');

  /// Navigate ke forgot password
  void goToForgotPassword() => go('/forgot-password');

  /// Navigate ke dashboard
  void goToDashboard() => go('/dashboard');

  /// Navigate ke orders list
  void goToOrders() => go('/orders');

  /// Navigate ke order detail
  void goToOrderDetail(String orderId) => go('/orders/$orderId');

  /// Navigate ke create order
  void goToCreateOrder() => go('/orders/create');

  /// Navigate ke customers list
  void goToCustomers() => go('/customers');

  /// Navigate ke customer detail
  void goToCustomerDetail(String customerId) => go('/customers/$customerId');

  /// Navigate ke create customer
  void goToCreateCustomer() => go('/customers/create');

  /// Navigate ke employees list
  void goToEmployees() => go('/employees');

  /// Navigate ke employee detail
  void goToEmployeeDetail(String employeeId) => go('/employees/$employeeId');

  /// Navigate ke create employee
  void goToCreateEmployee() => go('/employees/create');

  /// Navigate ke laundries list
  void goToLaundries() => go('/laundries');

  /// Navigate ke laundry detail
  void goToLaundryDetail(String laundryId) => go('/laundries/$laundryId');

  /// Navigate ke create laundry
  void goToCreateLaundry() => go('/laundries/create');

  /// Navigate ke services list
  void goToServices() => go('/services');

  /// Navigate ke create service
  void goToCreateService() => go('/services/create');

  /// Navigate ke reports
  void goToReports() => go('/reports');

  /// Navigate ke report detail
  void goToReportDetail(String reportId) => go('/reports/$reportId');

  /// Navigate ke settings
  void goToSettings() => go('/settings');

  /// Navigate ke profile settings
  void goToProfileSettings() => go('/settings/profile');

  /// Navigate ke subscription settings
  void goToSubscriptionSettings() => go('/settings/subscription');
}

// ============================================
// PLACEHOLDER SCREEN (untuk testing)
// ============================================

import 'package:flutter/material.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.work_outline,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Screen ini akan diimplementasikan segera',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
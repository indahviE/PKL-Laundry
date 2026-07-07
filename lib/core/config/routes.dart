import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../screens/auth/login_screen.dart';

/// GoRouter configuration
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const PlaceholderScreen(
          title: 'Dashboard Screen',
        ),
      ),
      GoRoute(
        path: '/orders',
        name: 'orders',
        builder: (context, state) => const PlaceholderScreen(
          title: 'Orders List Screen',
        ),
      ),
      GoRoute(
        path: '/customers',
        name: 'customers',
        builder: (context, state) => const PlaceholderScreen(
          title: 'Customers List Screen',
        ),
      ),
      GoRoute(
        path: '/employees',
        name: 'employees',
        builder: (context, state) => const PlaceholderScreen(
          title: 'Employees List Screen',
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const PlaceholderScreen(
          title: 'Settings Screen',
        ),
      ),
    ],
  );
});

/// Placeholder Screen
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
// lib/providers/app_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order; // Hindari bentrok keyword
import '../repositories/order_repository.dart';
import '../repositories/customer_repository.dart'; 
import '../services/dashboard_service.dart';
import '../models/order.dart';
import '../models/customer.dart'; 
import '../models/subscription.dart';

// AKALAN CERDAS: Mengganti StateProvider lama menjadi Notifier versi baru yang lebih stabil di VS Code
class UserNotifier extends Notifier<String> {
  @override
  String build() {
    return "TARGET_USER_ID_FROM_FIREBASE_AUTH"; // ID Sementara sebelum ada Auth
  }

  void updateUserId(String newId) {
    state = newId;
  }
}

// Ini pengganti userIdProvider yang merah tadi, dijamin Analyzer VS Code langsung hijau
final userIdProvider = NotifierProvider<UserNotifier, String>(() {
  return UserNotifier();
});

// Repository Providers (Membaca userIdNotifier secara otomatis)
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final uid = ref.watch(userIdProvider);
  return OrderRepository(userId: uid);
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final uid = ref.watch(userIdProvider);
  return CustomerRepository(userId: uid);
});

// Service Provider
final dashboardServiceProvider = Provider<DashboardService>((ref) => DashboardService());

// Streams untuk Real-time UI Data
final ordersStreamProvider = StreamProvider<List<Order>>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getAllOrders();
});

final customersStreamProvider = StreamProvider<List<Customer>>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.streamCustomers();
});

// Stream Subscription 
final subscriptionStreamProvider = StreamProvider<Subscription?>((ref) {
  final uid = ref.watch(userIdProvider);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('subscriptions')
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map((snap) => snap.docs.isEmpty 
          ? null 
          : Subscription.fromJson(snap.docs.first.data(), snap.docs.first.id)); 
});

// Provider Metrik Dashboard reaktif
final dashboardMetricsProvider = Provider<AsyncValue<DashboardMetrics>>((ref) {
  final ordersAsync = ref.watch(ordersStreamProvider);
  final service = ref.watch(dashboardServiceProvider);

  return ordersAsync.whenData((orders) => service.calculateRealtimeMetrics(orders));
});
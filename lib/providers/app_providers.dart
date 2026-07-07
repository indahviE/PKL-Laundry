// lib/providers/app_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order; // Hindari bentrok keyword
import '../repositories/order_repository.dart';
import '../repositories/customer_repository.dart'; // Tambahkan ini
import '../services/dashboard_service.dart';
import '../models/order.dart';
import '../models/customer.dart'; // Tambahkan ini
import '../models/subscription.dart';

// Provider ID Pengguna aktif (Diambil dinamis lewat Auth State jika sudah siap)
final userIdProvider = StateProvider<String>((ref) => "TARGET_USER_ID_FROM_FIREBASE_AUTH");

// Repository Providers (Pola Seragam: Membaca userId secara otomatis)
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

// Stream Subscription (Urutan parameter .fromJson sudah diperbaiki)
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
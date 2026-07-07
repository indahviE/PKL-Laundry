// lib/services/dashboard_service.dart

import 'package:intl/intl.dart';
import '../models/order.dart';

class DashboardMetrics {
  final int totalOrders;
  final int activeOrders;
  final double todayRevenue;
  final List<MapEntry<String, double>> topServices;

  DashboardMetrics({
    required this.totalOrders,
    required this.activeOrders,
    required this.todayRevenue,
    required this.topServices,
  });
}

class DashboardService {
  DashboardMetrics calculateRealtimeMetrics(List<Order> orders) {
    int totalOrders = orders.length;
    int activeOrders = 0;
    double todayRevenue = 0.0;
    
    Map<String, double> serviceUsageMap = {};
    final String todayStr = DateFormat('yyyyMMdd').format(DateTime.now());

    for (var order in orders) {
      // 1. Hitung Pesanan Aktif
      if (order.status != OrderStatus.completed && order.status != OrderStatus.cancelled) {
        activeOrders++;
      }

      // 2. Hitung Omzet Hari Ini
      final String orderDateStr = DateFormat('yyyyMMdd').format(order.createdAt);
      if (orderDateStr == todayStr && order.paymentStatus == PaymentStatus.paid) {
        todayRevenue += order.totalAmount;
      }

      // 3. Rekap Produk/Layanan Terlaris (SUDAH DIPERBAIKI)
      for (var item in order.items) {
        final serviceName = item.serviceName.isEmpty ? 'Layanan Umum' : item.serviceName;
        final quantity = item.quantity;
        serviceUsageMap[serviceName] = (serviceUsageMap[serviceName] ?? 0.0) + quantity;
      }
    }

    final sortedServices = serviceUsageMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final top5Services = sortedServices.take(5).toList();

    return DashboardMetrics(
      totalOrders: totalOrders,
      activeOrders: activeOrders,
      todayRevenue: todayRevenue,
      topServices: top5Services,
    );
  }
}
// lib/services/subscription_service.dart
import '../models/subscription.dart';

class SubscriptionService {
  final Subscription? currentSubscription;

  SubscriptionService({required this.currentSubscription});

  String get planId => currentSubscription?.planId ?? 'starter';
  String get status => currentSubscription?.status ?? 'inactive';

  bool get isSubscriptionActive => status == 'active';

  // [PRD 3.6.1]: Batasan Maksimal Cabang (Diambil langsung dari limits Firestore)
  int get maxLaundriesAllowed {
    if (!isSubscriptionActive) return 1;
    // Membaca key 'max_laundries' yang dikirim dari server/database
    return currentSubscription?.limits.maxLaundries ?? 1;
  }

  // [PRD 3.6.1]: Batasan Maksimal Karyawan (Diambil langsung dari limits Firestore)
  int get maxEmployeesAllowed {
    if (!isSubscriptionActive) return 5;
    // Membaca key 'max_employees' yang dikirim dari server/database
    return currentSubscription?.limits.maxEmployees ?? 5;
  }

  // [PRD 3.6.1]: Batasan Maksimal Order per Bulan (Diambil langsung dari limits Firestore)
  int get maxOrdersPerMonth {
    if (!isSubscriptionActive) return 500;
    // Membaca key 'max_orders_per_month' yang dikirim dari server/database
    return currentSubscription?.limits.maxOrdersPerMonth ?? 500;
  }

  // Validasi Gating sebelum melakukan penambahan Laundry/Cabang secara lokal
  bool canAddLaundry(int currentLaundryCount) {
    if (maxLaundriesAllowed == -1) return true; // -1 berarti unlimited
    return currentLaundryCount < maxLaundriesAllowed;
  }

  // Validasi Gating sebelum melakukan penambahan Karyawan
  bool canAddEmployee(int currentEmployeeCount) {
    if (maxEmployeesAllowed == -1) return true; // -1 berarti unlimited
    return currentEmployeeCount < maxEmployeesAllowed;
  }

  // Validasi Gating sebelum membuat Order baru
  bool canCreateOrder(int currentOrdersThisMonthCount) {
    if (maxOrdersPerMonth == -1) return true; // -1 berarti unlimited
    return currentOrdersThisMonthCount < maxOrdersPerMonth;
  }
}
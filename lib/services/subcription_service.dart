// lib/services/subscription_service.dart
import '../models/subscription.dart';

class SubscriptionService {
  final Subscription? currentSubscription;

  SubscriptionService({required this.currentSubscription});

  String get planId => currentSubscription?.planId ?? 'starter';
  String get status => currentSubscription?.status ?? 'inactive';

  bool get isSubscriptionActive => status == 'active';

  // [PRD 3.6.1]: Batasan Maksimal Cabang
  int get maxLaundriesAllowed {
    if (!isSubscriptionActive) return 1;
    if (planId == 'enterprise') return -1; // tak terbatas
    if (planId == 'professional') return 5;
    return 1;
  }

  // [PRD 3.6.1]: Batasan Maksimal Karyawan
  int get maxEmployeesAllowed {
    if (!isSubscriptionActive) return 5;
    if (planId == 'enterprise') return -1;
    if (planId == 'professional') return 25;
    return 5;
  }

  // [PRD 3.6.1]: Batasan Maksimal Order per Bulan
  int get maxOrdersPerMonth {
    if (!isSubscriptionActive) return 500;
    if (planId == 'enterprise') return -1;
    if (planId == 'professional') return 2000;
    return 500;
  }

  // Validasi Gating sebelum melakukan penambahan entitas baru secara lokal
  bool canAddLaundry(int currentLaundryCount) {
    if (maxLaundriesAllowed == -1) return true;
    return currentLaundryCount < maxLaundriesAllowed;
  }
}
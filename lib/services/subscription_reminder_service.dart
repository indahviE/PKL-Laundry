// lib/services/subscription_reminder_service.dart
//
// Reminder H-3/H-1 sebelum `current_period_end` -- versi CLIENT-SIDE.
//
// Kenapa client-side, bukan Cloud Functions scheduled job: project ini
// masih di plan Firebase Spark (belum upgrade ke Blaze), dan Cloud
// Functions -- termasuk yang dijadwalkan (scheduled/pub-sub trigger) --
// wajib Blaze, tidak ada jalan lain. Konsekuensinya reminder ini HANYA
// muncul kalau user benar-benar buka app pas H-3/H-1; kalau app nggak
// dibuka di hari itu, reminder-nya lewat begitu saja (tidak proaktif
// seperti push notification asli). Lihat SubscriptionService untuk guard
// akses fitur yang terpisah dari reminder ini.
//
// SENGAJA dipisah dari banner grace period (_buildSubscriptionBanner di
// dashboard_screen.dart): banner itu untuk status SUDAH bermasalah
// (past_due), sedangkan reminder ini untuk subscription yang MASIH aktif
// tapi mau segera habis -- dua kondisi yang tidak akan pernah tumpang
// tindih (checkDue() cuma jalan kalau status active/trialing).
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';

class SubscriptionReminderService {
  /// H-3 dan H-1 sebelum currentPeriodEnd.
  static const List<int> _reminderDays = [3, 1];

  /// Mengecek apakah reminder perlu ditampilkan SEKARANG untuk
  /// [subscription] ini, dan kalau iya langsung menandainya sebagai
  /// "sudah ditampilkan" (supaya tidak muncul berkali-kali untuk
  /// currentPeriodEnd + jumlah hari yang sama).
  ///
  /// Return null kalau:
  /// - status subscription bukan 'active'/'trialing' (subscription yang
  ///   sudah past_due/canceled/dll ditangani banner grace period, bukan
  ///   di sini), atau
  /// - hari ini bukan tepat H-3 atau H-1 dari currentPeriodEnd, atau
  ///   sudah pernah ditampilkan untuk kombinasi (subscription id,
  ///   currentPeriodEnd, daysLeft) ini.
  ///
  /// Return jumlah hari tersisa (3 atau 1) kalau reminder perlu tampil.
  static Future<int?> checkDue(Subscription subscription) async {
    if (subscription.status != 'active' && subscription.status != 'trialing') {
      return null;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = subscription.currentPeriodEnd;
    final endDay = DateTime(end.year, end.month, end.day);
    final daysLeft = endDay.difference(today).inDays;

    if (!_reminderDays.contains(daysLeft)) return null;

    final prefs = await SharedPreferences.getInstance();
    final key = _prefsKey(subscription.id, endDay, daysLeft);
    final alreadyShown = prefs.getBool(key) ?? false;
    if (alreadyShown) return null;

    await prefs.setBool(key, true);
    return daysLeft;
  }

  static String _prefsKey(String subscriptionId, DateTime endDay, int daysLeft) {
    final endKey = '${endDay.year}-${endDay.month}-${endDay.day}';
    return 'sub_renewal_reminder_${subscriptionId}_${endKey}_h$daysLeft';
  }
}

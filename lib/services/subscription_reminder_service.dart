// lib/services/subscription_reminder_service.dart
//
// Reminder sebelum & sesudah `current_period_end` -- versi CLIENT-SIDE.
//
// Kenapa client-side, bukan Cloud Functions scheduled job: project ini
// masih di plan Firebase Spark (belum upgrade ke Blaze), dan Cloud
// Functions -- termasuk yang dijadwalkan (scheduled/pub-sub trigger) --
// wajib Blaze, tidak ada jalan lain. Konsekuensinya reminder ini HANYA
// muncul kalau user benar-benar buka app pas harinya; kalau app nggak
// dibuka di hari itu, reminder-nya lewat begitu saja (tidak proaktif
// seperti push notification asli). Lihat SubscriptionService untuk guard
// akses fitur yang terpisah dari reminder ini.
//
// Ada DUA mode reminder, dibedain dari status subscription-nya:
// - active/trialing, mendekati currentPeriodEnd -> reminder H-3 & H-1
//   SEKALI masing-masing (supaya nggak spam tiap hari selagi masih aktif).
// - past_due (udah lewat currentPeriodEnd, masuk grace period atau
//   bahkan sudah lewat grace period juga) -> reminder muncul TIAP HARI
//   sampai user memperbarui/upgrade, bukan cuma sekali. Ini yang
//   sebelumnya hilang: begitu status pindah dari active ke past_due,
//   checkDue() versi lama langsung return null selamanya dan popup-nya
//   nggak pernah muncul lagi walau langganan udah lama expired.
//
// SENGAJA dipisah dari banner grace period (_buildSubscriptionBanner di
// dashboard_screen.dart): banner itu status indicator yang selalu nempel
// di dashboard selama bermasalah, sedangkan popup di sini cuma muncul
// SEKALI per sesi buka app per hari -- keduanya boleh tampil bersamaan.
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';

/// Hasil pengecekan [SubscriptionReminderService.checkDue].
class SubscriptionReminderDue {
  /// Sisa hari sebelum currentPeriodEnd (untuk mode "akan berakhir"),
  /// atau jumlah hari SUDAH lewat currentPeriodEnd (untuk mode
  /// [isOverdue] -- nilainya >= 0, bukan negatif).
  final int days;

  /// true kalau subscription sudah past_due (lewat currentPeriodEnd),
  /// false kalau ini reminder H-3/H-1 menjelang periode berakhir.
  final bool isOverdue;

  const SubscriptionReminderDue({required this.days, required this.isOverdue});
}

class SubscriptionReminderService {
  /// H-3 dan H-1 sebelum currentPeriodEnd, selama status masih aktif.
  static const List<int> _upcomingReminderDays = [3, 1];

  /// Mengecek apakah reminder perlu ditampilkan SEKARANG untuk
  /// [subscription] ini, dan kalau iya langsung menandainya sebagai
  /// "sudah ditampilkan" supaya tidak muncul berkali-kali di hari yang
  /// sama.
  ///
  /// Return null kalau tidak ada yang perlu ditampilkan hari ini.
  static Future<SubscriptionReminderDue?> checkDue(
    Subscription subscription,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = subscription.currentPeriodEnd;
    final endDay = DateTime(end.year, end.month, end.day);
    final daysLeft = endDay.difference(today).inDays;

    final prefs = await SharedPreferences.getInstance();

    // Mode 1: masih aktif/trialing, cek H-3/H-1 -- SEKALI per kombinasi
    // (subscription id, currentPeriodEnd, daysLeft), sesuai perilaku lama.
    if (subscription.status == 'active' || subscription.status == 'trialing') {
      if (!_upcomingReminderDays.contains(daysLeft)) return null;

      final key = _upcomingKey(subscription.id, endDay, daysLeft);
      final alreadyShown = prefs.getBool(key) ?? false;
      if (alreadyShown) return null;

      await prefs.setBool(key, true);
      return SubscriptionReminderDue(days: daysLeft, isOverdue: false);
    }

    // Mode 2: past_due -- sudah lewat currentPeriodEnd. Muncul SEKALI
    // per HARI (bukan per currentPeriodEnd) selama status masih
    // past_due, supaya tetap keliatan tiap kali app dibuka sampai user
    // benar-benar memperbarui, bukan cuma sekali lalu hilang.
    if (subscription.status == 'past_due') {
      final key = _overdueKey(subscription.id, today);
      final alreadyShown = prefs.getBool(key) ?? false;
      if (alreadyShown) return null;

      await prefs.setBool(key, true);
      final daysOverdue = today.difference(endDay).inDays;
      return SubscriptionReminderDue(
        days: daysOverdue < 0 ? 0 : daysOverdue,
        isOverdue: true,
      );
    }

    return null;
  }

  static String _upcomingKey(String subscriptionId, DateTime endDay, int daysLeft) {
    final endKey = '${endDay.year}-${endDay.month}-${endDay.day}';
    return 'sub_renewal_reminder_${subscriptionId}_${endKey}_h$daysLeft';
  }

  static String _overdueKey(String subscriptionId, DateTime today) {
    final todayKey = '${today.year}-${today.month}-${today.day}';
    return 'sub_overdue_reminder_${subscriptionId}_$todayKey';
  }
}

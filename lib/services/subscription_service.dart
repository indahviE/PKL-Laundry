// lib/services/subscription_service.dart
//
// Guard subscription: menentukan boleh/tidaknya sebuah aksi dijalankan
// berdasarkan status subscription + grace period, DAN menentukan sisa
// kuota (laundries/employees/orders) berdasarkan limits plan aktif.
//
// Dua hal ini SENGAJA dipisah jadi dua method berbeda karena mengukur
// hal yang berbeda:
// - checkAccess()      -> soal STATUS (aktif / grace period / expired)
// - canAdd.../canCreate...() -> soal KUOTA (angka limit vs jumlah saat ini)
// Sebuah aksi yang lolos checkAccess() masih bisa diblok kuota, dan
// sebaliknya kuota longgar tidak berguna kalau checkAccess() menolak.
import '../models/subscription.dart';

/// Jenis aksi yang digating berdasarkan status subscription.
///
/// - [administrative]: aksi yang menambah komitmen baru ke akun (nambah
///   karyawan, nambah cabang, nambah layanan). Diblokir begitu subscription
///   tidak aktif DAN sudah lewat masa grace period.
/// - [transactional]: aksi operasional harian (bikin order, bikin customer,
///   antar-jemput). TIDAK PERNAH diblok oleh status subscription - sesuai
///   keputusan final: laundry harus tetap bisa beroperasi normal walau
///   pembayaran lagi bermasalah. Kuota (mis. limit order/bulan) tetap
///   berlaku, tapi itu urusan canCreateOrder(), bukan checkAccess().
enum SubscriptionActionType { administrative, transactional }

/// Hasil keputusan checkAccess() untuk satu aksi tertentu.
///
/// [reasonKey] sengaja berupa kode singkat (bukan kalimat siap tampil),
/// supaya screen yang manggil bisa pilih string ter-lokalisasi (id/en)
/// sendiri lewat AppLocalizations - service ini tidak tahu-menahu soal UI.
class SubscriptionAccessResult {
  final bool allowed;
  final String? reasonKey; // null kalau allowed tanpa catatan apa pun
  final bool isInGracePeriod;
  final int? graceDaysRemaining;

  const SubscriptionAccessResult({
    required this.allowed,
    this.reasonKey,
    this.isInGracePeriod = false,
    this.graceDaysRemaining,
  });

  static const allowedNoNote = SubscriptionAccessResult(allowed: true);
}

class SubscriptionService {
  /// Berapa lama company masih boleh melakukan aksi administrative
  /// setelah subscription jatuh ke 'past_due', dihitung dari
  /// Subscription.graceStartedAt.
  ///
  /// ASUMSI: belum ada angka resmi yang disepakati sebelumnya di diskusi
  /// kita, jadi saya set 7 hari sebagai default yang wajar. Gampang
  /// diubah - cuma satu konstanta ini yang perlu disentuh.
  static const int gracePeriodDays = 7;

  final Subscription? currentSubscription;

  SubscriptionService({required this.currentSubscription});

  String get planId => currentSubscription?.planId ?? 'starter';
  String get status => currentSubscription?.status ?? 'inactive';

  bool get isSubscriptionActive => status == 'active' || status == 'trialing';

  /// True kalau status 'past_due' DAN masih di dalam window gracePeriodDays
  /// sejak graceStartedAt. Kalau graceStartedAt null (data lama / belum
  /// pernah lewat repository yang baru), dianggap TIDAK dalam grace period
  /// - lebih aman daripada diam-diam kasih grace period tanpa titik mulai
  /// yang jelas.
  bool get isInGracePeriod {
    if (status != 'past_due') return false;
    final graceStart = currentSubscription?.graceStartedAt;
    if (graceStart == null) return false;
    return DateTime.now().difference(graceStart).inDays < gracePeriodDays;
  }

  /// Sisa hari grace period (dibulatkan ke bawah, minimal 0).
  /// Null kalau memang sedang tidak dalam grace period.
  int? get graceDaysRemaining {
    if (!isInGracePeriod) return null;
    final elapsed =
        DateTime.now().difference(currentSubscription!.graceStartedAt!).inDays;
    final remaining = gracePeriodDays - elapsed;
    return remaining < 0 ? 0 : remaining;
  }

  /// Keputusan utama guard: boleh/tidak sebuah [actionType] dijalankan
  /// SEKARANG, berdasarkan status subscription.
  ///
  /// - transactional: selalu allowed=true, tidak pernah dicek statusnya.
  /// - administrative: allowed=true kalau subscription aktif ATAU masih
  ///   dalam grace period (dengan reasonKey 'grace_period_active' supaya
  ///   UI bisa kasih peringatan meski tetap mengizinkan); allowed=false
  ///   dengan reasonKey 'subscription_expired' kalau sudah lewat grace
  ///   period atau memang tidak pernah subscribe.
  SubscriptionAccessResult checkAccess(SubscriptionActionType actionType) {
    if (actionType == SubscriptionActionType.transactional) {
      return SubscriptionAccessResult.allowedNoNote;
    }

    if (isSubscriptionActive) {
      return SubscriptionAccessResult.allowedNoNote;
    }

    if (isInGracePeriod) {
      return SubscriptionAccessResult(
        allowed: true,
        reasonKey: 'grace_period_active',
        isInGracePeriod: true,
        graceDaysRemaining: graceDaysRemaining,
      );
    }

    return const SubscriptionAccessResult(
      allowed: false,
      reasonKey: 'subscription_expired',
    );
  }

  // ============================================
  // KUOTA (limits.max_* pada dokumen subscription)
  // ============================================
  // Selama subscription aktif ATAU masih grace period, limit dibaca dari
  // plan yang bersangkutan (tetap berlaku, belum di-downgrade paksa).
  // Begitu benar-benar expired (bukan aktif & bukan grace period), turun
  // ke batas Starter minimal - sama seperti fallback yang sebelumnya
  // ada di masing-masing screen, cuma sekarang terpusat di sini.

  int get maxLaundriesAllowed {
    if (!isSubscriptionActive && !isInGracePeriod) return 1;
    return currentSubscription?.limits.maxLaundries ?? 1;
  }

  int get maxEmployeesAllowed {
    if (!isSubscriptionActive && !isInGracePeriod) return 5;
    return currentSubscription?.limits.maxEmployees ?? 5;
  }

  int get maxOrdersPerMonth {
    if (!isSubscriptionActive && !isInGracePeriod) return 500;
    return currentSubscription?.limits.maxOrdersPerMonth ?? 500;
  }

  /// -1 pada limits berarti unlimited (khusus paket Enterprise).
  bool canAddLaundry(int currentLaundryCount) {
    if (maxLaundriesAllowed == -1) return true;
    return currentLaundryCount < maxLaundriesAllowed;
  }

  bool canAddEmployee(int currentEmployeeCount) {
    if (maxEmployeesAllowed == -1) return true;
    return currentEmployeeCount < maxEmployeesAllowed;
  }

  bool canCreateOrder(int currentOrdersThisMonthCount) {
    if (maxOrdersPerMonth == -1) return true;
    return currentOrdersThisMonthCount < maxOrdersPerMonth;
  }
}
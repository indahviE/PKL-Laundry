import 'package:cloud_functions/cloud_functions.dart';

/// Service pembungkus Cloud Function terkait pembayaran Stripe.
///
/// Sesuai PRD 4.6: Cloud Function `createCheckoutSession` membuat sesi
/// Stripe Checkout (mode: subscription) dan mengembalikan URL hosted
/// checkout yang dibuka lewat browser eksternal. Konfirmasi pembayaran
/// FINAL tidak dikembalikan langsung ke client — Stripe mengirim webhook
/// ke Cloud Function `stripeWebhook`, yang baru menuliskan dokumen ke
/// `users/{uid}/subscriptions/` dengan `status: 'active'`.
///
/// Karena itu, client tidak boleh menganggap pembayaran selesai hanya
/// karena user kembali dari browser — client harus mendengarkan
/// (listen/poll) koleksi `subscriptions` di Firestore sampai ada dokumen
/// aktif. Lihat `AuthRepository.watchActiveSubscription()` dan
/// `PaymentScreen`.
class StripeService {
  StripeService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-southeast2');

  final FirebaseFunctions _functions;

  /// Peta nama paket (display name di UI) ke `planId` yang dipakai sebagai
  /// document ID di koleksi `subscription_plans` (lihat PRD 4.6).
  static const Map<String, String> planIdByName = {
    'Starter': 'starter',
    'Professional': 'professional',
    'Enterprise': 'enterprise',
  };

  /// Memanggil Cloud Function `createCheckoutSession`.
  ///
  /// [planName] adalah nama tampilan paket (mis. 'Professional') dari
  /// ChoosePlanScreen — akan dipetakan otomatis ke `planId` Stripe.
  /// [successUrl] & [cancelUrl] hanya memengaruhi halaman yang dilihat user
  /// di browser setelah checkout; status sebenarnya tetap disinkronkan
  /// lewat webhook + Firestore listener, bukan lewat redirect ini.
  Future<StripeCheckoutSession> createCheckoutSession({
    required String planName,
    required bool isYearly,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final planId = planIdByName[planName];
    if (planId == null) {
      throw Exception('Paket "$planName" tidak dikenali.');
    }

    try {
      final callable = _functions.httpsCallable('createCheckoutSession');
      final result = await callable.call<Map<String, dynamic>>({
        'planId': isYearly ? '${planId}_yearly' : planId,
        'successUrl': successUrl,
        'cancelUrl': cancelUrl,
      });

      final data = result.data;
      final url = data['url'] as String?;
      final sessionId = data['sessionId'] as String?;

      if (url == null || sessionId == null) {
        throw Exception('Respons sesi pembayaran tidak valid.');
      }

      return StripeCheckoutSession(sessionId: sessionId, url: url);
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Gagal membuat sesi pembayaran.');
    }
  }
}

class StripeCheckoutSession {
  final String sessionId;
  final String url;

  StripeCheckoutSession({required this.sessionId, required this.url});
}
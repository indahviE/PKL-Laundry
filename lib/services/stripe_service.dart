import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// Service pembungkus backend Stripe (Vercel Serverless Function).
///
/// Sesuai PRD 4.6: endpoint `/api/create-checkout-session` membuat sesi
/// Stripe Checkout (mode: subscription) dan mengembalikan URL hosted
/// checkout yang dibuka lewat browser eksternal. Konfirmasi pembayaran
/// FINAL tidak dikembalikan langsung ke client — Stripe mengirim webhook
/// yang menuliskan dokumen ke `users/{uid}/subscriptions/` dengan
/// `status: 'active'`.
///
/// Karena itu, client tidak boleh menganggap pembayaran selesai hanya
/// karena user kembali dari browser — client harus mendengarkan
/// (listen/poll) koleksi `subscriptions` di Firestore sampai ada dokumen
/// aktif. Lihat `AuthRepository.watchActiveSubscription()` dan
/// `PaymentScreen`.
class StripeService {
  StripeService({String? baseUrl})
      : _baseUrl = baseUrl ?? 'https://netwash-stripe-backend.vercel.app';

  final String _baseUrl;

  /// Peta nama paket (display name di UI) ke `planId` yang dipakai sebagai
  /// document ID di koleksi `subscription_plans` (lihat PRD 4.6).
  static const Map<String, String> planIdByName = {
    'Starter': 'starter',
    'Professional': 'professional',
    'Enterprise': 'enterprise',
  };

  /// Memanggil endpoint `create-checkout-session` di Vercel.
  ///
  /// [planName] adalah nama tampilan paket (mis. 'Professional') dari
  /// ChoosePlanScreen — akan dipetakan otomatis ke `planId` Stripe.
  /// [successUrl] & [cancelUrl] hanya memengaruhi halaman yang dilihat user
  /// di browser setelah checkout; status sebenarnya tetap disinkronkan
  /// lewat webhook + Firestore listener, bukan lewat redirect ini.
  ///
  /// `uid` user yang sedang login diselipkan sebagai `client_reference_id`
  /// di Stripe Checkout Session, supaya nanti Cloud Function/webhook tahu
  /// dokumen `subscriptions` ini harus ditulis ke user mana.
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

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('Tidak ada user yang sedang login.');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/create-checkout-session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'planId': isYearly ? '${planId}_yearly' : planId,
          'successUrl': successUrl,
          'cancelUrl': cancelUrl,
          'uid': uid,
        }),
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          errorBody['error'] as String? ?? 'Gagal membuat sesi pembayaran.',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final url = data['url'] as String?;
      final sessionId = data['sessionId'] as String?;

      if (url == null) {
        throw Exception('Respons sesi pembayaran tidak valid.');
      }

      return StripeCheckoutSession(sessionId: sessionId ?? '', url: url);
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}

class StripeCheckoutSession {
  final String sessionId;
  final String url;

  StripeCheckoutSession({required this.sessionId, required this.url});
}
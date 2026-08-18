import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription.dart';
import '../providers/auth_provider.dart';

class SubscriptionRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  SubscriptionRepository({required this.userId}) : _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _subscriptionsRef =>
      _firestore.collection('users').doc(userId).collection('subscriptions');

  /// Membuat data subscription baru
  Future<Subscription> createSubscription(Subscription subscription) async {
    final docRef = _subscriptionsRef.doc();
    final now = DateTime.now();
    final newSubscription = Subscription(
      id: docRef.id,
      createdAt: now,
      updatedAt: now,
      companyId: subscription.companyId,
      planId: subscription.planId,
      planName: subscription.planName,
      stripeSubscriptionId: subscription.stripeSubscriptionId,
      stripeCustomerId: subscription.stripeCustomerId,
      status: subscription.status,
      currentPeriodStart: subscription.currentPeriodStart ?? now,
      currentPeriodEnd: subscription.currentPeriodEnd,
      trialStart: subscription.trialStart,
      trialEnd: subscription.trialEnd,
      canceledAt: subscription.canceledAt,
      billingCycle: subscription.billingCycle,
      features: subscription.features,
      limits: subscription.limits,
    );
    await docRef.set(newSubscription.toJson());
    return newSubscription;
  }

  /// FIX: Melakukan filter dan sorting di memori Dart (client-side) 
  /// untuk menghindari error "Composite Index Required" dari Firestore!
  Stream<Subscription?> streamActiveSubscription(String companyId) {
    return _subscriptionsRef
        .where('company_id', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;

      // 1. Filter data berstatus 'active' atau 'trialing' di memori
      final activeSubs = snapshot.docs
          .map((doc) => Subscription.fromJson(doc.data(), doc.id))
          .where((sub) => sub.status == 'active' || sub.status == 'trialing')
          .toList();

      if (activeSubs.isEmpty) return null;

      // 2. Urutkan berdasarkan tanggal dibuat secara descending (paling baru di awal)
      activeSubs.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // 3. Ambil satu subscription teraktif yang paling baru
      return activeSubs.first;
    });
  }

  /// Ambil subscription TERBARU untuk company ini, apa pun statusnya
  /// (termasuk past_due, canceled, unpaid, incomplete) - beda dari
  /// [streamActiveSubscription] yang cuma mengembalikan active/trialing.
  ///
  /// Guard butuh ini buat membedakan dua kondisi yang keduanya bikin
  /// streamActiveSubscription() return null:
  /// - company belum pernah subscribe sama sekali (dokumen memang tidak ada)
  /// - subscription-nya ada tapi lagi past_due/canceled (dokumen ada,
  ///   cuma bukan active/trialing)
  /// Tanpa method ini, guard tidak bisa tahu mana yang "belum pernah
  /// subscribe" vs "sedang grace period", padahal treatment-nya beda.
  Stream<Subscription?> streamSubscriptionForCompany(String companyId) {
    return _subscriptionsRef
        .where('company_id', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;

      final subs = snapshot.docs
          .map((doc) => Subscription.fromJson(doc.data(), doc.id))
          .toList();

      // Urutkan descending, ambil yang paling baru - sama seperti
      // streamActiveSubscription, supaya konsisten kalau ada lebih dari
      // satu dokumen subscription untuk company yang sama.
      subs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return subs.first;
    });
  }

  /// FIX: Pengurutan riwayat di memori untuk menghindari index crash
  Stream<List<Subscription>> streamSubscriptionHistory(String companyId) {
    return _subscriptionsRef
        .where('company_id', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Subscription.fromJson(doc.data(), doc.id))
          .toList();
      
      // Urutkan berdasarkan tanggal dibuat descending
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Update status subscription.
  ///
  /// Ikut ngurus `grace_started_at` otomatis berdasarkan transisi status,
  /// jadi caller (mis. webhook Stripe di functions/index.js lewat Admin
  /// SDK, atau kode klien lain yang manggil ini) tidak perlu tahu soal
  /// logic grace period sama sekali:
  /// - transisi ke 'past_due' -> di-set ke sekarang, TAPI hanya kalau
  ///   sebelumnya belum ada nilai (supaya webhook retry/duplicate event
  ///   tidak menggeser mundur titik mulai grace period).
  /// - transisi ke 'active'/'trialing' (mis. pembayaran berhasil) ->
  ///   di-null-kan lagi, karena grace period sudah tidak relevan.
  /// - status lain (canceled, unpaid, dst) -> dibiarkan apa adanya.
  /// Perpanjang subscription yang statusnya 'trialing' dengan menambah
  /// [days] hari ke `current_period_end` yang SEKARANG (bukan ke waktu
  /// sekarang) - supaya kalau user extend berkali-kali dalam 1 hari yang
  /// sama, harinya tetap nambah dari titik akhir trial yang benar, bukan
  /// numpuk dari "sekarang".
  ///
  /// Dipakai oleh fitur "Nonton Iklan buat Lanjut Trial" - dipanggil
  /// SETELAH RewardedAdService mengonfirmasi user benar-benar menonton
  /// iklan sampai selesai (onUserEarnedReward).
  Future<void> extendTrial(
    String subscriptionId, {
    required DateTime currentPeriodEnd,
    int days = 1,
  }) async {
    final newEnd = currentPeriodEnd.add(Duration(days: days));
    await _subscriptionsRef.doc(subscriptionId).update({
      'current_period_end': newEnd,
      'updated_at': DateTime.now(),
    });
  }

  Future<void> updateSubscriptionStatus(
    String subscriptionId,
    String newStatus, {
    DateTime? currentPeriodEnd,
    DateTime? canceledAt,
  }) async {
    final Map<String, dynamic> data = {
      'status': newStatus,
      if (currentPeriodEnd != null) 'current_period_end': currentPeriodEnd,
      if (canceledAt != null) 'canceled_at': canceledAt,
      'updated_at': DateTime.now(),
    };

    if (newStatus == 'past_due') {
      final snap = await _subscriptionsRef.doc(subscriptionId).get();
      final existingGraceStart = snap.data()?['grace_started_at'];
      if (existingGraceStart == null) {
        data['grace_started_at'] = DateTime.now();
      }
    } else if (newStatus == 'active' || newStatus == 'trialing') {
      data['grace_started_at'] = FieldValue.delete();
    }

    await _subscriptionsRef.doc(subscriptionId).update(data);
  }
}

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return SubscriptionRepository(userId: userId);
});
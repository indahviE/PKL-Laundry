import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../repositories/auth_repository.dart';

/// Halaman Subscription di menu Settings.
/// Nampilin plan yang beneran dipilih user (dari savePlanChoice, field
/// users/{uid}.subscription.plan) & status aktif dari
/// watchActiveSubscription() (subcollection subscriptions, ditulis oleh
/// Stripe webhook). Tombol "Upgrade Paket" masuk ke ChoosePlanScreen
/// dengan isUpgrade: true.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepo = ref.read(authRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Langganan Saya'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<Map<String, dynamic>?>(
            future: authRepo.getUserProfile(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (profileSnapshot.hasError) {
                return Center(
                  child: Text('Gagal memuat data langganan: ${profileSnapshot.error}'),
                );
              }

              final subscriptionField =
                  profileSnapshot.data?['subscription'] as Map<String, dynamic>?;
              final planName = subscriptionField?['plan'] as String? ?? '-';
              final period = subscriptionField?['period'] as String?;
              final periodLabel = period == 'yearly' ? 'Tahunan' : 'Bulanan';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Paket Aktif',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            planName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Periode: $periodLabel',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          // Status aktif/tidak dari subcollection
                          // subscriptions (ditulis Stripe webhook),
                          // real-time lewat StreamBuilder di bawah ini.
                          StreamBuilder<bool>(
                            stream: authRepo.watchActiveSubscription(),
                            builder: (context, activeSnapshot) {
                              if (!activeSnapshot.hasData) {
                                return const Text(
                                  'Status: memuat...',
                                  style: TextStyle(fontSize: 13),
                                );
                              }
                              final isActive = activeSnapshot.data!;
                              return Text(
                                isActive
                                    ? 'Status: Aktif · Perpanjang otomatis'
                                    : 'Status: Tidak aktif',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isActive ? Colors.green : Colors.red,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.push('/choose-plan', extra: {'isUpgrade': true});
                      },
                      child: const Text('Upgrade Paket'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
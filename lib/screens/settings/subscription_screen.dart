import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/themes/app_theme.dart';
import '../../repositories/auth_repository.dart';

/// Halaman Subscription di menu Settings.
/// Nampilin plan yang beneran dipilih user (dari savePlanChoice, field
/// users/{uid}.subscription.plan) & status aktif dari
/// watchActiveSubscription() (subcollection subscriptions, ditulis oleh
/// Stripe webhook). Tombol "Upgrade Paket" masuk ke ChoosePlanScreen
/// dengan isUpgrade: true.
///
/// Tema disamain sama SettingsScreen: header gradient + badge icon,
/// section label, card dengan shadow tipis, dan font Poppins.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepo = ref.read(authRepositoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(context, isMobile),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          isMobile ? 16 : 24,
                          20,
                          isMobile ? 16 : 24,
                          24,
                        ),
                        child: FutureBuilder<Map<String, dynamic>?>(
                          future: authRepo.getUserProfile(),
                          builder: (context, profileSnapshot) {
                            if (profileSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            if (profileSnapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Gagal memuat data langganan: ${profileSnapshot.error}',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              );
                            }

                            final subscriptionField = profileSnapshot
                                .data?['subscription'] as Map<String, dynamic>?;
                            final planName =
                                subscriptionField?['plan'] as String? ?? '-';
                            final period =
                                subscriptionField?['period'] as String?;
                            final periodLabel =
                                period == 'yearly' ? 'Tahunan' : 'Bulanan';

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _sectionLabel('Paket Aktif'),
                                _buildPlanCard(
                                  authRepo: authRepo,
                                  planName: planName,
                                  periodLabel: periodLabel,
                                ),
                                const SizedBox(height: 24),
                                _buildUpgradeButton(context),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ==========================================================
  // HEADER — samain gaya sama SettingsScreen: gradient, responsif,
  // badge icon kecil di atas judul.
  // ==========================================================
  Widget _buildHeader(BuildContext context, bool isMobile) {
    final horizontalPadding = isMobile ? 18.0 : 24.0;
    final cornerRadius = isMobile ? 20.0 : 26.0;
    final badgeSize = isMobile ? 58.0 : 64.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        isMobile ? 16 : 20,
        horizontalPadding,
        isMobile ? 20 : 24,
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(cornerRadius),
          bottomRight: Radius.circular(cornerRadius),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Langganan Saya',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.85),
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Container(
            width: badgeSize,
            height: badgeSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              size: badgeSize * 0.5,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Kelola Paket Langganan',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Lihat status & upgrade paketmu kapan saja',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4, left: 4),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textTertiary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // ==========================================================
  // CARD PAKET AKTIF — gaya card sama shadow disamain sama
  // _buildSectionCard di SettingsScreen.
  // ==========================================================
  Widget _buildPlanCard({
    required AuthRepository authRepo,
    required String planName,
    required String periodLabel,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: AppTheme.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planName,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Periode: $periodLabel',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                // Status aktif/tidak + tanggal berakhir, dari dokumen
                // subcollection subscriptions (ditulis Stripe webhook),
                // real-time lewat StreamBuilder.
                StreamBuilder<Map<String, dynamic>?>(
                  stream: authRepo.watchActiveSubscriptionData(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData && snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Text(
                        'Status: memuat...',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: AppTheme.textTertiary,
                        ),
                      );
                    }

                    final data = snapshot.data;
                    final isActive = data != null;

                    // Field ini opsional — cuma tampil kalau webhook-nya
                    // sudah nulis Timestamp `currentPeriodStart` &
                    // `currentPeriodEnd`. Kalau belum ada, badge status
                    // tetap tampil tanpa rentang tanggal.
                    DateTime? toDate(dynamic value) {
                      if (value is Timestamp) return value.toDate();
                      if (value is DateTime) return value;
                      return null;
                    }

                    final periodStart = toDate(data?['current_period_start']);
                    final periodEnd = toDate(data?['current_period_end']);

                    return Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (isActive ? Colors.green : Colors.red)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isActive
                                ? 'Aktif · Perpanjang otomatis'
                                : 'Tidak aktif',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                        if (periodStart != null && periodEnd != null)
                          Text(
                            '${_formatDate(periodStart)} - ${_formatDate(periodEnd)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textSecondary,
                            ),
                          )
                        else if (periodEnd != null)
                          Text(
                            'Berlaku sampai ${_formatDate(periodEnd)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TOMBOL UPGRADE — samain gaya rounded button sama tombol
  // logout di SettingsScreen, tapi pakai warna brand (filled).
  // ==========================================================
  Widget _buildUpgradeButton(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          context.push('/choose-plan', extra: {'isUpgrade': true});
        },
        icon: const Icon(Icons.arrow_upward_rounded, size: 19),
        label: Text(
          'Upgrade Paket',
          style: GoogleFonts.poppins(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
      ),
    );
  }

  // Format tanggal manual (dd Bulan yyyy) biar nggak nambah dependency
  // intl cuma buat satu baris teks ini.
  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  String _formatDate(DateTime date) {
    return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
  }
}
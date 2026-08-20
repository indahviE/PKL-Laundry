import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/rewarded_ad_service.dart';
import '../themes/app_theme.dart';

/// Dialog "paywall" yang muncul saat trial user sudah habis.
/// Kasih 2 pilihan: nonton iklan buat extend 1 hari, atau upgrade
/// langsung ke paket berbayar.
///
/// [onWatchAdSuccess] dipanggil SETELAH user benar-benar menonton iklan
/// sampai selesai (bukan pas tombol diklik) - di situ caller yang urus
/// panggil SubscriptionRepository.extendTrial() dan update UI/state.
class TrialPaywallDialog extends StatefulWidget {
  final VoidCallback onWatchAdSuccess;

  const TrialPaywallDialog({
    super.key,
    required this.onWatchAdSuccess,
  });

  /// Helper biar caller nggak perlu import showDialog + barrier settings
  /// manual tiap kali mau munculin ini. barrierDismissible sengaja false
  /// - trial sudah habis, user harus pilih salah satu aksi, bukan
  /// nutup dialog begitu saja lalu balik pakai app tanpa batasan.
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onWatchAdSuccess,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => TrialPaywallDialog(onWatchAdSuccess: onWatchAdSuccess),
    );
  }

  @override
  State<TrialPaywallDialog> createState() => _TrialPaywallDialogState();
}

class _TrialPaywallDialogState extends State<TrialPaywallDialog> {
  final RewardedAdService _adService = RewardedAdService();
  bool _isShowingAd = false;

  @override
  void initState() {
    super.initState();
    _adService.loadAd();
  }

  @override
  void dispose() {
    _adService.dispose();
    super.dispose();
  }

  void _handleWatchAd() {
    setState(() => _isShowingAd = true);

    _adService.showAd(
      onUserEarnedReward: () {
        if (!mounted) return;
        setState(() => _isShowingAd = false);
        Navigator.of(context).pop(); // tutup dialog
        widget.onWatchAdSuccess(); // caller yang urus extendTrial()
      },
      onAdNotReady: () {
        if (!mounted) return;
        setState(() => _isShowingAd = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Iklan lagi disiapkan, coba lagi sebentar ya'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_bottom_rounded, size: 42, color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            const Text(
              'Trial Kamu Sudah Berakhir',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Tonton iklan buat lanjut akses 1 hari lagi, atau upgrade sekarang buat akses penuh tanpa batas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _isShowingAd ? null : _handleWatchAd,
                icon: _isShowingAd
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.play_circle_outline_rounded, size: 20),
                label: Text(_isShowingAd ? 'Memuat...' : 'Tonton Iklan (+1 Hari)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Wajib pakai extra isUpgrade: true. Subscription status
                  // masih 'trialing' di titik ini (belum sempat diubah jadi
                  // 'canceled' oleh Cloud Function harian), jadi
                  // hasActiveSubscription() di routes.dart masih anggap
                  // user "aktif" dan redirect guard-nya bakal nendang balik
                  // ke '/dashboard' begitu lihat '/choose-plan' tanpa flag
                  // ini (dianggap onboarding route biasa yang harus
                  // di-skip user yang sudah onboarded) - makanya keliatan
                  // kayak dialog cuma ke-close tanpa pindah halaman.
                  context.push('/choose-plan', extra: {'isUpgrade': true});
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Upgrade Sekarang'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
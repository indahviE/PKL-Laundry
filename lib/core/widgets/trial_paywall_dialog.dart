import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/rewarded_ad_service.dart';
import '../themes/app_theme.dart';
import '../../l10n/app_localizations.dart';

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

  // Status "iklan sudah siap ditampilkan" - dikontrol lewat callback
  // onAdReadyChanged dari RewardedAdService. Tombol "Nonton Iklan" WAJIB
  // disabled selama ini false, karena loadAd() itu proses async yang
  // butuh beberapa detik (kadang lebih lama kalau device lagi berat
  // decode video ad-nya). Sebelumnya tombol langsung aktif begitu dialog
  // dibuka, jadi kalau user klik cepat, _rewardedAd di service masih
  // null walau sebenarnya cuma soal timing - bukan gagal beneran.
  bool _isAdReady = false;

  // Fallback kalau iklan gagal dimuat ATAU proses load kelamaan (mis.
  // App masih ditinjau AdMob, koneksi lambat, dsb) - user nunggu 30
  // detik sebagai pengganti nonton iklan, biar tetap bisa lanjut pakai
  // app.
  //
  // TODO: sebelum production/setelah App di-approve AdMob, pertimbangkan
  // untuk menonaktifkan/membatasi fallback ini supaya user tetap
  // "diwajibkan" nonton iklan asli (demi revenue), bukan selalu ambil
  // jalur timer.
  bool _showFallbackTimer = false;
  int _fallbackSecondsLeft = 30;
  Timer? _fallbackTimer;

  // Kalau loadAd() belum juga selesai (baik sukses maupun gagal) dalam
  // rentang ini, anggap kelamaan dan langsung tawarkan fallback timer -
  // daripada user cuma liat tombol loading tanpa kepastian. Dinaikkan
  // ke 15 detik (dari 8 detik) karena di beberapa device, proses decode
  // video utk rewarded ad bisa makan waktu lumayan lama saat main thread
  // lagi sibuk (kelihatan dari log "Skipped XXX frames" pas ad lagi
  // disiapkan) - 8 detik ternyata sering kepicu duluan sebelum ad
  // benar-benar selesai load.
  static const _loadTimeout = Duration(seconds: 15);
  Timer? _loadTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _adService.onAdReadyChanged = _handleAdReadyChanged;
    _adService.loadAd();

    _loadTimeoutTimer = Timer(_loadTimeout, () {
      if (!mounted || _isAdReady || _showFallbackTimer) return;
      _startFallbackTimer();
    });
  }

  @override
  void dispose() {
    _adService.dispose();
    _fallbackTimer?.cancel();
    _loadTimeoutTimer?.cancel();
    super.dispose();
  }

  void _handleAdReadyChanged(bool ready) {
    if (!mounted) return;

    // Kalau iklan ternyata BERHASIL dimuat SETELAH fallback timer sudah
    // kepicu (mis. karena _loadTimeout keburu habis duluan di device
    // yang lemot), batalkan fallback dan kembalikan user ke tombol
    // "Nonton Iklan" asli - daripada user kejebak nunggu timer padahal
    // iklannya sebenarnya udah siap ditonton.
    if (ready && _showFallbackTimer) {
      _fallbackTimer?.cancel();
      setState(() {
        _showFallbackTimer = false;
        _isAdReady = true;
      });
      return;
    }

    setState(() => _isAdReady = ready);
  }

  void _startFallbackTimer() {
    _loadTimeoutTimer?.cancel();
    setState(() {
      _showFallbackTimer = true;
      _fallbackSecondsLeft = 30;
    });

    _fallbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _fallbackSecondsLeft--);

      if (_fallbackSecondsLeft <= 0) {
        timer.cancel();
        Navigator.of(context).pop();
        widget.onWatchAdSuccess();
      }
    });
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
        _startFallbackTimer();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    // Tombol disabled kalau: iklan belum siap DAN belum masuk fallback,
    // ATAU lagi proses nampilin iklan, ATAU lagi fallback timer.
    final bool buttonDisabled =
        _isShowingAd || _showFallbackTimer || !_isAdReady;

    final bool showSpinner =
        _isShowingAd || _showFallbackTimer || !_isAdReady;

    String buttonLabel;
    if (_showFallbackTimer) {
      buttonLabel = t.trialPaywallWaitingButton(_fallbackSecondsLeft);
    } else if (_isShowingAd) {
      buttonLabel = t.trialPaywallLoadingButton;
    } else if (!_isAdReady) {
      buttonLabel = t.trialPaywallLoadingButton; // "menyiapkan iklan..."
    } else {
      buttonLabel = t.trialPaywallWatchAdButton;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_bottom_rounded, size: 42, color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(
              t.trialPaywallTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              t.trialPaywallMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: buttonDisabled ? null : _handleWatchAd,
                icon: showSpinner
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.play_circle_outline_rounded, size: 20),
                label: Text(buttonLabel),
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
                  context.push('/choose-plan', extra: {'isUpgrade': true});
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(t.trialPaywallUpgradeButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
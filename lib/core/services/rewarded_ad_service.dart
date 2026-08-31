import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Service buat handle Rewarded Ad (AdMob) — dipakai di fitur
/// "Nonton Iklan buat Lanjut Trial 15 hari+".
///
/// PENTING: sekarang masih pakai TEST Ad Unit ID dari Google.
/// Sebelum publish ke Play Store, WAJIB ganti _adUnitId di bawah
/// pakai Ad Unit ID asli dari dashboard AdMob (yang formatnya pakai
/// tanda '/', BUKAN App ID yang pakai '~').
class RewardedAdService {
  RewardedAd? _rewardedAd;
  bool _isLoading = false;

    static const String _rewardedAdUnitId =
           'ca-app-pub-3940256099942544/5224354917'; // TEST ID
  // static const String _rewardedAdUnitId =
  //     'ca-app-pub-9762254209738667/1476656162'; // PRODUCTION ID (aktifkan lagi kalau udah approved)
  String get _adUnitId => _rewardedAdUnitId;

  /// Dipanggil setiap kali status "siap tayang" berubah (true saat
  /// onAdLoaded, false saat gagal load / setelah ad dipakai/dispose).
  /// UI (mis. TrialPaywallDialog) pasang listener ini buat tahu kapan
  /// boleh mengaktifkan tombol "Nonton Iklan" - sebelum ini, tombol
  /// HARUS disabled, karena RewardedAd.load() itu async dan butuh
  /// beberapa detik; kalau tombol diklik sebelum onAdLoaded selesai,
  /// _rewardedAd masih null dan showAd() bakal langsung jatuh ke
  /// fallback timer meskipun iklannya sebenarnya berhasil dimuat
  /// (cuma telat beberapa detik).
  ValueChanged<bool>? onAdReadyChanged;

  bool get isAdReady => _rewardedAd != null;

  /// Panggil ini duluan (misal pas buka halaman "Choose Plan"),
  /// supaya iklan udah siap dari sebelum user klik tombol.
  void loadAd() {
    if (_isLoading || _rewardedAd != null) return;
    _isLoading = true;

    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          debugPrint('RewardedAd: berhasil dimuat');
          onAdReadyChanged?.call(true);
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          debugPrint('RewardedAd: gagal dimuat -> $error');
          onAdReadyChanged?.call(false);
        },
      ),
    );
  }

  /// Panggil ini pas user klik tombol "Nonton Iklan buat Lanjut".
  /// [onUserEarnedReward] dipanggil KALAU DAN HANYA KALAU user
  /// nonton iklan sampai selesai (bukan skip di tengah).
  void showAd({
    required VoidCallback onUserEarnedReward,
    VoidCallback? onAdNotReady,
  }) {
    if (_rewardedAd == null) {
      onAdNotReady?.call();
      // Coba load lagi buat kesempatan berikutnya
      loadAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        onAdReadyChanged?.call(false);
        loadAd(); // pre-load lagi buat next time
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        onAdReadyChanged?.call(false);
        loadAd();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onUserEarnedReward();
      },
    );
  }

  void dispose() {
    onAdReadyChanged = null;
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
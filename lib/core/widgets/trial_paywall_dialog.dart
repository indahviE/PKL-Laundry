import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/manual_ad_service.dart';
import 'package:netwash/models/manual_ad.dart';
import '../widgets/manual_ad_player_dialog.dart';
import '../themes/app_theme.dart';
import '../../l10n/app_localizations.dart';

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
  final ManualAdService _adService = ManualAdService();

  ManualAd? _ad;
  bool _isFetchingAd = true;
  bool _fetchFailed = false;

  @override
  void initState() {
    super.initState();
    _fetchAd();
  }

  Future<void> _fetchAd() async {
    try {
      final ad = await _adService.fetchActiveAd();
      if (!mounted) return;

      if (ad == null) {
        // Query berhasil, tapi gak ada dokumen dengan isActive: true.
        debugPrint('[ManualAd] Gak ada iklan aktif ditemukan di collection manual_ads.');
        setState(() {
          _isFetchingAd = false;
          _fetchFailed = true;
        });
        return;
      }

      setState(() {
        _ad = ad;
        _isFetchingAd = false;
      });
    } catch (e, st) {
      // Print penyebab asli errornya - paling sering ini karena
      // Firestore Security Rules belum ngizinin read ke manual_ads.
      debugPrint('[ManualAd] Gagal fetch iklan: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      setState(() {
        _isFetchingAd = false;
        _fetchFailed = true;
      });
    }
  }

  Future<void> _handleWatchAd() async {
    final ad = _ad;
    if (ad == null) return;

    await ManualAdPlayerDialog.show(
      context,
      videoUrl: ad.videoUrl,
      durationSeconds: ad.durationSeconds,
      onAdCompleted: () {
        if (!mounted) return;
        Navigator.of(context).pop(); // tutup TrialPaywallDialog juga
        widget.onWatchAdSuccess();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final bool buttonDisabled = _isFetchingAd || _fetchFailed || _ad == null;

    String buttonLabel;
    if (_fetchFailed) {
      buttonLabel = 'Iklan tidak tersedia';
    } else if (_isFetchingAd) {
      buttonLabel = t.trialPaywallLoadingButton;
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
                icon: _isFetchingAd
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
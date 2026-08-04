import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notif_prefs_provider.dart';

enum HapticFeedbackType { light, medium, heavy }
enum AppSound { success, error }

class AppFeedback {
  static final _player = AudioPlayer();

  static void haptic(WidgetRef ref, {HapticFeedbackType type = HapticFeedbackType.medium}) {
    final prefs = ref.read(notifPrefsProvider).valueOrNull ?? const {};
    final enabled = prefs['haptic_feedback'] ?? true;
    if (!enabled) return;

    switch (type) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  static Future<void> playSound(WidgetRef ref, AppSound sound) async {
    final prefs = ref.read(notifPrefsProvider).valueOrNull ?? const {};
    final enabled = prefs['in_app_sound'] ?? true;
    if (!enabled) return;

    // Pakai UrlSource (bukan AssetSource) - path persis sesuai yang
    // ke-serve, tanpa auto-prefix "assets/" yang bikin bingung di web.
    final path = sound == AppSound.success
        ? 'asset/sounds/success.wav'
        : 'asset/sounds/error.wav';
    try {
      await _player.play(UrlSource(path));
    } catch (e) {
      // ignore: avoid_print
      print('DEBUG playSound error: $e');
    }
  }
}
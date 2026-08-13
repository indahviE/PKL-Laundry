import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notif_prefs_provider.dart';

enum HapticFeedbackType { light, medium, heavy }
enum AppSound { success, error, notification }

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

    try {
      if (kIsWeb) {
        // Web: audioplayers butuh UrlSource, path persis sesuai yang
        // ke-serve dari folder asset, tanpa auto-prefix "assets/".
        final path = switch (sound) {
          AppSound.success => 'assets/sounds/success.wav',
          AppSound.error => 'assets/sounds/error.wav',
          AppSound.notification => 'assets/sounds/notif.wav',
        };
        await _player.play(UrlSource(path));
      } else {
        // Android/iOS/desktop: wajib pakai AssetSource, path RELATIF
        // dari folder assets yang didaftarkan di pubspec.yaml (tanpa
        // prefix "asset/" di depan, itu bagian dari root folder-nya).
        final path = switch (sound) {
          AppSound.success => 'sounds/success.wav',
          AppSound.error => 'sounds/error.wav',
          AppSound.notification => 'sounds/notif.wav',
        };
        await _player.play(AssetSource(path));
      }
    } catch (e) {
      // ignore: avoid_print
      print('DEBUG playSound error: $e');
    }
  }
}
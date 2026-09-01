import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ManualAdPlayerDialog extends StatefulWidget {
  final String videoUrl;
  final int durationSeconds;
  final VoidCallback onAdCompleted;

  const ManualAdPlayerDialog({
    super.key,
    required this.videoUrl,
    required this.durationSeconds,
    required this.onAdCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    required String videoUrl,
    required int durationSeconds,
    required VoidCallback onAdCompleted,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ManualAdPlayerDialog(
        videoUrl: videoUrl,
        durationSeconds: durationSeconds,
        onAdCompleted: onAdCompleted,
      ),
    );
  }

  @override
  State<ManualAdPlayerDialog> createState() => _ManualAdPlayerDialogState();
}

class _ManualAdPlayerDialogState extends State<ManualAdPlayerDialog> {
  late final VideoPlayerController _controller;
  bool _isReady = false;
  bool _hasError = false;
  bool _isCompleted = false;
  int _secondsWatched = 0;
  Timer? _watchTimer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _controller.addListener(_checkVideoEnd);
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _isReady = true);
      _controller.play();
      _startWatchTimer();
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _hasError = true);
    });
  }

  // Jaga-jaga kalau video aslinya lebih PENDEK dari durationSeconds
  // yang di-set admin - begitu video abis diputar, langsung anggap
  // selesai daripada nunggu timer detik yang gak akan pernah kekejar.
  void _checkVideoEnd() {
    if (_isCompleted) return;
    final value = _controller.value;
    if (value.isInitialized &&
        value.duration.inMilliseconds > 0 &&
        value.position >= value.duration) {
      _completeAd();
    }
  }

  void _startWatchTimer() {
    _watchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _secondsWatched++);
      if (_secondsWatched >= widget.durationSeconds) {
        timer.cancel();
        _completeAd();
      }
    });
  }

  void _completeAd() {
    if (_isCompleted) return;
    _isCompleted = true;
    _watchTimer?.cancel();
    _controller.pause();
    Navigator.of(context).pop();
    widget.onAdCompleted();
  }

  @override
  void dispose() {
    _watchTimer?.cancel();
    _controller.removeListener(_checkVideoEnd);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining =
        (widget.durationSeconds - _secondsWatched).clamp(0, widget.durationSeconds);
    final progress = widget.durationSeconds == 0
        ? 1.0
        : (_secondsWatched / widget.durationSeconds).clamp(0.0, 1.0);

    return PopScope(
      canPop: false, // kunci: gak bisa di-back sebelum durasi habis
      child: Dialog(
        insetPadding: const EdgeInsets.all(12),
        backgroundColor: Colors.black,
        child: AspectRatio(
          aspectRatio: _isReady ? _controller.value.aspectRatio : 16 / 9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isReady)
                VideoPlayer(_controller)
              else if (_hasError)
                const Icon(Icons.error_outline, color: Colors.white, size: 40)
              else
                const CircularProgressIndicator(color: Colors.white),
              if (_isReady)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 4),
                      Text(
                        remaining > 0 ? 'Sisa $remaining detik' : 'Selesai...',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
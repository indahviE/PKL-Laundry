// lib/core/widgets/app_snackbar.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSnackbar {
  static OverlayEntry? _currentEntry;

  static void success(BuildContext context, String message) {
    _show(context, message, icon: Icons.check_circle_rounded, color: const Color(0xFF16A34A));
  }

  static void error(BuildContext context, String message) {
    _show(context, message, icon: Icons.error_rounded, color: const Color(0xFFDC2626));
  }

  static void info(BuildContext context, String message) {
    _show(context, message, icon: Icons.info_rounded, color: const Color(0xFF0061A4));
  }

  static void _show(
    BuildContext context,
    String message, {
    required IconData icon,
    required Color color,
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _SnackbarToast(
        message: message,
        icon: icon,
        color: color,
        onDismiss: () {
          entry.remove();
          if (identical(_currentEntry, entry)) _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _SnackbarToast extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback onDismiss;

  const _SnackbarToast({
    required this.message,
    required this.icon,
    required this.color,
    required this.onDismiss,
  });

  @override
  State<_SnackbarToast> createState() => _SnackbarToastState();
}

class _SnackbarToastState extends State<_SnackbarToast> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    // Slide dari bawah, bukan atas.
    _slide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    Future.delayed(const Duration(seconds: 3), _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Background SOLID (opaque), bukan warna transparan yang numpuk sama
    // konten di baliknya - warna aksen di-"campur" ke atas putih supaya
    // hasilnya tetap solid tapi kelihatan tint-nya.
    final solidBg = Color.alphaBlend(widget.color.withOpacity(0.12), Colors.white);

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomPadding + 16,
      child: SafeArea(
        top: false,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onVerticalDragEnd: (d) {
                  if ((d.primaryVelocity ?? 0) > 150) _dismiss();
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                  decoration: BoxDecoration(
                    color: solidBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: widget.color.withOpacity(0.28), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(top: 1),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: widget.color.withOpacity(0.16), shape: BoxShape.circle),
                        child: Icon(widget.icon, color: widget.color, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            widget.message,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1B1C1C),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _dismiss,
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.close_rounded, size: 16, color: widget.color.withOpacity(0.7)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
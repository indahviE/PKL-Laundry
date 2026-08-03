import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/themes/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';

class _NotifPref {
  final String key; // cocok dengan key di UserModel.notifPrefs / Firestore
  final String title;
  final String subtitle;
  final IconData icon;

  _NotifPref({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

List<_NotifPref> _buildPrefDefs(AppLocalizations t) => [
      _NotifPref(
        key: 'status_pesanan',
        title: t.notifPrefOrderStatusTitle,
        subtitle: t.notifPrefOrderStatusSubtitle,
        icon: Icons.local_shipping_outlined,
      ),
      _NotifPref(
        key: 'promo',
        title: t.notifPrefPromoTitle,
        subtitle: t.notifPrefPromoSubtitle,
        icon: Icons.sell_outlined,
      ),
      _NotifPref(
        key: 'pengingat',
        title: t.notifPrefReminderTitle,
        subtitle: t.notifPrefReminderSubtitle,
        icon: Icons.schedule_outlined,
      ),
      _NotifPref(
        key: 'chat_cs',
        title: t.notifPrefChatCsTitle,
        subtitle: t.notifPrefChatCsSubtitle,
        icon: Icons.chat_bubble_outline,
      ),
    ];

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Optimistic update: toggle langsung berubah di UI, baru nulis ke
  /// Firestore di background. Kalau gagal, balikin toggle + kasih tau user
  /// lewat SnackBar -- daripada nge-block UI nunggu network round-trip.
  Future<void> _toggle(
    Map<String, bool> currentPrefs,
    String key,
    bool newValue,
  ) async {
    final uid = _uid;
    if (uid == null) return;

    final t = AppLocalizations.of(context)!;
    final repo = ref.read(userRepositoryProvider);
    try {
      await repo.updateNotificationPrefs(uid, {key: newValue});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.notifPrefSaveError(e.toString()))),
      );
    }
    // Tidak perlu setState manual -- StreamBuilder di bawah otomatis
    // re-render begitu Firestore konfirmasi perubahan.
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final uid = _uid;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, t),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: uid == null
                        ? const SizedBox.shrink()
                        : StreamBuilder<UserModel?>(
                            stream: ref
                                .read(userRepositoryProvider)
                                .getUserProfileStream(uid),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 40),
                                    child: CircularProgressIndicator(
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                );
                              }
                              final prefs =
                                  snapshot.data?.notifPrefs ?? const {};
                              return _buildSectionCard(t, prefs);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 20, 24, 28),
      decoration: const BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 4),
          Text(
            t.notificationTitle,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(AppLocalizations t, Map<String, bool> prefs) {
    final prefDefs = _buildPrefDefs(t);
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
      child: Column(
        children: List.generate(prefDefs.length, (index) {
          final def = prefDefs[index];
          // Default true kalau field belum pernah disimpan di Firestore
          // (user lama / belum pernah buka halaman ini).
          final value = prefs[def.key] ?? true;
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(def.icon,
                          color: AppTheme.primaryColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            def.title,
                            style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            def.subtitle,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: value,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (v) => _toggle(prefs, def.key, v),
                    ),
                  ],
                ),
              ),
              if (index != prefDefs.length - 1)
                Divider(
                  height: 1,
                  indent: 70,
                  color: AppTheme.borderColor.withOpacity(0.6),
                ),
            ],
          );
        }),
      ),
    );
  }
}
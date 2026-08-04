import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/locale.provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';

// ============================================================
// PALETTE — disamain PERSIS sama _DS di services_list_screen.dart
// ("NetWash Utility System"): primary #0061A4, navy #0B3B66,
// canvas #F5F7FA. Badge kategori tetap warna-warni bentuk lingkaran
// seperti mockup, cuma primary & canvas-nya yang disamakan.
// ============================================================
class _Palette {
  static const canvas = Color(0xFFF5F7FA);
  static const surface = Colors.white;

  static const primary = Color(0xFF0061A4);
  static const primaryDark = Color(0xFF0B3B66); // = navy di halaman Layanan
  static const primaryContainer = Color(0xFFD1E4FF);

  static const ink = Color(0xFF1B1C1C);
  static const inkSoft = Color(0xFF404752);
  static const inkFaint = Color(0xFF9CA3AF);
  static const divider = Color(0xFFBFC7D4);

  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);

  static const indigo = Color(0xFF4F46E5);
  static const indigoSoft = Color(0xFFE0E7FF);
  static const cyan = Color(0xFF0891B2);
  static const cyanSoft = Color(0xFFCFFAFE);
  static const orange = Color(0xFFEA580C);
  static const orangeSoft = Color(0xFFFFEDD5);
  static const green = Color(0xFF16A34A);
  static const greenSoft = Color(0xFFDCFCE7);
  static const purple = Color(0xFF9333EA);
  static const purpleSoft = Color(0xFFF3E8FF);
  static const gray = Color(0xFF4B5563);
  static const graySoft = Color(0xFFF3F4F6);

  static const radiusLg = 20.0;
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  User? get _user => FirebaseAuth.instance.currentUser;

  Future<void> _openEditProfile() async {
    final result = await context.push('/settings/profile');
    if (result == true) {
      await _user?.reload();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final user = _user;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : (user?.email?.split('@').first ?? 'User NetWash');
    final photoUrl = user?.photoURL;

    return Scaffold(
      backgroundColor: _Palette.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;
            return Column(
              children: [
                // ==== Top bar TETAP (pinned) saat konten di-scroll ====
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Container(
                      color: _Palette.canvas,
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 16 : 24,
                        isMobile ? 12 : 16,
                        isMobile ? 8 : 12,
                        4,
                      ),
                      child: _buildTopBar(context, t),
                    ),
                  ),
                ),
                // ==== Konten yang bisa di-scroll ====
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                isMobile ? 16 : 24,
                                0,
                                isMobile ? 16 : 24,
                                4,
                              ),
                              child: _buildProfileCard(
                                context,
                                t,
                                displayName,
                                user?.email,
                                photoUrl,
                                isMobile,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                isMobile ? 16 : 24,
                                0,
                                isMobile ? 16 : 24,
                                24,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _sectionLabel(t.sectionAccount),
                                  _buildSectionCard([
                                    _buildTile(
                                      icon: Icons.person_outline_rounded,
                                      title: t.editProfileTitle,
                                      subtitle: t.editProfileSubtitle,
                                      color: _Palette.primary,
                                      background: _Palette.primaryContainer,
                                      onTap: _openEditProfile,
                                    ),
                                    _buildTile(
                                      icon: Icons.lock_outline_rounded,
                                      title: t.changePasswordTitle,
                                      subtitle: t.changePasswordSubtitle,
                                      color: _Palette.indigo,
                                      background: _Palette.indigoSoft,
                                      onTap: () => context
                                          .push('/settings/change-password'),
                                      showDivider: false,
                                    ),
                                  ]),
                                  const SizedBox(height: 20),
                                  _sectionLabel(t.sectionPreference),
                                  _buildSectionCard([
                                    _buildTile(
                                      icon: Icons.notifications_outlined,
                                      title: t.notificationTitle,
                                      subtitle: t.notificationSubtitle,
                                      color: _Palette.orange,
                                      background: _Palette.orangeSoft,
                                      onTap: () => context
                                          .push('/settings/notifications'),
                                    ),
                                    _buildTile(
                                      icon: Icons.language_outlined,
                                      title: t.languageTitle,
                                      subtitle:
                                          currentLocale.languageCode == 'id'
                                              ? 'Indonesia'
                                              : 'English',
                                      color: _Palette.purple,
                                      background: _Palette.purpleSoft,
                                      onTap: () => _showLanguagePicker(
                                          context, t, currentLocale),
                                      showDivider: false,
                                    ),
                                  ]),
                                  const SizedBox(height: 20),
                                  // Section ini cuma nongol buat user dengan
                                  // role 'admin' (tim CS platform NetWash) --
                                  // owner/manager/employee biasa nggak lihat ini
                                  // sama sekali. Role dibaca dari dokumen profil
                                  // Firestore, bukan FirebaseAuth User.
                                  if (_user != null)
                                    StreamBuilder<UserModel?>(
                                      stream: ref
                                          .read(userRepositoryProvider)
                                          .getUserProfileStream(_user!.uid),
                                      builder: (context, snapshot) {
                                        if (snapshot.data?.role != 'admin') {
                                          return const SizedBox.shrink();
                                        }
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            _sectionLabel(t.sectionCsTeam),
                                            _buildSectionCard([
                                              _buildTile(
                                                icon: Icons
                                                    .support_agent_rounded,
                                                title: t.manageCsChatTitle,
                                                subtitle:
                                                    t.manageCsChatSubtitle,
                                                color: _Palette.cyan,
                                                background: _Palette.cyanSoft,
                                                onTap: () => context
                                                    .push('/admin/support'),
                                                showDivider: false,
                                              ),
                                            ]),
                                            const SizedBox(height: 20),
                                          ],
                                        );
                                      },
                                    ),
                                  _sectionLabel(t.sectionOther),
                                  _buildSectionCard([
                                    _buildTile(
                                      icon: Icons.help_outline_rounded,
                                      title: t.helpTitle,
                                      subtitle: t.helpSubtitle,
                                      color: _Palette.gray,
                                      background: _Palette.graySoft,
                                      onTap: () =>
                                          context.push('/settings/help'),
                                    ),
                                    _buildTile(
                                      icon: Icons.info_outline_rounded,
                                      title: t.aboutTitle,
                                      subtitle: 'NetWash v1.0.0',
                                      color: _Palette.gray,
                                      background: _Palette.graySoft,
                                      onTap: () =>
                                          context.push('/settings/about'),
                                      showDivider: false,
                                    ),
                                  ]),
                                  const SizedBox(height: 28),
                                  _buildLogoutButton(context, t),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==========================================================
  // Dialog pilih bahasa — sekarang beneran manggil localeProvider
  // ==========================================================
  void _showLanguagePicker(
    BuildContext context,
    AppLocalizations t,
    Locale currentLocale,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _Palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_Palette.radiusLg),
        ),
        title: Text(
          t.languageTitle,
          style: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.w600,
            color: _Palette.ink,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              value: 'id',
              groupValue: currentLocale.languageCode,
              title: Text('Indonesia', style: GoogleFonts.beVietnamPro()),
              activeColor: _Palette.primary,
              onChanged: (value) {
                ref.read(localeProvider.notifier).setLocale(const Locale('id'));
                Navigator.pop(dialogContext);
              },
            ),
            RadioListTile<String>(
              value: 'en',
              groupValue: currentLocale.languageCode,
              title: Text('English', style: GoogleFonts.beVietnamPro()),
              activeColor: _Palette.primary,
              onChanged: (value) {
                ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // TOP BAR — putih polos, judul biru. Persis seperti header di
  // code.html (bg-surface, bukan panel biru).
  // ==========================================================
  Widget _buildTopBar(BuildContext context, AppLocalizations t) {
    return Row(
      children: [
        Expanded(
          child: Text(
            t.settingsTitle,
            style: GoogleFonts.beVietnamPro(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _Palette.primaryDark,
            ),
          ),
        ),
        IconButton(
          onPressed: () => context.push('/settings/notifications'),
          icon: const Icon(Icons.notifications_outlined,
              color: _Palette.primaryDark),
        ),
      ],
    );
  }

  // ==========================================================
  // PROFILE CARD — kartu putih (bukan panel gradient biru),
  // avatar dengan cincin primary-container, badge role di
  // sebelah nama, tombol "Edit Profil" di bawah. Avatar juga
  // bisa ditekan langsung untuk ganti foto.
  // ==========================================================
  Widget _buildProfileCard(
    BuildContext context,
    AppLocalizations t,
    String name,
    String? email,
    String? photoUrl,
    bool isMobile,
  ) {
    final avatarSize = isMobile ? 76.0 : 84.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _openEditProfile,
            child: Container(
              width: avatarSize,
              height: avatarSize,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _Palette.primaryContainer, width: 2),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _Palette.primaryContainer,
                      shape: BoxShape.circle,
                      image: (photoUrl != null && photoUrl.isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(photoUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: avatarSize * 0.36,
                              fontWeight: FontWeight.w700,
                              color: _Palette.primary,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: _Palette.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _Palette.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _Palette.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  t.roleOwner.toUpperCase(),
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: _Palette.primary,
                  ),
                ),
              ),
            ],
          ),
          if (email != null) ...[
            const SizedBox(height: 4),
            Text(
              email,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: _Palette.inkSoft,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: _openEditProfile,
              style: OutlinedButton.styleFrom(
                foregroundColor: _Palette.primary,
                side: const BorderSide(color: _Palette.primary, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                t.editProfileTitle,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
        style: GoogleFonts.beVietnamPro(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _Palette.inkFaint,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(_Palette.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = _Palette.primary,
    Color background = _Palette.primaryContainer,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_Palette.radiusLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: _Palette.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: _Palette.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: _Palette.inkFaint, size: 20),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 70,
            color: _Palette.divider.withOpacity(0.5),
          ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, AppLocalizations t) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context, t),
        icon: const Icon(Icons.logout_rounded, size: 19),
        label: Text(
          t.logoutButton,
          style: GoogleFonts.beVietnamPro(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _Palette.error,
          side: const BorderSide(color: _Palette.error, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_Palette.radiusLg),
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppLocalizations t) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _Palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_Palette.radiusLg),
        ),
        title: Text(
          t.logoutDialogTitle,
          style: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.w600,
            color: _Palette.ink,
          ),
        ),
        content: Text(
          t.logoutDialogContent,
          style: GoogleFonts.beVietnamPro(color: _Palette.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              t.cancel,
              style: GoogleFonts.beVietnamPro(color: _Palette.inkSoft),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: Text(
              t.logout,
              style: GoogleFonts.beVietnamPro(
                fontWeight: FontWeight.w600,
                color: _Palette.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
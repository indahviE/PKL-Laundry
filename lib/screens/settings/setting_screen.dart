import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/themes/app_theme.dart';
import '../../core/providers/locale.provider.dart';
import '../../l10n/app_localizations.dart';

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
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(
                        context,
                        t,
                        displayName,
                        user?.email,
                        photoUrl,
                        isMobile,
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
                                onTap: _openEditProfile,
                              ),
                              _buildTile(
                                icon: Icons.lock_outline_rounded,
                                title: t.changePasswordTitle,
                                subtitle: t.changePasswordSubtitle,
                                onTap: () =>
                                    context.push('/settings/change-password'),
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
                                onTap: () {},
                              ),
                              _buildTile(
                                icon: Icons.language_outlined,
                                title: t.languageTitle,
                                subtitle: currentLocale.languageCode == 'id'
                                    ? 'Indonesia'
                                    : 'English',
                                onTap: () => _showLanguagePicker(
                                    context, t, currentLocale),
                                showDivider: false,
                              ),
                            ]),
                            const SizedBox(height: 20),
                            _sectionLabel(t.sectionOther),
                            _buildSectionCard([
                              _buildTile(
                                icon: Icons.help_outline_rounded,
                                title: t.helpTitle,
                                subtitle: t.helpSubtitle,
                                onTap: () {},
                              ),
                              _buildTile(
                                icon: Icons.info_outline_rounded,
                                title: t.aboutTitle,
                                subtitle: 'NetWash v1.0.0',
                                onTap: () {},
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text(
          t.languageTitle,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              value: 'id',
              groupValue: currentLocale.languageCode,
              title: Text('Indonesia', style: GoogleFonts.poppins()),
              activeColor: AppTheme.primaryColor,
              onChanged: (value) {
                ref.read(localeProvider.notifier).setLocale(const Locale('id'));
                Navigator.pop(dialogContext);
              },
            ),
            RadioListTile<String>(
              value: 'en',
              groupValue: currentLocale.languageCode,
              title: Text('English', style: GoogleFonts.poppins()),
              activeColor: AppTheme.primaryColor,
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
  // HEADER
  // ==========================================================
  // Dirapikan: sebelumnya padding horizontal fixed 24 di semua ukuran
  // layar (nggak ngikutin `isMobile` kayak konten di bawahnya yang
  // 16/24), radius sudut 32 dan avatar 76px juga kebesaran buat layar
  // sempit -> keliatan "meleber"/terlalu lebar dibanding body di
  // bawahnya. Sekarang padding, radius, avatar, dan spacing semua
  // responsif + judul dikasih icon badge kecil (senada sama pola header
  // di Dashboard/Orders/Customers) biar lebih proporsional dan rapi.
  Widget _buildHeader(
    BuildContext context,
    AppLocalizations t,
    String name,
    String? email,
    String? photoUrl,
    bool isMobile,
  ) {
    final horizontalPadding = isMobile ? 18.0 : 24.0;
    final avatarSize = isMobile ? 58.0 : 64.0;
    final cornerRadius = isMobile ? 20.0 : 26.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        isMobile ? 16 : 20,
        horizontalPadding,
        isMobile ? 20 : 24,
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(cornerRadius),
          bottomRight: Radius.circular(cornerRadius),
        ),
      ),
      child: Column(
        children: [
          Text(
            t.settingsTitle,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.85),
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Container(
            width: avatarSize,
            height: avatarSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
              image: (photoUrl != null && photoUrl.isNotEmpty)
                  ? DecorationImage(
                      image: NetworkImage(photoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: (photoUrl == null || photoUrl.isEmpty)
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                      fontSize: avatarSize * 0.38,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (email != null) ...[
            const SizedBox(height: 2),
            Text(
              email,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              t.roleOwner,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white,
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
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textTertiary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
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
      child: Column(children: children),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textTertiary, size: 20),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 70,
            color: AppTheme.borderColor.withOpacity(0.6),
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
          style: GoogleFonts.poppins(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.redAccent, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppLocalizations t) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text(
          t.logoutDialogTitle,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          t.logoutDialogContent,
          style: GoogleFonts.poppins(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              t.cancel,
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
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
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
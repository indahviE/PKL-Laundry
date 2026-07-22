import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/themes/app_theme.dart';
import '../../l10n/app_localizations.dart';

// TODO: kalau versi sering berubah tiap rilis, ganti jadi baca otomatis
// dari package_info_plus (PackageInfo.fromPlatform().version) daripada
// hardcode di sini.
const String kAppVersion = '1.0.0';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka tautan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildAppInfo(),
                        const SizedBox(height: 16),
                        _buildDescriptionCard(),
                        const SizedBox(height: 16),
                        _buildLinksCard(context),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            '© 2026 NetWash. All rights reserved.',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ),
                      ],
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
            t.aboutTitle,
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

  Widget _buildAppInfo() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.local_laundry_service_outlined,
                size: 30, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            'NetWash',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Versi $kAppVersion',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
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
      padding: const EdgeInsets.all(16),
      child: Text(
        'NetWash adalah aplikasi laundry on-demand yang memudahkan kamu menjemput, mencuci, dan mengantar pakaian tanpa repot.',
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: AppTheme.textSecondary,
          height: 1.7,
        ),
      ),
    );
  }

  Widget _buildLinksCard(BuildContext context) {
    Widget row(String label, VoidCallback onTap, {bool showDivider = true}) {
      return Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppTheme.textTertiary, size: 20),
                ],
              ),
            ),
          ),
          if (showDivider)
            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: AppTheme.borderColor.withOpacity(0.6),
            ),
        ],
      );
    }

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
        children: [
          // TODO: ganti URL kebijakan privasi & syarat ketentuan sesuai domain resmi
          row('Kebijakan privasi',
              () => _openUrl(context, 'https://netwash.id/privasi')),
          row('Syarat dan ketentuan',
              () => _openUrl(context, 'https://netwash.id/syarat')),
          row(
            'Beri rating aplikasi',
            () => _openUrl(context,
                'https://play.google.com/store/apps/details?id=com.netwash.app'),
            showDivider: false,
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/themes/app_theme.dart';
import '../../l10n/app_localizations.dart';

class _Faq {
  final String question;
  final String answer;
  const _Faq(this.question, this.answer);
}

// TODO: pindahkan ke Firestore/CMS kalau kontennya sering berubah,
// biar tidak perlu rilis ulang app tiap update FAQ.
const List<_Faq> _faqData = [
  _Faq(
    'Bagaimana cara order cuci?',
    'Buka menu Order, pilih layanan, tentukan alamat jemput, lalu konfirmasi pesanan. Kurir akan datang sesuai jadwal.',
  ),
  _Faq(
    'Berapa lama proses cucian?',
    'Proses cuci reguler 1-2 hari kerja, express selesai dalam 6 jam sejak dijemput.',
  ),
  _Faq(
    'Metode pembayaran apa saja?',
    'Kami menerima transfer bank, e-wallet, dan pembayaran tunai langsung ke kurir.',
  ),
  _Faq(
    'Cara lacak status pesanan?',
    'Buka menu Orders, pilih pesanan aktif, status akan otomatis update mengikuti tahap pengerjaan.',
  ),
];

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _expandedIndex;
  String _query = '';

  List<_Faq> get _filtered {
    if (_query.trim().isEmpty) return _faqData;
    return _faqData
        .where((f) => f.question.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _launch(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka aplikasi tujuan')),
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
                        _buildSearchBar(),
                        const SizedBox(height: 16),
                        _buildFaqCard(),
                        const SizedBox(height: 16),
                        _buildContactCard(),
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
            t.helpTitle,
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

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _query = v),
        style: GoogleFonts.poppins(fontSize: 13.5),
        decoration: InputDecoration(
          hintText: 'Cari pertanyaan...',
          hintStyle: GoogleFonts.poppins(
              fontSize: 13.5, color: AppTheme.textTertiary),
          prefixIcon: const Icon(Icons.search,
              size: 20, color: AppTheme.textTertiary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            borderSide: BorderSide(color: AppTheme.borderColor),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqCard() {
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
        children: List.generate(_filtered.length, (index) {
          final faq = _filtered[index];
          final isOpen = _expandedIndex == index;
          return Column(
            children: [
              InkWell(
                onTap: () =>
                    setState(() => _expandedIndex = isOpen ? null : index),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              faq.question,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Icon(
                            isOpen
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: isOpen
                                ? AppTheme.primaryColor
                                : AppTheme.textTertiary,
                          ),
                        ],
                      ),
                      if (isOpen)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            faq.answer,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: AppTheme.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (index != _filtered.length - 1)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: AppTheme.borderColor.withOpacity(0.6),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildContactCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Belum terjawab? Hubungi kami',
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  // TODO: ganti nomor CS asli, format 62xxxxxxxxxx
                  onPressed: () =>
                      _launch(Uri.parse('https://wa.me/6281234567890')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                  ),
                  icon: const Icon(Icons.chat, size: 16),
                  label: const Text('WhatsApp'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _launch(Uri.parse('mailto:cs@netwash.id')),
                  icon: const Icon(Icons.email_outlined, size: 16),
                  label: const Text('Email'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/themes/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Nomor WhatsApp CS NetWash. GANTI dengan nomor asli sebelum rilis.
const String _csWhatsappNumber = '08996733553';

class _Faq {
  final String question;
  final String answer;
  final IconData icon;
  final List<String> keywords;

  const _Faq({
    required this.question,
    required this.answer,
    this.icon = Icons.help_outline_rounded,
    this.keywords = const [],
  });
}

class _FaqSection {
  final String title;
  final List<_Faq> items;

  const _FaqSection({required this.title, required this.items});
}

// TODO: pindahkan ke Firestore/CMS kalau kontennya sering berubah,
// biar tidak perlu rilis ulang app tiap update FAQ.
// Ini fungsi (bukan const list) supaya isinya ikut bahasa aktif (t).
//
// NOTE: gabungan dari HelpScreen (FAQ umum) + ChatCsScreen (panduan
// pakai aplikasi buat staff/owner baru). ChatCsScreen sudah tidak
// dipakai lagi -- lihat riwayat repo kalau butuh referensi UI chat-nya.
List<_FaqSection> _faqSections(AppLocalizations t) => [
      _FaqSection(
        title: t.helpSectionGeneralTitle,
        items: [
          _Faq(
            question: t.faqOrderQuestion,
            answer: t.faqOrderAnswer,
            icon: Icons.receipt_long_outlined,
            keywords: const ['pesanan', 'order'],
          ),
          _Faq(
            question: t.faqDurationQuestion,
            answer: t.faqDurationAnswer,
            icon: Icons.timer_outlined,
            keywords: const ['durasi', 'lama', 'waktu', 'duration'],
          ),
          _Faq(
            question: t.faqPaymentQuestion,
            answer: t.faqPaymentAnswer,
            icon: Icons.payments_outlined,
            keywords: const ['bayar', 'pembayaran', 'payment'],
          ),
          _Faq(
            question: t.faqTrackQuestion,
            answer: t.faqTrackAnswer,
            icon: Icons.track_changes_outlined,
            keywords: const ['lacak', 'tracking', 'status'],
          ),
        ],
      ),
      _FaqSection(
        title: t.helpSectionAppGuideTitle,
        items: [
          _Faq(
            question: t.chatBotTopicBranchQuestion,
            answer: t.chatBotTopicBranchAnswer,
            icon: Icons.storefront_outlined,
            keywords: const ['cabang', 'branch', 'tambah cabang', 'buka cabang'],
          ),
          _Faq(
            question: t.chatBotTopicEmployeeQuestion,
            answer: t.chatBotTopicEmployeeAnswer,
            icon: Icons.badge_outlined,
            keywords: const ['karyawan', 'pegawai', 'staff', 'employee'],
          ),
          _Faq(
            question: t.chatBotTopicServiceQuestion,
            answer: t.chatBotTopicServiceAnswer,
            icon: Icons.local_laundry_service_outlined,
            keywords: const ['layanan', 'harga', 'service', 'pricing'],
          ),
          _Faq(
            question: t.chatBotTopicOrderQuestion,
            answer: t.chatBotTopicOrderAnswer,
            icon: Icons.add_shopping_cart_outlined,
            keywords: const ['buat pesanan', 'new order', 'create order', 'input pesanan'],
          ),
          _Faq(
            question: t.chatBotTopicReportQuestion,
            answer: t.chatBotTopicReportAnswer,
            icon: Icons.bar_chart_outlined,
            keywords: const ['laporan', 'pendapatan', 'report', 'revenue'],
          ),
          _Faq(
            question: t.chatBotTopicLanguageQuestion,
            answer: t.chatBotTopicLanguageAnswer,
            icon: Icons.language_outlined,
            keywords: const ['bahasa', 'ganti bahasa', 'language'],
          ),
        ],
      ),
    ];

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _expandedGlobalIndex;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filter tiap section berdasarkan pertanyaan ATAU keywords, lalu
  /// buang section yang jadi kosong. Index tetap dibikin global
  /// (lintas section) biar state expand/collapse gak nabrak.
  List<_FaqSection> _filteredSections(AppLocalizations t) {
    final sections = _faqSections(t);
    if (_query.trim().isEmpty) return sections;
    final q = _query.toLowerCase();
    return sections
        .map((s) => _FaqSection(
              title: s.title,
              items: s.items
                  .where((f) =>
                      f.question.toLowerCase().contains(q) ||
                      f.keywords.any((kw) => kw.contains(q)))
                  .toList(),
            ))
        .where((s) => s.items.isNotEmpty)
        .toList();
  }

  Future<void> _launch(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.linkOpenError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final sections = _filteredSections(t);

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
                        _buildSearchBar(t),
                        const SizedBox(height: 20),
                        ..._buildSections(sections),
                        const SizedBox(height: 4),
                        _buildContactCard(t),
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

  Widget _buildSearchBar(AppLocalizations t) {
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
          hintText: t.searchFaqHint,
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

  List<Widget> _buildSections(List<_FaqSection> sections) {
    final widgets = <Widget>[];
    var globalIndex = 0;
    for (final section in sections) {
      final startIndex = globalIndex;
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4),
        child: Text(
          section.title,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ));
      widgets.add(_buildFaqCard(section.items, startIndex));
      widgets.add(const SizedBox(height: 16));
      globalIndex += section.items.length;
    }
    return widgets;
  }

  Widget _buildFaqCard(List<_Faq> items, int startIndex) {
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
        children: List.generate(items.length, (i) {
          final faq = items[i];
          final globalIndex = startIndex + i;
          final isOpen = _expandedGlobalIndex == globalIndex;
          return Column(
            children: [
              InkWell(
                onTap: () => setState(
                    () => _expandedGlobalIndex = isOpen ? null : globalIndex),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(faq.icon,
                              size: 17, color: AppTheme.textSecondary),
                          const SizedBox(width: 10),
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
                          padding: const EdgeInsets.only(top: 10, left: 27),
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
              if (i != items.length - 1)
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

  Widget _buildContactCard(AppLocalizations t) {
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
            t.notAnsweredContactUs,
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
                  onPressed: () =>
                      _launch(Uri.parse('https://wa.me/$_csWhatsappNumber')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                  ),
                  icon: const Icon(Icons.chat, size: 16),
                  label: Text(t.whatsappButton),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _launch(Uri.parse('mailto:cs@netwash.id')),
                  icon: const Icon(Icons.email_outlined, size: 16),
                  label: Text(t.emailLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
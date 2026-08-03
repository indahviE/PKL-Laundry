import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/themes/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Nomor WhatsApp CS NetWash yang dipakai sebagai fallback kalau bot
/// gak nemu jawaban yang cocok. GANTI dengan nomor asli sebelum rilis.
const String _csWhatsappNumber = '083144823911';

enum _Sender { bot, user }

class _ChatMessage {
  final _Sender sender;
  final String text;
  final DateTime time;
  final bool showWhatsappCta;
  final bool isWelcomeCard;

  _ChatMessage({
    required this.sender,
    required this.text,
    required this.time,
    this.showWhatsappCta = false,
    this.isWelcomeCard = false,
  });
}

class _FaqTopic {
  final String question;
  final String shortLabel;
  final String answer;
  final IconData icon;
  final List<String> keywords;

  _FaqTopic({
    required this.question,
    required this.shortLabel,
    required this.answer,
    required this.icon,
    required this.keywords,
  });
}

/// Chat bot FAQ 1-arah untuk bantu pemilik/staff laundry yang baru pegang
/// aplikasi -- BUKAN chat ke pelanggan laundry (itu tetap lewat WhatsApp,
/// lihat OrderDetailScreen). Semua jawaban statis/lokal, gak ada backend:
/// user pilih topik (dari kartu sambutan atau pill di atas input) atau
/// ketik bebas, bot coba cocokkan ke salah satu FAQ lewat keyword; kalau
/// gak ketemu, tawarin kontak WhatsApp CS.
class ChatCsScreen extends StatefulWidget {
  const ChatCsScreen({super.key});

  @override
  State<ChatCsScreen> createState() => _ChatCsScreenState();
}

class _ChatCsScreenState extends State<ChatCsScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _botTyping = false;
  bool _greeted = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<_FaqTopic> _buildTopics(AppLocalizations t) => [
        _FaqTopic(
          question: t.chatBotTopicBranchQuestion,
          shortLabel: t.chatBotTopicBranchShortLabel,
          answer: t.chatBotTopicBranchAnswer,
          icon: Icons.storefront_outlined,
          keywords: const [
            'cabang',
            'branch',
            'tambah cabang',
            'buka cabang',
            'new branch',
            'add branch',
          ],
        ),
        _FaqTopic(
          question: t.chatBotTopicEmployeeQuestion,
          shortLabel: t.chatBotTopicEmployeeShortLabel,
          answer: t.chatBotTopicEmployeeAnswer,
          icon: Icons.badge_outlined,
          keywords: const [
            'karyawan',
            'pegawai',
            'staff',
            'employee',
            'tambah karyawan',
            'new employee',
            'add employee',
          ],
        ),
        _FaqTopic(
          question: t.chatBotTopicServiceQuestion,
          shortLabel: t.chatBotTopicServiceShortLabel,
          answer: t.chatBotTopicServiceAnswer,
          icon: Icons.local_laundry_service_outlined,
          keywords: const [
            'layanan',
            'harga',
            'service',
            'price',
            'pricing',
            'tambah layanan',
            'new service',
          ],
        ),
        _FaqTopic(
          question: t.chatBotTopicOrderQuestion,
          shortLabel: t.chatBotTopicOrderShortLabel,
          answer: t.chatBotTopicOrderAnswer,
          icon: Icons.receipt_long_outlined,
          keywords: const [
            'pesanan',
            'buat pesanan',
            'order',
            'new order',
            'create order',
          ],
        ),
        _FaqTopic(
          question: t.chatBotTopicReportQuestion,
          shortLabel: t.chatBotTopicReportShortLabel,
          answer: t.chatBotTopicReportAnswer,
          icon: Icons.bar_chart_outlined,
          keywords: const [
            'laporan',
            'pendapatan',
            'report',
            'reports',
            'revenue',
          ],
        ),
        _FaqTopic(
          question: t.chatBotTopicLanguageQuestion,
          shortLabel: t.chatBotTopicLanguageShortLabel,
          answer: t.chatBotTopicLanguageAnswer,
          icon: Icons.language_outlined,
          keywords: const [
            'bahasa',
            'ganti bahasa',
            'language',
            'change language',
          ],
        ),
      ];

  void _greetIfNeeded(AppLocalizations t) {
    if (_greeted) return;
    _greeted = true;
    _messages.add(_ChatMessage(
      sender: _Sender.bot,
      text: t.chatBotGreeting,
      time: DateTime.now(),
      isWelcomeCard: true,
    ));
  }

  _FaqTopic? _matchTopic(String input, List<_FaqTopic> topics) {
    final lower = input.toLowerCase();
    for (final topic in topics) {
      for (final kw in topic.keywords) {
        if (lower.contains(kw)) return topic;
      }
    }
    return null;
  }

  Future<void> _sendUserText(String text) async {
    if (text.trim().isEmpty || _botTyping) return;
    final t = AppLocalizations.of(context)!;
    final topics = _buildTopics(t);

    setState(() {
      _messages.add(_ChatMessage(
        sender: _Sender.user,
        text: text.trim(),
        time: DateTime.now(),
      ));
      _botTyping = true;
    });
    _scrollToBottom();

    final match = _matchTopic(text, topics);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    setState(() {
      _botTyping = false;
      if (match != null) {
        _messages.add(_ChatMessage(
          sender: _Sender.bot,
          text: match.answer,
          time: DateTime.now(),
        ));
      } else {
        _messages.add(_ChatMessage(
          sender: _Sender.bot,
          text: t.chatBotFallbackMessage,
          time: DateTime.now(),
          showWhatsappCta: true,
        ));
      }
    });
    _scrollToBottom();
  }

  Future<void> _sendTopic(_FaqTopic topic) async {
    if (_botTyping) return;
    setState(() {
      _messages.add(_ChatMessage(
        sender: _Sender.user,
        text: topic.question,
        time: DateTime.now(),
      ));
      _botTyping = true;
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    setState(() {
      _botTyping = false;
      _messages.add(_ChatMessage(
        sender: _Sender.bot,
        text: topic.answer,
        time: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  Future<void> _openWhatsapp() async {
    final t = AppLocalizations.of(context)!;
    final uri = Uri.parse('https://wa.me/$_csWhatsappNumber');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw Exception('launch failed');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.whatsappOpenError)),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final topics = _buildTopics(t);
    _greetIfNeeded(t);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, t),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_botTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return _buildTypingBubble();
                  }
                  final message = _messages[index];
                  if (message.isWelcomeCard) {
                    return _buildWelcomeCard(t, message, topics);
                  }
                  return _buildBubble(message);
                },
              ),
            ),
            _buildQuickActionsRow(topics),
            _buildInputBar(t),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 20, 24, 20),
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
          const SizedBox(width: 2),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Icon(Icons.support_agent_rounded,
                color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            t.chatCsScreenTitle,
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

  /// Kartu sambutan pertama dari bot -- gaya kayak menu bantuan CS
  /// e-commerce: teks singkat + list tombol topik full-width.
  Widget _buildWelcomeCard(
    AppLocalizations t,
    _ChatMessage message,
    List<_FaqTopic> topics,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Icon(Icons.support_agent_rounded,
                    color: AppTheme.primaryColor, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message.text,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...topics.map((topic) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _sendTopic(topic),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppTheme.borderColor.withOpacity(0.7)),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Icon(topic.icon,
                            size: 17, color: AppTheme.textSecondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            topic.question,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            size: 18, color: AppTheme.textTertiary),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  /// Pill shortcut yang selalu nempel di atas input, biar user bisa
  /// langsung lompat ke topik lain kapan aja tanpa scroll ke atas.
  Widget _buildQuickActionsRow(List<_FaqTopic> topics) {
    return Container(
      color: AppTheme.backgroundColor,
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: topics.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final topic = topics[index];
            return OutlinedButton.icon(
              onPressed: () => _sendTopic(topic),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppTheme.cardColor,
                foregroundColor: AppTheme.textPrimary,
                side: BorderSide(
                    color: AppTheme.borderColor.withOpacity(0.7)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                visualDensity: VisualDensity.compact,
              ),
              icon: Icon(topic.icon, size: 15),
              label: Text(
                topic.shortLabel,
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(2),
            bottomRight: Radius.circular(14),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: SizedBox(
          width: 24,
          height: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              3,
              (i) => CircleAvatar(
                radius: 2.5,
                backgroundColor: AppTheme.textTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(_ChatMessage message) {
    final isUser = message.sender == _Sender.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primaryColor : AppTheme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 2),
            bottomRight: Radius.circular(isUser ? 2 : 14),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: isUser ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            if (message.showWhatsappCta) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: _openWhatsapp,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_outlined,
                          size: 15, color: AppTheme.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        AppLocalizations.of(context)!
                            .chatBotContactWhatsappButton,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.time),
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                color: isUser
                    ? Colors.white.withOpacity(0.75)
                    : AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (value) {
                      _sendUserText(value);
                      _inputController.clear();
                    },
                    style: GoogleFonts.poppins(fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: t.chatCsInputHint,
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13.5,
                        color: AppTheme.textTertiary,
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusXxl),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: AppTheme.primaryColor,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _botTyping
                        ? null
                        : () {
                            final text = _inputController.text;
                            _inputController.clear();
                            _sendUserText(text);
                          },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _botTyping
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              t.chatBotAutoReplyNotice,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
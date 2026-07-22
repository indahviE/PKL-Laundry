import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/themes/app_theme.dart';
import '../../models/support_message.dart';
import '../../repositories/admin_support_repository.dart';
import 'admin_guard.dart';

/// Detail 1 percakapan CS, dilihat & dibalas dari sisi admin.
/// Bubble di-mirror dari ChatCsScreen: di sini 'cs' (tim CS/kita) yang
/// ditaro di kanan, 'user' (business owner) di kiri -- kebalikan dari
/// ChatCsScreen punya user.
class AdminSupportChatScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? businessName;

  const AdminSupportChatScreen({
    super.key,
    required this.userId,
    this.businessName,
  });

  @override
  ConsumerState<AdminSupportChatScreen> createState() =>
      _AdminSupportChatScreenState();
}

class _AdminSupportChatScreenState
    extends ConsumerState<AdminSupportChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputController.text;
    if (text.trim().isEmpty || _sending) return;

    setState(() => _sending = true);
    _inputController.clear();
    try {
      await ref
          .read(adminSupportRepositoryProvider)
          .sendAsCs(widget.userId, text);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim balasan: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
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
    return AdminGuard(
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: StreamBuilder<List<SupportMessage>>(
                  stream: ref
                      .read(adminSupportRepositoryProvider)
                      .watchMessagesForUser(widget.userId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      );
                    }
                    final messages = snapshot.data!;
                    if (messages.isEmpty) {
                      return Center(
                        child: Text(
                          'Belum ada pesan di percakapan ini.',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      );
                    }
                    _scrollToBottom();
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) =>
                          _buildBubble(messages[index]),
                    );
                  },
                ),
              ),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              widget.businessName ?? widget.userId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(SupportMessage message) {
    final isCs = message.sender == MessageSender.cs;
    return Align(
      alignment: isCs ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isCs ? AppTheme.primaryColor : AppTheme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isCs ? 14 : 2),
            bottomRight: Radius.circular(isCs ? 2 : 14),
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
                color: isCs ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.createdAt),
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                color: isCs
                    ? Colors.white.withOpacity(0.75)
                    : AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
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
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                style: GoogleFonts.poppins(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Balas sebagai CS...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13.5,
                    color: AppTheme.textTertiary,
                  ),
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
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
                onTap: _sending ? null : _send,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _sending
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
      ),
    );
  }
}
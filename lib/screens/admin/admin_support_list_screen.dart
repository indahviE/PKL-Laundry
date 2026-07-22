import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/themes/app_theme.dart';
import '../../repositories/admin_support_repository.dart';
import 'admin_guard.dart';

/// Daftar semua percakapan "Chat dan CS" lintas user, buat tim CS.
/// Akses: /admin/support -- cuma bisa dibuka user dengan role 'admin'
/// (lihat AdminGuard). Tap 1 percakapan -> AdminSupportChatScreen.
class AdminSupportListScreen extends ConsumerWidget {
  const AdminSupportListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminGuard(
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: StreamBuilder<List<SupportConversationPreview>>(
                  stream: ref
                      .read(adminSupportRepositoryProvider)
                      .watchRecentConversations(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Gagal memuat percakapan:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      );
                    }
                    final conversations = snapshot.data!;
                    if (conversations.isEmpty) {
                      return _buildEmptyState();
                    }
                    // Belum dibalas CS ditaro paling atas biar gampang
                    // dicek tim CS duluan.
                    final sorted = [...conversations]..sort((a, b) {
                        if (a.lastMessageFromUser != b.lastMessageFromUser) {
                          return a.lastMessageFromUser ? -1 : 1;
                        }
                        return b.lastMessageAt.compareTo(a.lastMessageAt);
                      });
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: sorted.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _buildConversationTile(context, sorted[index]),
                    );
                  },
                ),
              ),
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
          Text(
            'Chat CS - Admin',
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 56, color: AppTheme.textTertiary),
            const SizedBox(height: 16),
            Text(
              'Belum ada percakapan masuk.',
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(
      BuildContext context, SupportConversationPreview c) {
    final needsReply = c.lastMessageFromUser;
    return Material(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: () => context.push(
          '/admin/support/${c.userId}',
          extra: {'businessName': c.businessName},
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: needsReply
                  ? AppTheme.primaryColor.withOpacity(0.4)
                  : AppTheme.borderColor.withOpacity(0.6),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Icon(Icons.store_outlined,
                    color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.businessName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM HH:mm').format(c.lastMessageAt),
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      needsReply
                          ? c.lastMessageText
                          : 'Kamu: ${c.lastMessageText}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: needsReply
                            ? AppTheme.textPrimary
                            : AppTheme.textTertiary,
                        fontWeight:
                            needsReply ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (needsReply) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
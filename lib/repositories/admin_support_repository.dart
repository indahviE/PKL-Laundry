import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/support_message.dart';

final adminSupportRepositoryProvider = Provider<AdminSupportRepository>((ref) {
  return AdminSupportRepository(FirebaseFirestore.instance);
});

/// Ringkasan 1 percakapan buat ditampilin di daftar (sisi admin/CS).
/// Bukan disimpan di Firestore -- dibentuk on-the-fly dari pesan terakhir
/// tiap user, jadi tidak perlu bikin collection summary terpisah dulu.
class SupportConversationPreview {
  final String userId;
  final String businessName;
  final String lastMessageText;
  final DateTime lastMessageAt;
  final bool lastMessageFromUser; // true = nunggu dibalas CS

  SupportConversationPreview({
    required this.userId,
    required this.businessName,
    required this.lastMessageText,
    required this.lastMessageAt,
    required this.lastMessageFromUser,
  });
}

class AdminSupportRepository {
  final FirebaseFirestore _firestore;

  AdminSupportRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _messagesRef(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('support_messages');

  /// Ambil [limit] pesan TERAKHIR lintas semua user (collectionGroup),
  /// lalu diringkas jadi 1 preview per user (ambil kemunculan pertama,
  /// karena query-nya udah descending by created_at = paling baru duluan).
  ///
  /// CATATAN SKALA: ini bukan pendekatan yang scale ke ribuan percakapan
  /// aktif -- kalau volume chat CS udah tinggi, ganti ke collection
  /// summary terpisah (mis. `support_conversations/{userId}` yang
  /// di-upsert oleh Cloud Function tiap ada pesan baru) daripada scan
  /// collectionGroup tiap kali. Untuk volume kecil/menengah ini cukup.
  Stream<List<SupportConversationPreview>> watchRecentConversations({int limit = 200}) {
    return _firestore
        .collectionGroup('support_messages')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
      final seenUserIds = <String>{};
      final previews = <SupportConversationPreview>[];

      for (final doc in snapshot.docs) {
        final userRef = doc.reference.parent.parent;
        if (userRef == null || seenUserIds.contains(userRef.id)) continue;
        seenUserIds.add(userRef.id);

        final data = doc.data();
        final message = SupportMessage.fromJson(data, doc.id);

        final userSnap = await userRef.get();
        final userData = userSnap.data() as Map<String, dynamic>?;
        final businessName = (userData?['full_name'] as String?)?.trim();

        previews.add(SupportConversationPreview(
          userId: userRef.id,
          businessName: (businessName == null || businessName.isEmpty)
              ? userRef.id
              : businessName,
          lastMessageText: message.text,
          lastMessageAt: message.createdAt,
          lastMessageFromUser: message.sender == MessageSender.user,
        ));
      }

      return previews;
    });
  }

  /// Sama seperti SupportMessageRepository.watchMessages, dipisah di sini
  /// supaya sisi admin tidak bergantung ke repository sisi user.
  Stream<List<SupportMessage>> watchMessagesForUser(String userId) {
    return _messagesRef(userId)
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportMessage.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Balas sebagai CS. Sender di-hardcode 'cs' -- ini yang jadi pembeda
  /// dari sendMessage() di sisi user, dan yang men-trigger Cloud Function
  /// `onSupportMessageCreated` buat kirim push notification ke user.
  Future<void> sendAsCs(String userId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    try {
      final message = SupportMessage(
        id: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sender: MessageSender.cs,
        text: trimmed,
      );
      await _messagesRef(userId).add(message.toJson());
    } catch (e) {
      throw Exception('Gagal mengirim balasan: $e');
    }
  }
}
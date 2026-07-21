import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/support_message.dart';

final supportMessageRepositoryProvider = Provider<SupportMessageRepository>((ref) {
  return SupportMessageRepository(FirebaseFirestore.instance);
});

class SupportMessageRepository {
  final FirebaseFirestore _firestore;

  SupportMessageRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _messagesRef(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('support_messages');

  /// Stream real-time, urut dari yang paling lama ke paling baru (dipakai
  /// langsung sama urutan tampil di ListView chat, tanpa reverse manual).
  Stream<List<SupportMessage>> watchMessages(String userId) {
    return _messagesRef(userId)
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportMessage.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Kirim pesan dari sisi user (business owner/staff). Sender di-hardcode
  /// 'user' di sini -- pesan dengan sender 'cs' cuma boleh ditulis dari
  /// sisi admin/CS (dashboard terpisah / manual, di luar scope screen ini).
  Future<void> sendMessage(String userId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    try {
      final message = SupportMessage(
        id: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sender: MessageSender.user,
        text: trimmed,
      );
      await _messagesRef(userId).add(message.toJson());
    } catch (e) {
      throw Exception('Gagal mengirim pesan: $e');
    }
  }
}
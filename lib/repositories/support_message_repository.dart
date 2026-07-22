import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/support_message.dart';

final supportMessageRepositoryProvider =
    Provider<SupportMessageRepository>((ref) {
  return SupportMessageRepository(FirebaseFirestore.instance);
});

/// Ringkasan 1 percakapan buat ditampilin di daftar "Kelola Chat CS"
/// (sisi admin) -- 1 item per user, isinya pesan PALING BARU aja.
///
/// CATATAN: kalau kamu sudah punya class serupa di model file kamu,
/// hapus class ini dan pakai punya kamu -- ini cuma dibuat di sini
/// biar file langsung bisa dipakai tanpa nunggu file lain.
class SupportConversationSummary {
  final String userId;
  final SupportMessage lastMessage;
  final bool isUnread;

  SupportConversationSummary({
    required this.userId,
    required this.lastMessage,
    required this.isUnread,
  });
}

class SupportMessageRepository {
  final FirebaseFirestore _firestore;

  SupportMessageRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _messagesRef(String userId) =>
      _firestore.collection('users').doc(userId).collection(
          'support_messages');

  /// Stream real-time, urut dari yang paling lama ke paling baru (dipakai
  /// langsung sama urutan tampil di ListView chat, tanpa reverse manual).
  /// Dipakai di sisi USER (chat 1 percakapan miliknya sendiri) DAN di sisi
  /// ADMIN pas buka detail 1 percakapan tertentu (userId = milik user itu,
  /// bukan admin).
  Stream<List<SupportMessage>> watchMessages(String userId) {
    return _messagesRef(userId)
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportMessage.fromJson(doc.data(), doc.id))
            .toList());
  }

  /// Dipakai di sisi ADMIN/CS -- nampilin daftar percakapan dari SEMUA
  /// user, diurutin dari yang paling baru ada aktivitas.
  ///
  /// PENTING -- ini scaffold berdasarkan asumsi, cek & sesuaikan:
  /// 1. Pakai collectionGroup('support_messages') karena perlu baca
  ///    lintas semua users/{userId}/support_messages sekaligus -- BUKAN
  ///    collection('support_messages') biasa (itu nggak akan nemu
  ///    apa-apa, soalnya collection kamu ada di bawah users/{userId}/,
  ///    bukan top-level).
  /// 2. Query ini butuh composite index (collectionGroup + orderBy
  ///    created_at). Pertama kali dijalanin, kemungkinan besar muncul
  ///    error FAILED_PRECONDITION di console dengan link buat generate
  ///    index-nya -- klik link itu, atau tambahin manual ke
  ///    firestore.indexes.json lalu deploy ulang.
  /// 3. "Belum dibalas" (titik biru) di sini aku asumsikan: pesan
  ///    terakhir di percakapan itu sender-nya 'user' (CS belum sempat
  ///    bales). Kalau kamu punya field 'read'/'is_read' di model, ganti
  ///    logic-nya pakai field itu -- lebih akurat daripada nebak dari
  ///    sender terakhir.
  /// 4. Firestore rules HARUS udah ngasih akses admin ke collection
  ///    support_messages lintas user (function isAdmin() di
  ///    firestore.rules) -- kalau belum di-deploy, query ini bakal kena
  ///    permission-denied.
  /// 5. Nama field 'sender' dan value MessageSender.user di bawah ini
  ///    ngikutin yang udah dipakai di sendMessage() -- kalau enum/field
  ///    kamu beda namanya, sesuaikan baris isUnread.
  Stream<List<SupportConversationSummary>> watchRecentConversations() {
    return _firestore
        .collectionGroup('support_messages')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      // Group per user (ambil pesan PALING BARU untuk tiap userId).
      final Map<String, SupportConversationSummary> latestPerUser = {};

      for (final doc in snapshot.docs) {
        // doc.reference.parent.parent = dokumen users/{userId}
        final userRef = doc.reference.parent.parent;
        if (userRef == null) continue;
        final userId = userRef.id;

        // Karena query sudah diurutkan descending, dokumen PERTAMA yang
        // ketemu untuk userId tertentu otomatis yang paling baru --
        // entry berikutnya untuk userId yang sama pasti lebih lama,
        // jadi di-skip.
        if (latestPerUser.containsKey(userId)) continue;

        final message = SupportMessage.fromJson(
            doc.data() as Map<String, dynamic>, doc.id);
        latestPerUser[userId] = SupportConversationSummary(
          userId: userId,
          lastMessage: message,
          isUnread: message.sender == MessageSender.user,
        );
      }

      final list = latestPerUser.values.toList()
        ..sort((a, b) =>
            b.lastMessage.createdAt.compareTo(a.lastMessage.createdAt));
      return list;
    });
  }

  /// Kirim pesan dari sisi user (business owner/staff). Sender di-hardcode
  /// 'user' di sini -- pesan dengan sender 'cs' cuma boleh ditulis dari
  /// sisi admin/CS (lihat sendCsReply di bawah).
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

  /// Kirim balasan dari sisi ADMIN/CS ke percakapan milik user tertentu.
  /// Ini yang bikin sender-nya 'cs', beda dari sendMessage() di atas --
  /// dan ini juga yang men-trigger Cloud Function onSupportMessageCreated
  /// buat kirim push notif ke user (kalau Cloud Functions kamu udah aktif
  /// di plan Blaze).
  Future<void> sendCsReply(String userId, String text) async {
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
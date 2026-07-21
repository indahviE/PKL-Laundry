import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_model.dart';

/// Siapa yang ngirim pesan. 'user' = business owner/staff yang pakai app,
/// 'cs' = balasan dari customer service (platform NetWash), BUKAN dari
/// pelanggan laundry -- itu beda konteks, tetap ditangani via WhatsApp
/// (lihat _launchWhatsappMessage di OrderDetailScreen).
enum MessageSender { user, cs }

MessageSender _senderFromFirestore(dynamic value) {
  return value == 'cs' ? MessageSender.cs : MessageSender.user;
}

String _senderToFirestore(MessageSender sender) {
  return sender == MessageSender.cs ? 'cs' : 'user';
}

/// Maps to `users/{userId}/support_messages/{messageId}`.
///
/// NOTE: koleksi ini yang jadi trigger Cloud Function
/// `onSupportMessageCreated` (lihat functions/index.js) -- setiap
/// dokumen baru dengan sender == 'cs' otomatis kirim push notification
/// ke user kalau notif_prefs.chat_cs mereka true.
class SupportMessage extends BaseModel {
  final MessageSender sender;
  final String text;
  final bool read;

  SupportMessage({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.sender,
    required this.text,
    this.read = false,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json, String documentId) {
    final createdAt = dateTimeFromSnapshot(json['created_at']);
    return SupportMessage(
      id: documentId,
      createdAt: createdAt,
      // Pesan tidak pernah diedit setelah dikirim, jadi updatedAt tidak
      // relevan -- disamakan saja dengan createdAt supaya tetap patuh
      // kontrak BaseModel tanpa nambah field yang tidak pernah dipakai.
      updatedAt: createdAt,
      sender: _senderFromFirestore(json['sender']),
      text: json['text'] ?? '',
      read: json['read'] == true,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'sender': _senderToFirestore(sender),
      'text': text,
      'read': read,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
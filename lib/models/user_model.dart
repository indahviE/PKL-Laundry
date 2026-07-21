import 'base_model.dart';

/// Maps to `users/{user_id}/profile` in the blueprint (§3.2.1).
/// Note: `plan_id` is intentionally NOT here - the blueprint keeps
/// subscription/plan info in the `subscriptions` collection (§3.6.2),
/// not on the profile. `companyId` isn't in the blueprint's literal
/// profile JSON either, but is kept here since the app needs a fast way
/// to know which company an owner/manager/employee belongs to.
class UserModel extends BaseModel {
  final String fullName;
  final String email;
  final String phone;
  final String avatarUrl;
  final String role; // admin, owner, manager, employee
  final String? companyId;

  /// Preferensi notifikasi per kategori. Key: 'status_pesanan', 'promo',
  /// 'pengingat', 'chat_cs'. Default semua true kalau field belum ada
  /// di Firestore (user lama sebelum fitur ini ditambahkan).
  final Map<String, bool> notifPrefs;

  /// Token FCM device aktif, dipakai backend buat kirim push notification
  /// yang ditarget ke user ini. Di-refresh otomatis oleh FcmService.
  final String? fcmToken;

  UserModel({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.fullName,
    required this.email,
    this.phone = '',
    this.avatarUrl = '',
    required this.role,
    this.companyId,
    this.notifPrefs = const {
      'status_pesanan': true,
      'promo': true,
      'pengingat': true,
      'chat_cs': true,
    },
    this.fcmToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String documentId) {
    final rawPrefs = json['notif_prefs'] as Map<String, dynamic>?;
    return UserModel(
      id: documentId,
      createdAt: dateTimeFromSnapshot(json['created_at']),
      updatedAt: dateTimeFromSnapshot(json['updated_at']),
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      role: json['role'] ?? 'owner',
      companyId: json['company_id'],
      notifPrefs: rawPrefs != null
          ? rawPrefs.map((k, v) => MapEntry(k, v == true))
          : const {
              'status_pesanan': true,
              'promo': true,
              'pengingat': true,
              'chat_cs': true,
            },
      fcmToken: json['fcm_token'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'role': role,
      'company_id': companyId,
      'notif_prefs': notifPrefs,
      'fcm_token': fcmToken,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
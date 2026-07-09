import 'package:cloud_firestore/cloud_firestore.dart';
 
abstract class BaseModel {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
 
  BaseModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
  });
 
  Map<String, dynamic> toJson();
}
 
/// Converts a Firestore value into a DateTime.
///
/// Firestore stores date fields as native `Timestamp` objects (per the
/// blueprint schema: `created_at: Timestamp`), but data coming from a
/// local cache, a REST call, or older documents might still be a String.
/// This handles both cases instead of assuming one or the other.
///
/// Only falls back to DateTime.now() when the value is completely absent
/// (e.g. a legacy document missing the field) - use [dateTimeFromSnapshotOrNull]
/// for fields that are genuinely optional (pickup_date, trial_end, etc.)
/// so a missing value stays `null` instead of silently becoming "now".
DateTime dateTimeFromSnapshot(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}
 
/// Same as [dateTimeFromSnapshot] but returns null when the value is null.
DateTime? dateTimeFromSnapshotOrNull(dynamic value) {
  if (value == null) return null;
  return dateTimeFromSnapshot(value);
}
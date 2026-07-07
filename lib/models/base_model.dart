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
DateTime dateTimeFromSnapshot(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}
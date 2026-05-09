import 'package:cloud_firestore/cloud_firestore.dart';

DateTime dateFromFirestore(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.now();
}

String cleanJoinCode(String value) {
  return value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
}

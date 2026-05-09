import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_mapper.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final DateTime createdAt;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return AppUser(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      createdAt: dateFromFirestore(data['createdAt']),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

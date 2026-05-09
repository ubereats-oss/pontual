import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_mapper.dart';

class PunchLocation {
  const PunchLocation({
    required this.id,
    required this.name,
    required this.code,
    required this.adminUid,
    required this.latitude,
    required this.longitude,
    required this.allowedRadiusMeters,
    required this.memberUids,
    required this.active,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String code;
  final String adminUid;
  final double latitude;
  final double longitude;
  final double allowedRadiusMeters;
  final List<String> memberUids;
  final bool active;
  final DateTime createdAt;

  factory PunchLocation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return PunchLocation(
      id: doc.id,
      name: data['name'] as String? ?? '',
      code: data['code'] as String? ?? '',
      adminUid: data['adminUid'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      allowedRadiusMeters:
          (data['allowedRadiusMeters'] as num?)?.toDouble() ?? 100,
      memberUids: (data['memberUids'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(),
      active: data['active'] as bool? ?? true,
      createdAt: dateFromFirestore(data['createdAt']),
    );
  }

  bool isAdmin(String uid) => adminUid == uid;
}

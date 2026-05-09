import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/firestore_mapper.dart';

enum PunchType {
  arrival,
  departure;

  String get label {
    return switch (this) {
      PunchType.arrival => 'Chegada',
      PunchType.departure => 'Saida',
    };
  }

  String get storageValue {
    return switch (this) {
      PunchType.arrival => 'arrival',
      PunchType.departure => 'departure',
    };
  }

  static PunchType fromStorage(String value) {
    return switch (value) {
      'departure' => PunchType.departure,
      _ => PunchType.arrival,
    };
  }
}

class PunchRecord {
  const PunchRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.createdAt,
    required this.distanceMeters,
    required this.accuracyMeters,
  });

  final String id;
  final String userId;
  final String userName;
  final PunchType type;
  final DateTime createdAt;
  final double distanceMeters;
  final double accuracyMeters;

  factory PunchRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return PunchRecord(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      type: PunchType.fromStorage(data['type'] as String? ?? ''),
      createdAt: dateFromFirestore(data['createdAt']),
      distanceMeters: (data['distanceMeters'] as num?)?.toDouble() ?? 0,
      accuracyMeters: (data['accuracyMeters'] as num?)?.toDouble() ?? 0,
    );
  }
}

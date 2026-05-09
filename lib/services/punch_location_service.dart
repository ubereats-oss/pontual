import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../core/utils/firestore_mapper.dart';
import '../models/app_user.dart';
import '../models/punch_location.dart';
import '../models/punch_record.dart';
import 'location_security_service.dart';

class PunchLocationService {
  PunchLocationService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<PunchLocation>> watchMyLocations(String uid) {
    return _db
        .collection('punchLocations')
        .where('memberUids', arrayContains: uid)
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final locations = snapshot.docs.map(PunchLocation.fromDoc).toList();
          locations.sort((a, b) => a.name.compareTo(b.name));
          return locations;
        });
  }

  Stream<PunchLocation?> watchLocation(String locationId) {
    return _db
        .collection('punchLocations')
        .doc(locationId)
        .snapshots()
        .map((doc) => doc.exists ? PunchLocation.fromDoc(doc) : null);
  }

  Stream<List<PunchRecord>> watchRecentPunches(String locationId) {
    return _db
        .collection('punchLocations')
        .doc(locationId)
        .collection('punches')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(PunchRecord.fromDoc).toList());
  }

  Future<CreateLocationResult> createLocation({
    required String name,
    required double allowedRadiusMeters,
    required Position position,
    required AppUser admin,
  }) async {
    for (var attempt = 0; attempt < 6; attempt++) {
      final code = _generateCode();
      final locationRef = _db.collection('punchLocations').doc();
      final codeRef = _db.collection('locationCodes').doc(code);

      try {
        await _db.runTransaction((transaction) async {
          final codeDoc = await transaction.get(codeRef);
          if (codeDoc.exists) throw const _CodeCollision();

          transaction.set(locationRef, {
            'name': name,
            'code': code,
            'adminUid': admin.uid,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'allowedRadiusMeters': allowedRadiusMeters,
            'memberUids': [admin.uid],
            'active': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          transaction.set(locationRef.collection('members').doc(admin.uid), {
            'uid': admin.uid,
            'name': admin.name,
            'email': admin.email,
            'role': 'admin',
            'joinedAt': FieldValue.serverTimestamp(),
          });
          transaction.set(codeRef, {
            'locationId': locationRef.id,
            'createdBy': admin.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        });

        return CreateLocationResult(locationId: locationRef.id, code: code);
      } on _CodeCollision {
        continue;
      }
    }

    throw StateError('Nao foi possivel gerar um codigo unico.');
  }

  Future<String> joinLocationWithCode({
    required String rawCode,
    required AppUser user,
  }) async {
    final code = cleanJoinCode(rawCode);
    if (code.length != 6) {
      throw ArgumentError('Codigo invalido.');
    }

    return _db.runTransaction((transaction) async {
      final codeRef = _db.collection('locationCodes').doc(code);
      final codeDoc = await transaction.get(codeRef);
      if (!codeDoc.exists) throw StateError('Codigo nao encontrado.');

      final locationId = codeDoc.data()?['locationId'] as String?;
      if (locationId == null || locationId.isEmpty) {
        throw StateError('Codigo sem local vinculado.');
      }

      final locationRef = _db.collection('punchLocations').doc(locationId);
      final locationDoc = await transaction.get(locationRef);
      if (!locationDoc.exists) throw StateError('Local nao encontrado.');
      if (locationDoc.data()?['active'] != true) {
        throw StateError('Este local esta inativo.');
      }

      transaction.update(locationRef, {
        'memberUids': FieldValue.arrayUnion([user.uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(locationRef.collection('members').doc(user.uid), {
        'uid': user.uid,
        'name': user.name,
        'email': user.email,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return locationId;
    });
  }

  Future<void> registerPunch({
    required PunchLocation location,
    required AppUser user,
    required PunchType type,
    required LocationGateResult gate,
  }) async {
    final position = gate.position;
    if (!gate.allowed || position == null) {
      await logBlockedAttempt(location: location, user: user, gate: gate);
      throw StateError(gate.reason);
    }

    await _db
        .collection('punchLocations')
        .doc(location.id)
        .collection('punches')
        .add({
          'userId': user.uid,
          'userName': user.name,
          'type': type.storageValue,
          'createdAt': FieldValue.serverTimestamp(),
          'deviceTime': Timestamp.fromDate(DateTime.now()),
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracyMeters': position.accuracy,
          'distanceMeters': gate.distanceMeters,
          'isMocked': position.isMocked,
          'securityStatus': 'approved',
        });
  }

  Future<void> logBlockedAttempt({
    required PunchLocation location,
    required AppUser user,
    required LocationGateResult gate,
  }) async {
    final position = gate.position;
    await _db
        .collection('punchLocations')
        .doc(location.id)
        .collection('blockedPunchAttempts')
        .add({
          'userId': user.uid,
          'userName': user.name,
          'createdAt': FieldValue.serverTimestamp(),
          'reason': gate.reason,
          'latitude': position?.latitude,
          'longitude': position?.longitude,
          'accuracyMeters': position?.accuracy,
          'distanceMeters': gate.distanceMeters,
          'isMocked': position?.isMocked,
        });
  }

  String _generateCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(
      6,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }
}

class CreateLocationResult {
  const CreateLocationResult({required this.locationId, required this.code});

  final String locationId;
  final String code;
}

class _CodeCollision implements Exception {
  const _CodeCollision();
}

import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../models/punch_location.dart';

class LocationSecurityService {
  const LocationSecurityService();

  Future<Position> captureSetupPosition() async {
    await _ensureLocationPermission();
    final position = await _currentPosition();
    if (position.isMocked) {
      throw const LocationSecurityException(
        'Localizacao simulada detectada. Desative o fake GPS.',
      );
    }
    if (position.accuracy <= 0 || position.accuracy > 50) {
      throw LocationSecurityException(
        'GPS impreciso: ${position.accuracy.toStringAsFixed(0)} m.',
      );
    }
    return position;
  }

  Future<LocationGateResult> evaluate(PunchLocation location) async {
    try {
      await _ensureLocationPermission();
      final position = await _currentPosition();
      return evaluatePosition(location: location, position: position);
    } on LocationSecurityException catch (error) {
      return LocationGateResult.denied(reason: error.message);
    } on TimeoutException {
      return LocationGateResult.denied(
        reason: 'Nao foi possivel obter o GPS agora. Tente novamente.',
      );
    } on Object catch (error) {
      return LocationGateResult.denied(reason: error.toString());
    }
  }

  static LocationGateResult evaluatePosition({
    required PunchLocation location,
    required Position position,
    DateTime? now,
  }) {
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      location.latitude,
      location.longitude,
    );
    final maxAccuracy = math.min(
      75.0,
      math.max(20.0, location.allowedRadiusMeters * 0.6),
    );
    final clockAge = Duration(
      microseconds: (now ?? DateTime.now())
          .difference(position.timestamp)
          .inMicroseconds
          .abs(),
    );

    if (position.isMocked) {
      return LocationGateResult.denied(
        reason: 'Fake GPS detectado pelo sistema.',
        position: position,
        distanceMeters: distance,
      );
    }
    if (clockAge > const Duration(minutes: 2)) {
      return LocationGateResult.denied(
        reason: 'GPS antigo. Atualize a localizacao e tente novamente.',
        position: position,
        distanceMeters: distance,
      );
    }
    if (position.accuracy <= 0 || position.accuracy > maxAccuracy) {
      return LocationGateResult.denied(
        reason: 'GPS impreciso (${position.accuracy.toStringAsFixed(0)} m).',
        position: position,
        distanceMeters: distance,
      );
    }
    if (distance > location.allowedRadiusMeters) {
      return LocationGateResult.denied(
        reason:
            'Voce esta a ${distance.toStringAsFixed(0)} m do local permitido.',
        position: position,
        distanceMeters: distance,
      );
    }

    return LocationGateResult.allowed(
      position: position,
      distanceMeters: distance,
    );
  }

  Future<void> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationSecurityException('Ative o GPS do celular.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationSecurityException('Permissao de GPS negada.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationSecurityException(
        'Permissao de GPS bloqueada nas configuracoes do celular.',
      );
    }
  }

  Future<Position> _currentPosition() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }
}

class LocationGateResult {
  const LocationGateResult._({
    required this.allowed,
    required this.reason,
    required this.position,
    required this.distanceMeters,
  });

  factory LocationGateResult.allowed({
    required Position position,
    required double distanceMeters,
  }) {
    return LocationGateResult._(
      allowed: true,
      reason: 'Ponto liberado.',
      position: position,
      distanceMeters: distanceMeters,
    );
  }

  factory LocationGateResult.denied({
    required String reason,
    Position? position,
    double? distanceMeters,
  }) {
    return LocationGateResult._(
      allowed: false,
      reason: reason,
      position: position,
      distanceMeters: distanceMeters,
    );
  }

  final bool allowed;
  final String reason;
  final Position? position;
  final double? distanceMeters;
}

class LocationSecurityException implements Exception {
  const LocationSecurityException(this.message);

  final String message;

  @override
  String toString() => message;
}

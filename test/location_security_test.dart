import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pontual/models/punch_location.dart';
import 'package:pontual/services/location_security_service.dart';

void main() {
  final location = PunchLocation(
    id: 'loc1',
    name: 'Escritorio',
    code: 'ABC123',
    adminUid: 'admin1',
    latitude: -23.561684,
    longitude: -46.625378,
    allowedRadiusMeters: 80,
    memberUids: const ['user1'],
    active: true,
    createdAt: DateTime(2026),
  );

  Position position({
    required double latitude,
    required double longitude,
    double accuracy = 8,
    bool isMocked = false,
  }) {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime(2026, 1, 1, 12),
      accuracy: accuracy,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
      isMocked: isMocked,
    );
  }

  test('bloqueia fake GPS informado pelo sistema', () {
    final result = LocationSecurityService.evaluatePosition(
      location: location,
      position: position(
        latitude: location.latitude,
        longitude: location.longitude,
        isMocked: true,
      ),
      now: DateTime(2026, 1, 1, 12),
    );

    expect(result.allowed, isFalse);
    expect(result.reason, contains('Fake GPS'));
  });

  test('bloqueia distancia fora do raio', () {
    final result = LocationSecurityService.evaluatePosition(
      location: location,
      position: position(latitude: -23.565, longitude: -46.629),
      now: DateTime(2026, 1, 1, 12),
    );

    expect(result.allowed, isFalse);
    expect(result.distanceMeters, greaterThan(location.allowedRadiusMeters));
  });

  test('libera posicao proxima com boa precisao', () {
    final result = LocationSecurityService.evaluatePosition(
      location: location,
      position: position(
        latitude: location.latitude,
        longitude: location.longitude,
      ),
      now: DateTime(2026, 1, 1, 12),
    );

    expect(result.allowed, isTrue);
  });
}

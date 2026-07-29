import 'package:flutter_test/flutter_test.dart';
import 'package:sks/core/utils/geo_utils.dart';
import 'package:sks/models/bus.dart';

void main() {
  group('coordinate parsing', () {
    test('accepts numeric values and numeric strings', () {
      expect(parseLatitude(13), 13.0);
      expect(parseLatitude(13.7563), 13.7563);
      expect(parseLatitude(' 13.7563 '), 13.7563);
      expect(parseLongitude(100), 100.0);
      expect(parseLongitude('100.5018'), 100.5018);
    });

    test('returns zero for invalid and out-of-range values', () {
      expect(parseLatitude(null), 0.0);
      expect(parseLatitude('not-a-number'), 0.0);
      expect(parseLatitude(double.nan), 0.0);
      expect(parseLatitude(90.1), 0.0);
      expect(parseLongitude(double.infinity), 0.0);
      expect(parseLongitude(-180.1), 0.0);
    });

    test('keeps valid coordinate boundaries', () {
      expect(parseLatitude(-90), -90.0);
      expect(parseLatitude(90), 90.0);
      expect(parseLongitude(-180), -180.0);
      expect(parseLongitude(180), 180.0);
    });

    test('Bus.fromMap accepts legacy string coordinates', () {
      final bus = Bus.fromMap('bus-1', {
        'busNumber': 'Bus 1',
        'schoolId': 'school-1',
        'childIds': <String>[],
        'currentLat': '13.7563',
        'currentLng': '100.5018',
      });

      expect(bus.currentLat, 13.7563);
      expect(bus.currentLng, 100.5018);
    });
  });
}

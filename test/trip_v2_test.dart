import 'package:flutter_test/flutter_test.dart';
import 'package:sks/models/trip.dart';
import 'package:sks/models/trip_stop.dart';
import 'package:sks/services/trip_service.dart';

void main() {
  group('Trip schema compatibility', () {
    test('legacy schoolId is exposed through effectiveSchoolIds', () {
      final trip = Trip.fromMap('trip_legacy', {
        'schoolId': 'school_a',
        'busId': 'bus_1',
        'serviceDate': '2026-07-28T00:00:00.000Z',
        'round': 'toSchool',
        'childIds': ['child_1'],
      });

      expect(trip.routeVersion, 1);
      expect(trip.effectiveSchoolIds, ['school_a']);
      expect(trip.toMap().containsKey('schoolId'), isFalse);
      expect(trip.toMap()['schoolIds'], ['school_a']);
    });

    test('v2 trip keeps multiple schools and route metadata', () {
      final trip = Trip.fromMap('trip_v2', {
        'schoolIds': ['school_a', 'school_b'],
        'busId': 'bus_1',
        'serviceDate': '2026-07-28T00:00:00.000Z',
        'round': 'toHome',
        'childIds': ['child_1', 'child_2'],
        'routeVersion': 2,
        'origin': {'lat': 13.75, 'lng': 100.5, 'label': 'Bus position'},
        'routePlan': {
          'provider': 'google-route-optimization',
          'inputHash': 'hash',
        },
      });

      expect(trip.routeVersion, 2);
      expect(trip.effectiveSchoolIds, ['school_a', 'school_b']);
      expect(trip.origin?['label'], 'Bus position');
      expect(trip.routePlan?['inputHash'], 'hash');
    });
  });

  test('grouped stop applies to every child at the location', () {
    final stop = TripStop.fromMap({
      'id': 'home:13.75000:100.50000',
      'type': 'home',
      'action': 'dropoff',
      'childIds': ['child_1', 'child_2'],
      'childNames': ['Alice', 'Bob'],
      'schoolIds': ['school_a', 'school_b'],
      'sequence': 3,
      'lat': 13.75,
      'lng': 100.5,
      'pickupLabel': 'Shared home',
    });

    expect(stop.effectiveChildIds, ['child_1', 'child_2']);
    expect(stop.action, 'dropoff');
    expect(stop.type, 'home');
    expect(stop.toMap()['childIds'], ['child_1', 'child_2']);
  });

  test('legacy stop exposes childId through effectiveChildIds', () {
    final stop = TripStop.fromMap({
      'childId': 'child_legacy',
      'sequence': 0,
      'lat': 13,
      'lng': 100,
    });

    expect(stop.effectiveChildIds, ['child_legacy']);
  });

  test('start result warns only when dynamic recalculation falls back', () {
    final trip = Trip.fromMap('trip_v2', {
      'busId': 'bus_1',
      'serviceDate': '2026-07-28T00:00:00.000Z',
      'round': 'toSchool',
      'childIds': ['child_1'],
      'routeVersion': 2,
    });

    TripStartResult result(String reason) => TripStartResult(
      trip: trip,
      routeRecalculated: false,
      fallbackReason: reason,
      alreadyActive: false,
    );

    expect(result('locationUnavailable').shouldWarnAboutSavedRoute, isTrue);
    expect(result('routeCalculationFailed').shouldWarnAboutSavedRoute, isTrue);
    expect(result('legacyTrip').shouldWarnAboutSavedRoute, isFalse);
    expect(result('').shouldWarnAboutSavedRoute, isFalse);
  });
}

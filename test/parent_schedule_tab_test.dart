import 'package:flutter_test/flutter_test.dart';
import 'package:sks/models/bus.dart';
import 'package:sks/models/child.dart';
import 'package:sks/models/school.dart';
import 'package:sks/models/trip.dart';
import 'package:sks/models/trip_stop.dart';
import 'package:sks/providers/trip_provider.dart';
import 'package:sks/screens/parent/parent_schedule_logic.dart';
import 'package:sks/services/trip_service.dart';

void main() {
  test(
    'TripProvider finds selected-date trips by child and splits rounds',
    () async {
      final today = _dateOnly(DateTime.now());
      final yesterday = today.subtract(const Duration(days: 1));
      final provider = TripProvider(
        _FakeTripService([
          _trip(
            id: 'trip_yesterday',
            childIds: const ['child_01'],
            busId: 'bus_old',
            serviceDate: yesterday,
            round: TripRound.toSchool,
            scheduledStartAt: _at(yesterday, 7, 0),
          ),
          _trip(
            id: 'trip_morning',
            childIds: const ['child_01'],
            busId: 'bus_today',
            serviceDate: today,
            round: TripRound.toSchool,
            scheduledStartAt: _at(today, 8, 15),
          ),
          _trip(
            id: 'trip_afternoon',
            childIds: const ['child_01'],
            busId: 'bus_today_pm',
            serviceDate: today,
            round: TripRound.toHome,
            scheduledStartAt: _at(today, 16, 45),
          ),
        ]),
      );

      await provider.loadAllTrips();
      await Future<void>.delayed(Duration.zero);

      final result = provider.tripsForChildOnDate('child_01', today);

      expect(result.morningTrip?.id, 'trip_morning');
      expect(result.afternoonTrip?.id, 'trip_afternoon');
      expect(result.primaryTrip?.busId, 'bus_today');

      provider.dispose();
    },
  );

  test(
    'Assigned child without selected-date trips shows no service and no fallback times',
    () {
      final presentation = buildParentSchedulePresentation(
        child: _child(),
        school: _school(),
        bus: null,
        dayTrips: const ChildTripsForDate(),
      );

      expect(presentation.status, ParentScheduleStatus.noServiceToday);
      expect(presentation.hasService, isFalse);
      expect(presentation.morningPickup, isNull);
      expect(presentation.eveningPickup, isNull);
      expect(presentation.busNumber, isNull);
    },
  );

  test('Assigned child with morning trip only shows morning pickup only', () {
    final today = _dateOnly(DateTime.now());
    final presentation = buildParentSchedulePresentation(
      child: _child(),
      school: _school(),
      bus: _bus(),
      dayTrips: ChildTripsForDate(
        morningTrip: _trip(
          id: 'trip_morning',
          childIds: const ['child_01'],
          busId: 'bus_01',
          serviceDate: today,
          round: TripRound.toSchool,
          scheduledStartAt: _at(today, 8, 15),
        ),
      ),
    );

    expect(presentation.status, ParentScheduleStatus.hasService);
    expect(presentation.morningPickup, '08:15');
    expect(presentation.eveningPickup, isNull);
    expect(presentation.busNumber, 'Bus 01');
  });

  test(
    'Assigned child with afternoon trip only shows afternoon pickup only',
    () {
      final today = _dateOnly(DateTime.now());
      final presentation = buildParentSchedulePresentation(
        child: _child(),
        school: _school(),
        bus: _bus(),
        dayTrips: ChildTripsForDate(
          afternoonTrip: _trip(
            id: 'trip_afternoon',
            childIds: const ['child_01'],
            busId: 'bus_01',
            serviceDate: today,
            round: TripRound.toHome,
            scheduledStartAt: _at(today, 16, 45),
          ),
        ),
      );

      expect(presentation.status, ParentScheduleStatus.hasService);
      expect(presentation.morningPickup, isNull);
      expect(presentation.eveningPickup, '16:45');
    },
  );

  test('Assigned child with both trips shows both selected-date rows', () {
    final today = _dateOnly(DateTime.now());
    final presentation = buildParentSchedulePresentation(
      child: _child(),
      school: _school(),
      bus: _bus(),
      dayTrips: ChildTripsForDate(
        morningTrip: _trip(
          id: 'trip_morning',
          childIds: const ['child_01'],
          busId: 'bus_01',
          serviceDate: today,
          round: TripRound.toSchool,
          scheduledStartAt: _at(today, 8, 10),
        ),
        afternoonTrip: _trip(
          id: 'trip_afternoon',
          childIds: const ['child_01'],
          busId: 'bus_01',
          serviceDate: today,
          round: TripRound.toHome,
          scheduledStartAt: _at(today, 16, 20),
        ),
      ),
    );

    expect(presentation.status, ParentScheduleStatus.hasService);
    expect(presentation.morningPickup, '08:10');
    expect(presentation.eveningPickup, '16:20');
  });

  test(
    'Selected-date bus info is preferred over stale child trip reference',
    () {
      final today = _dateOnly(DateTime.now());
      final presentation = buildParentSchedulePresentation(
        child: _child(tripId: 'trip_yesterday', busId: 'bus_old'),
        school: _school(),
        bus: _bus(id: 'bus_today', busNumber: 'Bus Today'),
        dayTrips: ChildTripsForDate(
          morningTrip: _trip(
            id: 'trip_today',
            childIds: const ['child_01'],
            busId: 'bus_today',
            serviceDate: today,
            round: TripRound.toSchool,
            scheduledStartAt: _at(today, 8, 25),
          ),
        ),
      );

      expect(presentation.busNumber, 'Bus Today');
      expect(presentation.morningPickup, '08:25');
    },
  );

  test('Unassigned child keeps waiting-for-route and pickup details', () {
    final presentation = buildParentSchedulePresentation(
      child: _child(
        tripId: null,
        busId: null,
        assignmentStatus: ChildAssignmentStatus.pending,
        name: 'Unassigned Kid',
      ),
      school: _school(),
      bus: null,
      dayTrips: const ChildTripsForDate(),
    );

    expect(presentation.status, ParentScheduleStatus.waitingForRoute);
    expect(presentation.pickupLabel, '456 Ladprao 1');
    expect(presentation.morningPickup, isNull);
    expect(presentation.eveningPickup, isNull);
  });
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime _at(DateTime date, int hour, int minute) {
  return DateTime(date.year, date.month, date.day, hour, minute);
}

Child _child({
  String? tripId = 'trip_01',
  String? busId = 'bus_01',
  ChildAssignmentStatus assignmentStatus = ChildAssignmentStatus.assigned,
  String name = 'Kong Rukluk',
}) {
  return Child(
    id: 'child_01',
    name: name,
    parentId: 'parent_01',
    tripId: tripId,
    schoolId: 'school_01',
    busId: busId,
    homeAddress: '456 Ladprao 1, Bangkok',
    pickupLabel: '456 Ladprao 1',
    pickupLat: 13.79,
    pickupLng: 100.55,
    qrCodeValue: 'qr-01',
    schoolName: 'Demo School',
    gradeLevel: 'P1',
    emergencyContactName: 'Mali',
    emergencyContactPhone: '0812345678',
    assignmentStatus: assignmentStatus,
  );
}

Trip _trip({
  required String id,
  required List<String> childIds,
  required String busId,
  required DateTime serviceDate,
  required TripRound round,
  DateTime? scheduledStartAt,
}) {
  return Trip(
    id: id,
    schoolId: 'school_01',
    busId: busId,
    serviceDate: serviceDate,
    round: round,
    scheduledStartAt: scheduledStartAt,
    childIds: childIds,
    stops: const <TripStop>[],
  );
}

Bus _bus({String id = 'bus_01', String busNumber = 'Bus 01'}) {
  return Bus(
    id: id,
    busNumber: busNumber,
    schoolId: 'school_01',
    childIds: const ['child_01'],
    currentLat: 0,
    currentLng: 0,
  );
}

School _school() {
  return const School(
    id: 'school_01',
    name: 'Demo School',
    lat: 13.7563,
    lng: 100.5018,
    address: '123 Road',
    morningPickup: '07:00',
    morningDropoff: '08:00',
    eveningPickup: '15:30',
    eveningDropoff: '17:00',
  );
}

class _FakeTripService implements ITripService {
  _FakeTripService(this.trips);

  final List<Trip> trips;

  @override
  Stream<List<Trip>> watchAllTrips() => Stream.value(trips);

  @override
  Stream<List<Trip>> watchTripsBySchoolId(String schoolId) {
    return Stream.value(
      trips.where((trip) => trip.schoolId == schoolId).toList(),
    );
  }

  @override
  Future<Trip?> getTripById(String tripId) async {
    for (final trip in trips) {
      if (trip.id == tripId) {
        return trip;
      }
    }
    return null;
  }

  @override
  Future<List<Trip>> getTripsByIds(Iterable<String> tripIds) async {
    final ids = tripIds.toSet();
    return trips.where((trip) => ids.contains(trip.id)).toList();
  }

  @override
  Future<Trip?> getActiveTripByBusId(String busId) async => null;

  @override
  Future<Trip?> getActiveTripByDriverId(String driverId) async => null;

  @override
  Future<bool> updateTripStatus(String tripId, TripStatus status) async => true;

  @override
  Future<bool> startTrip(String tripId) async => true;

  @override
  Future<bool> updateCurrentStopIndex(String tripId, int index) async => true;

  @override
  Future<bool> updateStopStatus(
    String tripId,
    int stopIndex,
    TripStopStatus status,
  ) async => true;

  @override
  Future<bool> completeTrip(String tripId) async => true;

  @override
  Stream<Trip?> watchTripById(String tripId) => Stream.value(null);
}

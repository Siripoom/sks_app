import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sks/models/trip.dart';
import 'package:sks/models/trip_stop.dart';

abstract class ITripService {
  Stream<List<Trip>> watchTripsBySchoolId(String schoolId);
  Stream<List<Trip>> watchAllTrips();
  Future<Trip?> getTripById(String tripId);
  Future<List<Trip>> getTripsByIds(Iterable<String> tripIds);
  Future<Trip?> getActiveTripByBusId(String busId);
  Future<Trip?> getActiveTripByDriverId(String driverId);
  Future<bool> updateTripStatus(String tripId, TripStatus status);
  Future<bool> startTrip(String tripId);
  Future<bool> updateCurrentStopIndex(String tripId, int index);
  Future<bool> updateStopStatus(
    String tripId,
    int stopIndex,
    TripStopStatus status,
  );
  Future<bool> completeTrip(String tripId);
  Stream<Trip?> watchTripById(String tripId);
}

class FirebaseTripService implements ITripService {
  FirebaseTripService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _trips =>
      _firestore.collection('trips');

  Iterable<Trip> _activeTrips(Iterable<Trip> trips) =>
      trips.where((trip) => !trip.isArchived);

  @override
  Stream<List<Trip>> watchTripsBySchoolId(String schoolId) {
    if (schoolId.trim().isEmpty) {
      return watchAllTrips();
    }
    return _trips.where('schoolId', isEqualTo: schoolId).snapshots().map((
      snapshot,
    ) {
      final trips = _activeTrips(
        snapshot.docs.map((doc) => Trip.fromMap(doc.id, doc.data())),
      ).toList();
      trips.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
      return trips;
    });
  }

  @override
  Stream<List<Trip>> watchAllTrips() {
    return _trips.snapshots().map((snapshot) {
      final trips = _activeTrips(
        snapshot.docs.map((doc) => Trip.fromMap(doc.id, doc.data())),
      ).toList();
      trips.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
      return trips;
    });
  }

  @override
  Future<Trip?> getTripById(String tripId) async {
    if (tripId.trim().isEmpty) {
      return null;
    }
    final snapshot = await _trips.doc(tripId).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    final trip = Trip.fromMap(snapshot.id, data);
    return trip.isArchived ? null : trip;
  }

  @override
  Future<List<Trip>> getTripsByIds(Iterable<String> tripIds) async {
    final ids = tripIds.toSet().where((id) => id.trim().isNotEmpty).toList();
    if (ids.isEmpty) {
      return const [];
    }
    final snapshot = await _trips
        .where(FieldPath.documentId, whereIn: ids)
        .get();
    final trips = _activeTrips(
      snapshot.docs.map((doc) => Trip.fromMap(doc.id, doc.data())),
    ).toList();
    trips.sort((a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)));
    return trips;
  }

  @override
  Future<Trip?> getActiveTripByBusId(String busId) async {
    final snapshot = await _trips.where('busId', isEqualTo: busId).get();
    final trips = _activeTrips(
      snapshot.docs.map((doc) => Trip.fromMap(doc.id, doc.data())),
    ).where((trip) =>
        trip.status == TripStatus.active ||
        trip.status == TripStatus.draft,
    ).toList()
      ..sort((a, b) {
        // active trips first, then draft
        if (a.status != b.status) {
          if (a.status == TripStatus.active) return -1;
          if (b.status == TripStatus.active) return 1;
        }
        return b.serviceDate.compareTo(a.serviceDate);
      });
    return trips.isEmpty ? null : trips.first;
  }

  @override
  Future<Trip?> getActiveTripByDriverId(String driverId) async {
    final buses = await _firestore
        .collection('buses')
        .where('driverId', isEqualTo: driverId)
        .limit(1)
        .get();
    if (buses.docs.isEmpty) {
      return null;
    }
    return getActiveTripByBusId(buses.docs.first.id);
  }

  @override
  Future<bool> updateTripStatus(String tripId, TripStatus status) async {
    await _trips.doc(tripId).set({
      'status': status.value,
      'updatedAt': DateTime.now(),
    }, SetOptions(merge: true));
    return true;
  }

  @override
  Future<bool> startTrip(String tripId) async {
    await _trips.doc(tripId).set({
      'status': TripStatus.active.value,
      'currentStopIndex': 0,
      'startedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return true;
  }

  @override
  Future<bool> updateCurrentStopIndex(String tripId, int index) async {
    await _trips.doc(tripId).set({
      'currentStopIndex': index,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return true;
  }

  @override
  Future<bool> updateStopStatus(
    String tripId,
    int stopIndex,
    TripStopStatus status,
  ) async {
    final doc = await _trips.doc(tripId).get();
    final data = doc.data();
    if (data == null) return false;

    final stops = List<Map<String, dynamic>>.from(
      data['stops'] as List? ?? [],
    );
    if (stopIndex < 0 || stopIndex >= stops.length) return false;

    stops[stopIndex]['status'] = status.value;
    final now = DateTime.now();
    if (status == TripStopStatus.arrived) {
      stops[stopIndex]['arrivedAt'] = now;
    } else if (status == TripStopStatus.pickedUp) {
      stops[stopIndex]['pickedUpAt'] = now;
    }

    await _trips.doc(tripId).set({
      'stops': stops,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return true;
  }

  @override
  Future<bool> completeTrip(String tripId) async {
    await _trips.doc(tripId).set({
      'status': TripStatus.completed.value,
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return true;
  }

  @override
  Stream<Trip?> watchTripById(String tripId) {
    if (tripId.trim().isEmpty) {
      return Stream.value(null);
    }
    return _trips.doc(tripId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      final trip = Trip.fromMap(snapshot.id, data);
      return trip.isArchived ? null : trip;
    });
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sks/models/trip.dart';
import 'package:sks/services/trip_service.dart';

class TripProvider extends ChangeNotifier {
  TripProvider(this._tripService);

  final ITripService _tripService;

  List<Trip> _trips = [];
  StreamSubscription<List<Trip>>? _tripSubscription;
  String? _schoolId;

  List<Trip> get trips => _trips;

  Future<void> loadTripsForSchool(String schoolId) async {
    _schoolId = schoolId;
    await _tripSubscription?.cancel();
    _tripSubscription = _tripService.watchTripsBySchoolId(schoolId).listen((
      trips,
    ) {
      _trips = trips;
      notifyListeners();
    });
  }

  Future<void> loadAllTrips() async {
    _schoolId = null;
    await _tripSubscription?.cancel();
    _tripSubscription = _tripService.watchAllTrips().listen((trips) {
      _trips = trips;
      notifyListeners();
    });
  }

  Trip? getTripById(String? tripId) {
    if (tripId == null || tripId.isEmpty) {
      return null;
    }
    try {
      return _trips.firstWhere((trip) => trip.id == tripId);
    } catch (_) {
      return null;
    }
  }

  List<Trip> tripsForBus(String busId) {
    return _trips.where((trip) => trip.busId == busId).toList();
  }

  Future<void> refresh() async {
    if (_schoolId == null) {
      await loadAllTrips();
      return;
    }
    await loadTripsForSchool(_schoolId!);
  }

  @override
  void dispose() {
    _tripSubscription?.cancel();
    super.dispose();
  }
}

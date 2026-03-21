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

  ChildTripsForDate tripsForChildOnDate(String childId, DateTime date) {
    if (childId.trim().isEmpty) {
      return const ChildTripsForDate();
    }

    final sameDayTrips = _trips.where((trip) {
      return trip.childIds.contains(childId) &&
          _isSameDay(trip.serviceDate, date);
    }).toList();

    return ChildTripsForDate(
      morningTrip: _preferredTripForRound(sameDayTrips, TripRound.toSchool),
      afternoonTrip: _preferredTripForRound(sameDayTrips, TripRound.toHome),
    );
  }

  List<Trip> tripsForBus(String busId) {
    return _trips.where((trip) => trip.busId == busId).toList();
  }

  Trip? _preferredTripForRound(List<Trip> trips, TripRound round) {
    final candidates = trips.where((trip) => trip.round == round).toList();
    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort((left, right) {
      final leftTime = left.scheduledStartAt ?? left.serviceDate;
      final rightTime = right.scheduledStartAt ?? right.serviceDate;
      return leftTime.compareTo(rightTime);
    });
    return candidates.first;
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
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

class ChildTripsForDate {
  final Trip? morningTrip;
  final Trip? afternoonTrip;

  const ChildTripsForDate({this.morningTrip, this.afternoonTrip});

  bool get hasService => morningTrip != null || afternoonTrip != null;

  Trip? get primaryTrip => morningTrip ?? afternoonTrip;
}

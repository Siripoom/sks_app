import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sks/models/bus.dart';
import 'package:sks/services/bus_service.dart';
import 'package:sks/services/location_service.dart';

class BusProvider extends ChangeNotifier {
  BusProvider(this._busService, this._locationService) {
    _subscribeToLocationUpdates();
  }

  final IBusService _busService;
  final ILocationService _locationService;

  List<Bus> _buses = [];
  Map<String, LatLng> _busLocations = {};
  StreamSubscription<List<Bus>>? _busSubscription;
  StreamSubscription<Map<String, LatLng>>? _locationSubscription;

  List<Bus> get buses => _buses;
  Map<String, LatLng> get busLocations => _busLocations;

  Future<void> loadAllBuses() async {
    await _busSubscription?.cancel();
    _busSubscription = _busService.watchAllBuses().listen((buses) {
      _buses = buses;
      _syncLocationsIntoBuses();
      notifyListeners();
    });
  }

  Bus? getBusById(String busId) {
    try {
      return _buses.firstWhere((b) => b.id == busId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateBusStatus(String busId, BusStatus status) async {
    final success = await _busService.updateBusStatus(busId, status);
    if (success) {
      await loadAllBuses();
    }
    return success;
  }

  void _subscribeToLocationUpdates() {
    _locationSubscription = _locationService.getBusLocationStream().listen((
      locations,
    ) {
      _busLocations = locations;
      _syncLocationsIntoBuses();
      notifyListeners();
    });
  }

  void _syncLocationsIntoBuses() {
    for (final bus in _buses) {
      final latLng = _busLocations[bus.id];
      if (latLng == null) {
        continue;
      }
      bus.currentLat = latLng.latitude;
      bus.currentLng = latLng.longitude;
    }
  }

  @override
  void dispose() {
    _busSubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }
}

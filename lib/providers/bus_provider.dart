import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sks/models/bus.dart';
import 'package:sks/services/bus_service.dart';
import 'package:sks/services/location_service.dart';

class BusProvider extends ChangeNotifier {
  final IBusService _busService;
  final ILocationService _locationService;

  List<Bus> _buses = [];
  Map<String, LatLng> _busLocations = {};

  List<Bus> get buses => _buses;
  Map<String, LatLng> get busLocations => _busLocations;

  BusProvider(this._busService, this._locationService) {
    _subscribeToLocationUpdates();
  }

  Future<void> loadBusesForSchool(String schoolId) async {
    _buses = await _busService.getBusesBySchoolId(schoolId);
    notifyListeners();
  }

  Bus? getBusById(String busId) {
    try {
      return _buses.firstWhere((b) => b.id == busId);
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateBusStatus(String busId, BusStatus status) async {
    final success = await _busService.updateBusStatus(busId, status);
    if (success) {
      await loadBusesForSchool(_buses.isNotEmpty ? _buses.first.schoolId : '');
    }
    return success;
  }

  void _subscribeToLocationUpdates() {
    _locationService.getBusLocationStream().listen((locations) {
      _busLocations = locations;

      // Update bus objects with new locations
      for (var bus in _buses) {
        if (locations.containsKey(bus.id)) {
          final latLng = locations[bus.id]!;
          bus.currentLat = latLng.latitude;
          bus.currentLng = latLng.longitude;
        }
      }

      notifyListeners();
    });
  }
}

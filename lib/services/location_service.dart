import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class ILocationService {
  Stream<Map<String, LatLng>> getBusLocationStream();
}

class MockLocationService implements ILocationService {
  Timer? _timer;
  late final StreamController<Map<String, LatLng>> _locationController;
  bool _started = false;

  // Initial locations
  double _bus01Lat = 13.7900;
  double _bus01Lng = 100.5500;
  final double _targetSchoolLat = 13.7563;
  final double _targetSchoolLng = 100.5018;

  MockLocationService() {
    _locationController = StreamController<Map<String, LatLng>>.broadcast(
      onListen: _startLocationUpdates,
    );
  }

  void _startLocationUpdates() {
    if (_started) {
      return;
    }

    _started = true;
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      // Move bus_01 toward school gradually
      const double deltaLat = 0.0012;
      const double deltaLng = 0.0017;

      if (_bus01Lat > _targetSchoolLat) {
        _bus01Lat -= deltaLat;
      }
      if (_bus01Lng < _targetSchoolLng) {
        _bus01Lng += deltaLng;
      }

      // Emit locations
      _locationController.add({
        'bus_01': LatLng(_bus01Lat, _bus01Lng),
        'bus_02': const LatLng(13.7200, 100.5800),
        'bus_03': const LatLng(13.7563, 100.5018),
      });
    });
  }

  @override
  Stream<Map<String, LatLng>> getBusLocationStream() {
    return _locationController.stream;
  }

  void dispose() {
    _timer?.cancel();
    _locationController.close();
  }
}

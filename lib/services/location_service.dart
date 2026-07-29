import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sks/core/utils/geo_utils.dart';

abstract class ILocationService {
  Stream<Map<String, LatLng>> getBusLocationStream();
  Future<Position> getCurrentDevicePosition();
  Stream<Position> watchDevicePosition();
}

class FirebaseLocationService implements ILocationService {
  FirebaseLocationService(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<Map<String, LatLng>> getBusLocationStream() {
    return _firestore.collection('buses').snapshots().map((snapshot) {
      final locations = <String, LatLng>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final lat = parseLatitude(data['currentLat']);
        final lng = parseLongitude(data['currentLng']);
        locations[doc.id] = LatLng(lat, lng);
      }
      return locations;
    });
  }

  @override
  Future<Position> getCurrentDevicePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Location services are disabled.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Location permission is unavailable.');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  @override
  Stream<Position> watchDevicePosition() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50,
    );
    return Geolocator.getPositionStream(locationSettings: settings);
  }
}

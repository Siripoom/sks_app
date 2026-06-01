import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class ILocationService {
  Stream<Map<String, LatLng>> getBusLocationStream();
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
        final lat = (data['currentLat'] as num?)?.toDouble() ?? 0.0;
        final lng = (data['currentLng'] as num?)?.toDouble() ?? 0.0;
        locations[doc.id] = LatLng(lat, lng);
      }
      return locations;
    });
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

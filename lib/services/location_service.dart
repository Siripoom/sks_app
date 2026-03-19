import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sks/models/bus.dart';

abstract class ILocationService {
  Stream<Map<String, LatLng>> getBusLocationStream();
}

class FirebaseLocationService implements ILocationService {
  FirebaseLocationService(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<Map<String, LatLng>> getBusLocationStream() {
    return _firestore.collection('buses').snapshots().map((snapshot) {
      final locations = <String, LatLng>{};
      for (final doc in snapshot.docs) {
        final bus = Bus.fromMap(doc.id, doc.data());
        locations[bus.id] = LatLng(bus.currentLat, bus.currentLng);
      }
      return locations;
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sks/models/bus.dart';

abstract class IBusService {
  Stream<List<Bus>> watchAllBuses();
  Future<List<Bus>> getBusesByIds(Iterable<String> busIds);
  Future<Bus?> getBusById(String busId);
  Future<Bus?> getBusByDriverId(String driverId);
  Future<bool> updateBusStatus(String busId, BusStatus status);
  Future<bool> updateBusLocation(String busId, double lat, double lng);
}

class FirebaseBusService implements IBusService {
  FirebaseBusService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _buses =>
      _firestore.collection('buses');

  Iterable<Bus> _activeBuses(Iterable<Bus> buses) =>
      buses.where((bus) => !bus.isArchived);

  @override
  Stream<List<Bus>> watchAllBuses() {
    return _buses.snapshots().map((snapshot) {
      final buses = _activeBuses(
        snapshot.docs.map((doc) => Bus.fromMap(doc.id, doc.data())),
      ).toList();
      buses.sort((a, b) => a.busNumber.compareTo(b.busNumber));
      return buses;
    });
  }

  @override
  Future<List<Bus>> getBusesByIds(Iterable<String> busIds) async {
    final ids = busIds.toSet().where((id) => id.trim().isNotEmpty).toList();
    if (ids.isEmpty) {
      return const [];
    }

    final snapshot = await _buses
        .where(FieldPath.documentId, whereIn: ids)
        .get();
    final buses = _activeBuses(
      snapshot.docs.map((doc) => Bus.fromMap(doc.id, doc.data())),
    ).toList();
    buses.sort((a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)));
    return buses;
  }

  @override
  Future<Bus?> getBusById(String busId) async {
    final snapshot = await _buses.doc(busId).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    final bus = Bus.fromMap(snapshot.id, data);
    return bus.isArchived ? null : bus;
  }

  @override
  Future<Bus?> getBusByDriverId(String driverId) async {
    final snapshot = await _buses
        .where('driverId', isEqualTo: driverId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    final doc = snapshot.docs.first;
    final bus = Bus.fromMap(doc.id, doc.data());
    return bus.isArchived ? null : bus;
  }

  @override
  Future<bool> updateBusStatus(String busId, BusStatus status) async {
    await _buses.doc(busId).update({'status': status.value});
    return true;
  }

  @override
  Future<bool> updateBusLocation(String busId, double lat, double lng) async {
    await _buses.doc(busId).update({'currentLat': lat, 'currentLng': lng});
    return true;
  }
}

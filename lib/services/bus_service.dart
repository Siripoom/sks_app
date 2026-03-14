import 'package:sks/data/mock_data.dart';
import 'package:sks/models/bus.dart';
import 'package:sks/models/bus_stop.dart';

abstract class IBusService {
  Future<List<Bus>> getBusesBySchoolId(String schoolId);
  Future<Bus?> getBusById(String busId);
  Future<Bus?> getBusByDriverId(String driverId);
  Future<bool> updateBusStatus(String busId, BusStatus status);
  Future<bool> updateBusLocation(String busId, double lat, double lng);
  Future<List<BusStop>> getBusStopsByBusId(String busId);
}

class MockBusService implements IBusService {
  final List<Bus> _buses = List.from(MockData.buses);
  final List<BusStop> _busStops = List.from(MockData.busStops);

  @override
  Future<List<Bus>> getBusesBySchoolId(String schoolId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _buses.where((b) => b.schoolId == schoolId).toList();
  }

  @override
  Future<Bus?> getBusById(String busId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _buses.firstWhere((b) => b.id == busId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Bus?> getBusByDriverId(String driverId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _buses.firstWhere((b) => b.driverId == driverId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> updateBusStatus(String busId, BusStatus status) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _buses.indexWhere((b) => b.id == busId);
    if (index != -1) {
      _buses[index].status = status;
      return true;
    }
    return false;
  }

  @override
  Future<bool> updateBusLocation(String busId, double lat, double lng) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _buses.indexWhere((b) => b.id == busId);
    if (index != -1) {
      _buses[index].currentLat = lat;
      _buses[index].currentLng = lng;
      return true;
    }
    return false;
  }

  @override
  Future<List<BusStop>> getBusStopsByBusId(String busId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final bus = await getBusById(busId);
    if (bus == null) return [];
    return _busStops
        .where((s) => bus.childIds.any((cId) => s.childIds.contains(cId)))
        .toList();
  }

  List<Bus> getBuses() => _buses;
}

import 'package:flutter/material.dart';
import 'package:sks/models/bus.dart';
import 'package:sks/models/child.dart';
import 'package:sks/services/bus_service.dart';
import 'package:sks/services/child_service.dart';
import 'package:sks/services/notification_service.dart';

class DriverProvider extends ChangeNotifier {
  final IBusService _busService;
  final IChildService _childService;
  final INotificationService _notificationService;

  Bus? _assignedBus;
  List<Child> _assignedChildren = [];

  Bus? get assignedBus => _assignedBus;
  List<Child> get assignedChildren => _assignedChildren;

  DriverProvider(
    this._busService,
    this._childService,
    this._notificationService,
  );

  Future<void> loadDriverData(String driverId) async {
    _assignedBus = await _busService.getBusByDriverId(driverId);
    if (_assignedBus != null) {
      _assignedChildren = [];
      for (var childId in _assignedBus!.childIds) {
        final child = await _childService.getChildById(childId);
        if (child != null) {
          _assignedChildren.add(child);
        }
      }
    }
    notifyListeners();
  }

  Future<bool> toggleBoarding(String childId) async {
    final index = _assignedChildren.indexWhere((c) => c.id == childId);
    if (index != -1) {
      _assignedChildren[index].hasBoarded =
          !_assignedChildren[index].hasBoarded;
      await _childService.updateChild(_assignedChildren[index]);
      notifyListeners();
      return true;
    }
    return false;
  }

  int getChildrenBoarded() {
    return _assignedChildren.where((c) => c.hasBoarded).length;
  }

  Future<bool> markArrived() async {
    if (_assignedBus == null) return false;

    final success = await _busService.updateBusStatus(
      _assignedBus!.id,
      BusStatus.arrived,
    );
    if (success) {
      _assignedBus!.status = BusStatus.arrived;

      // Mark all children as arrived
      for (var child in _assignedChildren) {
        child.hasArrived = true;
        await _childService.updateChild(child);

        // Send arrival notification
        await _notificationService.sendArrivalNotification(
          child.name,
          _assignedBus!.busNumber,
        );
      }

      notifyListeners();
    }
    return success;
  }
}

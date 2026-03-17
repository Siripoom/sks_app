import 'package:flutter/material.dart';
import 'package:sks/models/bus.dart';
import 'package:sks/models/child.dart';
import 'package:sks/services/bus_service.dart';
import 'package:sks/services/child_service.dart';
import 'package:sks/services/notification_service.dart';

enum DriverQrCheckInStatus { success, alreadyCheckedIn, notAssigned, notFound }

class DriverQrCheckInResult {
  final DriverQrCheckInStatus status;
  final Child? child;

  const DriverQrCheckInResult(this.status, {this.child});
}

class DriverBoardingToggleResult {
  final bool success;
  final Child? child;
  final bool isBoarded;

  const DriverBoardingToggleResult({
    required this.success,
    required this.child,
    required this.isBoarded,
  });

  const DriverBoardingToggleResult.failure()
    : success = false,
      child = null,
      isBoarded = false;
}

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
      for (final childId in _assignedBus!.childIds) {
        final child = await _childService.getChildById(childId);
        if (child != null) {
          _assignedChildren.add(child);
        }
      }
    }
    notifyListeners();
  }

  Future<DriverBoardingToggleResult> toggleBoarding(String childId) async {
    final index = _assignedChildren.indexWhere((c) => c.id == childId);
    if (index == -1) {
      return const DriverBoardingToggleResult.failure();
    }

    final child = _assignedChildren[index];
    child.hasBoarded = !child.hasBoarded;
    await _childService.updateChild(child);
    if (child.hasBoarded) {
      await _notificationService.sendBoardingNotification(
        child.name,
      );
    }
    notifyListeners();
    return DriverBoardingToggleResult(
      success: true,
      child: child,
      isBoarded: child.hasBoarded,
    );
  }

  Future<DriverQrCheckInResult> checkInByQr(String qrCodeValue) async {
    final index = _assignedChildren.indexWhere(
      (child) => child.qrCodeValue == qrCodeValue,
    );

    if (index != -1) {
      final child = _assignedChildren[index];
      if (child.hasBoarded) {
        return DriverQrCheckInResult(
          DriverQrCheckInStatus.alreadyCheckedIn,
          child: child,
        );
      }

      child.hasBoarded = true;
      await _childService.updateChild(child);
      await _notificationService.sendBoardingNotification(child.name);
      notifyListeners();
      return DriverQrCheckInResult(DriverQrCheckInStatus.success, child: child);
    }

    final child = await _childService.getChildByQrCode(qrCodeValue);
    if (child != null) {
      return DriverQrCheckInResult(
        DriverQrCheckInStatus.notAssigned,
        child: child,
      );
    }

    return const DriverQrCheckInResult(DriverQrCheckInStatus.notFound);
  }

  int getChildrenBoarded() {
    return _assignedChildren.where((c) => c.hasBoarded).length;
  }

  Future<bool> markArrived() async {
    if (_assignedBus == null) {
      return false;
    }

    final success = await _busService.updateBusStatus(
      _assignedBus!.id,
      BusStatus.arrived,
    );
    if (success) {
      _assignedBus!.status = BusStatus.arrived;

      for (final child in _assignedChildren) {
        child.hasArrived = true;
        await _childService.updateChild(child);
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

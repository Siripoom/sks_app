import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sks/models/bus.dart';
import 'package:sks/models/child.dart';
import 'package:sks/models/trip.dart';
import 'package:sks/services/bus_service.dart';
import 'package:sks/services/child_service.dart';
import 'package:sks/services/notification_service.dart';
import 'package:sks/services/trip_service.dart';

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
  DriverProvider(
    this._busService,
    this._childService,
    this._notificationService,
    this._tripService,
  );

  final IBusService _busService;
  final IChildService _childService;
  final INotificationService _notificationService;
  final ITripService _tripService;

  Bus? _assignedBus;
  Trip? _activeTrip;
  List<Child> _assignedChildren = [];
  StreamSubscription<List<Child>>? _childrenSubscription;

  Bus? get assignedBus => _assignedBus;
  Trip? get activeTrip => _activeTrip;
  List<Child> get assignedChildren => _assignedChildren;

  Future<void> loadDriverData(String driverId) async {
    _activeTrip = await _tripService.getActiveTripByDriverId(driverId);
    final busId = _activeTrip?.busId;
    _assignedBus = busId == null ? await _busService.getBusByDriverId(driverId) : await _busService.getBusById(busId);
    await _childrenSubscription?.cancel();

    if (_activeTrip == null) {
      _assignedChildren = [];
      notifyListeners();
      return;
    }

    _childrenSubscription = _childService
        .watchChildrenByIds(_activeTrip!.childIds)
        .listen((children) {
          _assignedChildren = children;
          notifyListeners();
        });
  }

  Future<DriverBoardingToggleResult> toggleBoarding(String childId) async {
    final index = _assignedChildren.indexWhere((c) => c.id == childId);
    if (index == -1 || _assignedBus == null) {
      return const DriverBoardingToggleResult.failure();
    }

    final child = _assignedChildren[index];
      child.hasBoarded = !child.hasBoarded;
      await _childService.updateChild(child);
      if (child.hasBoarded && _assignedBus != null && _activeTrip != null) {
        await _notificationService.sendBoardingNotification(
          child: child,
          bus: _assignedBus!,
          trip: _activeTrip!,
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
      if (_assignedBus != null && _activeTrip != null) {
        await _notificationService.sendBoardingNotification(
          child: child,
          bus: _assignedBus!,
          trip: _activeTrip!,
        );
      }
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
    if (_assignedBus == null || _activeTrip == null) {
      return false;
    }

    final success = await _tripService.updateTripStatus(
      _activeTrip!.id,
      TripStatus.completed,
    );
    if (success) {
      await _busService.updateBusStatus(_assignedBus!.id, BusStatus.arrived);
      _activeTrip = _activeTrip!.copyWith(status: TripStatus.completed);
      _assignedBus = _assignedBus!.copyWith(status: BusStatus.arrived);

      for (final child in _assignedChildren) {
        child.hasArrived = true;
        await _childService.updateChild(child);
        await _notificationService.sendArrivalNotification(
          child: child,
          bus: _assignedBus!,
          trip: _activeTrip!,
        );
      }

      notifyListeners();
    }
    return success;
  }

  @override
  void dispose() {
    _childrenSubscription?.cancel();
    super.dispose();
  }
}

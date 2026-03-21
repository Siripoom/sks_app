import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sks/core/utils/geo_utils.dart';
import 'package:sks/models/bus.dart';
import 'package:sks/models/child.dart';
import 'package:sks/models/trip.dart';
import 'package:sks/models/trip_stop.dart';
import 'package:sks/services/bus_service.dart';
import 'package:sks/services/child_service.dart';
import 'package:sks/services/location_service.dart';
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
    this._locationService,
  );

  final IBusService _busService;
  final IChildService _childService;
  final INotificationService _notificationService;
  final ITripService _tripService;
  final ILocationService _locationService;

  Bus? _assignedBus;
  Trip? _activeTrip;
  List<Child> _assignedChildren = [];
  StreamSubscription<List<Child>>? _childrenSubscription;
  StreamSubscription<Position>? _positionSubscription;
  final Set<String> _notifiedApproachingChildIds = {};

  Bus? get assignedBus => _assignedBus;
  Trip? get activeTrip => _activeTrip;
  List<Child> get assignedChildren => _assignedChildren;

  List<TripStop> get stops => _activeTrip?.stops ?? const [];
  int get currentStopIndex => _activeTrip?.currentStopIndex ?? -1;

  TripStop? get currentStop {
    final idx = currentStopIndex;
    final s = stops;
    if (idx < 0 || idx >= s.length) return null;
    return s[idx];
  }

  bool get isTripActive => _activeTrip?.status == TripStatus.active;
  bool get allStopsDone => isTripActive && currentStopIndex >= stops.length;

  int get completedStopsCount =>
      stops.where((s) => s.isDone).length;

  Future<void> loadDriverData(String driverId) async {
    _activeTrip = await _tripService.getActiveTripByDriverId(driverId);
    final busId = _activeTrip?.busId;
    _assignedBus = busId == null
        ? await _busService.getBusByDriverId(driverId)
        : await _busService.getBusById(busId);
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

    // Resume location sharing if trip is already active
    if (isTripActive) {
      _startLocationSharing();
    }
  }

  // ---------------------------------------------------------------------------
  // Trip stop workflow
  // ---------------------------------------------------------------------------

  Future<bool> startTrip() async {
    if (_activeTrip == null || _assignedBus == null) return false;
    if (_activeTrip!.stops.isEmpty) return false;

    final success = await _tripService.startTrip(_activeTrip!.id);
    if (!success) return false;

    await _busService.updateBusStatus(_assignedBus!.id, BusStatus.enRoute);

    _activeTrip = _activeTrip!.copyWith(
      status: TripStatus.active,
      currentStopIndex: 0,
      startedAt: DateTime.now(),
    );
    _assignedBus = _assignedBus!.copyWith(status: BusStatus.enRoute);
    _notifiedApproachingChildIds.clear();

    // For toHome: children are already on the bus at school
    if (_activeTrip!.round == TripRound.toHome) {
      for (final child in _assignedChildren) {
        child.hasBoarded = true;
        await _childService.updateChild(child);
      }
    }

    _startLocationSharing();

    await _notificationService.sendTripStartedNotification(
      trip: _activeTrip!,
      bus: _assignedBus!,
      children: _assignedChildren,
    );

    notifyListeners();
    return true;
  }

  Future<bool> markPickedUp() async {
    final stop = currentStop;
    final idx = currentStopIndex;
    if (stop == null || _activeTrip == null || _assignedBus == null) {
      return false;
    }

    // Update stop status in Firestore
    try {
      await _tripService.updateStopStatus(
        _activeTrip!.id,
        idx,
        TripStopStatus.pickedUp,
      );
    } catch (e) {
      debugPrint('updateStopStatus failed: $e');
    }

    // Mark child boarding status (toHome = drop off, toSchool = pick up)
    final child = _assignedChildren.where((c) => c.id == stop.childId).firstOrNull;
    final isToHome = _activeTrip!.round == TripRound.toHome;
    if (child != null) {
      child.hasBoarded = !isToHome; // toHome: false (dropped off), toSchool: true (boarded)
      try {
        await _childService.updateChild(child);
      } catch (e) {
        debugPrint('updateChild failed: $e');
      }
      // Non-blocking notification
      _notificationService.sendBoardingNotification(
        child: child,
        bus: _assignedBus!,
        trip: _activeTrip!,
      ).catchError((e) => debugPrint('sendBoardingNotification failed: $e'));
    }

    // Advance to next stop
    final nextIndex = idx + 1;
    try {
      await _tripService.updateCurrentStopIndex(_activeTrip!.id, nextIndex);
    } catch (e) {
      debugPrint('updateCurrentStopIndex failed: $e');
    }

    // Update local state
    final updatedStops = List<TripStop>.from(_activeTrip!.stops);
    updatedStops[idx] = stop.copyWith(
      status: TripStopStatus.pickedUp,
      pickedUpAt: DateTime.now(),
    );
    _activeTrip = _activeTrip!.copyWith(
      stops: updatedStops,
      currentStopIndex: nextIndex,
    );

    notifyListeners();
    return true;
  }

  Future<bool> skipCurrentStop() async {
    final stop = currentStop;
    final idx = currentStopIndex;
    if (stop == null || _activeTrip == null || _assignedBus == null) {
      return false;
    }

    try {
      await _tripService.updateStopStatus(
        _activeTrip!.id,
        idx,
        TripStopStatus.skipped,
      );
    } catch (e) {
      debugPrint('updateStopStatus (skip) failed: $e');
    }

    final child = _assignedChildren.where((c) => c.id == stop.childId).firstOrNull;
    if (child != null) {
      // Non-blocking notification
      _notificationService.sendChildSkippedNotification(
        child: child,
        bus: _assignedBus!,
        trip: _activeTrip!,
      ).catchError((e) => debugPrint('sendChildSkippedNotification failed: $e'));
    }

    final nextIndex = idx + 1;
    try {
      await _tripService.updateCurrentStopIndex(_activeTrip!.id, nextIndex);
    } catch (e) {
      debugPrint('updateCurrentStopIndex (skip) failed: $e');
    }

    final updatedStops = List<TripStop>.from(_activeTrip!.stops);
    updatedStops[idx] = stop.copyWith(
      status: TripStopStatus.skipped,
    );
    _activeTrip = _activeTrip!.copyWith(
      stops: updatedStops,
      currentStopIndex: nextIndex,
    );

    notifyListeners();
    return true;
  }

  Future<bool> completeTrip() async {
    if (_assignedBus == null || _activeTrip == null) return false;

    final success = await _tripService.completeTrip(_activeTrip!.id);
    if (!success) return false;

    await _busService.updateBusStatus(_assignedBus!.id, BusStatus.arrived);
    _activeTrip = _activeTrip!.copyWith(
      status: TripStatus.completed,
      completedAt: DateTime.now(),
    );
    _assignedBus = _assignedBus!.copyWith(status: BusStatus.arrived);

    final isToHome = _activeTrip!.round == TripRound.toHome;

    if (isToHome) {
      // toHome: notify for all children who were dropped off (hasBoarded == false means dropped)
      for (final child in _assignedChildren) {
        child.hasArrived = false;
        await _childService.updateChild(child);
        await _notificationService.sendArrivalNotification(
          child: child,
          bus: _assignedBus!,
          trip: _activeTrip!,
        );
      }
    } else {
      // toSchool: notify for children who boarded
      for (final child in _assignedChildren) {
        if (child.hasBoarded) {
          child.hasArrived = true;
          await _childService.updateChild(child);
          await _notificationService.sendArrivalNotification(
            child: child,
            bus: _assignedBus!,
            trip: _activeTrip!,
          );
        }
      }
    }

    _stopLocationSharing();
    notifyListeners();
    return success;
  }

  // ---------------------------------------------------------------------------
  // Legacy methods (kept for backward compat)
  // ---------------------------------------------------------------------------

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
    return completeTrip();
  }

  // ---------------------------------------------------------------------------
  // Location sharing & proximity detection
  // ---------------------------------------------------------------------------

  void _startLocationSharing() {
    _positionSubscription?.cancel();
    _positionSubscription = _locationService.watchDevicePosition().listen(
      _onPositionUpdate,
      onError: (e) => debugPrint('GPS stream error: $e'),
    );
  }

  void _stopLocationSharing() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void _onPositionUpdate(Position position) {
    if (_assignedBus == null) return;

    // Push location to Firestore
    _busService.updateBusLocation(
      _assignedBus!.id,
      position.latitude,
      position.longitude,
    );

    // Check proximity to current stop
    _checkProximity(position.latitude, position.longitude);
  }

  void _checkProximity(double busLat, double busLng) {
    final stop = currentStop;
    if (stop == null || !isTripActive) return;
    if (_notifiedApproachingChildIds.contains(stop.childId)) return;

    final distanceKm = haversineDistanceKm(
      busLat,
      busLng,
      stop.lat,
      stop.lng,
    );

    if (distanceKm < 1.0) {
      _notifiedApproachingChildIds.add(stop.childId);
      final minutes = estimateMinutes(distanceKm);
      final child = _assignedChildren
          .where((c) => c.id == stop.childId)
          .firstOrNull;
      if (child != null && _assignedBus != null && _activeTrip != null) {
        _notificationService.sendApproachingNotification(
          child: child,
          bus: _assignedBus!,
          trip: _activeTrip!,
          minutesAway: minutes,
        );
      }
    }
  }

  @override
  void dispose() {
    _childrenSubscription?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}

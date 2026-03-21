import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sks/core/utils/geo_utils.dart';
import 'package:sks/models/child.dart';
import 'package:sks/models/trip.dart';
import 'package:sks/models/trip_stop.dart';
import 'package:sks/services/child_service.dart';
import 'package:sks/services/notification_service.dart';
import 'package:sks/services/trip_service.dart';

class ParentProvider extends ChangeNotifier {
  ParentProvider(
    this._childService,
    this._notificationService,
    this._tripService,
  );

  final IChildService _childService;
  final INotificationService _notificationService;
  final ITripService _tripService;

  List<Child> _myChildren = [];
  List<Map<String, String>> _notifications = [];
  StreamSubscription<List<Child>>? _childrenSubscription;
  StreamSubscription<List<Map<String, String>>>? _notificationsSubscription;

  Trip? _watchedTrip;
  StreamSubscription<Trip?>? _tripSubscription;

  List<Child> get myChildren => _myChildren;
  List<Map<String, String>> get notifications => _notifications;
  Trip? get watchedTrip => _watchedTrip;

  // ---------------------------------------------------------------------------
  // Trip-stop awareness for parent tracking
  // ---------------------------------------------------------------------------

  TripStop? myChildStop(String childId) {
    if (_watchedTrip == null) return null;
    return _watchedTrip!.stops
        .where((s) => s.childId == childId)
        .firstOrNull;
  }

  int stopsRemaining(String childId) {
    final stop = myChildStop(childId);
    if (stop == null || _watchedTrip == null) return -1;
    final current = _watchedTrip!.currentStopIndex;
    if (current < 0) return stop.sequence + 1;
    return (stop.sequence - current).clamp(0, _watchedTrip!.stops.length);
  }

  String get currentlyPickingUpName {
    if (_watchedTrip == null) return '';
    final idx = _watchedTrip!.currentStopIndex;
    final stops = _watchedTrip!.stops;
    if (idx < 0 || idx >= stops.length) return '';
    return stops[idx].childName;
  }

  int estimatedMinutesAway({
    required String childId,
    required double busLat,
    required double busLng,
  }) {
    final stop = myChildStop(childId);
    if (stop == null) return -1;
    if (busLat == 0 && busLng == 0) return -1;
    return estimateMinutesBetween(busLat, busLng, stop.lat, stop.lng);
  }

  // ---------------------------------------------------------------------------
  // Trip watching
  // ---------------------------------------------------------------------------

  void watchTrip(String tripId) {
    if (tripId.isEmpty) return;
    _tripSubscription?.cancel();
    _tripSubscription = _tripService.watchTripById(tripId).listen((trip) {
      _watchedTrip = trip;
      notifyListeners();
    });
  }

  void stopWatchingTrip() {
    _tripSubscription?.cancel();
    _tripSubscription = null;
    _watchedTrip = null;
  }

  // ---------------------------------------------------------------------------
  // Children & notifications
  // ---------------------------------------------------------------------------

  Future<void> loadChildren(String parentId) async {
    await _childrenSubscription?.cancel();
    await _notificationsSubscription?.cancel();

    _childrenSubscription = _childService
        .watchChildrenByParentId(parentId)
        .listen((children) {
          _myChildren = children;
          notifyListeners();
        });

    _notificationsSubscription = _notificationService
        .watchNotificationsForParent(parentId)
        .listen((notifications) {
          _notifications = notifications;
          notifyListeners();
        });
  }

  Future<bool> addChild(Child child, {XFile? photo}) {
    return _childService.addChild(child, photo: photo);
  }

  Future<bool> updateChild(Child child, {XFile? photo}) {
    return _childService.updateChild(child, photo: photo);
  }

  Child? getChild(String childId) {
    try {
      return _myChildren.firstWhere((c) => c.id == childId);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _childrenSubscription?.cancel();
    _notificationsSubscription?.cancel();
    _tripSubscription?.cancel();
    super.dispose();
  }
}

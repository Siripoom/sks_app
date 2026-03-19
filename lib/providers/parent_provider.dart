import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sks/models/child.dart';
import 'package:sks/services/child_service.dart';
import 'package:sks/services/notification_service.dart';

class ParentProvider extends ChangeNotifier {
  ParentProvider(this._childService, this._notificationService);

  final IChildService _childService;
  final INotificationService _notificationService;

  List<Child> _myChildren = [];
  List<Map<String, String>> _notifications = [];
  StreamSubscription<List<Child>>? _childrenSubscription;
  StreamSubscription<List<Map<String, String>>>? _notificationsSubscription;

  List<Child> get myChildren => _myChildren;
  List<Map<String, String>> get notifications => _notifications;

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
    super.dispose();
  }
}

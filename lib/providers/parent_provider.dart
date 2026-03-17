import 'package:flutter/material.dart';
import 'package:sks/data/mock_data.dart';
import 'package:sks/models/child.dart';
import 'package:sks/services/child_service.dart';
import 'package:sks/services/notification_service.dart';

class ParentProvider extends ChangeNotifier {
  final IChildService _childService;
  final INotificationService _notificationService;

  List<Child> _myChildren = [];
  List<Map<String, String>> _notifications = [];
  String? _currentParentId;

  List<Child> get myChildren => _myChildren;
  List<Map<String, String>> get notifications => _notifications;

  ParentProvider(this._childService, this._notificationService) {
    _notificationService.addListener(_syncNotifications);
  }

  Future<void> loadChildren(String parentId) async {
    _currentParentId = parentId;
    _myChildren = await _childService.getChildrenByParentId(parentId);
    _syncNotifications();
  }

  void _syncNotifications() {
    if (_currentParentId == null) {
      return;
    }

    _notifications = [
      ...MockData.notificationHistory,
      ..._notificationService.getNotificationsForParent(_currentParentId!),
    ];
    notifyListeners();
  }

  Future<bool> addChild(Child child) async {
    final success = await _childService.addChild(child);
    if (success) {
      _myChildren.add(child);
      notifyListeners();
    }
    return success;
  }

  Future<bool> updateChild(Child child) async {
    final success = await _childService.updateChild(child);
    if (success) {
      final index = _myChildren.indexWhere((c) => c.id == child.id);
      if (index != -1) {
        _myChildren[index] = child;
        notifyListeners();
      }
    }
    return success;
  }

  Child? getChild(String childId) {
    try {
      return _myChildren.firstWhere((c) => c.id == childId);
    } catch (e) {
      return null;
    }
  }

  void addNotification(Map<String, String> notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationService.removeListener(_syncNotifications);
    super.dispose();
  }
}

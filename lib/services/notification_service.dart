import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

abstract class INotificationService {
  Future<void> initialize();
  Future<void> sendArrivalNotification(String childName, String busNumber);
  Future<void> sendBoardingNotification(String childName);
  List<Map<String, String>> getNotificationsForParent(String parentId);
  void addListener(VoidCallback listener);
  void removeListener(VoidCallback listener);
}

class MockNotificationService extends ChangeNotifier
    implements INotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final List<Map<String, String>> _notifications = [];
  bool _initialized = false;
  bool _notificationsAvailable = true;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _flutterLocalNotificationsPlugin.initialize(settings);
    } catch (error, stackTrace) {
      _notificationsAvailable = false;
      debugPrint(
        'MockNotificationService initialization failed: $error\n$stackTrace',
      );
    }

    _initialized = true;
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  String _formattedNow() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showNotification({
    required String title,
    required String body,
    required NotificationDetails details,
  }) async {
    if (!_notificationsAvailable) {
      return;
    }

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().microsecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  @override
  Future<void> sendArrivalNotification(
    String childName,
    String busNumber,
  ) async {
    await _ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      'bus_arrival_channel',
      'แจ้งเตือนรถ',
      channelDescription: 'แจ้งเตือนเมื่อรถถึงโรงเรียน',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final nowLabel = _formattedNow();
    await _showNotification(
      title: '$childName ถึงโรงเรียนแล้ว',
      body: 'รถสาย $busNumber ถึงโรงเรียนแล้ว เวลา $nowLabel',
      details: details,
    );

    _notifications.insert(0, {
      'type': 'arrived',
      'message': '$childName ถึงโรงเรียนแล้ว (รถสาย $busNumber)',
      'time': nowLabel,
    });
    notifyListeners();
  }

  @override
  Future<void> sendBoardingNotification(String childName) async {
    await _ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      'bus_boarding_channel',
      'แจ้งเตือนขึ้นรถ',
      channelDescription: 'แจ้งเตือนเมื่อเด็กขึ้นรถ',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final nowLabel = _formattedNow();
    await _showNotification(
      title: '$childName ขึ้นรถแล้ว',
      body: 'เวลา $nowLabel',
      details: details,
    );

    _notifications.insert(0, {
      'type': 'boarded',
      'message': '$childName ขึ้นรถแล้ว',
      'time': nowLabel,
    });
    notifyListeners();
  }

  @override
  List<Map<String, String>> getNotificationsForParent(String parentId) {
    return List.unmodifiable(_notifications);
  }
}

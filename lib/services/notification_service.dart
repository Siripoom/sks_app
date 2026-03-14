import 'package:flutter_local_notifications/flutter_local_notifications.dart';

abstract class INotificationService {
  Future<void> initialize();
  Future<void> sendArrivalNotification(String childName, String busNumber);
  Future<void> sendBoardingNotification(String childName);
  List<Map<String, String>> getNotificationsForParent(String parentId);
}

class MockNotificationService implements INotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final List<Map<String, String>> _notifications = [];

  @override
  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  @override
  Future<void> sendArrivalNotification(
    String childName,
    String busNumber,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'bus_arrival_channel',
          'บัญชีแจ้งเตือนรถ',
          channelDescription: 'แจ้งเตือนเมื่อรถถึงโรงเรียน',
          importance: Importance.max,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      '$childName ถึงโรงเรียนแล้ว',
      'รถสาย $busNumber ถึงโรงเรียนแล้ว เวลา ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      platformChannelSpecifics,
    );

    _notifications.add({
      'timestamp': DateTime.now().toString(),
      'message': '$childName ถึงโรงเรียนแล้ว (รถสาย $busNumber)',
    });
  }

  @override
  Future<void> sendBoardingNotification(String childName) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'bus_boarding_channel',
          'บัญชีแจ้งเตือนขึ้นรถ',
          channelDescription: 'แจ้งเตือนเมื่อเด็กขึ้นรถ',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      '$childName ขึ้นรถแล้ว',
      'เวลา ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      platformChannelSpecifics,
    );

    _notifications.add({
      'timestamp': DateTime.now().toString(),
      'message': '$childName ขึ้นรถแล้ว',
    });
  }

  @override
  List<Map<String, String>> getNotificationsForParent(String parentId) {
    return List.from(_notifications);
  }
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sks/models/app_notification_record.dart';
import 'package:sks/models/app_user.dart';
import 'package:sks/models/bus.dart';
import 'package:sks/models/child.dart';
import 'package:sks/models/trip.dart';

abstract class INotificationService implements Listenable {
  Future<void> initialize();
  Future<void> registerDeviceForUser(AppUser user);
  Stream<List<Map<String, String>>> watchNotificationsForParent(
    String parentId,
  );
  Stream<List<Map<String, String>>> watchNotificationsForSchool(
    String schoolId,
  );
  Stream<List<Map<String, String>>> watchMessagesForDriver(String driverId);
  Future<void> sendArrivalNotification({
    required Child child,
    required Bus bus,
    required Trip trip,
  });
  Future<void> sendBoardingNotification({
    required Child child,
    required Bus bus,
    required Trip trip,
  });
  Future<void> sendTripStartedNotification({
    required Trip trip,
    required Bus bus,
    required List<Child> children,
  });
  Future<void> sendApproachingNotification({
    required Child child,
    required Bus bus,
    required Trip trip,
    required int minutesAway,
  });
  Future<void> sendChildSkippedNotification({
    required Child child,
    required Bus bus,
    required Trip trip,
  });
}

class FirebaseNotificationService extends ChangeNotifier
    implements INotificationService {
  FirebaseNotificationService(this._firestore, this._messaging);

  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSubscription;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

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
    await _localNotifications.initialize(settings);

    if (!kIsWeb) {
      await _messaging.requestPermission();
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    FirebaseMessaging.onMessage.listen((message) async {
      final notification = message.notification;
      if (notification == null) {
        return;
      }

      await _showLocalNotification(
        title: notification.title ?? '',
        body: notification.body ?? '',
      );
    });

    _initialized = true;
  }

  @override
  Future<void> registerDeviceForUser(AppUser user) async {
    await initialize();

    String? token;
    try {
      token = await _messaging.getToken();
    } catch (_) {
      token = null;
    }

    if (token != null && token.isNotEmpty) {
      await _saveToken(user, token);
    }

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      (newToken) => _saveToken(user, newToken),
    );
  }

  @override
  Stream<List<Map<String, String>>> watchNotificationsForParent(
    String parentId,
  ) {
    return _notifications
        .where('targetParentId', isEqualTo: parentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapRecords);
  }

  @override
  Stream<List<Map<String, String>>> watchNotificationsForSchool(
    String schoolId,
  ) {
    return _notifications
        .where('schoolId', isEqualTo: schoolId)
        .where('targetRole', isEqualTo: 'teacher')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapRecords);
  }

  @override
  Stream<List<Map<String, String>>> watchMessagesForDriver(String driverId) {
    return _notifications
        .where('targetDriverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapRecords);
  }

  @override
  Future<void> sendArrivalNotification({
    required Child child,
    required Bus bus,
    required Trip trip,
  }) async {
    final now = DateTime.now();
    final time = _timeLabel(now);
    final isToHome = trip.round == TripRound.toHome;
    final parentMessage = isToHome
        ? '${child.name} ถึงบ้านแล้ว (${bus.busNumber})'
        : '${child.name} ถึงโรงเรียนแล้ว (${bus.busNumber})';
    final teacherMessage = isToHome
        ? '${child.name} ถึงบ้านแล้วด้วยรถ ${bus.busNumber}'
        : '${child.name} มาถึงโรงเรียนด้วยรถ ${bus.busNumber} แล้ว';

    await Future.wait([
      _createRecord(
        AppNotificationRecord(
          id: '',
          type: 'arrived',
          message: parentMessage,
          sender: 'ระบบ',
          createdAt: now,
          time: time,
          targetParentId: child.parentId,
          targetRole: 'parent',
          schoolId: trip.schoolId,
        ),
      ),
      _createRecord(
        AppNotificationRecord(
          id: '',
          type: 'arrived',
          message: teacherMessage,
          sender: 'ระบบ',
          createdAt: now,
          time: time,
          schoolId: trip.schoolId,
          targetRole: 'teacher',
        ),
      ),
    ]);

    await _showLocalNotification(
      title: isToHome
          ? '${child.name} ถึงบ้านแล้ว'
          : '${child.name} ถึงโรงเรียนแล้ว',
      body: isToHome
          ? 'รถ ${bus.busNumber} ส่งถึงบ้านเวลา $time'
          : 'รถ ${bus.busNumber} ถึงโรงเรียนเวลา $time',
    );
    notifyListeners();
  }

  @override
  Future<void> sendBoardingNotification({
    required Child child,
    required Bus bus,
    required Trip trip,
  }) async {
    final now = DateTime.now();
    final time = _timeLabel(now);
    final isToHome = trip.round == TripRound.toHome;
    final parentMessage = isToHome
        ? '${child.name} ลงรถแล้ว (ถึงบ้านแล้ว)'
        : '${child.name} ขึ้นรถแล้ว';
    final teacherMessage = isToHome
        ? '${child.name} ลงรถ ${bus.busNumber} แล้ว (ส่งถึงบ้าน)'
        : '${child.name} เช็กอินขึ้นรถ ${bus.busNumber} แล้ว';

    await Future.wait([
      _createRecord(
        AppNotificationRecord(
          id: '',
          type: 'boarded',
          message: parentMessage,
          sender: 'ระบบ',
          createdAt: now,
          time: time,
          targetParentId: child.parentId,
          targetRole: 'parent',
          schoolId: trip.schoolId,
        ),
      ),
      _createRecord(
        AppNotificationRecord(
          id: '',
          type: 'boarded',
          message: teacherMessage,
          sender: 'ระบบ',
          createdAt: now,
          time: time,
          schoolId: trip.schoolId,
          targetRole: 'teacher',
        ),
      ),
    ]);

    await _showLocalNotification(
      title: isToHome
          ? '${child.name} ลงรถแล้ว'
          : '${child.name} ขึ้นรถแล้ว',
      body: 'เวลา $time',
    );
    notifyListeners();
  }

  @override
  Future<void> sendTripStartedNotification({
    required Trip trip,
    required Bus bus,
    required List<Child> children,
  }) async {
    final now = DateTime.now();
    final time = _timeLabel(now);

    final futures = <Future<void>>[];
    for (final child in children) {
      futures.add(
        _createRecord(
          AppNotificationRecord(
            id: '',
            type: 'trip_started',
            message: 'รถสาย ${bus.busNumber} เริ่มออกเดินทางแล้ว',
            sender: 'ระบบ',
            createdAt: now,
            time: time,
            targetParentId: child.parentId,
            targetRole: 'parent',
            schoolId: trip.schoolId,
          ),
        ),
      );
    }
    await Future.wait(futures);

    await _showLocalNotification(
      title: 'รถออกเดินทาง',
      body: 'รถสาย ${bus.busNumber} เริ่มออกเดินทางเวลา $time',
    );
    notifyListeners();
  }

  @override
  Future<void> sendApproachingNotification({
    required Child child,
    required Bus bus,
    required Trip trip,
    required int minutesAway,
  }) async {
    final now = DateTime.now();
    final time = _timeLabel(now);

    final isToHome = trip.round == TripRound.toHome;
    final stopLabel = isToHome ? 'จุดส่ง' : 'จุดรับ';

    await _createRecord(
      AppNotificationRecord(
        id: '',
        type: 'bus_approaching',
        message: 'รถสาย ${bus.busNumber} กำลังจะถึง$stopLabel ${child.name} ใน ~$minutesAway นาที',
        sender: 'ระบบ',
        createdAt: now,
        time: time,
        targetParentId: child.parentId,
        targetRole: 'parent',
        schoolId: trip.schoolId,
      ),
    );

    await _showLocalNotification(
      title: 'รถใกล้ถึงแล้ว',
      body: 'รถสาย ${bus.busNumber} จะถึง$stopLabel ${child.name} ใน ~$minutesAway นาที',
    );
    notifyListeners();
  }

  @override
  Future<void> sendChildSkippedNotification({
    required Child child,
    required Bus bus,
    required Trip trip,
  }) async {
    final now = DateTime.now();
    final time = _timeLabel(now);

    final isToHome = trip.round == TripRound.toHome;

    await _createRecord(
      AppNotificationRecord(
        id: '',
        type: 'child_skipped',
        message: isToHome
            ? '${child.name} ข้ามจุดส่ง รถสาย ${bus.busNumber} ข้ามจุดนี้'
            : '${child.name} ไม่อยู่ที่จุดรับ รถสาย ${bus.busNumber} ข้ามจุดนี้',
        sender: 'ระบบ',
        createdAt: now,
        time: time,
        targetParentId: child.parentId,
        targetRole: 'parent',
        schoolId: trip.schoolId,
      ),
    );

    await _showLocalNotification(
      title: isToHome ? 'ข้ามจุดส่ง' : 'ข้ามจุดรับ',
      body: isToHome
          ? '${child.name} ข้ามจุดส่ง'
          : '${child.name} ไม่อยู่ที่จุดรับ',
    );
    notifyListeners();
  }

  Future<void> _saveToken(AppUser user, String token) async {
    await _firestore
        .collection('app_users')
        .doc(user.id)
        .collection('device_tokens')
        .doc(token)
        .set({
          'token': token,
          'platform': defaultTargetPlatform.name,
          'updatedAt': DateTime.now(),
        });
  }

  Future<void> _createRecord(AppNotificationRecord record) async {
    await _notifications.add(record.toMap());
  }

  List<Map<String, String>> _mapRecords(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map((doc) => AppNotificationRecord.fromMap(doc.id, doc.data()))
        .map((record) => record.toDisplayMap())
        .toList();
  }

  String _timeLabel(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const android = AndroidNotificationDetails(
      'sks_notifications',
      'SmartKids Notifications',
      channelDescription: 'General SmartKids notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: android, iOS: ios);

    await _localNotifications.show(
      DateTime.now().microsecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  @override
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    super.dispose();
  }
}

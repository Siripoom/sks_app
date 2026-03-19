import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotificationRecord {
  final String id;
  final String type;
  final String message;
  final String sender;
  final DateTime createdAt;
  final String time;
  final String? targetParentId;
  final String? targetDriverId;
  final String? schoolId;
  final String? targetRole;

  const AppNotificationRecord({
    required this.id,
    required this.type,
    required this.message,
    required this.sender,
    required this.createdAt,
    required this.time,
    this.targetParentId,
    this.targetDriverId,
    this.schoolId,
    this.targetRole,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'message': message,
      'sender': sender,
      'createdAt': createdAt,
      'time': time,
      'targetParentId': targetParentId,
      'targetDriverId': targetDriverId,
      'schoolId': schoolId,
      'targetRole': targetRole,
    };
  }

  Map<String, String> toDisplayMap() {
    return {'type': type, 'message': message, 'time': time, 'sender': sender};
  }

  factory AppNotificationRecord.fromMap(String id, Map<String, dynamic> map) {
    return AppNotificationRecord(
      id: id,
      type: map['type'] as String? ?? '',
      message: map['message'] as String? ?? '',
      sender: map['sender'] as String? ?? '',
      createdAt: _dateTimeFromMap(map['createdAt']) ?? DateTime.now(),
      time: map['time'] as String? ?? '',
      targetParentId: map['targetParentId'] as String?,
      targetDriverId: map['targetDriverId'] as String?,
      schoolId: map['schoolId'] as String?,
      targetRole: map['targetRole'] as String?,
    );
  }

  static DateTime? _dateTimeFromMap(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

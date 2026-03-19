import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProfile {
  final String id;
  final String name;
  final String schoolId;
  final bool isArchived;
  final DateTime? archivedAt;

  const AdminProfile({
    required this.id,
    required this.name,
    required this.schoolId,
    this.isArchived = false,
    this.archivedAt,
  });

  AdminProfile copyWith({
    String? id,
    String? name,
    String? schoolId,
    bool? isArchived,
    DateTime? archivedAt,
  }) {
    return AdminProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      schoolId: schoolId ?? this.schoolId,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'schoolId': schoolId,
      'isArchived': isArchived,
      'archivedAt': archivedAt,
    };
  }

  factory AdminProfile.fromMap(String id, Map<String, dynamic> map) {
    return AdminProfile(
      id: id,
      name: map['name'] as String? ?? '',
      schoolId: map['schoolId'] as String? ?? '',
      isArchived: map['isArchived'] as bool? ?? false,
      archivedAt: _dateTimeFromMap(map['archivedAt']),
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

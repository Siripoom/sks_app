import 'package:cloud_firestore/cloud_firestore.dart';

class Driver {
  final String id;
  final String name;
  final String phone;
  final String busId;
  final String licenseNumber;
  final String schoolId;
  final bool isArchived;
  final DateTime? archivedAt;

  const Driver({
    required this.id,
    required this.name,
    required this.phone,
    this.busId = '',
    required this.licenseNumber,
    this.schoolId = '',
    this.isArchived = false,
    this.archivedAt,
  });

  Driver copyWith({
    String? id,
    String? name,
    String? phone,
    String? busId,
    String? licenseNumber,
    String? schoolId,
    bool? isArchived,
    DateTime? archivedAt,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      busId: busId ?? this.busId,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      schoolId: schoolId ?? this.schoolId,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'busId': busId,
      'licenseNumber': licenseNumber,
      'schoolId': schoolId,
      'isArchived': isArchived,
      'archivedAt': archivedAt,
    };
  }

  factory Driver.fromMap(String id, Map<String, dynamic> map) {
    return Driver(
      id: id,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      busId: map['busId'] as String? ?? '',
      licenseNumber: map['licenseNumber'] as String? ?? '',
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

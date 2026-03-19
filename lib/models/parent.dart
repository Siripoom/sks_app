import 'package:cloud_firestore/cloud_firestore.dart';

class Parent {
  final String id;
  final String name;
  final String phone;
  final List<String> childIds;
  final List<String> schoolIds;
  final bool isArchived;
  final DateTime? archivedAt;

  const Parent({
    required this.id,
    required this.name,
    required this.phone,
    required this.childIds,
    this.schoolIds = const [],
    this.isArchived = false,
    this.archivedAt,
  });

  Parent copyWith({
    String? id,
    String? name,
    String? phone,
    List<String>? childIds,
    List<String>? schoolIds,
    bool? isArchived,
    DateTime? archivedAt,
  }) {
    return Parent(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      childIds: childIds ?? this.childIds,
      schoolIds: schoolIds ?? this.schoolIds,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  String get primarySchoolId => schoolIds.isEmpty ? '' : schoolIds.first;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'childIds': childIds,
      'schoolIds': schoolIds,
      'isArchived': isArchived,
      'archivedAt': archivedAt,
    };
  }

  factory Parent.fromMap(String id, Map<String, dynamic> map) {
    return Parent(
      id: id,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      childIds: List<String>.from(map['childIds'] as List? ?? const []),
      schoolIds: _schoolIdsFromMap(map),
      isArchived: map['isArchived'] as bool? ?? false,
      archivedAt: _dateTimeFromMap(map['archivedAt']),
    );
  }

  static List<String> _schoolIdsFromMap(Map<String, dynamic> map) {
    final schoolIds = List<String>.from(map['schoolIds'] as List? ?? const []);
    if (schoolIds.isNotEmpty) {
      return schoolIds;
    }
    final legacySchoolId = map['schoolId'] as String? ?? '';
    return legacySchoolId.isEmpty ? const [] : [legacySchoolId];
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

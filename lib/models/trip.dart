import 'package:cloud_firestore/cloud_firestore.dart';

enum TripRound { toSchool, toHome }

extension TripRoundX on TripRound {
  String get value => switch (this) {
    TripRound.toSchool => 'toSchool',
    TripRound.toHome => 'toHome',
  };

  static TripRound fromValue(String value) => switch (value) {
    'toHome' => TripRound.toHome,
    _ => TripRound.toSchool,
  };
}

enum TripStatus { draft, active, completed, cancelled }

extension TripStatusX on TripStatus {
  String get value => switch (this) {
    TripStatus.draft => 'draft',
    TripStatus.active => 'active',
    TripStatus.completed => 'completed',
    TripStatus.cancelled => 'cancelled',
  };

  static TripStatus fromValue(String value) => switch (value) {
    'active' => TripStatus.active,
    'completed' => TripStatus.completed,
    'cancelled' => TripStatus.cancelled,
    _ => TripStatus.draft,
  };
}

class Trip {
  final String id;
  final String schoolId;
  final String busId;
  final DateTime serviceDate;
  final TripRound round;
  final DateTime? scheduledStartAt;
  final List<String> childIds;
  final TripStatus status;
  final bool isArchived;
  final DateTime? archivedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Trip({
    required this.id,
    required this.schoolId,
    required this.busId,
    required this.serviceDate,
    required this.round,
    this.scheduledStartAt,
    required this.childIds,
    this.status = TripStatus.draft,
    this.isArchived = false,
    this.archivedAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get isOpen =>
      !isArchived &&
      status != TripStatus.completed &&
      status != TripStatus.cancelled;

  Trip copyWith({
    String? id,
    String? schoolId,
    String? busId,
    DateTime? serviceDate,
    TripRound? round,
    DateTime? scheduledStartAt,
    bool clearScheduledStartAt = false,
    List<String>? childIds,
    TripStatus? status,
    bool? isArchived,
    DateTime? archivedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Trip(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      busId: busId ?? this.busId,
      serviceDate: serviceDate ?? this.serviceDate,
      round: round ?? this.round,
      scheduledStartAt: clearScheduledStartAt
          ? null
          : (scheduledStartAt ?? this.scheduledStartAt),
      childIds: childIds ?? this.childIds,
      status: status ?? this.status,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'busId': busId,
      'serviceDate': serviceDate,
      'round': round.value,
      'scheduledStartAt': scheduledStartAt,
      'childIds': childIds,
      'status': status.value,
      'isArchived': isArchived,
      'archivedAt': archivedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Trip.fromMap(String id, Map<String, dynamic> map) {
    return Trip(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      busId: map['busId'] as String? ?? '',
      serviceDate:
          _dateTimeFromMap(map['serviceDate']) ?? DateTime.now(),
      round: TripRoundX.fromValue(map['round'] as String? ?? 'toSchool'),
      scheduledStartAt: _dateTimeFromMap(map['scheduledStartAt']),
      childIds: List<String>.from(map['childIds'] as List? ?? const []),
      status: TripStatusX.fromValue(map['status'] as String? ?? 'draft'),
      isArchived: map['isArchived'] as bool? ?? false,
      archivedAt: _dateTimeFromMap(map['archivedAt']),
      createdAt: _dateTimeFromMap(map['createdAt']),
      updatedAt: _dateTimeFromMap(map['updatedAt']),
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

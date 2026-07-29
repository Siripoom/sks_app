import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sks/models/trip_stop.dart';

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
  @Deprecated('Use schoolIds')
  final String schoolId;
  final List<String> schoolIds;
  final String busId;
  final DateTime serviceDate;
  final TripRound round;
  final DateTime? scheduledStartAt;
  final List<String> childIds;
  final List<TripStop> stops;
  final int currentStopIndex;
  final TripStatus status;
  final bool isArchived;
  final DateTime? archivedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int routeVersion;
  final Map<String, dynamic>? origin;
  final Map<String, dynamic>? routePlan;

  const Trip({
    required this.id,
    this.schoolId = '',
    this.schoolIds = const [],
    required this.busId,
    required this.serviceDate,
    required this.round,
    this.scheduledStartAt,
    required this.childIds,
    this.stops = const [],
    this.currentStopIndex = -1,
    this.status = TripStatus.draft,
    this.isArchived = false,
    this.archivedAt,
    this.startedAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
    this.routeVersion = 1,
    this.origin,
    this.routePlan,
  });

  List<String> get effectiveSchoolIds => schoolIds.isNotEmpty
      ? schoolIds
      : (schoolId.isEmpty ? const [] : [schoolId]);

  bool get isOpen =>
      !isArchived &&
      status != TripStatus.completed &&
      status != TripStatus.cancelled;

  Trip copyWith({
    String? id,
    String? schoolId,
    List<String>? schoolIds,
    String? busId,
    DateTime? serviceDate,
    TripRound? round,
    DateTime? scheduledStartAt,
    bool clearScheduledStartAt = false,
    List<String>? childIds,
    List<TripStop>? stops,
    int? currentStopIndex,
    TripStatus? status,
    bool? isArchived,
    DateTime? archivedAt,
    DateTime? startedAt,
    bool clearStartedAt = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? routeVersion,
    Map<String, dynamic>? origin,
    Map<String, dynamic>? routePlan,
  }) {
    return Trip(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      schoolIds: schoolIds ?? this.schoolIds,
      busId: busId ?? this.busId,
      serviceDate: serviceDate ?? this.serviceDate,
      round: round ?? this.round,
      scheduledStartAt: clearScheduledStartAt
          ? null
          : (scheduledStartAt ?? this.scheduledStartAt),
      childIds: childIds ?? this.childIds,
      stops: stops ?? this.stops,
      currentStopIndex: currentStopIndex ?? this.currentStopIndex,
      status: status ?? this.status,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      routeVersion: routeVersion ?? this.routeVersion,
      origin: origin ?? this.origin,
      routePlan: routePlan ?? this.routePlan,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolIds': effectiveSchoolIds,
      'busId': busId,
      'serviceDate': serviceDate,
      'round': round.value,
      'scheduledStartAt': scheduledStartAt,
      'childIds': childIds,
      'stops': stops.map((s) => s.toMap()).toList(),
      'currentStopIndex': currentStopIndex,
      'status': status.value,
      'isArchived': isArchived,
      'archivedAt': archivedAt,
      'startedAt': startedAt,
      'completedAt': completedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'routeVersion': routeVersion,
      'origin': origin,
      'routePlan': routePlan,
    };
  }

  factory Trip.fromMap(String id, Map<String, dynamic> map) {
    return Trip(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      schoolIds: _schoolIdsFromMap(map),
      busId: map['busId'] as String? ?? '',
      serviceDate: _dateTimeFromMap(map['serviceDate']) ?? DateTime.now(),
      round: TripRoundX.fromValue(map['round'] as String? ?? 'toSchool'),
      scheduledStartAt: _dateTimeFromMap(map['scheduledStartAt']),
      childIds: List<String>.from(map['childIds'] as List? ?? const []),
      stops: (map['stops'] as List? ?? const [])
          .map((s) => TripStop.fromMap(Map<String, dynamic>.from(s as Map)))
          .toList(),
      currentStopIndex: map['currentStopIndex'] as int? ?? -1,
      status: TripStatusX.fromValue(map['status'] as String? ?? 'draft'),
      isArchived: map['isArchived'] as bool? ?? false,
      archivedAt: _dateTimeFromMap(map['archivedAt']),
      startedAt: _dateTimeFromMap(map['startedAt']),
      completedAt: _dateTimeFromMap(map['completedAt']),
      createdAt: _dateTimeFromMap(map['createdAt']),
      updatedAt: _dateTimeFromMap(map['updatedAt']),
      routeVersion: map['routeVersion'] as int? ?? 1,
      origin: map['origin'] is Map
          ? Map<String, dynamic>.from(map['origin'] as Map)
          : null,
      routePlan: map['routePlan'] is Map
          ? Map<String, dynamic>.from(map['routePlan'] as Map)
          : null,
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

  static List<String> _schoolIdsFromMap(Map<String, dynamic> map) {
    final values = List<String>.from(map['schoolIds'] as List? ?? const []);
    if (values.isNotEmpty) return values;
    final legacy = map['schoolId'] as String? ?? '';
    return legacy.isEmpty ? const [] : [legacy];
  }
}

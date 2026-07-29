import 'package:cloud_firestore/cloud_firestore.dart';

enum TripStopStatus { pending, approaching, arrived, pickedUp, skipped }

extension TripStopStatusX on TripStopStatus {
  String get value => switch (this) {
    TripStopStatus.pending => 'pending',
    TripStopStatus.approaching => 'approaching',
    TripStopStatus.arrived => 'arrived',
    TripStopStatus.pickedUp => 'pickedUp',
    TripStopStatus.skipped => 'skipped',
  };

  static TripStopStatus fromValue(String value) => switch (value) {
    'approaching' => TripStopStatus.approaching,
    'arrived' => TripStopStatus.arrived,
    'pickedUp' => TripStopStatus.pickedUp,
    'skipped' => TripStopStatus.skipped,
    _ => TripStopStatus.pending,
  };
}

class TripStop {
  final String id;
  final String type;
  final String action;
  final String childId;
  final List<String> childIds;
  final List<String> childNames;
  final String schoolId;
  final List<String> schoolIds;
  final int sequence;
  final double lat;
  final double lng;
  final String pickupLabel;
  final String childName;
  final TripStopStatus status;
  final DateTime? arrivedAt;
  final DateTime? pickedUpAt;
  final DateTime? completedAt;

  const TripStop({
    this.id = '',
    this.type = 'home',
    this.action = 'pickup',
    this.childId = '',
    this.childIds = const [],
    this.childNames = const [],
    this.schoolId = '',
    this.schoolIds = const [],
    required this.sequence,
    required this.lat,
    required this.lng,
    this.pickupLabel = '',
    this.childName = '',
    this.status = TripStopStatus.pending,
    this.arrivedAt,
    this.pickedUpAt,
    this.completedAt,
  });

  List<String> get effectiveChildIds =>
      childIds.isNotEmpty ? childIds : (childId.isEmpty ? const [] : [childId]);

  bool get isDone =>
      status == TripStopStatus.pickedUp || status == TripStopStatus.skipped;

  TripStop copyWith({
    String? childId,
    String? id,
    String? type,
    String? action,
    List<String>? childIds,
    List<String>? childNames,
    String? schoolId,
    List<String>? schoolIds,
    int? sequence,
    double? lat,
    double? lng,
    String? pickupLabel,
    String? childName,
    TripStopStatus? status,
    DateTime? arrivedAt,
    bool clearArrivedAt = false,
    DateTime? pickedUpAt,
    bool clearPickedUpAt = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return TripStop(
      id: id ?? this.id,
      type: type ?? this.type,
      action: action ?? this.action,
      childId: childId ?? this.childId,
      childIds: childIds ?? this.childIds,
      childNames: childNames ?? this.childNames,
      schoolId: schoolId ?? this.schoolId,
      schoolIds: schoolIds ?? this.schoolIds,
      sequence: sequence ?? this.sequence,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      pickupLabel: pickupLabel ?? this.pickupLabel,
      childName: childName ?? this.childName,
      status: status ?? this.status,
      arrivedAt: clearArrivedAt ? null : (arrivedAt ?? this.arrivedAt),
      pickedUpAt: clearPickedUpAt ? null : (pickedUpAt ?? this.pickedUpAt),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'action': action,
      'childId': childId,
      'childIds': effectiveChildIds,
      'childNames': childNames,
      'schoolId': schoolId,
      'schoolIds': schoolIds,
      'sequence': sequence,
      'lat': lat,
      'lng': lng,
      'pickupLabel': pickupLabel,
      'childName': childName,
      'status': status.value,
      'arrivedAt': arrivedAt,
      'pickedUpAt': pickedUpAt,
      'completedAt': completedAt,
    };
  }

  factory TripStop.fromMap(Map<String, dynamic> map) {
    return TripStop(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? 'home',
      action: map['action'] as String? ?? 'pickup',
      childId: map['childId'] as String? ?? '',
      childIds: _childIdsFromMap(map),
      childNames: List<String>.from(map['childNames'] as List? ?? const []),
      schoolId: map['schoolId'] as String? ?? '',
      schoolIds: List<String>.from(map['schoolIds'] as List? ?? const []),
      sequence: map['sequence'] as int? ?? 0,
      lat: _toDouble(map['lat']),
      lng: _toDouble(map['lng']),
      pickupLabel: map['pickupLabel'] as String? ?? '',
      childName: map['childName'] as String? ?? '',
      status: TripStopStatusX.fromValue(map['status'] as String? ?? 'pending'),
      arrivedAt: _dateTimeFromMap(map['arrivedAt']),
      pickedUpAt: _dateTimeFromMap(map['pickedUpAt']),
      completedAt: _dateTimeFromMap(map['completedAt']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _dateTimeFromMap(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  static List<String> _childIdsFromMap(Map<String, dynamic> map) {
    final values = List<String>.from(map['childIds'] as List? ?? const []);
    if (values.isNotEmpty) return values;
    final legacy = map['childId'] as String? ?? '';
    return legacy.isEmpty ? const [] : [legacy];
  }
}

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
  final String childId;
  final int sequence;
  final double lat;
  final double lng;
  final String pickupLabel;
  final String childName;
  final TripStopStatus status;
  final DateTime? arrivedAt;
  final DateTime? pickedUpAt;

  const TripStop({
    required this.childId,
    required this.sequence,
    required this.lat,
    required this.lng,
    this.pickupLabel = '',
    this.childName = '',
    this.status = TripStopStatus.pending,
    this.arrivedAt,
    this.pickedUpAt,
  });

  bool get isDone =>
      status == TripStopStatus.pickedUp || status == TripStopStatus.skipped;

  TripStop copyWith({
    String? childId,
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
  }) {
    return TripStop(
      childId: childId ?? this.childId,
      sequence: sequence ?? this.sequence,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      pickupLabel: pickupLabel ?? this.pickupLabel,
      childName: childName ?? this.childName,
      status: status ?? this.status,
      arrivedAt: clearArrivedAt ? null : (arrivedAt ?? this.arrivedAt),
      pickedUpAt: clearPickedUpAt ? null : (pickedUpAt ?? this.pickedUpAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'childId': childId,
      'sequence': sequence,
      'lat': lat,
      'lng': lng,
      'pickupLabel': pickupLabel,
      'childName': childName,
      'status': status.value,
      'arrivedAt': arrivedAt,
      'pickedUpAt': pickedUpAt,
    };
  }

  factory TripStop.fromMap(Map<String, dynamic> map) {
    return TripStop(
      childId: map['childId'] as String? ?? '',
      sequence: map['sequence'] as int? ?? 0,
      lat: (map['lat'] as num?)?.toDouble() ?? 0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0,
      pickupLabel: map['pickupLabel'] as String? ?? '',
      childName: map['childName'] as String? ?? '',
      status: TripStopStatusX.fromValue(map['status'] as String? ?? 'pending'),
      arrivedAt: _dateTimeFromMap(map['arrivedAt']),
      pickedUpAt: _dateTimeFromMap(map['pickedUpAt']),
    );
  }

  static DateTime? _dateTimeFromMap(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}

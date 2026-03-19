import 'package:cloud_firestore/cloud_firestore.dart';

class School {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String address;
  final String morningPickup;
  final String morningDropoff;
  final String eveningPickup;
  final String eveningDropoff;
  final bool isArchived;
  final DateTime? archivedAt;

  const School({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.address,
    this.morningPickup = '',
    this.morningDropoff = '',
    this.eveningPickup = '',
    this.eveningDropoff = '',
    this.isArchived = false,
    this.archivedAt,
  });

  School copyWith({
    String? id,
    String? name,
    double? lat,
    double? lng,
    String? address,
    String? morningPickup,
    String? morningDropoff,
    String? eveningPickup,
    String? eveningDropoff,
    bool? isArchived,
    DateTime? archivedAt,
  }) {
    return School(
      id: id ?? this.id,
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
      morningPickup: morningPickup ?? this.morningPickup,
      morningDropoff: morningDropoff ?? this.morningDropoff,
      eveningPickup: eveningPickup ?? this.eveningPickup,
      eveningDropoff: eveningDropoff ?? this.eveningDropoff,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lat': lat,
      'lng': lng,
      'address': address,
      'morningPickup': morningPickup,
      'morningDropoff': morningDropoff,
      'eveningPickup': eveningPickup,
      'eveningDropoff': eveningDropoff,
      'isArchived': isArchived,
      'archivedAt': archivedAt,
    };
  }

  factory School.fromMap(String id, Map<String, dynamic> map) {
    return School(
      id: id,
      name: map['name'] as String? ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0,
      address: map['address'] as String? ?? '',
      morningPickup: map['morningPickup'] as String? ?? '',
      morningDropoff: map['morningDropoff'] as String? ?? '',
      eveningPickup: map['eveningPickup'] as String? ?? '',
      eveningDropoff: map['eveningDropoff'] as String? ?? '',
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

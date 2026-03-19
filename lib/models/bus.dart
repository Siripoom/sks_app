import 'package:cloud_firestore/cloud_firestore.dart';

enum BusStatus { waiting, enRoute, arrived }

extension BusStatusX on BusStatus {
  String get value => switch (this) {
    BusStatus.waiting => 'waiting',
    BusStatus.enRoute => 'enRoute',
    BusStatus.arrived => 'arrived',
  };

  static BusStatus fromValue(String value) => switch (value) {
    'enRoute' => BusStatus.enRoute,
    'arrived' => BusStatus.arrived,
    _ => BusStatus.waiting,
  };
}

class Bus {
  final String id;
  final String busNumber;
  final String driverId;
  final String schoolId;
  final List<String> childIds;
  final String licensePlate;
  final bool isArchived;
  final DateTime? archivedAt;
  BusStatus status;
  double currentLat;
  double currentLng;
  DateTime? estimatedArrival;

  Bus({
    required this.id,
    required this.busNumber,
    this.driverId = '',
    required this.schoolId,
    required this.childIds,
    this.licensePlate = '',
    this.isArchived = false,
    this.archivedAt,
    this.status = BusStatus.waiting,
    required this.currentLat,
    required this.currentLng,
    this.estimatedArrival,
  });

  Bus copyWith({
    String? id,
    String? busNumber,
    String? driverId,
    String? schoolId,
    List<String>? childIds,
    String? licensePlate,
    bool? isArchived,
    DateTime? archivedAt,
    BusStatus? status,
    double? currentLat,
    double? currentLng,
    DateTime? estimatedArrival,
  }) {
    return Bus(
      id: id ?? this.id,
      busNumber: busNumber ?? this.busNumber,
      driverId: driverId ?? this.driverId,
      schoolId: schoolId ?? this.schoolId,
      childIds: childIds ?? this.childIds,
      licensePlate: licensePlate ?? this.licensePlate,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      status: status ?? this.status,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'busNumber': busNumber,
      'driverId': driverId,
      'schoolId': schoolId,
      'childIds': childIds,
      'licensePlate': licensePlate,
      'isArchived': isArchived,
      'archivedAt': archivedAt,
      'status': status.value,
      'currentLat': currentLat,
      'currentLng': currentLng,
      'estimatedArrival': estimatedArrival,
    };
  }

  factory Bus.fromMap(String id, Map<String, dynamic> map) {
    return Bus(
      id: id,
      busNumber: map['busNumber'] as String? ?? '',
      driverId: map['driverId'] as String? ?? '',
      schoolId: map['schoolId'] as String? ?? '',
      childIds: List<String>.from(map['childIds'] as List? ?? const []),
      licensePlate: map['licensePlate'] as String? ?? '',
      isArchived: map['isArchived'] as bool? ?? false,
      archivedAt: _dateTimeFromMap(map['archivedAt']),
      status: BusStatusX.fromValue(map['status'] as String? ?? 'waiting'),
      currentLat: (map['currentLat'] as num?)?.toDouble() ?? 0,
      currentLng: (map['currentLng'] as num?)?.toDouble() ?? 0,
      estimatedArrival: _dateTimeFromMap(map['estimatedArrival']),
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

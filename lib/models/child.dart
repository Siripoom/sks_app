import 'package:cloud_firestore/cloud_firestore.dart';

enum ChildAssignmentStatus { pending, assigned }

extension ChildAssignmentStatusX on ChildAssignmentStatus {
  String get value => switch (this) {
    ChildAssignmentStatus.pending => 'pending',
    ChildAssignmentStatus.assigned => 'assigned',
  };

  static ChildAssignmentStatus fromValue(String value) => switch (value) {
    'assigned' => ChildAssignmentStatus.assigned,
    _ => ChildAssignmentStatus.pending,
  };
}

class Child {
  final String id;
  final String name;
  final String parentId;
  final String? tripId;
  final String? busId;
  final String schoolId;
  final String homeAddress;
  final String pickupLabel;
  final double? pickupLat;
  final double? pickupLng;
  final String qrCodeValue;
  final String photoUrl;
  final String schoolName;
  final String gradeLevel;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final ChildAssignmentStatus assignmentStatus;
  final bool isArchived;
  final DateTime? archivedAt;
  bool hasBoarded;
  bool hasArrived;

  Child({
    required this.id,
    required this.name,
    required this.parentId,
    this.tripId,
    required this.busId,
    required this.homeAddress,
    required this.pickupLabel,
    required this.qrCodeValue,
    required this.schoolId,
    this.pickupLat,
    this.pickupLng,
    this.photoUrl = '',
    this.schoolName = '',
    this.gradeLevel = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.assignmentStatus = ChildAssignmentStatus.assigned,
    this.isArchived = false,
    this.archivedAt,
    this.hasBoarded = false,
    this.hasArrived = false,
  });

  bool get isAssigned =>
      assignmentStatus == ChildAssignmentStatus.assigned &&
      ((tripId != null && tripId!.isNotEmpty) || busId != null);

  Child copyWith({
    String? id,
    String? name,
    String? parentId,
    String? tripId,
    bool clearTripId = false,
    String? busId,
    bool clearBusId = false,
    String? schoolId,
    String? homeAddress,
    String? pickupLabel,
    double? pickupLat,
    bool clearPickupLat = false,
    double? pickupLng,
    bool clearPickupLng = false,
    String? qrCodeValue,
    String? photoUrl,
    String? schoolName,
    String? gradeLevel,
    String? emergencyContactName,
    String? emergencyContactPhone,
    ChildAssignmentStatus? assignmentStatus,
    bool? isArchived,
    DateTime? archivedAt,
    bool? hasBoarded,
    bool? hasArrived,
  }) {
    return Child(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      tripId: clearTripId ? null : (tripId ?? this.tripId),
      busId: clearBusId ? null : (busId ?? this.busId),
      schoolId: schoolId ?? this.schoolId,
      homeAddress: homeAddress ?? this.homeAddress,
      pickupLabel: pickupLabel ?? this.pickupLabel,
      pickupLat: clearPickupLat ? null : (pickupLat ?? this.pickupLat),
      pickupLng: clearPickupLng ? null : (pickupLng ?? this.pickupLng),
      qrCodeValue: qrCodeValue ?? this.qrCodeValue,
      photoUrl: photoUrl ?? this.photoUrl,
      schoolName: schoolName ?? this.schoolName,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      assignmentStatus: assignmentStatus ?? this.assignmentStatus,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      hasBoarded: hasBoarded ?? this.hasBoarded,
      hasArrived: hasArrived ?? this.hasArrived,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'parentId': parentId,
      'tripId': tripId,
      'busId': busId,
      'schoolId': schoolId,
      'homeAddress': homeAddress,
      'pickupLabel': pickupLabel,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'qrCodeValue': qrCodeValue,
      'photoUrl': photoUrl,
      'schoolName': schoolName,
      'gradeLevel': gradeLevel,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'assignmentStatus': assignmentStatus.value,
      'isArchived': isArchived,
      'archivedAt': archivedAt,
      'hasBoarded': hasBoarded,
      'hasArrived': hasArrived,
    };
  }

  factory Child.fromMap(String id, Map<String, dynamic> map) {
    return Child(
      id: id,
      name: map['name'] as String? ?? '',
      parentId: map['parentId'] as String? ?? '',
      tripId: map['tripId'] as String?,
      busId: map['busId'] as String?,
      schoolId: map['schoolId'] as String? ?? '',
      homeAddress: map['homeAddress'] as String? ?? '',
      pickupLabel: map['pickupLabel'] as String? ?? '',
      pickupLat: (map['pickupLat'] as num?)?.toDouble(),
      pickupLng: (map['pickupLng'] as num?)?.toDouble(),
      qrCodeValue: map['qrCodeValue'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      schoolName: map['schoolName'] as String? ?? '',
      gradeLevel: map['gradeLevel'] as String? ?? '',
      emergencyContactName: map['emergencyContactName'] as String? ?? '',
      emergencyContactPhone: map['emergencyContactPhone'] as String? ?? '',
      assignmentStatus: ChildAssignmentStatusX.fromValue(
        map['assignmentStatus'] as String? ?? 'pending',
      ),
      isArchived: map['isArchived'] as bool? ?? false,
      archivedAt: _dateTimeFromMap(map['archivedAt']),
      hasBoarded: map['hasBoarded'] as bool? ?? false,
      hasArrived: map['hasArrived'] as bool? ?? false,
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

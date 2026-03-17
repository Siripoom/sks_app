enum ChildAssignmentStatus { pending, assigned }

class Child {
  final String id;
  final String name;
  final String parentId;
  final String? busId;
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
  bool hasBoarded;
  bool hasArrived;

  Child({
    required this.id,
    required this.name,
    required this.parentId,
    required this.busId,
    required this.homeAddress,
    required this.pickupLabel,
    required this.qrCodeValue,
    this.pickupLat,
    this.pickupLng,
    this.photoUrl = '',
    this.schoolName = '',
    this.gradeLevel = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.assignmentStatus = ChildAssignmentStatus.assigned,
    this.hasBoarded = false,
    this.hasArrived = false,
  });

  bool get isAssigned =>
      assignmentStatus == ChildAssignmentStatus.assigned && busId != null;

  Child copyWith({
    String? id,
    String? name,
    String? parentId,
    String? busId,
    bool clearBusId = false,
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
    bool? hasBoarded,
    bool? hasArrived,
  }) {
    return Child(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      busId: clearBusId ? null : (busId ?? this.busId),
      homeAddress: homeAddress ?? this.homeAddress,
      pickupLabel: pickupLabel ?? this.pickupLabel,
      pickupLat: clearPickupLat ? null : (pickupLat ?? this.pickupLat),
      pickupLng: clearPickupLng ? null : (pickupLng ?? this.pickupLng),
      qrCodeValue: qrCodeValue ?? this.qrCodeValue,
      photoUrl: photoUrl ?? this.photoUrl,
      schoolName: schoolName ?? this.schoolName,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      emergencyContactName:
          emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      assignmentStatus: assignmentStatus ?? this.assignmentStatus,
      hasBoarded: hasBoarded ?? this.hasBoarded,
      hasArrived: hasArrived ?? this.hasArrived,
    );
  }
}

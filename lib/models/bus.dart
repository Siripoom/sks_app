enum BusStatus { waiting, enRoute, arrived }

class Bus {
  final String id;
  final String busNumber;
  final String driverId;
  final String schoolId;
  final List<String> childIds;
  BusStatus status;
  double currentLat;
  double currentLng;
  DateTime? estimatedArrival;

  Bus({
    required this.id,
    required this.busNumber,
    required this.driverId,
    required this.schoolId,
    required this.childIds,
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
      status: status ?? this.status,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
    );
  }
}

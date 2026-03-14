class BusStop {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final List<String> childIds;
  bool isCompleted;

  BusStop({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.childIds,
    this.isCompleted = false,
  });

  BusStop copyWith({
    String? id,
    String? name,
    double? lat,
    double? lng,
    List<String>? childIds,
    bool? isCompleted,
  }) {
    return BusStop(
      id: id ?? this.id,
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      childIds: childIds ?? this.childIds,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

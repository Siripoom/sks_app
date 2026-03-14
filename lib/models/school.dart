class School {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String address;

  const School({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.address,
  });

  School copyWith({
    String? id,
    String? name,
    double? lat,
    double? lng,
    String? address,
  }) {
    return School(
      id: id ?? this.id,
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
    );
  }
}

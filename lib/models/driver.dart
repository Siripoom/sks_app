class Driver {
  final String id;
  final String name;
  final String phone;
  final String busId;
  final String licenseNumber;

  const Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.busId,
    required this.licenseNumber,
  });

  Driver copyWith({
    String? id,
    String? name,
    String? phone,
    String? busId,
    String? licenseNumber,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      busId: busId ?? this.busId,
      licenseNumber: licenseNumber ?? this.licenseNumber,
    );
  }
}

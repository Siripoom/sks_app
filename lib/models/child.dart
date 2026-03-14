class Child {
  final String id;
  final String name;
  final String parentId;
  final String busId;
  final String homeAddress;
  final String photoUrl;
  bool hasBoarded;
  bool hasArrived;

  Child({
    required this.id,
    required this.name,
    required this.parentId,
    required this.busId,
    required this.homeAddress,
    this.photoUrl = '',
    this.hasBoarded = false,
    this.hasArrived = false,
  });

  Child copyWith({
    String? id,
    String? name,
    String? parentId,
    String? busId,
    String? homeAddress,
    String? photoUrl,
    bool? hasBoarded,
    bool? hasArrived,
  }) {
    return Child(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      busId: busId ?? this.busId,
      homeAddress: homeAddress ?? this.homeAddress,
      photoUrl: photoUrl ?? this.photoUrl,
      hasBoarded: hasBoarded ?? this.hasBoarded,
      hasArrived: hasArrived ?? this.hasArrived,
    );
  }
}

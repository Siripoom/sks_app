class Parent {
  final String id;
  final String name;
  final String phone;
  final List<String> childIds;

  const Parent({
    required this.id,
    required this.name,
    required this.phone,
    required this.childIds,
  });

  Parent copyWith({
    String? id,
    String? name,
    String? phone,
    List<String>? childIds,
  }) {
    return Parent(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      childIds: childIds ?? this.childIds,
    );
  }
}

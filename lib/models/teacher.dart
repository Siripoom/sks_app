class Teacher {
  final String id;
  final String name;
  final String schoolId;

  const Teacher({required this.id, required this.name, required this.schoolId});

  Teacher copyWith({String? id, String? name, String? schoolId}) {
    return Teacher(
      id: id ?? this.id,
      name: name ?? this.name,
      schoolId: schoolId ?? this.schoolId,
    );
  }
}

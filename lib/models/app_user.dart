enum UserRole { parent, teacher, driver }

class AppUser {
  final String id;
  final String name;
  final UserRole role;
  final String referenceId;

  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    required this.referenceId,
  });

  AppUser copyWith({
    String? id,
    String? name,
    UserRole? role,
    String? referenceId,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      referenceId: referenceId ?? this.referenceId,
    );
  }
}

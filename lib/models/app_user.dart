import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { parent, teacher, driver, admin }

extension UserRoleX on UserRole {
  String get value => switch (this) {
    UserRole.parent => 'parent',
    UserRole.teacher => 'teacher',
    UserRole.driver => 'driver',
    UserRole.admin => 'admin',
  };

  static UserRole fromValue(String value) => switch (value) {
    'teacher' => UserRole.teacher,
    'driver' => UserRole.driver,
    'admin' => UserRole.admin,
    _ => UserRole.parent,
  };
}

class AppUser {
  final String id;
  final String name;
  final UserRole role;
  final String referenceId;
  final String profilePhotoPath;
  final String email;
  final DateTime? createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    required this.referenceId,
    this.profilePhotoPath = '',
    this.email = '',
    this.createdAt,
  });

  AppUser copyWith({
    String? id,
    String? name,
    UserRole? role,
    String? referenceId,
    String? profilePhotoPath,
    String? email,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      referenceId: referenceId ?? this.referenceId,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role.value,
      'referenceId': referenceId,
      'profilePhotoPath': profilePhotoPath,
      'email': email,
      'createdAt': createdAt,
    };
  }

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      name: map['name'] as String? ?? '',
      role: UserRoleX.fromValue(map['role'] as String? ?? 'parent'),
      referenceId: map['referenceId'] as String? ?? '',
      profilePhotoPath: map['profilePhotoPath'] as String? ?? '',
      email: map['email'] as String? ?? '',
      createdAt: _dateTimeFromMap(map['createdAt']),
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

import 'package:flutter/material.dart';
import 'package:sks/data/mock_data.dart';
import 'package:sks/models/app_user.dart';
import 'package:sks/models/parent.dart';
import 'package:uuid/uuid.dart';

class AppStateProvider extends ChangeNotifier {
  UserRole? _selectedRole;
  AppUser? _currentUser;

  UserRole? get selectedRole => _selectedRole;
  AppUser? get currentUser => _currentUser;

  void selectRole(UserRole role, AppUser user) {
    _selectedRole = role;
    _currentUser = user;
    notifyListeners();
  }

  /// Mock login: returns true if credentials match, sets currentUser and role.
  bool login(String email, String password) {
    final cred = MockData.mockCredentials[email];
    if (cred == null || cred['password'] != password) return false;

    final appUser = MockData.findAppUserById(cred['appUserId'] as String);
    if (appUser == null) return false;

    _currentUser = appUser;
    _selectedRole = appUser.role;
    notifyListeners();
    return true;
  }

  /// Register a new parent user. Returns true on success.
  bool register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) {
    if (MockData.mockCredentials.containsKey(email)) return false;

    final uid = const Uuid().v4().substring(0, 8);
    final parentId = 'parent_$uid';
    final appUserId = 'appuser_p$uid';
    final fullName = '$firstName $lastName';

    final newParent = Parent(
      id: parentId,
      name: fullName,
      phone: phone,
      childIds: [],
    );
    MockData.parents.add(newParent);

    final newAppUser = AppUser(
      id: appUserId,
      name: fullName,
      role: UserRole.parent,
      referenceId: parentId,
    );
    MockData.parentUsers.add(newAppUser);

    MockData.mockCredentials[email] = {
      'password': password,
      'appUserId': appUserId,
      'role': 'parent',
    };

    _currentUser = newAppUser;
    _selectedRole = UserRole.parent;
    notifyListeners();
    return true;
  }

  void logout() {
    _selectedRole = null;
    _currentUser = null;
    notifyListeners();
  }
}

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sks/models/app_user.dart';
import 'package:sks/services/auth_service.dart';
import 'package:sks/services/notification_service.dart';

enum AppLanguage { thai, english }

class AppStateProvider extends ChangeNotifier {
  AppStateProvider(
    this._authService,
    this._notificationService, {
    required SharedPreferences preferences,
    required Locale initialLocale,
  })  : _preferences = preferences,
        _locale = _normalizeLocale(initialLocale) {
    unawaited(_restoreSession());
  }

  final IAuthService _authService;
  final INotificationService _notificationService;
  final SharedPreferences _preferences;

  static const _localePreferenceKey = 'app_locale';

  UserRole? _selectedRole;
  AppUser? _currentUser;
  Locale _locale;
  bool _isInitializing = true;
  bool _isBusy = false;
  String? _errorMessage;

  UserRole? get selectedRole => _selectedRole;
  AppUser? get currentUser => _currentUser;
  Locale get locale => _locale;
  bool get isInitializing => _isInitializing;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  AppLanguage get language =>
      _locale.languageCode == 'en' ? AppLanguage.english : AppLanguage.thai;

  void selectRole(UserRole role, AppUser user) {
    _selectedRole = role;
    _currentUser = user;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    _locale = Locale(language == AppLanguage.english ? 'en' : 'th');
    await _preferences.setString(_localePreferenceKey, _locale.languageCode);
    notifyListeners();
  }

  static Locale localeFromPreferences(
    SharedPreferences preferences,
    Locale fallbackLocale,
  ) {
    final savedLanguageCode = preferences.getString(_localePreferenceKey);
    if (savedLanguageCode != null &&
        (savedLanguageCode == 'en' || savedLanguageCode == 'th')) {
      return Locale(savedLanguageCode);
    }
    return _normalizeLocale(fallbackLocale);
  }

  static Locale _normalizeLocale(Locale locale) {
    return locale.languageCode == 'en' ? const Locale('en') : const Locale('th');
  }

  Future<void> updateCurrentUserProfilePhoto(
    XFile? photo, {
    bool clear = false,
  }) async {
    if (_currentUser == null) {
      return;
    }

    final updated = await _authService.updateProfilePhoto(
      _currentUser!,
      photo: photo,
      clear: clear,
    );
    _currentUser = updated;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    return _runGuarded(() async {
      final appUser = await _authService.signIn(
        email: email,
        password: password,
      );
      await _setCurrentUser(appUser);
      return true;
    });
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    return _runGuarded(() async {
      final appUser = await _authService.registerParent(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
      );
      await _setCurrentUser(appUser);
      return true;
    });
  }

  Future<void> logout() async {
    await _authService.signOut();
    _selectedRole = null;
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _restoreSession() async {
    try {
      final appUser = await _authService.restoreSession();
      if (appUser != null) {
        await _setCurrentUser(appUser, notify: false);
      }
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> _setCurrentUser(AppUser appUser, {bool notify = true}) async {
    _currentUser = appUser;
    _selectedRole = appUser.role;
    await _notificationService.registerDeviceForUser(appUser);
    if (notify) {
      notifyListeners();
    }
  }

  Future<bool> _runGuarded(Future<bool> Function() action) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await action();
    } on FirebaseAuthException catch (error) {
      _errorMessage = error.message ?? error.code;
      return false;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}

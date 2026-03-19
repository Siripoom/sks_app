import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static const String _projectId = 'sks-app-d980c';
  static const String _messagingSenderId = '354366613674';
  static const String _storageBucket = 'sks-app-d980c.firebasestorage.app';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Firebase is configured in this project for Android, iOS, and Web.',
        );
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Firebase is not configured for Fuchsia.');
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: _require('FIREBASE_WEB_API_KEY'),
    appId: _require('FIREBASE_WEB_APP_ID'),
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    authDomain: const String.fromEnvironment(
      'FIREBASE_AUTH_DOMAIN',
      defaultValue: 'sks-app-d980c.firebaseapp.com',
    ),
    storageBucket: _storageBucket,
    measurementId: const String.fromEnvironment('FIREBASE_WEB_MEASUREMENT_ID'),
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: 'AIzaSyDLYmVbgRgm8muTj6B3SqUQvh9crwVOaco',
    appId: '1:354366613674:android:5773629eaf8eea37b448d3',
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
    androidClientId: const String.fromEnvironment('FIREBASE_ANDROID_CLIENT_ID'),
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: 'AIzaSyCCqYxA-dJt070j1idK_xmFnY0TJRdMhes',
    appId: '1:354366613674:ios:35ead0a6fcdea705b448d3',
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
    iosBundleId: 'com.sks.app',
    iosClientId: const String.fromEnvironment('FIREBASE_IOS_CLIENT_ID'),
  );

  static String _require(String name) {
    final value = String.fromEnvironment(name);
    if (value.isEmpty) {
      throw StateError(
        'Missing Firebase config for $name. Generate FlutterFire config or '
        'pass it with --dart-define.',
      );
    }
    return value;
  }
}

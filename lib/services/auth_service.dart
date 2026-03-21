import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sks/models/app_user.dart';
import 'package:sks/models/parent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class IAuthService {
  Future<AppUser?> restoreSession();
  Future<AppUser> signIn({required String email, required String password});
  Future<AppUser> registerParent({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  });
  Future<AppUser> updateProfilePhoto(
    AppUser user, {
    XFile? photo,
    bool clear = false,
  });
  Future<AppUser> updateProfile(
    AppUser user, {
    required String name,
    required String phone,
  });
  Future<void> signOut();
}

class FirebaseAuthService implements IAuthService {
  FirebaseAuthService(this._auth, this._firestore, this._storage);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _appUsers =>
      _firestore.collection('app_users');

  CollectionReference<Map<String, dynamic>> get _drivers =>
      _firestore.collection('drivers');

  CollectionReference<Map<String, dynamic>> get _parents =>
      _firestore.collection('parents');

  @override
  Future<AppUser?> restoreSession() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      return null;
    }

    await firebaseUser.getIdToken(true);
    return _loadAppUser(firebaseUser.uid);
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    await credential.user!.getIdToken(true);
    return _loadAppUser(credential.user!.uid);
  }

  @override
  Future<AppUser> registerParent({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final firebaseUser = credential.user!;
    final shortUid = firebaseUser.uid.substring(0, 8);
    final parentId = 'parent_$shortUid';
    final fullName = '$firstName $lastName'.trim();

    final parent = Parent(
      id: parentId,
      name: fullName,
      phone: phone,
      childIds: const [],
      schoolIds: const [],
    );
    final appUser = AppUser(
      id: firebaseUser.uid,
      name: fullName,
      role: UserRole.parent,
      referenceId: parentId,
      email: email,
      createdAt: DateTime.now(),
    );

    await _parents.doc(parentId).set(parent.toMap());
    await _appUsers.doc(firebaseUser.uid).set(appUser.toMap());

    return appUser;
  }

  @override
  Future<AppUser> updateProfilePhoto(
    AppUser user, {
    XFile? photo,
    bool clear = false,
  }) async {
    String nextPath = user.profilePhotoPath;

    if (clear) {
      nextPath = '';
    } else if (photo != null) {
      final bytes = await photo.readAsBytes();
      final fileName = photo.name.isEmpty ? '${user.id}.jpg' : photo.name;
      final ref = _storage.ref().child('profile_photos/${user.id}/$fileName');
      await ref.putData(
        bytes,
        SettableMetadata(contentType: _guessContentType(fileName)),
      );
      nextPath = await ref.getDownloadURL();
    }

    final updated = user.copyWith(profilePhotoPath: nextPath);
    await _appUsers.doc(user.id).update({'profilePhotoPath': nextPath});
    return updated;
  }

  @override
  Future<AppUser> updateProfile(
    AppUser user, {
    required String name,
    required String phone,
  }) async {
    final batch = _firestore.batch();
    batch.update(_appUsers.doc(user.id), {'name': name});

    final referenceId = user.referenceId;
    if (user.role == UserRole.parent) {
      batch.update(_parents.doc(referenceId), {'name': name, 'phone': phone});
    } else if (user.role == UserRole.driver) {
      batch.update(_drivers.doc(referenceId), {'name': name, 'phone': phone});
    }

    await batch.commit();
    return user.copyWith(name: name);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<AppUser> _loadAppUser(String uid) async {
    final snapshot = await _appUsers.doc(uid).get();
    final data = snapshot.data();
    if (data == null) {
      throw FirebaseAuthException(
        code: 'missing-profile',
        message: 'No app user profile found for the current account.',
      );
    }

    return AppUser.fromMap(snapshot.id, data);
  }

  String _guessContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }
    return 'image/jpeg';
  }
}

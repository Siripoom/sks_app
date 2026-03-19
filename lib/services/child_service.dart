import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sks/models/child.dart';

abstract class IChildService {
  Future<List<Child>> getChildrenByParentId(String parentId);
  Stream<List<Child>> watchChildrenByParentId(String parentId);
  Stream<List<Child>> watchChildrenByIds(Iterable<String> childIds);
  Stream<List<Child>> watchAllChildren();
  Future<Child?> getChildById(String childId);
  Future<Child?> getChildByQrCode(String qrCodeValue);
  Future<bool> addChild(Child child, {XFile? photo});
  Future<bool> updateChild(Child child, {XFile? photo});
  Future<bool> deleteChild(String childId);
}

class FirebaseChildService implements IChildService {
  FirebaseChildService(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _children =>
      _firestore.collection('children');

  CollectionReference<Map<String, dynamic>> get _parents =>
      _firestore.collection('parents');

  Iterable<Child> _activeChildren(Iterable<Child> children) =>
      children.where((child) => !child.isArchived);

  @override
  Future<List<Child>> getChildrenByParentId(String parentId) async {
    final snapshot = await _children
        .where('parentId', isEqualTo: parentId)
        .get();
    return _activeChildren(
      snapshot.docs.map((doc) => Child.fromMap(doc.id, doc.data())),
    ).toList();
  }

  @override
  Stream<List<Child>> watchChildrenByParentId(String parentId) {
    return _children
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .map(
          (snapshot) {
            final children = _activeChildren(
              snapshot.docs.map((doc) => Child.fromMap(doc.id, doc.data())),
            ).toList();
            children.sort((a, b) => a.name.compareTo(b.name));
            return children;
          },
        );
  }

  @override
  Stream<List<Child>> watchChildrenByIds(Iterable<String> childIds) {
    final ids = childIds.toSet().where((id) => id.trim().isNotEmpty).toList();
    if (ids.isEmpty) {
      return Stream.value(const []);
    }

    return _children.where(FieldPath.documentId, whereIn: ids).snapshots().map((
      snapshot,
    ) {
      final children = _activeChildren(
        snapshot.docs.map((doc) => Child.fromMap(doc.id, doc.data())),
      ).toList();
      children.sort((a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)));
      return children;
    });
  }

  @override
  Stream<List<Child>> watchAllChildren() {
    return _children.snapshots().map(
      (snapshot) {
        final children = _activeChildren(
          snapshot.docs.map((doc) => Child.fromMap(doc.id, doc.data())),
        ).toList();
        children.sort((a, b) => a.name.compareTo(b.name));
        return children;
      },
    );
  }

  @override
  Future<Child?> getChildById(String childId) async {
    final snapshot = await _children.doc(childId).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    final child = Child.fromMap(snapshot.id, data);
    return child.isArchived ? null : child;
  }

  @override
  Future<Child?> getChildByQrCode(String qrCodeValue) async {
    final snapshot = await _children
        .where('qrCodeValue', isEqualTo: qrCodeValue)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    final doc = snapshot.docs.first;
    final child = Child.fromMap(doc.id, doc.data());
    return child.isArchived ? null : child;
  }

  @override
  Future<bool> addChild(Child child, {XFile? photo}) async {
    final savedChild = await _persistPhotoIfNeeded(child, photo);
    await _children.doc(savedChild.id).set(savedChild.toMap());
    await _parents.doc(savedChild.parentId).set({
      'childIds': FieldValue.arrayUnion([savedChild.id]),
      'schoolIds': FieldValue.arrayUnion([savedChild.schoolId]),
    }, SetOptions(merge: true));
    await _syncParentSchoolIds(savedChild.parentId);
    return true;
  }

  @override
  Future<bool> updateChild(Child child, {XFile? photo}) async {
    final savedChild = await _persistPhotoIfNeeded(child, photo);
    await _children
        .doc(savedChild.id)
        .set(savedChild.toMap(), SetOptions(merge: true));
    await _syncParentSchoolIds(savedChild.parentId);
    return true;
  }

  @override
  Future<bool> deleteChild(String childId) async {
    final child = await getChildById(childId);
    if (child == null) {
      return false;
    }

    await _children.doc(childId).delete();
    await _parents.doc(child.parentId).set({
      'childIds': FieldValue.arrayRemove([childId]),
    }, SetOptions(merge: true));
    await _syncParentSchoolIds(child.parentId);
    return true;
  }

  Future<Child> _persistPhotoIfNeeded(Child child, XFile? photo) async {
    if (photo == null) {
      return child;
    }

    final bytes = await photo.readAsBytes();
    final fileName = photo.name.isEmpty ? '${child.id}.jpg' : photo.name;
    final ref = _storage.ref().child('child_photos/${child.id}/$fileName');
    await ref.putData(
      bytes,
      SettableMetadata(contentType: _guessContentType(fileName)),
    );
    final downloadUrl = await ref.getDownloadURL();
    return child.copyWith(photoUrl: downloadUrl);
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

  Future<void> _syncParentSchoolIds(String parentId) async {
    final snapshot = await _children.where('parentId', isEqualTo: parentId).get();
    final schoolIds = snapshot.docs
        .map((doc) => Child.fromMap(doc.id, doc.data()))
        .where((child) => !child.isArchived && child.schoolId.trim().isNotEmpty)
        .map((child) => child.schoolId.trim())
        .toSet()
        .toList()
      ..sort();

    await _parents.doc(parentId).set({
      'schoolIds': schoolIds,
    }, SetOptions(merge: true));
  }
}

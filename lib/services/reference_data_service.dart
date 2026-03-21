import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sks/models/admin_profile.dart';
import 'package:sks/models/driver.dart';
import 'package:sks/models/parent.dart';
import 'package:sks/models/school.dart';
import 'package:sks/models/teacher.dart';

abstract class IReferenceDataService {
  Future<School?> getSchoolById(String schoolId);
  Future<List<School>> getSchools();
  Stream<List<School>> watchSchools();
  Future<Driver?> getDriverById(String driverId);
  Future<List<Driver>> getDriversByIds(Iterable<String> driverIds);
  Future<Teacher?> getTeacherById(String teacherId);
  Future<AdminProfile?> getAdminById(String adminId);
  Future<Parent?> getParentById(String parentId);
}

class FirebaseReferenceDataService implements IReferenceDataService {
  FirebaseReferenceDataService(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<School?> getSchoolById(String schoolId) async {
    final snapshot = await _firestore.collection('schools').doc(schoolId).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    return School.fromMap(snapshot.id, data);
  }

  @override
  Future<List<School>> getSchools() async {
    final snapshot = await _firestore.collection('schools').get();
    final schools = snapshot.docs
        .map((doc) => School.fromMap(doc.id, doc.data()))
        .where((school) => !school.isArchived)
        .toList();
    schools.sort((a, b) => a.name.compareTo(b.name));
    return schools;
  }

  @override
  Stream<List<School>> watchSchools() {
    return _firestore.collection('schools').snapshots().map((snapshot) {
      final schools = snapshot.docs
          .map((doc) => School.fromMap(doc.id, doc.data()))
          .where((school) => !school.isArchived)
          .toList();
      schools.sort((a, b) => a.name.compareTo(b.name));
      return schools;
    });
  }

  @override
  Future<Driver?> getDriverById(String driverId) async {
    final snapshot = await _firestore.collection('drivers').doc(driverId).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    final driver = Driver.fromMap(snapshot.id, data);
    return driver.isArchived ? null : driver;
  }

  @override
  Future<List<Driver>> getDriversByIds(Iterable<String> driverIds) async {
    final ids = driverIds.toSet().where((id) => id.trim().isNotEmpty).toList();
    if (ids.isEmpty) {
      return const [];
    }

    final snapshots = await _firestore
        .collection('drivers')
        .where(FieldPath.documentId, whereIn: ids)
        .get();

    final drivers = snapshots.docs
        .map((doc) => Driver.fromMap(doc.id, doc.data()))
        .where((driver) => !driver.isArchived)
        .toList();
    drivers.sort((a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)));
    return drivers;
  }

  @override
  Future<Teacher?> getTeacherById(String teacherId) async {
    final snapshot = await _firestore
        .collection('teachers')
        .doc(teacherId)
        .get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    final teacher = Teacher.fromMap(snapshot.id, data);
    return teacher.isArchived ? null : teacher;
  }

  @override
  Future<AdminProfile?> getAdminById(String adminId) async {
    final snapshot = await _firestore.collection('admins').doc(adminId).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    final admin = AdminProfile.fromMap(snapshot.id, data);
    return admin.isArchived ? null : admin;
  }

  @override
  Future<Parent?> getParentById(String parentId) async {
    final snapshot =
        await _firestore.collection('parents').doc(parentId).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    final parent = Parent.fromMap(snapshot.id, data);
    return parent.isArchived ? null : parent;
  }
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:sks/models/admin_profile.dart';
import 'package:sks/models/bus.dart';
import 'package:sks/models/child.dart';
import 'package:sks/models/driver.dart';
import 'package:sks/models/parent.dart';
import 'package:sks/models/school.dart';
import 'package:sks/models/teacher.dart';
import 'package:sks/models/trip.dart';

enum AdminEntityType { parent, teacher, driver, admin }

extension AdminEntityTypeX on AdminEntityType {
  String get value => switch (this) {
    AdminEntityType.parent => 'parent',
    AdminEntityType.teacher => 'teacher',
    AdminEntityType.driver => 'driver',
    AdminEntityType.admin => 'admin',
  };
}

class AdminManagedUserInput {
  const AdminManagedUserInput({
    this.uid,
    this.referenceId,
    required this.type,
    required this.name,
    required this.email,
    this.phone = '',
    this.licenseNumber = '',
    this.password,
    this.busId = '',
    this.schoolId = '',
  });

  final String? uid;
  final String? referenceId;
  final AdminEntityType type;
  final String name;
  final String email;
  final String phone;
  final String licenseNumber;
  final String? password;
  final String busId;
  final String schoolId;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'referenceId': referenceId,
      'role': type.value,
      'name': name,
      'email': email,
      'phone': phone,
      'licenseNumber': licenseNumber,
      'password': password,
      'busId': busId,
      'schoolId': schoolId,
    };
  }
}

class AdminSchoolInput {
  const AdminSchoolInput({
    this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.morningPickup = '',
    this.morningDropoff = '',
    this.eveningPickup = '',
    this.eveningDropoff = '',
    required this.busLimit,
  });

  final String? id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String morningPickup;
  final String morningDropoff;
  final String eveningPickup;
  final String eveningDropoff;
  final int busLimit;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'morningPickup': morningPickup,
      'morningDropoff': morningDropoff,
      'eveningPickup': eveningPickup,
      'eveningDropoff': eveningDropoff,
      'busLimit': busLimit,
    };
  }
}

class AdminBusInput {
  const AdminBusInput({
    this.id,
    required this.busNumber,
    required this.licensePlate,
    this.driverId = '',
    required this.schoolId,
    this.currentLat = 0,
    this.currentLng = 0,
  });

  final String? id;
  final String busNumber;
  final String licensePlate;
  final String driverId;
  final String schoolId;
  final double currentLat;
  final double currentLng;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'busNumber': busNumber,
      'licensePlate': licensePlate,
      'driverId': driverId,
      'schoolId': schoolId,
      'currentLat': currentLat,
      'currentLng': currentLng,
    };
  }
}

class AdminChildInput {
  const AdminChildInput({
    this.id,
    required this.name,
    required this.parentId,
    required this.schoolId,
    required this.homeAddress,
    required this.pickupLabel,
    this.schoolName = '',
    this.gradeLevel = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.pickupLat,
    this.pickupLng,
    this.photoUrl = '',
  });

  final String? id;
  final String name;
  final String parentId;
  final String schoolId;
  final String homeAddress;
  final String pickupLabel;
  final double? pickupLat;
  final double? pickupLng;
  final String photoUrl;
  final String schoolName;
  final String gradeLevel;
  final String emergencyContactName;
  final String emergencyContactPhone;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'schoolId': schoolId,
      'homeAddress': homeAddress,
      'pickupLabel': pickupLabel,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'photoUrl': photoUrl,
      'schoolName': schoolName,
      'gradeLevel': gradeLevel,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
    };
  }
}

class AdminTripInput {
  const AdminTripInput({
    this.id,
    required this.busId,
    required this.serviceDate,
    required this.round,
    this.scheduledStartAt,
    this.childIds = const [],
    required this.origin,
    required this.routePlan,
  });

  final String? id;
  final String busId;
  final DateTime serviceDate;
  final TripRound round;
  final DateTime? scheduledStartAt;
  final List<String> childIds;
  final Map<String, dynamic> origin;
  final Map<String, dynamic> routePlan;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'busId': busId,
      'serviceDate': serviceDate.toIso8601String(),
      'round': round.value,
      'scheduledStartAt': scheduledStartAt?.toIso8601String(),
      'childIds': childIds,
      'origin': origin,
      'routePlan': routePlan,
    };
  }
}

abstract class IAdminService {
  Stream<List<School>> watchSchools();
  Stream<List<Parent>> watchParents({String? schoolId});
  Stream<List<Teacher>> watchTeachers({String? schoolId});
  Stream<List<Driver>> watchDrivers();
  Stream<List<AdminProfile>> watchAdmins();
  Stream<List<Child>> watchChildren({String? schoolId});
  Stream<List<Bus>> watchBuses();
  Stream<List<Trip>> watchTrips({String? schoolId});
  Future<void> createManagedUser(AdminManagedUserInput input);
  Future<void> updateManagedUser(AdminManagedUserInput input);
  Future<void> setManagedUserArchived({
    required AdminEntityType type,
    required String referenceId,
    required bool archived,
  });
  Future<void> saveSchool(AdminSchoolInput input);
  Future<void> setSchoolArchived(String schoolId, bool archived);
  Future<void> saveBus(AdminBusInput input);
  Future<void> setBusArchived(String busId, bool archived);
  Future<void> saveChild(AdminChildInput input);
  Future<void> setChildArchived(String childId, bool archived);
  Future<void> saveTrip(AdminTripInput input);
  Future<Map<String, dynamic>> calculateTripRoute({
    String? tripId,
    required String busId,
    required DateTime serviceDate,
    required TripRound round,
    required DateTime? scheduledStartAt,
    required List<String> childIds,
    required Map<String, dynamic> origin,
    bool manual,
  });
  Future<void> setTripArchived(String tripId, bool archived);
  Future<void> setTripStatus(String tripId, TripStatus status);
  Future<void> assignChildToTrip({
    required String childId,
    required String tripId,
  });
  Future<void> removeChildFromTrip(String childId);
}

class FirebaseAdminService implements IAdminService {
  FirebaseAdminService(this._firestore, FirebaseFunctions functions)
    : _functions = functions;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _schools =>
      _firestore.collection('schools');
  CollectionReference<Map<String, dynamic>> get _parents =>
      _firestore.collection('parents');
  CollectionReference<Map<String, dynamic>> get _teachers =>
      _firestore.collection('teachers');
  CollectionReference<Map<String, dynamic>> get _drivers =>
      _firestore.collection('drivers');
  CollectionReference<Map<String, dynamic>> get _admins =>
      _firestore.collection('admins');
  CollectionReference<Map<String, dynamic>> get _children =>
      _firestore.collection('children');
  CollectionReference<Map<String, dynamic>> get _buses =>
      _firestore.collection('buses');
  CollectionReference<Map<String, dynamic>> get _trips =>
      _firestore.collection('trips');

  @override
  Stream<List<School>> watchSchools() {
    return _schools.snapshots().map((snapshot) {
      final records = snapshot.docs
          .map((doc) => School.fromMap(doc.id, doc.data()))
          .toList();
      records.sort((a, b) => a.name.compareTo(b.name));
      return records;
    });
  }

  @override
  Stream<List<Parent>> watchParents({String? schoolId}) {
    return _parents.snapshots().map((snapshot) {
      final records = snapshot.docs
          .map((doc) => Parent.fromMap(doc.id, doc.data()))
          .where((parent) {
            final filterSchoolId = schoolId?.trim() ?? '';
            return filterSchoolId.isEmpty ||
                parent.schoolIds.contains(filterSchoolId);
          })
          .toList();
      records.sort((a, b) => a.name.compareTo(b.name));
      return records;
    });
  }

  @override
  Stream<List<Teacher>> watchTeachers({String? schoolId}) {
    return _teachers.snapshots().map((snapshot) {
      final records = snapshot.docs
          .map((doc) => Teacher.fromMap(doc.id, doc.data()))
          .where((teacher) {
            final filterSchoolId = schoolId?.trim() ?? '';
            return filterSchoolId.isEmpty || teacher.schoolId == filterSchoolId;
          })
          .toList();
      records.sort((a, b) => a.name.compareTo(b.name));
      return records;
    });
  }

  @override
  Stream<List<Driver>> watchDrivers() {
    return _drivers.snapshots().map((snapshot) {
      final records = snapshot.docs
          .map((doc) => Driver.fromMap(doc.id, doc.data()))
          .toList();
      records.sort((a, b) => a.name.compareTo(b.name));
      return records;
    });
  }

  @override
  Stream<List<AdminProfile>> watchAdmins() {
    return _admins.snapshots().map((snapshot) {
      final records = snapshot.docs
          .map((doc) => AdminProfile.fromMap(doc.id, doc.data()))
          .toList();
      records.sort((a, b) => a.name.compareTo(b.name));
      return records;
    });
  }

  @override
  Stream<List<Child>> watchChildren({String? schoolId}) {
    return _children.snapshots().map((snapshot) {
      final records = snapshot.docs
          .map((doc) => Child.fromMap(doc.id, doc.data()))
          .where((child) {
            final filterSchoolId = schoolId?.trim() ?? '';
            return filterSchoolId.isEmpty || child.schoolId == filterSchoolId;
          })
          .toList();
      records.sort((a, b) => a.name.compareTo(b.name));
      return records;
    });
  }

  @override
  Stream<List<Bus>> watchBuses() {
    return _buses.snapshots().map((snapshot) {
      final records = snapshot.docs
          .map((doc) => Bus.fromMap(doc.id, doc.data()))
          .toList();
      records.sort((a, b) => a.busNumber.compareTo(b.busNumber));
      return records;
    });
  }

  @override
  Stream<List<Trip>> watchTrips({String? schoolId}) {
    return _trips.snapshots().map((snapshot) {
      final records = snapshot.docs
          .map((doc) => Trip.fromMap(doc.id, doc.data()))
          .where((trip) {
            final filterSchoolId = schoolId?.trim() ?? '';
            return filterSchoolId.isEmpty ||
                trip.effectiveSchoolIds.contains(filterSchoolId);
          })
          .toList();
      records.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
      return records;
    });
  }

  @override
  Future<void> createManagedUser(AdminManagedUserInput input) {
    return _call('manageUser', {...input.toMap(), 'action': 'create'});
  }

  @override
  Future<void> updateManagedUser(AdminManagedUserInput input) {
    return _call('manageUser', {...input.toMap(), 'action': 'update'});
  }

  @override
  Future<void> setManagedUserArchived({
    required AdminEntityType type,
    required String referenceId,
    required bool archived,
  }) {
    return _call('manageUser', {
      'action': archived ? 'archive' : 'restore',
      'role': type.value,
      'referenceId': referenceId,
    });
  }

  @override
  Future<void> saveSchool(AdminSchoolInput input) {
    return _call('manageSchool', {
      ...input.toMap(),
      'action': input.id == null ? 'create' : 'update',
    });
  }

  @override
  Future<void> setSchoolArchived(String schoolId, bool archived) {
    return _call('manageSchool', {
      'action': archived ? 'archive' : 'restore',
      'id': schoolId,
    });
  }

  @override
  Future<void> saveBus(AdminBusInput input) {
    return _call('manageBus', {
      ...input.toMap(),
      'action': input.id == null ? 'create' : 'update',
    });
  }

  @override
  Future<void> setBusArchived(String busId, bool archived) {
    return _call('manageBus', {
      'action': archived ? 'archive' : 'restore',
      'id': busId,
    });
  }

  @override
  Future<void> saveChild(AdminChildInput input) async {
    final childId = input.id ?? _children.doc().id;
    final schoolId = input.schoolId.trim();
    if (schoolId.isEmpty) {
      throw Exception('Child must have a school.');
    }

    final schoolSnap = await _schools.doc(schoolId).get();
    final schoolData = schoolSnap.data();
    if (!schoolSnap.exists || _asBool(schoolData?['isArchived'])) {
      throw Exception('Selected school is unavailable.');
    }

    final touchedParentIds = <String>{};

    await _firestore.runTransaction((tx) async {
      final childRef = _children.doc(childId);
      final childSnap = await tx.get(childRef);
      final existing = childSnap.data() ?? const <String, dynamic>{};
      final nextParentId = input.parentId.trim().isNotEmpty
          ? input.parentId.trim()
          : _asString(existing['parentId']);
      if (nextParentId.isEmpty) {
        throw Exception('Child must have a parent.');
      }

      final parentRef = _parents.doc(nextParentId);
      final parentSnap = await tx.get(parentRef);
      final parentData = parentSnap.data();
      if (!parentSnap.exists || _asBool(parentData?['isArchived'])) {
        throw Exception('Selected parent is unavailable.');
      }

      touchedParentIds.add(nextParentId);
      final previousParentId = _asString(existing['parentId']);
      if (previousParentId.isNotEmpty && previousParentId != nextParentId) {
        touchedParentIds.add(previousParentId);
        tx.set(_parents.doc(previousParentId), {
          'childIds': FieldValue.arrayRemove([childId]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      tx.set(parentRef, {
        'childIds': FieldValue.arrayUnion([childId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final existingTripId = _nullableString(existing['tripId']);
      final existingBusId = _nullableString(existing['busId']);
      final qrCodeValue = _asString(existing['qrCodeValue']).isEmpty
          ? 'SKS-CHILD-${childId.toUpperCase()}'
          : _asString(existing['qrCodeValue']);

      tx.set(childRef, {
        'name': input.name,
        'parentId': nextParentId,
        'tripId': existingTripId,
        'busId': existingBusId,
        'busStopId': FieldValue.delete(),
        'schoolId': schoolId,
        'homeAddress': input.homeAddress,
        'pickupLabel': input.pickupLabel,
        'pickupLat': input.pickupLat ?? existing['pickupLat'],
        'pickupLng': input.pickupLng ?? existing['pickupLng'],
        'qrCodeValue': qrCodeValue,
        'photoUrl': input.photoUrl.isNotEmpty
            ? input.photoUrl
            : _asString(existing['photoUrl']),
        'schoolName': _asString(schoolData?['name']).isNotEmpty
            ? _asString(schoolData?['name'])
            : (input.schoolName.isNotEmpty
                  ? input.schoolName
                  : _asString(existing['schoolName'])),
        'gradeLevel': input.gradeLevel.isNotEmpty
            ? input.gradeLevel
            : _asString(existing['gradeLevel']),
        'emergencyContactName': input.emergencyContactName.isNotEmpty
            ? input.emergencyContactName
            : _asString(existing['emergencyContactName']),
        'emergencyContactPhone': input.emergencyContactPhone.isNotEmpty
            ? input.emergencyContactPhone
            : _asString(existing['emergencyContactPhone']),
        'assignmentStatus':
            ((existingTripId?.isNotEmpty ?? false) ||
                (existingBusId?.isNotEmpty ?? false))
            ? ChildAssignmentStatus.assigned.value
            : ChildAssignmentStatus.pending.value,
        'isArchived': _asBool(existing['isArchived']),
        'archivedAt': existing['archivedAt'],
        'hasBoarded': _asBool(existing['hasBoarded']),
        'hasArrived': _asBool(existing['hasArrived']),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    await Future.wait(touchedParentIds.map(_syncParentSchoolIds));
  }

  @override
  Future<void> setChildArchived(String childId, bool archived) async {
    String parentId = '';
    await _firestore.runTransaction((tx) async {
      final childRef = _children.doc(childId);
      final childSnap = await tx.get(childRef);
      final childData = childSnap.data();
      if (!childSnap.exists || childData == null) {
        throw Exception('Child not found.');
      }
      parentId = _asString(childData['parentId']);

      if (archived) {
        _removeChildAssignmentInTransaction(tx, childId, childData);
      }

      tx.set(childRef, {
        'isArchived': archived,
        'archivedAt': archived ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
        'hasBoarded': archived ? false : _asBool(childData['hasBoarded']),
        'hasArrived': archived ? false : _asBool(childData['hasArrived']),
        'assignmentStatus': archived
            ? ChildAssignmentStatus.pending.value
            : (_asString(childData['assignmentStatus']).isEmpty
                  ? ChildAssignmentStatus.pending.value
                  : _asString(childData['assignmentStatus'])),
        'tripId': archived ? null : childData['tripId'],
        'busId': archived ? null : childData['busId'],
        'busStopId': FieldValue.delete(),
      }, SetOptions(merge: true));
    });

    if (parentId.isNotEmpty) {
      await _syncParentSchoolIds(parentId);
    }
  }

  @override
  Future<void> saveTrip(AdminTripInput input) {
    return _call('manageTrip', {
      ...input.toMap(),
      'action': input.id == null ? 'create' : 'update',
    });
  }

  @override
  Future<Map<String, dynamic>> calculateTripRoute({
    String? tripId,
    required String busId,
    required DateTime serviceDate,
    required TripRound round,
    required DateTime? scheduledStartAt,
    required List<String> childIds,
    required Map<String, dynamic> origin,
    bool manual = false,
  }) {
    return _callData('manageTrip', {
      'action': 'calculateRoute',
      'id': tripId,
      'busId': busId,
      'serviceDate': serviceDate.toIso8601String(),
      'round': round.value,
      'scheduledStartAt': scheduledStartAt?.toIso8601String(),
      'childIds': childIds,
      'origin': origin,
      'manual': manual,
    });
  }

  @override
  Future<void> setTripArchived(String tripId, bool archived) {
    return _call('manageTrip', {
      'action': archived ? 'archive' : 'restore',
      'id': tripId,
    });
  }

  @override
  Future<void> setTripStatus(String tripId, TripStatus status) {
    return _call('manageTrip', {
      'action': 'setStatus',
      'id': tripId,
      'status': status.value,
    });
  }

  @override
  Future<void> assignChildToTrip({
    required String childId,
    required String tripId,
  }) async {
    String parentId = '';
    await _firestore.runTransaction((tx) async {
      final childRef = _children.doc(childId);
      final tripRef = _trips.doc(tripId);
      final childSnap = await tx.get(childRef);
      final tripSnap = await tx.get(tripRef);
      final childData = childSnap.data();
      final tripData = tripSnap.data();

      if (!childSnap.exists ||
          !tripSnap.exists ||
          childData == null ||
          tripData == null) {
        throw Exception('Trip assignment target is missing.');
      }
      if (_asBool(childData['isArchived']) || _asBool(tripData['isArchived'])) {
        throw Exception('Archived records cannot be assigned.');
      }
      final tripSchoolIds = _asStringList(tripData['schoolIds']);
      final effectiveTripSchoolIds = tripSchoolIds.isNotEmpty
          ? tripSchoolIds
          : [_asString(tripData['schoolId'])];
      if (!effectiveTripSchoolIds.contains(_asString(childData['schoolId']))) {
        throw Exception('Child school does not match the trip school.');
      }

      parentId = _asString(childData['parentId']);
      _removeChildAssignmentInTransaction(tx, childId, childData);

      tx.set(tripRef, {
        'childIds': FieldValue.arrayUnion([childId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      tx.set(childRef, {
        'tripId': tripId,
        'busId': _nullableString(tripData['busId']),
        'busStopId': FieldValue.delete(),
        'assignmentStatus': ChildAssignmentStatus.assigned.value,
        'hasBoarded': false,
        'hasArrived': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    if (parentId.isNotEmpty) {
      await _syncParentSchoolIds(parentId);
    }
  }

  @override
  Future<void> removeChildFromTrip(String childId) async {
    String parentId = '';
    await _firestore.runTransaction((tx) async {
      final childRef = _children.doc(childId);
      final childSnap = await tx.get(childRef);
      final childData = childSnap.data();
      if (!childSnap.exists || childData == null) {
        throw Exception('Child not found.');
      }

      parentId = _asString(childData['parentId']);
      _removeChildAssignmentInTransaction(tx, childId, childData);
      tx.set(childRef, {
        'tripId': null,
        'busId': null,
        'busStopId': FieldValue.delete(),
        'assignmentStatus': ChildAssignmentStatus.pending.value,
        'hasBoarded': false,
        'hasArrived': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    if (parentId.isNotEmpty) {
      await _syncParentSchoolIds(parentId);
    }
  }

  Future<void> _call(String functionName, Map<String, dynamic> payload) async {
    await _callData(functionName, payload);
  }

  Future<Map<String, dynamic>> _callData(
    String functionName,
    Map<String, dynamic> payload,
  ) async {
    try {
      final result = await _functions.httpsCallable(functionName).call(payload);
      if (result.data is Map) {
        return Map<String, dynamic>.from(result.data as Map);
      }
      return const {};
    } on FirebaseFunctionsException catch (error) {
      throw Exception(error.message ?? error.code);
    }
  }

  void _removeChildAssignmentInTransaction(
    Transaction tx,
    String childId,
    Map<String, dynamic> childData,
  ) {
    final tripId = _nullableString(childData['tripId']);
    final busId = _nullableString(childData['busId']);

    if (tripId != null && tripId.isNotEmpty) {
      tx.set(_trips.doc(tripId), {
        'childIds': FieldValue.arrayRemove([childId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    if (busId != null && busId.isNotEmpty) {
      tx.set(_buses.doc(busId), {
        'childIds': FieldValue.arrayRemove([childId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _syncParentSchoolIds(String parentId) async {
    final snapshot = await _children
        .where('parentId', isEqualTo: parentId)
        .get();
    final schoolIds =
        snapshot.docs
            .map((doc) => doc.data())
            .where(
              (child) =>
                  !_asBool(child['isArchived']) &&
                  _asString(child['schoolId']).isNotEmpty,
            )
            .map((child) => _asString(child['schoolId']))
            .toSet()
            .toList()
          ..sort();

    await _parents.doc(parentId).set({
      'schoolIds': schoolIds,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _asString(Object? value) {
    return value is String ? value.trim() : '';
  }

  String? _nullableString(Object? value) {
    final normalized = _asString(value);
    return normalized.isEmpty ? null : normalized;
  }

  bool _asBool(Object? value) {
    return value is bool ? value : false;
  }

  List<String> _asStringList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<String>()
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }
}

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
    };
  }
}

class AdminBusInput {
  const AdminBusInput({
    this.id,
    required this.busNumber,
    required this.licensePlate,
    this.driverId = '',
    this.schoolId = '',
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
    required this.schoolId,
    required this.busId,
    required this.serviceDate,
    required this.round,
    this.scheduledStartAt,
    this.childIds = const [],
    this.stops = const [],
  });

  final String? id;
  final String schoolId;
  final String busId;
  final DateTime serviceDate;
  final TripRound round;
  final DateTime? scheduledStartAt;
  final List<String> childIds;
  final List<Map<String, dynamic>> stops;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'busId': busId,
      'serviceDate': serviceDate,
      'round': round.value,
      'scheduledStartAt': scheduledStartAt,
      'childIds': childIds,
      'stops': stops,
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
            return filterSchoolId.isEmpty || trip.schoolId == filterSchoolId;
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
  Future<void> saveSchool(AdminSchoolInput input) async {
    final schoolId = input.id ?? _generatePrefixedId('school');
    final schoolRef = _schools.doc(schoolId);
    final existing = (await schoolRef.get()).data() ?? const {};
    await schoolRef.set({
      'name': input.name,
      'address': input.address,
      'lat': input.lat,
      'lng': input.lng,
      'morningPickup': input.morningPickup,
      'morningDropoff': input.morningDropoff,
      'eveningPickup': input.eveningPickup,
      'eveningDropoff': input.eveningDropoff,
      'isArchived': _asBool(existing['isArchived']),
      'archivedAt': existing['archivedAt'],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> setSchoolArchived(String schoolId, bool archived) async {
    if (archived) {
      await _assertSchoolArchiveAllowed(schoolId);
    }
    await _schools.doc(schoolId).set({
      'isArchived': archived,
      'archivedAt': archived ? FieldValue.serverTimestamp() : null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> saveBus(AdminBusInput input) async {
    final busId = input.id ?? _generatePrefixedId('bus');
    await _firestore.runTransaction((tx) async {
      // ---- ALL READS FIRST ----
      final busRef = _buses.doc(busId);
      final busSnap = await tx.get(busRef);
      final existing = busSnap.data() ?? const <String, dynamic>{};
      final previousDriverId = _asString(existing['driverId']);
      final nextDriverId = input.driverId.trim();

      DocumentSnapshot<Map<String, dynamic>>? driverSnap;
      if (nextDriverId.isNotEmpty) {
        driverSnap = await tx.get(_drivers.doc(nextDriverId));
      }

      // ---- VALIDATE ----
      if (nextDriverId.isNotEmpty) {
        final driverData = driverSnap?.data();
        if (driverSnap == null || !driverSnap.exists || _asBool(driverData?['isArchived'])) {
          throw Exception('Assigned driver is unavailable.');
        }
      }

      // ---- ALL WRITES ----
      if (previousDriverId.isNotEmpty && previousDriverId != nextDriverId) {
        tx.set(_drivers.doc(previousDriverId), {
          'busId': '',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (nextDriverId.isNotEmpty && driverSnap != null) {
        final driverData = driverSnap.data();
        final driverBusId = _asString(driverData?['busId']);
        if (driverBusId.isNotEmpty && driverBusId != busId) {
          tx.set(_buses.doc(driverBusId), {
            'driverId': '',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        tx.set(_drivers.doc(nextDriverId), {
          'busId': busId,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      tx.set(busRef, {
        'busNumber': input.busNumber,
        'driverId': nextDriverId,
        'schoolId': input.schoolId,
        'childIds': _asStringList(existing['childIds']),
        'licensePlate': input.licensePlate,
        'status': _asString(existing['status']).isEmpty
            ? BusStatus.waiting.value
            : _asString(existing['status']),
        'currentLat': input.currentLat,
        'currentLng': input.currentLng,
        'estimatedArrival': existing['estimatedArrival'],
        'isArchived': _asBool(existing['isArchived']),
        'archivedAt': existing['archivedAt'],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  @override
  Future<void> setBusArchived(String busId, bool archived) async {
    if (archived) {
      await _assertBusArchiveAllowed(busId);
    }
    await _buses.doc(busId).set({
      'isArchived': archived,
      'archivedAt': archived ? FieldValue.serverTimestamp() : null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
  Future<void> saveTrip(AdminTripInput input) async {
    final tripId = input.id ?? _generatePrefixedId('trip');
    final schoolId = input.schoolId.trim();
    final busId = input.busId.trim();
    if (schoolId.isEmpty || busId.isEmpty) {
      throw Exception('Trip must have a school and bus.');
    }

    final childIds = _uniqueStrings(input.childIds);
    final serviceDateKey = _toDateKey(input.serviceDate);

    final schoolSnap = await _schools.doc(schoolId).get();
    final busSnap = await _buses.doc(busId).get();
    if (!schoolSnap.exists || _asBool(schoolSnap.data()?['isArchived'])) {
      throw Exception('Selected school is unavailable.');
    }
    if (!busSnap.exists || _asBool(busSnap.data()?['isArchived'])) {
      throw Exception('Selected bus is unavailable.');
    }

    await _validateTripConflicts(
      tripId: tripId,
      busId: busId,
      childIds: childIds,
      serviceDateKey: serviceDateKey,
      round: input.round.value,
    );

    final touchedParentIds = <String>{};

    await _firestore.runTransaction((tx) async {
      // ---- ALL READS FIRST ----
      final tripRef = _trips.doc(tripId);
      final tripSnap = await tx.get(tripRef);
      final existing = tripSnap.data() ?? const <String, dynamic>{};
      final existingChildIds = _asStringList(existing['childIds']);
      final removedChildIds = existingChildIds
          .where((childId) => !childIds.contains(childId))
          .toList();

      final removedChildSnaps = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final childId in removedChildIds) {
        removedChildSnaps[childId] = await tx.get(_children.doc(childId));
      }

      final assignedChildSnaps = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final childId in childIds) {
        assignedChildSnaps[childId] = await tx.get(_children.doc(childId));
      }

      // ---- VALIDATE ----
      for (final childId in childIds) {
        final childSnap = assignedChildSnaps[childId]!;
        final childData = childSnap.data();
        if (!childSnap.exists || childData == null) {
          throw Exception('Selected child is unavailable.');
        }
        if (_asBool(childData['isArchived'])) {
          throw Exception('Selected child is unavailable.');
        }
        if (_asString(childData['schoolId']) != schoolId) {
          throw Exception('Child school does not match the trip school.');
        }
      }

      // ---- ALL WRITES ----
      tx.set(tripRef, {
        'schoolId': schoolId,
        'busId': busId,
        'serviceDate': input.serviceDate,
        'serviceDateKey': serviceDateKey,
        'round': input.round.value,
        'scheduledStartAt': input.scheduledStartAt,
        'childIds': childIds,
        'stops': input.stops,
        'currentStopIndex': existing['currentStopIndex'] ?? -1,
        'status': _asString(existing['status']).isEmpty
            ? TripStatus.draft.value
            : _asString(existing['status']),
        'isArchived': _asBool(existing['isArchived']),
        'archivedAt': existing['archivedAt'],
        'startedAt': existing['startedAt'],
        'completedAt': existing['completedAt'],
        'createdAt': tripSnap.exists
            ? existing['createdAt']
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      for (final childId in removedChildIds) {
        final childSnap = removedChildSnaps[childId]!;
        final childData = childSnap.data();
        if (!childSnap.exists || childData == null) {
          continue;
        }
        final parentId = _asString(childData['parentId']);
        if (parentId.isNotEmpty) {
          touchedParentIds.add(parentId);
        }
        tx.set(_children.doc(childId), {
          'tripId': null,
          'busId': null,
          'busStopId': FieldValue.delete(),
          'assignmentStatus': ChildAssignmentStatus.pending.value,
          'hasBoarded': false,
          'hasArrived': false,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      for (final childId in childIds) {
        final childSnap = assignedChildSnaps[childId]!;
        final childData = childSnap.data()!;
        final parentId = _asString(childData['parentId']);
        if (parentId.isNotEmpty) {
          touchedParentIds.add(parentId);
        }
        tx.set(_children.doc(childId), {
          'tripId': tripId,
          'busId': busId,
          'busStopId': FieldValue.delete(),
          'schoolId': schoolId,
          'schoolName': _asString(schoolSnap.data()?['name']).isNotEmpty
              ? _asString(schoolSnap.data()?['name'])
              : _asString(childData['schoolName']),
          'assignmentStatus': ChildAssignmentStatus.assigned.value,
          'hasBoarded': false,
          'hasArrived': false,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });

    await Future.wait(touchedParentIds.map(_syncParentSchoolIds));
  }

  @override
  Future<void> setTripArchived(String tripId, bool archived) async {
    final touchedParentIds = <String>{};

    await _firestore.runTransaction((tx) async {
      // ---- ALL READS FIRST ----
      final tripRef = _trips.doc(tripId);
      final tripSnap = await tx.get(tripRef);
      final tripData = tripSnap.data();
      if (!tripSnap.exists || tripData == null) {
        throw Exception('Trip not found.');
      }

      final childSnaps = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      if (archived) {
        for (final childId in _asStringList(tripData['childIds'])) {
          childSnaps[childId] = await tx.get(_children.doc(childId));
        }
      }

      // ---- ALL WRITES ----
      if (archived) {
        for (final entry in childSnaps.entries) {
          final childData = entry.value.data();
          if (!entry.value.exists || childData == null) {
            continue;
          }
          final parentId = _asString(childData['parentId']);
          if (parentId.isNotEmpty) {
            touchedParentIds.add(parentId);
          }
          tx.set(_children.doc(entry.key), {
            'tripId': null,
            'busId': null,
            'busStopId': FieldValue.delete(),
            'assignmentStatus': ChildAssignmentStatus.pending.value,
            'hasBoarded': false,
            'hasArrived': false,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        tx.set(tripRef, {'childIds': []}, SetOptions(merge: true));
      }

      tx.set(tripRef, {
        'isArchived': archived,
        'archivedAt': archived ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    await Future.wait(touchedParentIds.map(_syncParentSchoolIds));
  }

  @override
  Future<void> setTripStatus(String tripId, TripStatus status) {
    return _trips.doc(tripId).set({
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
      if (_asString(childData['schoolId']) != _asString(tripData['schoolId'])) {
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
        'schoolId': _asString(tripData['schoolId']),
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
    try {
      await _functions.httpsCallable(functionName).call(payload);
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

  Future<void> _validateTripConflicts({
    required String tripId,
    required String busId,
    required List<String> childIds,
    required String serviceDateKey,
    required String round,
  }) async {
    final snapshot = await _trips
        .where('serviceDateKey', isEqualTo: serviceDateKey)
        .where('round', isEqualTo: round)
        .get();

    for (final doc in snapshot.docs) {
      if (doc.id == tripId) {
        continue;
      }

      final trip = doc.data();
      if (!_tripIsOpen(trip)) {
        continue;
      }

      if (_asString(trip['busId']) == busId) {
        throw Exception(
          'Selected bus already has an active trip in this round.',
        );
      }

      final assignedChildIds = _asStringList(trip['childIds']);
      final hasOverlap = assignedChildIds.any(childIds.contains);
      if (hasOverlap) {
        throw Exception(
          'A selected student already belongs to another active trip in this round.',
        );
      }
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

  Future<void> _assertSchoolArchiveAllowed(String schoolId) async {
    final teachers = await _teachers
        .where('schoolId', isEqualTo: schoolId)
        .get();
    final children = await _children
        .where('schoolId', isEqualTo: schoolId)
        .get();
    final trips = await _trips.where('schoolId', isEqualTo: schoolId).get();

    if (teachers.docs.any((doc) => !_asBool(doc.data()['isArchived']))) {
      throw Exception('School still has active teachers.');
    }
    if (children.docs.any((doc) => !_asBool(doc.data()['isArchived']))) {
      throw Exception('School still has active students.');
    }
    if (trips.docs.any((doc) => _tripIsOpen(doc.data()))) {
      throw Exception('School still has active trips.');
    }
  }

  Future<void> _assertBusArchiveAllowed(String busId) async {
    final children = await _children.where('busId', isEqualTo: busId).get();
    final trips = await _trips.where('busId', isEqualTo: busId).get();

    if (children.docs.any((doc) => !_asBool(doc.data()['isArchived']))) {
      throw Exception('Bus still has active students assigned.');
    }
    if (trips.docs.any((doc) => _tripIsOpen(doc.data()))) {
      throw Exception('Bus still has active trips.');
    }
  }

  bool _tripIsOpen(Map<String, dynamic> trip) {
    if (_asBool(trip['isArchived'])) {
      return false;
    }
    final status = _asString(trip['status']);
    return status != TripStatus.completed.value &&
        status != TripStatus.cancelled.value;
  }

  String _generatePrefixedId(String prefix) {
    final token = _firestore.collection('_').doc().id.substring(0, 8);
    return '${prefix}_$token';
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

  List<String> _uniqueStrings(Iterable<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
  }

  String _toDateKey(DateTime value) {
    return value.toUtc().toIso8601String().substring(0, 10);
  }
}

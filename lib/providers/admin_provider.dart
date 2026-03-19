import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sks/models/admin_profile.dart';
import 'package:sks/models/bus.dart';
import 'package:sks/models/child.dart';
import 'package:sks/models/driver.dart';
import 'package:sks/models/parent.dart';
import 'package:sks/models/school.dart';
import 'package:sks/models/teacher.dart';
import 'package:sks/models/trip.dart';
import 'package:sks/services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  AdminProvider(this._adminService);

  final IAdminService _adminService;

  String _selectedSchoolId = '';
  bool _isBootstrapped = false;
  String? _errorMessage;

  List<School> _schools = [];
  List<Parent> _parents = [];
  List<Teacher> _teachers = [];
  List<Driver> _drivers = [];
  List<AdminProfile> _admins = [];
  List<Child> _children = [];
  List<Bus> _buses = [];
  List<Trip> _trips = [];

  StreamSubscription<List<School>>? _schoolsSubscription;
  StreamSubscription<List<Parent>>? _parentsSubscription;
  StreamSubscription<List<Teacher>>? _teachersSubscription;
  StreamSubscription<List<Driver>>? _driversSubscription;
  StreamSubscription<List<AdminProfile>>? _adminsSubscription;
  StreamSubscription<List<Child>>? _childrenSubscription;
  StreamSubscription<List<Bus>>? _busesSubscription;
  StreamSubscription<List<Trip>>? _tripsSubscription;

  String get selectedSchoolId => _selectedSchoolId;
  bool get isBootstrapped => _isBootstrapped;
  String? get errorMessage => _errorMessage;

  List<School> get schools => _schools;
  List<Parent> get parents => _parents;
  List<Teacher> get teachers => _teachers;
  List<Driver> get drivers => _drivers;
  List<AdminProfile> get admins => _admins;
  List<Child> get children => _children;
  List<Bus> get buses => _buses;
  List<Trip> get trips => _trips;

  Future<void> bootstrap([String initialSchoolId = '']) async {
    _selectedSchoolId = initialSchoolId;
    _isBootstrapped = true;
    await Future.wait([
      _schoolsSubscription?.cancel() ?? Future.value(),
      _parentsSubscription?.cancel() ?? Future.value(),
      _teachersSubscription?.cancel() ?? Future.value(),
      _driversSubscription?.cancel() ?? Future.value(),
      _adminsSubscription?.cancel() ?? Future.value(),
      _childrenSubscription?.cancel() ?? Future.value(),
      _busesSubscription?.cancel() ?? Future.value(),
      _tripsSubscription?.cancel() ?? Future.value(),
    ]);

    _schoolsSubscription = _adminService.watchSchools().listen((records) {
      _schools = records;
      if (_selectedSchoolId.isEmpty && records.isNotEmpty) {
        _selectedSchoolId = records.first.id;
      }
      notifyListeners();
    });
    _parentsSubscription = _adminService.watchParents().listen((records) {
      _parents = records;
      notifyListeners();
    });
    _teachersSubscription = _adminService.watchTeachers().listen((records) {
      _teachers = records;
      notifyListeners();
    });
    _driversSubscription = _adminService.watchDrivers().listen((records) {
      _drivers = records;
      notifyListeners();
    });
    _adminsSubscription = _adminService.watchAdmins().listen((records) {
      _admins = records;
      notifyListeners();
    });
    _childrenSubscription = _adminService.watchChildren().listen((records) {
      _children = records;
      notifyListeners();
    });
    _busesSubscription = _adminService.watchBuses().listen((records) {
      _buses = records;
      notifyListeners();
    });
    _tripsSubscription = _adminService.watchTrips().listen((records) {
      _trips = records;
      notifyListeners();
    });
  }

  void selectSchool(String schoolId) {
    _selectedSchoolId = schoolId;
    notifyListeners();
  }

  List<Parent> get visibleParents => _selectedSchoolId.isEmpty
      ? _parents
      : _parents
            .where((parent) => parent.schoolIds.contains(_selectedSchoolId))
            .toList();

  List<Teacher> get visibleTeachers => _selectedSchoolId.isEmpty
      ? _teachers
      : _teachers.where((teacher) => teacher.schoolId == _selectedSchoolId).toList();

  List<Child> get visibleChildren => _selectedSchoolId.isEmpty
      ? _children
      : _children.where((child) => child.schoolId == _selectedSchoolId).toList();

  List<Trip> get visibleTrips => _selectedSchoolId.isEmpty
      ? _trips
      : _trips.where((trip) => trip.schoolId == _selectedSchoolId).toList();

  List<Child> get unassignedChildren => visibleChildren
      .where((child) => !child.isArchived && child.assignmentStatus == ChildAssignmentStatus.pending)
      .toList();

  Future<bool> runGuarded(Future<void> Function() action) async {
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createManagedUser(AdminManagedUserInput input) {
    return runGuarded(() => _adminService.createManagedUser(input));
  }

  Future<bool> updateManagedUser(AdminManagedUserInput input) {
    return runGuarded(() => _adminService.updateManagedUser(input));
  }

  Future<bool> setManagedUserArchived({
    required AdminEntityType type,
    required String referenceId,
    required bool archived,
  }) {
    return runGuarded(
      () => _adminService.setManagedUserArchived(
        type: type,
        referenceId: referenceId,
        archived: archived,
      ),
    );
  }

  Future<bool> saveSchool(AdminSchoolInput input) {
    return runGuarded(() => _adminService.saveSchool(input));
  }

  Future<bool> setSchoolArchived(String schoolId, bool archived) {
    return runGuarded(() => _adminService.setSchoolArchived(schoolId, archived));
  }

  Future<bool> saveBus(AdminBusInput input) {
    return runGuarded(() => _adminService.saveBus(input));
  }

  Future<bool> setBusArchived(String busId, bool archived) {
    return runGuarded(() => _adminService.setBusArchived(busId, archived));
  }

  Future<bool> saveChild(AdminChildInput input) {
    return runGuarded(() => _adminService.saveChild(input));
  }

  Future<bool> setChildArchived(String childId, bool archived) {
    return runGuarded(() => _adminService.setChildArchived(childId, archived));
  }

  Future<bool> saveTrip(AdminTripInput input) {
    return runGuarded(() => _adminService.saveTrip(input));
  }

  Future<bool> setTripArchived(String tripId, bool archived) {
    return runGuarded(() => _adminService.setTripArchived(tripId, archived));
  }

  Future<bool> assignChildToTrip({
    required String childId,
    required String tripId,
  }) {
    return runGuarded(
      () => _adminService.assignChildToTrip(childId: childId, tripId: tripId),
    );
  }

  Future<bool> removeChildFromTrip(String childId) {
    return runGuarded(() => _adminService.removeChildFromTrip(childId));
  }

  School? schoolById(String schoolId) {
    try {
      return _schools.firstWhere((school) => school.id == schoolId);
    } catch (_) {
      return null;
    }
  }

  Trip? tripById(String? tripId) {
    if (tripId == null || tripId.isEmpty) {
      return null;
    }
    try {
      return _trips.firstWhere((trip) => trip.id == tripId);
    } catch (_) {
      return null;
    }
  }

  Bus? busById(String? busId) {
    if (busId == null || busId.isEmpty) {
      return null;
    }
    try {
      return _buses.firstWhere((bus) => bus.id == busId);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _schoolsSubscription?.cancel();
    _parentsSubscription?.cancel();
    _teachersSubscription?.cancel();
    _driversSubscription?.cancel();
    _adminsSubscription?.cancel();
    _childrenSubscription?.cancel();
    _busesSubscription?.cancel();
    _tripsSubscription?.cancel();
    super.dispose();
  }
}

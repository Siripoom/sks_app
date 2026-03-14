import 'package:sks/models/app_user.dart';
import 'package:sks/models/bus.dart';
import 'package:sks/models/bus_stop.dart';
import 'package:sks/models/child.dart';
import 'package:sks/models/driver.dart';
import 'package:sks/models/parent.dart';
import 'package:sks/models/school.dart';
import 'package:sks/models/teacher.dart';

class MockData {
  // School
  static final School school = School(
    id: 'school_01',
    name: 'โรงเรียนสาธิต',
    lat: 13.7563,
    lng: 100.5018,
    address: '123 ถนนพระราม 4 เขตบางรัก กรุงเทพมหานคร 10500',
  );

  // Drivers
  static final List<Driver> drivers = [
    Driver(
      id: 'driver_01',
      name: 'สมชาย มีสุข',
      phone: '0812345001',
      busId: 'bus_01',
      licenseNumber: '9876543210001',
    ),
    Driver(
      id: 'driver_02',
      name: 'สมหญิง ดีใจ',
      phone: '0812345002',
      busId: 'bus_02',
      licenseNumber: '9876543210002',
    ),
    Driver(
      id: 'driver_03',
      name: 'ประเสริฐ สุขใจ',
      phone: '0812345003',
      busId: 'bus_03',
      licenseNumber: '9876543210003',
    ),
  ];

  // Buses
  static final List<Bus> buses = [
    Bus(
      id: 'bus_01',
      busNumber: 'สาย 1',
      driverId: 'driver_01',
      schoolId: 'school_01',
      childIds: ['child_01', 'child_02', 'child_04'],
      status: BusStatus.enRoute,
      currentLat: 13.7900,
      currentLng: 100.5500,
      estimatedArrival: DateTime.now().add(const Duration(minutes: 15)),
    ),
    Bus(
      id: 'bus_02',
      busNumber: 'สาย 2',
      driverId: 'driver_02',
      schoolId: 'school_01',
      childIds: ['child_03', 'child_05'],
      status: BusStatus.waiting,
      currentLat: 13.7200,
      currentLng: 100.5800,
    ),
    Bus(
      id: 'bus_03',
      busNumber: 'สาย 3',
      driverId: 'driver_03',
      schoolId: 'school_01',
      childIds: ['child_06'],
      status: BusStatus.arrived,
      currentLat: 13.7563,
      currentLng: 100.5018,
    ),
  ];

  // Parents
  static final List<Parent> parents = [
    Parent(
      id: 'parent_01',
      name: 'นางสาวมาลี รักลูก',
      phone: '0812345101',
      childIds: ['child_01', 'child_02'],
    ),
    Parent(
      id: 'parent_02',
      name: 'นายสมศักดิ์ พรดี',
      phone: '0812345102',
      childIds: ['child_03'],
    ),
    Parent(
      id: 'parent_03',
      name: 'นางวันดี ใจดี',
      phone: '0812345103',
      childIds: ['child_04', 'child_05'],
    ),
    Parent(
      id: 'parent_04',
      name: 'นายประยุทธ ใจงาม',
      phone: '0812345104',
      childIds: ['child_06'],
    ),
  ];

  // Children
  static final List<Child> children = [
    Child(
      id: 'child_01',
      name: 'เด็กชายก้อง รักลูก',
      parentId: 'parent_01',
      busId: 'bus_01',
      homeAddress: '456 ซอยลาดพร้าว 1 เขตวังทองหลาง กรุงเทพฯ',
      hasBoarded: true,
      hasArrived: false,
    ),
    Child(
      id: 'child_02',
      name: 'เด็กหญิงแก้ว รักลูก',
      parentId: 'parent_01',
      busId: 'bus_01',
      homeAddress: '456 ซอยลาดพร้าว 1 เขตวังทองหลาง กรุงเทพฯ',
      hasBoarded: false,
      hasArrived: false,
    ),
    Child(
      id: 'child_03',
      name: 'เด็กชายบิ๊ก พรดี',
      parentId: 'parent_02',
      busId: 'bus_02',
      homeAddress: '789 ถนนรามคำแหง เขตหัวหมาก กรุงเทพฯ',
      hasBoarded: true,
      hasArrived: false,
    ),
    Child(
      id: 'child_04',
      name: 'เด็กหญิงมิ้ว ใจดี',
      parentId: 'parent_03',
      busId: 'bus_01',
      homeAddress: '321 ซอยสุทธิสาร 1 เขตดิน แดง กรุงเทพฯ',
      hasBoarded: true,
      hasArrived: false,
    ),
    Child(
      id: 'child_05',
      name: 'เด็กชายแมน ใจดี',
      parentId: 'parent_03',
      busId: 'bus_02',
      homeAddress: '321 ซอยสุทธิสาร 1 เขตดินแดง กรุงเทพฯ',
      hasBoarded: false,
      hasArrived: false,
    ),
    Child(
      id: 'child_06',
      name: 'เด็กหญิงน้ำ ใจงาม',
      parentId: 'parent_04',
      busId: 'bus_03',
      homeAddress: '147 ซอยสุทธิสาร 5 เขตดินแดง กรุงเทพฯ',
      hasBoarded: true,
      hasArrived: true,
    ),
  ];

  // Teachers
  static final List<Teacher> teachers = [
    Teacher(id: 'teacher_01', name: 'ครูสมใจ', schoolId: 'school_01'),
    Teacher(id: 'teacher_02', name: 'ครูรัตนา', schoolId: 'school_01'),
  ];

  // Bus Stops
  static final List<BusStop> busStops = [
    // Bus 1 stops
    BusStop(
      id: 'stop_01',
      name: 'ซอยลาดพร้าว 1',
      lat: 13.7900,
      lng: 100.5500,
      childIds: ['child_01', 'child_02'],
      isCompleted: true,
    ),
    BusStop(
      id: 'stop_02',
      name: 'ซอยสุทธิสาร 1',
      lat: 13.7700,
      lng: 100.5300,
      childIds: ['child_04'],
      isCompleted: false,
    ),
    // Bus 2 stops
    BusStop(
      id: 'stop_03',
      name: 'ถนนรามคำแหง',
      lat: 13.7200,
      lng: 100.5800,
      childIds: ['child_03'],
      isCompleted: false,
    ),
    BusStop(
      id: 'stop_04',
      name: 'สุทธิสาร 2',
      lat: 13.7100,
      lng: 100.5600,
      childIds: ['child_05'],
      isCompleted: false,
    ),
    // Bus 3 stops
    BusStop(
      id: 'stop_05',
      name: 'ซอยสุทธิสาร 5',
      lat: 13.7563,
      lng: 100.5018,
      childIds: ['child_06'],
      isCompleted: true,
    ),
  ];

  // App Users for Role Selection
  static final List<AppUser> parentUsers = [
    AppUser(
      id: 'appuser_p01',
      name: 'นางสาวมาลี รักลูก',
      role: UserRole.parent,
      referenceId: 'parent_01',
    ),
    AppUser(
      id: 'appuser_p02',
      name: 'นายสมศักดิ์ พรดี',
      role: UserRole.parent,
      referenceId: 'parent_02',
    ),
    AppUser(
      id: 'appuser_p03',
      name: 'นางวันดี ใจดี',
      role: UserRole.parent,
      referenceId: 'parent_03',
    ),
    AppUser(
      id: 'appuser_p04',
      name: 'นายประยุทธ ใจงาม',
      role: UserRole.parent,
      referenceId: 'parent_04',
    ),
  ];

  static final List<AppUser> teacherUsers = [
    AppUser(
      id: 'appuser_t01',
      name: 'ครูสมใจ',
      role: UserRole.teacher,
      referenceId: 'teacher_01',
    ),
    AppUser(
      id: 'appuser_t02',
      name: 'ครูรัตนา',
      role: UserRole.teacher,
      referenceId: 'teacher_02',
    ),
  ];

  static final List<AppUser> driverUsers = [
    AppUser(
      id: 'appuser_d01',
      name: 'สมชาย มีสุข',
      role: UserRole.driver,
      referenceId: 'driver_01',
    ),
    AppUser(
      id: 'appuser_d02',
      name: 'สมหญิง ดีใจ',
      role: UserRole.driver,
      referenceId: 'driver_02',
    ),
    AppUser(
      id: 'appuser_d03',
      name: 'ประเสริฐ สุขใจ',
      role: UserRole.driver,
      referenceId: 'driver_03',
    ),
  ];

  // Notification history
  static final List<Map<String, String>> notificationHistory = [
    {
      'type': 'arrived',
      'message': 'เด็กชายก้อง ถึงโรงเรียนแล้ว (รถสาย 1)',
      'time': '08:00',
    },
    {'type': 'boarded', 'message': 'เด็กชายก้อง ขึ้นรถแล้ว', 'time': '07:15'},
    {
      'type': 'departed',
      'message': 'รถสาย 1 ออกจากจุดเริ่มต้นแล้ว',
      'time': '06:45',
    },
    {
      'type': 'arrived',
      'message': 'เด็กหญิงแก้ว ถึงโรงเรียนแล้ว (รถสาย 1)',
      'time': '08:00',
    },
    {'type': 'boarded', 'message': 'เด็กหญิงแก้ว ขึ้นรถแล้ว', 'time': '07:15'},
    {
      'type': 'system',
      'message': 'พรุ่งนี้รถสาย 1 จะมาเร็วขึ้น 10 นาที',
      'time': '18:00',
    },
    {'type': 'arrived', 'message': 'เด็กชายก้อง ถึงบ้านแล้ว', 'time': '16:30'},
    {
      'type': 'departed',
      'message': 'รถสาย 1 ออกจากโรงเรียนแล้ว (รอบเย็น)',
      'time': '15:45',
    },
  ];

  // Mock login credentials (all password = 1234)
  static final Map<String, Map<String, dynamic>> mockCredentials = {
    'parent1@sks.com': {
      'password': '1234',
      'appUserId': 'appuser_p01',
      'role': 'parent',
    },
    'parent2@sks.com': {
      'password': '1234',
      'appUserId': 'appuser_p02',
      'role': 'parent',
    },
    'parent3@sks.com': {
      'password': '1234',
      'appUserId': 'appuser_p03',
      'role': 'parent',
    },
    'parent4@sks.com': {
      'password': '1234',
      'appUserId': 'appuser_p04',
      'role': 'parent',
    },
    'teacher1@sks.com': {
      'password': '1234',
      'appUserId': 'appuser_t01',
      'role': 'teacher',
    },
    'teacher2@sks.com': {
      'password': '1234',
      'appUserId': 'appuser_t02',
      'role': 'teacher',
    },
    'driver1@sks.com': {
      'password': '1234',
      'appUserId': 'appuser_d01',
      'role': 'driver',
    },
    'driver2@sks.com': {
      'password': '1234',
      'appUserId': 'appuser_d02',
      'role': 'driver',
    },
    'driver3@sks.com': {
      'password': '1234',
      'appUserId': 'appuser_d03',
      'role': 'driver',
    },
  };

  // Bus license plates
  static final Map<String, String> busLicensePlates = {
    'bus_01': 'กก 1234',
    'bus_02': 'ขข 5678',
    'bus_03': 'คค 9012',
  };

  // Mock messages for driver
  static final List<Map<String, String>> mockMessages = [
    {
      'sender': 'ระบบ',
      'message': 'เริ่มเส้นทางรอบเช้าเรียบร้อย',
      'time': '06:30',
    },
    {
      'sender': 'นางสาวมาลี',
      'message': 'วันนี้ก้องไม่สบาย ไม่ไปโรงเรียนค่ะ',
      'time': '06:45',
    },
    {'sender': 'ระบบ', 'message': 'เด็กชายบิ๊ก ขึ้นรถแล้ว', 'time': '07:00'},
    {
      'sender': 'นางวันดี',
      'message': 'รบกวนรอหน้าซอยนะคะ มิ้วกำลังมา',
      'time': '07:10',
    },
    {'sender': 'ระบบ', 'message': 'ถึงโรงเรียนแล้ว', 'time': '07:45'},
  ];

  // Mock schedule
  static final List<Map<String, String>> mockSchedule = [
    {'period': 'รอบเช้า', 'pickup': '07:00', 'dropoff': '08:00'},
    {'period': 'รอบเย็น', 'pickup': '15:30', 'dropoff': '17:00'},
  ];

  // Helper: find AppUser by ID
  static AppUser? findAppUserById(String appUserId) {
    final allUsers = [...parentUsers, ...teacherUsers, ...driverUsers];
    try {
      return allUsers.firstWhere((u) => u.id == appUserId);
    } catch (_) {
      return null;
    }
  }
}

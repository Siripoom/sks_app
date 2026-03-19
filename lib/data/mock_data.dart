import 'package:sks/models/bus.dart';
import 'package:sks/models/child.dart';
import 'package:sks/models/driver.dart';
import 'package:sks/models/school.dart';

class MockData {
  static final School school = School(
    id: 'school_01',
    name: 'Demo School Riverside',
    lat: 13.7563,
    lng: 100.5018,
    address: '123 Rama IV Road, Bangkok 10500',
    morningPickup: '07:00',
    morningDropoff: '08:00',
    eveningPickup: '15:30',
    eveningDropoff: '17:00',
  );

  static final List<Driver> drivers = [
    const Driver(
      id: 'driver_01',
      name: 'Somchai Meesuk',
      phone: '0812345001',
      busId: 'bus_01',
      licenseNumber: '9876543210001',
    ),
  ];

  static final List<Bus> buses = [
    Bus(
      id: 'bus_01',
      busNumber: 'Bus 01',
      driverId: 'driver_01',
      schoolId: '',
      childIds: const ['child_01', 'child_02'],
      licensePlate: 'GG-1234',
      status: BusStatus.enRoute,
      currentLat: 13.7900,
      currentLng: 100.5500,
      estimatedArrival: DateTime.now().add(const Duration(minutes: 15)),
    ),
  ];

  static final List<Child> children = [
    Child(
      id: 'child_01',
      name: 'Kong Rukluk',
      parentId: 'parent_01',
      tripId: 'trip_01',
      schoolId: 'school_01',
      busId: 'bus_01',
      homeAddress: '456 Ladprao 1, Bangkok',
      pickupLabel: '456 Ladprao 1, Bangkok',
      pickupLat: 13.7900,
      pickupLng: 100.5500,
      qrCodeValue: 'SKS-CHILD-01',
      schoolName: school.name,
      gradeLevel: 'P1',
      emergencyContactName: 'Mali Rukluk',
      emergencyContactPhone: '0812345101',
      hasBoarded: true,
    ),
    Child(
      id: 'child_02',
      name: 'Kaew Rukluk',
      parentId: 'parent_01',
      tripId: 'trip_01',
      schoolId: 'school_01',
      busId: 'bus_01',
      homeAddress: '456 Ladprao 1, Bangkok',
      pickupLabel: '456 Ladprao 1, Bangkok',
      pickupLat: 13.7901,
      pickupLng: 100.5499,
      qrCodeValue: 'SKS-CHILD-02',
      schoolName: school.name,
      gradeLevel: 'P3',
      emergencyContactName: 'Mali Rukluk',
      emergencyContactPhone: '0812345101',
    ),
  ];

  static final List<Map<String, String>> notificationHistory = [
    {
      'type': 'arrived',
      'message': 'Kong Rukluk arrived at school',
      'time': '08:00',
    },
    {
      'type': 'boarded',
      'message': 'Kong Rukluk ขึ้นรถแล้ว',
      'time': '07:15',
    },
  ];
}

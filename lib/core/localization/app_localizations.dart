// ignore_for_file: equal_keys_in_map

import 'package:flutter/material.dart';
import 'package:sks/core/constants/app_strings.dart';

class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const supportedLocales = <Locale>[Locale('th'), Locale('en')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localization = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localization != null, 'AppLocalizations not found in context');
    return localization!;
  }

  bool get isEnglish => locale.languageCode == 'en';

  String tr(String key) {
    final languageMap = isEnglish ? _english : _thai;
    return languageMap[key] ?? key;
  }

  String trArgs(String key, Map<String, String> arguments) {
    var value = tr(key);
    arguments.forEach((placeholder, replacement) {
      value = value.replaceAll('{$placeholder}', replacement);
    });
    return value;
  }

  static final Map<String, String> _english = {
    AppStrings.appTitle: 'Shuttle Tracking',
    AppStrings.selectRole: 'Select role',
    AppStrings.roleParent: 'Parent',
    AppStrings.roleTeacher: 'Teacher',
    AppStrings.roleDriver: 'Driver',
    AppStrings.selectUser: 'Select user',
    AppStrings.enter: 'Enter',
    AppStrings.selectUserHint: 'Please select a user',
    AppStrings.myChildren: 'My children',
    AppStrings.addChild: 'Add child',
    AppStrings.childName: 'Child name',
    AppStrings.homeAddress: 'Home address',
    AppStrings.selectBus: 'Select bus',
    AppStrings.save: 'Save',
    AppStrings.trackBus: 'Track bus',
    AppStrings.notificationHistory: 'Notification history',
    AppStrings.childDetail: 'Child details',
    AppStrings.busStatus: 'Bus status',
    AppStrings.estimatedArrival: 'Estimated arrival',
    AppStrings.teacherHome: 'Home',
    AppStrings.allBuses: 'All buses',
    AppStrings.busCount: 'Buses',
    AppStrings.arrivedCount: 'Arrived',
    AppStrings.childrenOnBus: 'Children on bus',
    AppStrings.childRoster: 'Child roster',
    AppStrings.boarded: 'Boarded',
    AppStrings.notYetBoarded: 'Not boarded yet',
    AppStrings.parentName: 'Parent name',
    AppStrings.driverHome: 'Driver account',
    AppStrings.assignedBus: 'Assigned bus',
    AppStrings.totalChildren: 'Total children',
    AppStrings.childrenBoarded: 'Boarded',
    AppStrings.startRoute: 'Start route',
    AppStrings.viewChildList: 'View child list',
    AppStrings.boardingScreen: 'Child check-in',
    AppStrings.markArrived: 'Arrived at school',
    AppStrings.boardedStatus: 'Boarded',
    AppStrings.notBoarded: 'Not boarded',
    AppStrings.busWaiting: 'Waiting',
    AppStrings.busEnRoute: 'En route',
    AppStrings.busArrived: 'Arrived',
    AppStrings.back: 'Back',
    AppStrings.close: 'Close',
    AppStrings.loading: 'Loading...',
    AppStrings.error: 'Error',
    AppStrings.ok: 'OK',
    AppStrings.cancel: 'Cancel',
    AppStrings.noData: 'No data',
    AppStrings.emptyList: 'No data',
    AppStrings.currentLocation: 'Current location',
    AppStrings.school: 'School',
    AppStrings.busLocation: 'Bus location',
    AppStrings.driverName: 'Driver name',
    AppStrings.busNumber: 'Bus number',
    AppStrings.arrivedAtSchool: 'Your child arrived at school',
    AppStrings.arrivedWithBus: 'Bus {busNumber} arrived at school',
    AppStrings.childBoarded: '{childName} boarded the bus',
    AppStrings.childAlighted: '{childName} got off the bus',
    AppStrings.logout: 'Log out',
    AppStrings.backToRoleSelection: 'Back to role selection',
    AppStrings.loginTitle: 'Log in',
    AppStrings.email: 'Email',
    AppStrings.password: 'Password',
    AppStrings.loginButton: 'Log in',
    AppStrings.loginFailed: 'Incorrect email or password',
    AppStrings.testAccounts: 'Test accounts',
    AppStrings.smartKidsShuttle: 'SmartKids Shuttle',
    AppStrings.tabHome: 'Home',
    AppStrings.tabSchedule: 'Schedule',
    AppStrings.tabMyKids: 'My kids',
    AppStrings.tabSettings: 'Settings',
    AppStrings.welcomeGreeting: 'Hello',
    AppStrings.arrivingIn: 'Arriving in',
    AppStrings.minutes: 'minutes',
    AppStrings.pickUp: 'Pick up',
    AppStrings.notifications: 'Notifications',
    AppStrings.busSchedule: 'Bus schedule',
    AppStrings.morningRound: 'Morning round',
    AppStrings.afternoonRound: 'Afternoon round',
    AppStrings.notificationPreferences: 'Notification preferences',
    AppStrings.language: 'Language',
    AppStrings.tabStudents: 'Students',
    AppStrings.tabMessages: 'Messages',
    AppStrings.tabDrivers: 'Driver',
    AppStrings.morningTrip: 'Morning trip',
    AppStrings.routeNumber: 'Route',
    AppStrings.goodMorning: 'Good morning! Drive safely.',
    AppStrings.startTrip: 'Start trip',
    AppStrings.endTrip: 'End trip',
    AppStrings.inTransit: 'In transit...',
    AppStrings.checkedIn: 'Checked in',
    AppStrings.seeAll: 'See all',
    AppStrings.pickUpAction: 'Pick up',
    AppStrings.licensePlate: 'License plate',
    AppStrings.messages: 'Messages',
    AppStrings.driverProfile: 'Driver profile',
    AppStrings.otherDrivers: 'Other drivers',
    AppStrings.teacherDashboard: 'Teacher dashboard',
    AppStrings.pickupStatus: 'Pickup status',
    AppStrings.buses: 'buses',
    AppStrings.students: 'students',
    AppStrings.minuteShort: 'min',
    AppStrings.driverLabel: 'Driver:',
    AppStrings.register: 'Register',
    AppStrings.createParentAccount: 'Create parent account',
    AppStrings.firstName: 'First name',
    AppStrings.lastName: 'Last name',
    AppStrings.phoneNumber: 'Phone number',
    AppStrings.confirmPassword: 'Confirm password',
    AppStrings.next: 'Next',
    AppStrings.alreadyHaveAccount: 'Already have an account?',
    AppStrings.noAccount: 'No account yet?',
    AppStrings.registerSuccess: 'Registration successful',
    AppStrings.emailAlreadyExists: 'This email is already in use',
    AppStrings.fieldRequired: 'Please fill in the information',
    AppStrings.invalidEmail: 'Invalid email format',
    AppStrings.invalidPhone: 'Please enter a 10-digit phone number',
    AppStrings.passwordTooShort: 'Password must be at least 6 characters',
    AppStrings.passwordsDoNotMatch: 'Passwords do not match',
    AppStrings.privacyAndTerms: 'Privacy and terms',
    AppStrings.privacyPolicyTitle: 'Privacy policy',
    AppStrings.termsOfServiceTitle: 'Terms of service',
    AppStrings.acceptTerms: 'I accept the privacy policy and terms of service',
    AppStrings.acceptAndRegister: 'Accept and register',
    AppStrings.privacyPolicyContent: 'SmartKids Shuttle privacy policy',
    AppStrings.termsOfServiceContent: 'SmartKids Shuttle terms of service',
    AppStrings.mapSection: 'Map',
    AppStrings.todayTrip: "Today's trip",
    AppStrings.studentStatus: 'Student status',
    AppStrings.todayPickupHistory: "Today's pickup history",
    AppStrings.callDriver: 'Call driver',
    AppStrings.driverPhoneFallback: 'Driver phone {phone}',
    AppStrings.readyTrackToday: 'Ready to track your child\'s trip today',
    AppStrings.noMapToday: 'No map is available for today',
    AppStrings.noTripToday: 'No trip has been assigned for today',
    AppStrings.noStudentData: 'No student data yet',
    AppStrings.noHistoryToday: 'No pickup history for today yet',
    AppStrings.waitingForRoute: 'Waiting for route assignment',
    AppStrings.arrivedAtSchoolStatus: 'Arrived at school',
    AppStrings.waitingToBoard: 'Waiting to board',
    AppStrings.boardingTime: 'Time',
    AppStrings.noServiceToday: 'No shuttle service today',
    AppStrings.pickupLocation: 'Pickup location',
    AppStrings.pickupLocationHint: 'Tap to choose a location from the map',
    AppStrings.pendingAssignmentHint:
        'A new child will be added as pending until an admin assigns a route.',
    AppStrings.childPhoto: 'Child photo',
    AppStrings.photoHelperEmpty:
        'Choose a photo from the gallery to show on the child profile.',
    AppStrings.photoHelperFilled:
        'A photo is selected. You can change or remove it.',
    AppStrings.selectPhoto: 'Choose photo',
    AppStrings.changePhoto: 'Change photo',
    AppStrings.removePhoto: 'Remove photo',
    AppStrings.requiredCompleteForm: 'Please complete all required fields',
    AppStrings.childAddedSuccess:
        'Child added successfully. Waiting for route assignment.',
    AppStrings.schoolName: 'School name',
    AppStrings.gradeLevel: 'Grade level',
    AppStrings.emergencyContactName: 'Emergency contact name',
    AppStrings.emergencyContactPhone: 'Emergency contact phone',
    AppStrings.profilePhoto: 'Profile photo',
    AppStrings.changeProfilePhoto: 'Change profile photo',
    AppStrings.removeProfilePhoto: 'Remove profile photo',
    AppStrings.languageThai: 'Thai',
    AppStrings.languageEnglish: 'English',
    AppStrings.languageUpdated: 'Language updated',
    AppStrings.teacherSettings: 'Teacher settings',
    AppStrings.contactAdmin: 'Contact admin',
    AppStrings.reportIssue: 'Report an issue',
    AppStrings.adminSupportTitle: 'Contact or report to admin',
    AppStrings.adminSupportSubtitle:
        'Send a message or issue report to the admin team',
    AppStrings.issueType: 'Issue type',
    AppStrings.issueSubject: 'Subject',
    AppStrings.issueDetail: 'Details',
    AppStrings.senderContact: 'Sender contact',
    AppStrings.submitIssue: 'Send to admin',
    AppStrings.issueSubmitted: 'Your message was sent to the admin',
    AppStrings.generalQuestion: 'General question',
    AppStrings.incidentReport: 'Incident report',
    AppStrings.technicalProblem: 'Technical problem',
    AppStrings.supportHint: 'Describe what you need help with',
    AppStrings.subjectHint: 'Enter a short subject',
    AppStrings.selectIssueType: 'Select issue type',
  };

  static final Map<String, String> _thai = {
    AppStrings.roleAdmin: 'แอดมิน',
    AppStrings.welcome: 'ยินดีต้อนรับ',
    AppStrings.welcomeSubtitle: 'ปลอดภัย มองเห็นได้ ทุกระยะทาง',
    AppStrings.startupFirebaseIncomplete: 'การตั้งค่า Firebase ยังไม่สมบูรณ์',
    AppStrings.startupFirebaseDescription:
        'โค้ดชุดนี้เชื่อมต่อ Firebase Auth, Firestore, Storage และ Messaging แล้ว โดย Android และ iOS ถูกตั้งค่าสำหรับโปรเจกต์ sks-app-d980c ส่วน Web ยังต้องใช้ FlutterFire config ที่สร้างจริงหากต้องการรองรับบนเบราว์เซอร์',
    AppStrings.startupErrorLabel: 'ข้อผิดพลาดตอนเริ่มต้น:',
    AppStrings.startupUnknownError: 'ไม่ทราบข้อผิดพลาดในการเริ่มต้น Firebase',
    AppStrings.startupWebHint:
        'หากปัญหานี้เกิดบน Web ให้ใส่ FlutterFire config ที่สร้างจริง หรือ --dart-define สำหรับค่า FIREBASE_WEB_* ที่ใช้ใน lib/firebase_options.dart',
    AppStrings.selectedLocationLabel: 'ตำแหน่งที่เลือก',
    AppStrings.choosePickupLocation: 'เลือกตำแหน่งรับส่ง',
    AppStrings.mapPickerHint: 'แตะบนแผนที่หรือลากหมุดเพื่อเลือกจุดรับส่ง',
    AppStrings.confirmThisLocation: 'ยืนยันตำแหน่งนี้',
    AppStrings.scanQrCode: 'สแกน QR Code',
    AppStrings.qrScannerHint: 'เล็งกล้องไปที่ QR ของนักเรียนเพื่อเช็กอิน',
    AppStrings.qrNotAssignedMessage:
        'QR นี้ไม่ใช่นักเรียนในสายรถที่คุณรับผิดชอบ',
    AppStrings.qrStudentNotFound: 'ไม่พบข้อมูลนักเรียนจาก QR นี้',
    AppStrings.unableUpdateBoarding: 'ไม่สามารถอัปเดตสถานะขึ้นรถได้',
    AppStrings.checkedInSuccess: 'เช็กอิน {name} สำเร็จ',
    AppStrings.alreadyCheckedIn: '{name} เช็กอินแล้ว',
    AppStrings.boardingConfirmed: 'ยืนยัน {name} ขึ้นรถแล้ว',
    AppStrings.boardingCanceled: 'ยกเลิกสถานะขึ้นรถของ {name} แล้ว',
    AppStrings.confirmArrivalTitle: 'ยืนยันการมาถึง',
    AppStrings.confirmArrivalMessage: 'รถของคุณถึงโรงเรียนแล้วใช่หรือไม่?',
    AppStrings.arrivalMarked: 'ทำเครื่องหมายว่าถึงโรงเรียนแล้ว',
    AppStrings.checkedInAlready: 'เช็กอินแล้ว',
    AppStrings.waitingForQrScan: 'รอสแกน QR',
    AppStrings.confirmBoarding: 'ยืนยันขึ้นรถ',
    AppStrings.cancelBoarding: 'ยกเลิกขึ้นรถ',
    AppStrings.busLabel: 'รถ',
    AppStrings.schoolLabel: 'โรงเรียน',
    AppStrings.gradeLabel: 'ระดับชั้น',
    AppStrings.phoneLabel: 'โทร',
    AppStrings.childrenLabel: 'นักเรียน',
    AppStrings.licenseLabel: 'ใบอนุญาต',
    AppStrings.plateLabel: 'ทะเบียน',
    AppStrings.tripLabel: 'ทริป',
    AppStrings.notAssigned: 'ยังไม่กำหนด',
    AppStrings.cannotTrackBusUntilAssigned:
        'จะติดตามรถได้เมื่อมีการกำหนดสายรถแล้ว',
    AppStrings.selectedCoordinates: 'ตำแหน่ง: {lat}, {lng}',
    AppStrings.noNotifications: 'ไม่มีการแจ้งเตือน',
    AppStrings.qrForBoarding: 'QR สำหรับเช็กขึ้นรถ',
    AppStrings.busArrivedAt: 'ถึงโรงเรียนเวลา {time}',
    AppStrings.busStartedRoute: 'รถ {bus} ออกเดินทางแล้ว',
    AppStrings.waitingAdminAssignment: 'รอการกำหนดสายรถจากแอดมิน',
    AppStrings.assignmentNoticeHint:
        'เมื่อมีการกำหนดสายรถแล้ว ระบบจะแจ้งในหน้านี้',
    AppStrings.studentIdLabel: 'นักเรียน {id}',
    AppStrings.passengerCount: '{count} คน',
    AppStrings.adminWorkspace: 'พื้นที่จัดการแอดมิน',
    AppStrings.dashboard: 'ภาพรวม',
    AppStrings.people: 'ผู้ใช้งาน',
    AppStrings.fleet: 'ยานพาหนะ',
    AppStrings.assignments: 'การจัดทริป',
    AppStrings.operationsSnapshot: 'สรุปการดำเนินงาน',
    AppStrings.activeBusesWithDriver: 'รถที่มีคนขับประจำ',
    AppStrings.archivedRecords: 'ข้อมูลที่เก็บถาวร',
    AppStrings.assignedStudentsLabel: 'นักเรียนที่ถูกจัดทริปแล้ว',
    AppStrings.managePeopleSubtitle: 'จัดการผู้ปกครอง ครู และคนขับ',
    AppStrings.manageStudentsSubtitle:
        'จัดการข้อมูลนักเรียนและผู้ปกครอง',
    AppStrings.manageFleetSubtitle:
        'จัดการรถและการผูกคนขับกับรถ',
    AppStrings.pendingTripAssignments: 'นักเรียนที่รอจัดทริป',
    AppStrings.allActiveStudentsAssigned:
        'นักเรียนที่ยังใช้งานอยู่ถูกจัดทริปครบแล้ว',
    AppStrings.noAssignedStudentsYet: 'ยังไม่มีนักเรียนที่ถูกจัดทริป',
    AppStrings.add: 'เพิ่ม',
    AppStrings.search: 'ค้นหา',
    AppStrings.showArchived: 'แสดงรายการที่เก็บถาวร',
    AppStrings.active: 'ใช้งานอยู่',
    AppStrings.archived: 'เก็บถาวร',
    AppStrings.edit: 'แก้ไข',
    AppStrings.assign: 'จัดทริป',
    AppStrings.reassign: 'จัดใหม่',
    AppStrings.assignTrip: 'กำหนดทริป',
    AppStrings.remove: 'นำออก',
    AppStrings.restore: 'กู้คืน',
    AppStrings.archive: 'เก็บถาวร',
    AppStrings.nameLabel: 'ชื่อ',
    AppStrings.parentLabel: 'ผู้ปกครอง',
    AppStrings.latLabel: 'ละติจูด',
    AppStrings.lngLabel: 'ลองจิจูด',
    AppStrings.qrCodeLabel: 'QR code',
    AppStrings.licenseNumberLabel: 'เลขใบอนุญาต',
    AppStrings.initialPassword: 'รหัสผ่านเริ่มต้น',
    AppStrings.newPasswordOptional: 'รหัสผ่านใหม่ (ถ้าแก้ไข)',
    AppStrings.unassignedBus: 'ยังไม่ผูกรถ',
    AppStrings.unassignedDriver: 'ยังไม่ผูกคนขับ',
    AppStrings.unassignedLabel: 'ยังไม่กำหนด',
    AppStrings.unknownParent: 'ไม่ทราบผู้ปกครอง',
    AppStrings.createUserTitle: 'สร้าง{entity}',
    AppStrings.editUserTitle: 'แก้ไข{entity}',
    AppStrings.createStudentTitle: 'สร้างนักเรียน',
    AppStrings.editStudentTitle: 'แก้ไขนักเรียน',
    AppStrings.createBusTitle: 'สร้างรถ',
    AppStrings.editBusTitle: 'แก้ไขรถ',
    AppStrings.assignStudentTitle: 'จัดทริปให้ {name}',
    AppStrings.saveChanges: 'บันทึกการเปลี่ยนแปลง',
    AppStrings.saveAssignment: 'บันทึกการจัดทริป',
    AppStrings.createdEntitySuccess: 'สร้าง{entity}สำเร็จ',
    AppStrings.updatedEntitySuccess: 'อัปเดต{entity}สำเร็จ',
    AppStrings.archivedEntitySuccess: 'เก็บถาวร{entity}สำเร็จ',
    AppStrings.restoredEntitySuccess: 'กู้คืน{entity}สำเร็จ',
    AppStrings.removeFromTripSuccess: 'นำ {name} ออกจากทริปแล้ว',
    AppStrings.tripAssignmentUpdated: 'อัปเดตการจัดทริปแล้ว',
    AppStrings.unableSaveUser: 'ไม่สามารถบันทึกข้อมูลผู้ใช้ได้',
    AppStrings.unableSaveStudent: 'ไม่สามารถบันทึกข้อมูลนักเรียนได้',
    AppStrings.unableSaveBus: 'ไม่สามารถบันทึกข้อมูลรถได้',
    AppStrings.unableAssignChildToTrip: 'ไม่สามารถจัดทริปให้นักเรียนได้',
    AppStrings.unableRemoveChildFromTrip: 'ไม่สามารถนำเด็กออกจากทริปได้',
    AppStrings.unableUpdateArchiveState:
        'ไม่สามารถอัปเดตสถานะการเก็บถาวรได้',
    AppStrings.unableUpdateStudentArchiveState:
        'ไม่สามารถอัปเดตสถานะเก็บถาวรของนักเรียนได้',
    AppStrings.unableUpdateBusArchiveState:
        'ไม่สามารถอัปเดตสถานะเก็บถาวรของรถได้',
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String tr(String key) => l10n.tr(key);

  String trArgs(String key, Map<String, String> arguments) =>
      l10n.trArgs(key, arguments);
}

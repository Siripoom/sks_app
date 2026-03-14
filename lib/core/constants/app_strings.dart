class AppStrings {
  // App Title
  static const String appTitle = 'ระบบติดตามรถรับส่ง';

  // Role Selection
  static const String selectRole = 'เลือกบทบาท';
  static const String roleParent = 'ผู้ปกครอง';
  static const String roleTeacher = 'ครู';
  static const String roleDriver = 'คนขับ';
  static const String selectUser = 'เลือกผู้ใช้';
  static const String enter = 'เข้าสู่ระบบ';
  static const String selectUserHint = 'กรุณาเลือกผู้ใช้';

  // Parent Screen
  static const String myChildren = 'บุตรหลานของฉัน';
  static const String addChild = 'เพิ่มลูก';
  static const String childName = 'ชื่อลูก';
  static const String homeAddress = 'ที่อยู่บ้าน';
  static const String selectBus = 'เลือกรถ';
  static const String save = 'บันทึก';
  static const String trackBus = 'ดูตำแหน่งรถ';
  static const String notificationHistory = 'ประวัติการแจ้งเตือน';
  static const String childDetail = 'รายละเอียดลูก';
  static const String busStatus = 'สถานะรถ';
  static const String estimatedArrival = 'เวลาถึงโรงเรียน';

  // Teacher Screen
  static const String teacherHome = 'หน้าหลัก';
  static const String allBuses = 'รถทั้งหมด';
  static const String busCount = 'รถ';
  static const String arrivedCount = 'ถึงแล้ว';
  static const String childrenOnBus = 'เด็กบนรถ';
  static const String childRoster = 'รายชื่อเด็ก';
  static const String boarded = 'ขึ้นรถแล้ว';
  static const String notYetBoarded = 'ยังไม่ขึ้น';
  static const String parentName = 'ชื่อผู้ปกครอง';

  // Driver Screen
  static const String driverHome = 'บัญชีคนขับ';
  static const String assignedBus = 'รถที่รับผิดชอบ';
  static const String totalChildren = 'เด็กรวม';
  static const String childrenBoarded = 'ขึ้นรถแล้ว';
  static const String startRoute = 'เริ่มเส้นทาง';
  static const String viewChildList = 'ดูรายชื่อเด็ก';
  static const String boardingScreen = 'เช็คอินเด็ก';
  static const String markArrived = 'ถึงโรงเรียน';
  static const String boardedStatus = 'ขึ้นรถแล้ว';
  static const String notBoarded = 'ยังไม่ขึ้น';

  // Bus Status
  static const String busWaiting = 'รอออก';
  static const String busEnRoute = 'กำลังมา';
  static const String busArrived = 'ถึงแล้ว';

  // General
  static const String back = 'ย้อนกลับ';
  static const String close = 'ปิด';
  static const String loading = 'กำลังโหลด...';
  static const String error = 'เกิดข้อผิดพลาด';
  static const String ok = 'ตกลง';
  static const String cancel = 'ยกเลิก';
  static const String noData = 'ไม่มีข้อมูล';
  static const String emptyList = 'ไม่มีข้อมูล';

  // Map & Location
  static const String currentLocation = 'ตำแหน่งปัจจุบัน';
  static const String school = 'โรงเรียน';
  static const String busLocation = 'ตำแหน่งรถ';
  static const String driverName = 'ชื่อคนขับ';
  static const String busNumber = 'เลขรถ';

  // Notifications
  static const String arrivedAtSchool = 'ลูกไปถึงโรงเรียนแล้ว';
  static const String arrivedWithBus = 'รถหมายเลข {busNumber} ถึงโรงเรียนแล้ว';
  static const String childBoarded = '{childName} ขึ้นรถแล้ว';
  static const String childAlighted = '{childName} ลงรถแล้ว';

  // Logout/Navigation
  static const String logout = 'ออกจากระบบ';
  static const String backToRoleSelection = 'กลับไปเลือกบทบาท';

  // Login Screen
  static const String loginTitle = 'เข้าสู่ระบบ';
  static const String email = 'อีเมล';
  static const String password = 'รหัสผ่าน';
  static const String loginButton = 'เข้าสู่ระบบ';
  static const String loginFailed = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
  static const String testAccounts = 'บัญชีทดสอบ';
  static const String smartKidsShuttle = 'SmartKids Shuttle';

  // Parent Tabs
  static const String tabHome = 'หน้าแรก';
  static const String tabSchedule = 'ตารางเวลา';
  static const String tabMyKids = 'ลูกของฉัน';
  static const String tabSettings = 'ตั้งค่า';
  static const String welcomeGreeting = 'สวัสดี';
  static const String arrivingIn = 'กำลังจะถึงบ้านใน';
  static const String minutes = 'นาที';
  static const String pickUp = 'รับลูก';
  static const String notifications = 'การแจ้งเตือน';
  static const String busSchedule = 'ตารางเวลารถ';
  static const String morningRound = 'รอบเช้า';
  static const String afternoonRound = 'รอบเย็น';
  static const String notificationPreferences = 'ตั้งค่าการแจ้งเตือน';
  static const String language = 'ภาษา';

  // Driver Tabs
  static const String tabStudents = 'นักเรียน';
  static const String tabMessages = 'ข้อความ';
  static const String tabDrivers = 'คนขับ';
  static const String morningTrip = 'รอบเช้า';
  static const String routeNumber = 'สาย';
  static const String goodMorning = 'สวัสดีตอนเช้า! ขับระวังนะ';
  static const String startTrip = 'เริ่มเดินทาง';
  static const String endTrip = 'จบเดินทาง';
  static const String inTransit = 'กำลังเดินทาง...';
  static const String checkedIn = 'เช็คอินแล้ว';
  static const String seeAll = 'ดูทั้งหมด';
  static const String pickUpAction = 'รับ';
  static const String licensePlate = 'ทะเบียนรถ';
  static const String messages = 'ข้อความ';
  static const String driverProfile = 'ข้อมูลคนขับ';
  static const String otherDrivers = 'คนขับอื่นๆ';

  // Teacher Dashboard
  static const String teacherDashboard = 'แดชบอร์ดครู';
  static const String pickupStatus = 'สถานะการรับ';
  static const String buses = 'คัน';
  static const String students = 'นักเรียน';
  static const String minuteShort = 'นาที';
  static const String driverLabel = 'คนขับ:';

  // Registration
  static const String register = 'สมัครสมาชิก';
  static const String createParentAccount = 'สร้างบัญชีผู้ปกครอง';
  static const String firstName = 'ชื่อจริง';
  static const String lastName = 'นามสกุล';
  static const String phoneNumber = 'เบอร์โทรศัพท์';
  static const String confirmPassword = 'ยืนยันรหัสผ่าน';
  static const String next = 'ถัดไป';
  static const String alreadyHaveAccount = 'มีบัญชีอยู่แล้ว?';
  static const String noAccount = 'ยังไม่มีบัญชี?';
  static const String registerSuccess = 'สมัครสมาชิกสำเร็จ';
  static const String emailAlreadyExists = 'อีเมลนี้ถูกใช้งานแล้ว';

  // Validation
  static const String fieldRequired = 'กรุณากรอกข้อมูล';
  static const String invalidEmail = 'รูปแบบอีเมลไม่ถูกต้อง';
  static const String invalidPhone = 'กรุณากรอกเบอร์โทรศัพท์ 10 หลัก';
  static const String passwordTooShort = 'รหัสผ่านต้องมีอย่างน้อย 4 ตัวอักษร';
  static const String passwordsDoNotMatch = 'รหัสผ่านไม่ตรงกัน';

  // Privacy & Terms
  static const String privacyAndTerms = 'นโยบายและเงื่อนไข';
  static const String privacyPolicyTitle = 'นโยบายความเป็นส่วนตัว';
  static const String termsOfServiceTitle = 'เงื่อนไขการใช้บริการ';
  static const String acceptTerms =
      'ฉันยอมรับนโยบายความเป็นส่วนตัวและเงื่อนไขการใช้บริการ';
  static const String acceptAndRegister = 'ยอมรับและสมัครสมาชิก';
  static const String privacyPolicyContent =
      'แอปพลิเคชัน SmartKids Shuttle เก็บรวบรวมข้อมูลส่วนบุคคลของท่าน'
      'เพื่อให้บริการติดตามรถรับส่งนักเรียน โดยมีรายละเอียดดังนี้\n\n'
      '1. ข้อมูลที่เก็บรวบรวม\n'
      '• ชื่อ-นามสกุล อีเมล และเบอร์โทรศัพท์ของผู้ปกครอง\n'
      '• ข้อมูลบุตรหลาน (ชื่อ ที่อยู่ สายรถ)\n'
      '• ข้อมูลตำแหน่งรถรับส่ง\n\n'
      '2. วัตถุประสงค์ในการใช้ข้อมูล\n'
      '• ติดตามตำแหน่งรถรับส่งนักเรียนแบบเรียลไทม์\n'
      '• แจ้งเตือนสถานะการรับ-ส่งบุตรหลาน\n'
      '• ติดต่อสื่อสารกับผู้ปกครองในกรณีฉุกเฉิน\n\n'
      '3. การเปิดเผยข้อมูล\n'
      '• ข้อมูลจะถูกแชร์กับโรงเรียนและคนขับรถเฉพาะที่จำเป็นต่อการให้บริการ\n'
      '• เราจะไม่เปิดเผยข้อมูลส่วนบุคคลแก่บุคคลภายนอก\n\n'
      '4. สิทธิ์ของท่าน\n'
      '• ท่านสามารถขอดู แก้ไข หรือลบข้อมูลส่วนบุคคลได้ตลอดเวลา\n'
      '• ท่านสามารถยกเลิกบัญชีได้โดยติดต่อผู้ดูแลระบบ';
  static const String termsOfServiceContent =
      'ข้อกำหนดและเงื่อนไขการใช้บริการ SmartKids Shuttle\n\n'
      '1. การใช้บริการ\n'
      '• บริการนี้มีไว้สำหรับผู้ปกครองนักเรียนเพื่อติดตามรถรับส่งเท่านั้น\n'
      '• ผู้ใช้ต้องให้ข้อมูลที่ถูกต้องและเป็นปัจจุบัน\n\n'
      '2. ความรับผิดชอบของผู้ใช้\n'
      '• รักษาความลับของรหัสผ่านและบัญชีผู้ใช้\n'
      '• แจ้งข้อมูลการเปลี่ยนแปลงที่อยู่หรือสายรถให้โรงเรียนทราบ\n'
      '• ไม่ใช้แอปพลิเคชันในทางที่ผิดกฎหมาย\n\n'
      '3. ข้อจำกัดความรับผิด\n'
      '• ข้อมูลตำแหน่งรถเป็นการประมาณและอาจมีความคลาดเคลื่อน\n'
      '• ระบบอาจมีการหยุดให้บริการชั่วคราวเพื่อบำรุงรักษา\n\n'
      '4. การยกเลิกบัญชี\n'
      '• ท่านสามารถยกเลิกบัญชีได้ตลอดเวลา\n'
      '• โรงเรียนขอสงวนสิทธิ์ในการระงับบัญชีที่ละเมิดเงื่อนไข';
}

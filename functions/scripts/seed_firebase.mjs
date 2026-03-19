import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import admin from 'firebase-admin';

const projectId = 'sks-app-d980c';
const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;

if (!serviceAccountPath) {
  console.error(
    'Missing FIREBASE_SERVICE_ACCOUNT_PATH. Point it to a service account JSON file.',
  );
  process.exit(1);
}

const absolutePath = path.resolve(serviceAccountPath);
const serviceAccount = JSON.parse(fs.readFileSync(absolutePath, 'utf8'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket:
    process.env.FIREBASE_STORAGE_BUCKET || `${projectId}.firebasestorage.app`,
});

const db = admin.firestore();
const auth = admin.auth();

const schools = [
  {
    id: 'school_01',
    name: 'Demo School Riverside',
    lat: 13.7563,
    lng: 100.5018,
    address: '123 Rama IV Road, Bangkok 10500',
    morningPickup: '07:00',
    morningDropoff: '08:00',
    eveningPickup: '15:30',
    eveningDropoff: '17:00',
    isArchived: false,
    archivedAt: null,
  },
  {
    id: 'school_02',
    name: 'Demo School Midtown',
    lat: 13.7308,
    lng: 100.5418,
    address: '88 Phetchaburi Road, Bangkok 10310',
    morningPickup: '06:45',
    morningDropoff: '07:45',
    eveningPickup: '15:45',
    eveningDropoff: '17:15',
    isArchived: false,
    archivedAt: null,
  },
];

const parents = [
  {
    id: 'parent_01',
    name: 'Mali Rukluk',
    phone: '0812345101',
    childIds: ['child_01', 'child_02'],
    schoolIds: ['school_01'],
    isArchived: false,
    archivedAt: null,
  },
  {
    id: 'parent_02',
    name: 'Somsak Pordee',
    phone: '0812345102',
    childIds: ['child_03'],
    schoolIds: ['school_02'],
    isArchived: false,
    archivedAt: null,
  },
  {
    id: 'parent_03',
    name: 'Wandee Jaidee',
    phone: '0812345103',
    childIds: ['child_04', 'child_05'],
    schoolIds: ['school_01', 'school_02'],
    isArchived: false,
    archivedAt: null,
  },
  {
    id: 'parent_04',
    name: 'Prayut Jaingam',
    phone: '0812345104',
    childIds: ['child_06'],
    schoolIds: ['school_02'],
    isArchived: false,
    archivedAt: null,
  },
];

const teachers = [
  {
    id: 'teacher_01',
    name: 'Teacher Somjai',
    schoolId: 'school_01',
    isArchived: false,
    archivedAt: null,
  },
  {
    id: 'teacher_02',
    name: 'Teacher Ratana',
    schoolId: 'school_01',
    isArchived: false,
    archivedAt: null,
  },
  {
    id: 'teacher_03',
    name: 'Teacher Napat',
    schoolId: 'school_02',
    isArchived: false,
    archivedAt: null,
  },
];

const drivers = [
  {
    id: 'driver_01',
    name: 'Somchai Meesuk',
    phone: '0812345001',
    busId: 'bus_01',
    licenseNumber: '9876543210001',
    schoolId: '',
    isArchived: false,
    archivedAt: null,
  },
  {
    id: 'driver_02',
    name: 'Somying Deejai',
    phone: '0812345002',
    busId: 'bus_02',
    licenseNumber: '9876543210002',
    schoolId: '',
    isArchived: false,
    archivedAt: null,
  },
  {
    id: 'driver_03',
    name: 'Prasert Sukjai',
    phone: '0812345003',
    busId: 'bus_03',
    licenseNumber: '9876543210003',
    schoolId: '',
    isArchived: false,
    archivedAt: null,
  },
];

const admins = [
  {
    id: 'admin_01',
    name: 'System Admin',
    schoolId: '',
    isArchived: false,
    archivedAt: null,
  },
];

const buses = [
  {
    id: 'bus_01',
    busNumber: 'Bus 01',
    driverId: 'driver_01',
    schoolId: '',
    childIds: ['child_01', 'child_02'],
    licensePlate: 'GG-1234',
    status: 'enRoute',
    currentLat: 13.79,
    currentLng: 100.55,
    estimatedArrival: new Date(Date.now() + 15 * 60 * 1000),
    isArchived: false,
    archivedAt: null,
  },
  {
    id: 'bus_02',
    busNumber: 'Bus 02',
    driverId: 'driver_02',
    schoolId: '',
    childIds: ['child_03', 'child_06'],
    licensePlate: 'KK-5678',
    status: 'waiting',
    currentLat: 13.72,
    currentLng: 100.58,
    estimatedArrival: null,
    isArchived: false,
    archivedAt: null,
  },
  {
    id: 'bus_03',
    busNumber: 'Bus 03',
    driverId: 'driver_03',
    schoolId: '',
    childIds: ['child_04', 'child_05'],
    licensePlate: 'CC-9012',
    status: 'arrived',
    currentLat: 13.7308,
    currentLng: 100.5418,
    estimatedArrival: null,
    isArchived: false,
    archivedAt: null,
  },
];

const children = [
  {
    id: 'child_01',
    name: 'Kong Rukluk',
    parentId: 'parent_01',
    tripId: 'trip_01',
    busId: 'bus_01',
    schoolId: 'school_01',
    homeAddress: '456 Ladprao 1, Bangkok',
    pickupLabel: '456 Ladprao 1, Bangkok',
    pickupLat: 13.79,
    pickupLng: 100.55,
    qrCodeValue: 'SKS-CHILD-01',
    photoUrl: '',
    schoolName: 'Demo School Riverside',
    gradeLevel: 'P1',
    emergencyContactName: 'Mali Rukluk',
    emergencyContactPhone: '0812345101',
    assignmentStatus: 'assigned',
    isArchived: false,
    archivedAt: null,
    hasBoarded: true,
    hasArrived: false,
  },
  {
    id: 'child_02',
    name: 'Kaew Rukluk',
    parentId: 'parent_01',
    tripId: 'trip_01',
    busId: 'bus_01',
    schoolId: 'school_01',
    homeAddress: '456 Ladprao 1, Bangkok',
    pickupLabel: '456 Ladprao 1, Bangkok',
    pickupLat: 13.7901,
    pickupLng: 100.5499,
    qrCodeValue: 'SKS-CHILD-02',
    photoUrl: '',
    schoolName: 'Demo School Riverside',
    gradeLevel: 'P3',
    emergencyContactName: 'Mali Rukluk',
    emergencyContactPhone: '0812345101',
    assignmentStatus: 'assigned',
    isArchived: false,
    archivedAt: null,
    hasBoarded: false,
    hasArrived: false,
  },
  {
    id: 'child_03',
    name: 'Big Pordee',
    parentId: 'parent_02',
    tripId: 'trip_02',
    busId: 'bus_02',
    schoolId: 'school_02',
    homeAddress: '789 Ramkhamhaeng, Bangkok',
    pickupLabel: '789 Ramkhamhaeng, Bangkok',
    pickupLat: 13.72,
    pickupLng: 100.58,
    qrCodeValue: 'SKS-CHILD-03',
    photoUrl: '',
    schoolName: 'Demo School Midtown',
    gradeLevel: 'P2',
    emergencyContactName: 'Somsak Pordee',
    emergencyContactPhone: '0812345102',
    assignmentStatus: 'assigned',
    isArchived: false,
    archivedAt: null,
    hasBoarded: true,
    hasArrived: false,
  },
  {
    id: 'child_04',
    name: 'Miew Jaidee',
    parentId: 'parent_03',
    tripId: 'trip_03',
    busId: 'bus_03',
    schoolId: 'school_01',
    homeAddress: '321 Sutthisan 1, Bangkok',
    pickupLabel: '321 Sutthisan 1, Bangkok',
    pickupLat: 13.77,
    pickupLng: 100.53,
    qrCodeValue: 'SKS-CHILD-04',
    photoUrl: '',
    schoolName: 'Demo School Riverside',
    gradeLevel: 'P5',
    emergencyContactName: 'Wandee Jaidee',
    emergencyContactPhone: '0812345103',
    assignmentStatus: 'assigned',
    isArchived: false,
    archivedAt: null,
    hasBoarded: true,
    hasArrived: true,
  },
  {
    id: 'child_05',
    name: 'Man Jaidee',
    parentId: 'parent_03',
    tripId: null,
    busId: null,
    schoolId: 'school_02',
    homeAddress: '321 Sutthisan 1, Bangkok',
    pickupLabel: '321 Sutthisan 1, Bangkok',
    pickupLat: 13.71,
    pickupLng: 100.56,
    qrCodeValue: 'SKS-CHILD-05',
    photoUrl: '',
    schoolName: 'Demo School Midtown',
    gradeLevel: 'P4',
    emergencyContactName: 'Wandee Jaidee',
    emergencyContactPhone: '0812345103',
    assignmentStatus: 'pending',
    isArchived: false,
    archivedAt: null,
    hasBoarded: false,
    hasArrived: false,
  },
  {
    id: 'child_06',
    name: 'Nam Jaingam',
    parentId: 'parent_04',
    tripId: 'trip_02',
    busId: 'bus_02',
    schoolId: 'school_02',
    homeAddress: '147 Sutthisan 5, Bangkok',
    pickupLabel: '147 Sutthisan 5, Bangkok',
    pickupLat: 13.7563,
    pickupLng: 100.5018,
    qrCodeValue: 'SKS-CHILD-06',
    photoUrl: '',
    schoolName: 'Demo School Midtown',
    gradeLevel: 'K3',
    emergencyContactName: 'Prayut Jaingam',
    emergencyContactPhone: '0812345104',
    assignmentStatus: 'assigned',
    isArchived: false,
    archivedAt: null,
    hasBoarded: false,
    hasArrived: false,
  },
];

const today = new Date();
const startOfToday = new Date(today.getFullYear(), today.getMonth(), today.getDate());

const trips = [
  {
    id: 'trip_01',
    schoolId: 'school_01',
    busId: 'bus_01',
    serviceDate: startOfToday,
    serviceDateKey: toDateKey(startOfToday),
    round: 'toSchool',
    scheduledStartAt: atTime(startOfToday, 7, 0),
    childIds: ['child_01', 'child_02'],
    status: 'active',
    isArchived: false,
    archivedAt: null,
    createdAt: new Date(),
    updatedAt: new Date(),
  },
  {
    id: 'trip_02',
    schoolId: 'school_02',
    busId: 'bus_02',
    serviceDate: startOfToday,
    serviceDateKey: toDateKey(startOfToday),
    round: 'toSchool',
    scheduledStartAt: atTime(startOfToday, 6, 45),
    childIds: ['child_03', 'child_06'],
    status: 'draft',
    isArchived: false,
    archivedAt: null,
    createdAt: new Date(),
    updatedAt: new Date(),
  },
  {
    id: 'trip_03',
    schoolId: 'school_01',
    busId: 'bus_03',
    serviceDate: startOfToday,
    serviceDateKey: toDateKey(startOfToday),
    round: 'toHome',
    scheduledStartAt: atTime(startOfToday, 15, 30),
    childIds: ['child_04'],
    status: 'completed',
    isArchived: false,
    archivedAt: null,
    createdAt: new Date(),
    updatedAt: new Date(),
  },
];

const accountSpecs = [
  {
    email: 'parent1@sks.com',
    password: '123456',
    role: 'parent',
    name: 'Mali Rukluk',
    referenceId: 'parent_01',
  },
  {
    email: 'parent2@sks.com',
    password: '123456',
    role: 'parent',
    name: 'Somsak Pordee',
    referenceId: 'parent_02',
  },
  {
    email: 'parent3@sks.com',
    password: '123456',
    role: 'parent',
    name: 'Wandee Jaidee',
    referenceId: 'parent_03',
  },
  {
    email: 'parent4@sks.com',
    password: '123456',
    role: 'parent',
    name: 'Prayut Jaingam',
    referenceId: 'parent_04',
  },
  {
    email: 'teacher1@sks.com',
    password: '123456',
    role: 'teacher',
    name: 'Teacher Somjai',
    referenceId: 'teacher_01',
  },
  {
    email: 'teacher2@sks.com',
    password: '123456',
    role: 'teacher',
    name: 'Teacher Ratana',
    referenceId: 'teacher_02',
  },
  {
    email: 'teacher3@sks.com',
    password: '123456',
    role: 'teacher',
    name: 'Teacher Napat',
    referenceId: 'teacher_03',
  },
  {
    email: 'driver1@sks.com',
    password: '123456',
    role: 'driver',
    name: 'Somchai Meesuk',
    referenceId: 'driver_01',
  },
  {
    email: 'driver2@sks.com',
    password: '123456',
    role: 'driver',
    name: 'Somying Deejai',
    referenceId: 'driver_02',
  },
  {
    email: 'driver3@sks.com',
    password: '123456',
    role: 'driver',
    name: 'Prasert Sukjai',
    referenceId: 'driver_03',
  },
  {
    email: 'admin@sks.com',
    password: '123456',
    role: 'admin',
    name: 'System Admin',
    referenceId: 'admin_01',
  },
];

const notifications = [
  {
    type: 'boarded',
    message: 'Kong Rukluk boarded Bus 01',
    sender: 'System',
    time: '07:10',
    targetParentId: 'parent_01',
    targetRole: 'parent',
    schoolId: 'school_01',
  },
  {
    type: 'arrived',
    message: 'Miew Jaidee arrived at Demo School Riverside',
    sender: 'System',
    time: '16:10',
    targetParentId: 'parent_03',
    targetRole: 'parent',
    schoolId: 'school_01',
  },
  {
    type: 'system',
    message: 'Bus 02 is preparing for Demo School Midtown',
    sender: 'System',
    time: '06:20',
    targetRole: 'teacher',
    schoolId: 'school_02',
  },
  {
    type: 'message',
    message: 'Morning route is ready to start',
    sender: 'System',
    time: '06:30',
    targetDriverId: 'driver_01',
  },
];

await seedCollection('schools', schools);
await seedCollection('parents', parents);
await seedCollection('teachers', teachers);
await seedCollection('drivers', drivers);
await seedCollection('admins', admins);
await seedCollection('buses', buses);
await seedCollection('children', children);
await seedCollection('trips', trips);
await seedNotifications();
await seedAuthUsers();

console.log('Firebase seed completed for project', projectId);

async function seedCollection(collectionName, items) {
  const batch = db.batch();
  for (const item of items) {
    const { id, ...data } = item;
    batch.set(db.collection(collectionName).doc(id), data, { merge: true });
  }
  await batch.commit();
}

async function seedNotifications() {
  for (const [index, notification] of notifications.entries()) {
    await db
      .collection('notifications')
      .doc(`seed_notification_${index + 1}`)
      .set(
        {
          ...notification,
          createdAt: notification.createdAt || new Date(),
        },
        { merge: true },
      );
  }
}

async function seedAuthUsers() {
  for (const spec of accountSpecs) {
    const userRecord = await ensureAuthUser(spec);
    await db
      .collection('app_users')
      .doc(userRecord.uid)
      .set(
        {
          name: spec.name,
          role: spec.role,
          referenceId: spec.referenceId,
          profilePhotoPath: '',
          email: spec.email,
          createdAt: new Date(),
          updatedAt: new Date(),
          isArchived: false,
          archivedAt: null,
        },
        { merge: true },
      );
    if (spec.role === 'admin') {
      await auth.setCustomUserClaims(userRecord.uid, { admin: true });
    }
  }
}

async function ensureAuthUser(spec) {
  try {
    const existing = await auth.getUserByEmail(spec.email);
    await auth.updateUser(existing.uid, {
      password: spec.password,
      displayName: spec.name,
    });
    return existing;
  } catch (error) {
    if (error.code !== 'auth/user-not-found') {
      throw error;
    }
  }

  return auth.createUser({
    email: spec.email,
    password: spec.password,
    displayName: spec.name,
  });
}

function atTime(date, hours, minutes) {
  const value = new Date(date);
  value.setHours(hours, minutes, 0, 0);
  return value;
}

function toDateKey(value) {
  return value.toISOString().slice(0, 10);
}

import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { getStorage } from 'firebase-admin/storage';
import { createHash } from 'node:crypto';
import { GoogleAuth } from 'google-auth-library';
import { greedyStopOrder } from './route_planning.js';

initializeApp();

const REGION = 'asia-southeast1';
const db = getFirestore();
const auth = getAuth();
const storage = getStorage();

export const pushNotificationOnCreate = onDocumentCreated(
  { document: 'notifications/{notificationId}', region: REGION },
  async (event) => {
    const payload = event.data?.data();
    if (!payload) return;
    const appUserIds = await resolveTargetAppUserIds(payload);
    if (appUserIds.length === 0) return;
    const tokenSnapshots = await Promise.all(
      appUserIds.map((uid) =>
        db.collection('app_users').doc(uid).collection('device_tokens').get(),
      ),
    );
    const tokens = tokenSnapshots
      .flatMap((snapshot) => snapshot.docs.map((doc) => doc.id))
      .filter(Boolean);
    if (tokens.length === 0) return;
    await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title: buildTitle(payload), body: payload.message ?? '' },
      data: {
        type: payload.type ?? '',
        message: payload.message ?? '',
        time: payload.time ?? '',
      },
      android: { priority: 'high' },
      apns: {
        headers: { 'apns-priority': '10' },
        payload: { aps: { sound: 'default' } },
      },
    });
  },
);

export const manageUser = onCall({ region: REGION, enforceAppCheck: false }, async (request) => {
  await assertAdmin(request);
  const { action, role } = request.data ?? {};
  if (!action || !role) throw new HttpsError('invalid-argument', 'Missing action or role.');
  if (action === 'create') return createManagedUser(request.data);
  if (action === 'update') return updateManagedUser(request.data);
  if (action === 'archive') return setManagedUserArchived(request.data, true);
  if (action === 'restore') return setManagedUserArchived(request.data, false);
  if (action === 'delete') return deleteManagedUser(request.data);
  throw new HttpsError('invalid-argument', `Unsupported action ${action}.`);
});

export const deleteOwnAccount = onCall({ region: REGION, enforceAppCheck: false }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Authentication is required.');

  const authTime = Number(request.auth.token?.auth_time || 0);
  if (!authTime || (Date.now() / 1000) - authTime > 300) {
    throw new HttpsError('failed-precondition', 'Please sign in again before deleting your account.');
  }

  const appUserRef = db.collection('app_users').doc(uid);
  const appUserSnap = await appUserRef.get();
  if (!appUserSnap.exists) throw new HttpsError('not-found', 'Account profile not found.');
  const appUser = appUserSnap.data() || {};
  const role = appUser.role || 'parent';
  const referenceId = appUser.referenceId || '';

  if (role === 'parent' && referenceId) await deleteParentData(referenceId);
  if (role === 'driver' && referenceId) await deleteDriverData(referenceId);
  if (role === 'teacher' && referenceId) await db.collection('teachers').doc(referenceId).delete();
  if (role === 'admin' && referenceId) await db.collection('admins').doc(referenceId).delete();

  await deleteNotificationsForRole(role, referenceId);
  await storage.bucket().deleteFiles({ prefix: `profile_photos/${uid}/` });
  try {
    await auth.deleteUser(uid);
  } catch (error) {
    if (error?.code !== 'auth/user-not-found') throw error;
  }
  await db.recursiveDelete(appUserRef);
  return { ok: true };
});

export const manageSchool = onCall({ region: REGION, enforceAppCheck: false }, async (request) => {
  await assertAdmin(request);
  const { action } = request.data ?? {};
  if (action === 'create' || action === 'update') return saveSchool(request.data);
  if (action === 'archive') return setSchoolArchived(request.data.id, true);
  if (action === 'restore') return setSchoolArchived(request.data.id, false);
  throw new HttpsError('invalid-argument', 'Unsupported school action.');
});

export const manageBus = onCall({ region: REGION, enforceAppCheck: false }, async (request) => {
  await assertAdmin(request);
  const { action } = request.data ?? {};
  if (action === 'create' || action === 'update') return saveBus(request.data);
  if (action === 'archive') return setBusArchived(request.data.id, true);
  if (action === 'restore') return setBusArchived(request.data.id, false);
  throw new HttpsError('invalid-argument', 'Unsupported bus action.');
});

export const manageChild = onCall({ region: REGION, enforceAppCheck: false }, async (request) => {
  await assertAdmin(request);
  const { action } = request.data ?? {};
  if (action === 'create' || action === 'update') return saveChild(request.data);
  if (action === 'archive') return setChildArchived(request.data.id, true);
  if (action === 'restore') return setChildArchived(request.data.id, false);
  throw new HttpsError('invalid-argument', 'Unsupported child action.');
});

export const manageTrip = onCall({ region: REGION, enforceAppCheck: false }, async (request) => {
  await assertAdmin(request);
  const { action } = request.data ?? {};
  if (action === 'calculateRoute') return calculateTripRoute(request.data);
  if (action === 'create' || action === 'update') return saveTrip(request.data);
  if (action === 'archive') return setTripArchived(request.data.id, true);
  if (action === 'restore') return setTripArchived(request.data.id, false);
  if (action === 'setStatus') return setTripStatus(request.data.id, request.data.status);
  throw new HttpsError('invalid-argument', 'Unsupported trip action.');
});

export const startDriverTrip = onCall({
  region: REGION,
  enforceAppCheck: false,
  timeoutSeconds: 120,
}, async (request) => startTripForDriver(request));

export const assignChildToTrip = onCall({ region: REGION, enforceAppCheck: false }, async (request) => {
  await assertAdmin(request);
  const { childId, tripId } = request.data ?? {};
  if (!childId || !tripId) throw new HttpsError('invalid-argument', 'Missing childId or tripId.');
  await assignChildToTripTx(childId, tripId);
  return { ok: true };
});

export const removeChildFromTrip = onCall({ region: REGION, enforceAppCheck: false }, async (request) => {
  await assertAdmin(request);
  const { childId } = request.data ?? {};
  if (!childId) throw new HttpsError('invalid-argument', 'Missing childId.');
  await removeChildFromTripTx(childId);
  return { ok: true };
});

async function createManagedUser(data) {
  const role = mustString(data.role, 'role');
  const name = mustString(data.name, 'name');
  const email = mustString(data.email, 'email');
  const password = mustPassword(data.password);
  const schoolId = role === 'teacher' ? mustString(data.schoolId, 'schoolId') : (data.schoolId || '');
  const referenceId = data.referenceId || `${role}_${db.collection('_').doc().id.slice(0, 8)}`;
  const userRecord = await auth.createUser({ email, password, displayName: name, disabled: false });
  await upsertRoleDocument({
    role,
    referenceId,
    name,
    email,
    phone: data.phone || '',
    licenseNumber: data.licenseNumber || '',
    schoolId,
    busId: data.busId || '',
    archived: false,
  });
  await db.collection('app_users').doc(userRecord.uid).set({
    name,
    role,
    referenceId,
    profilePhotoPath: '',
    email,
    createdAt: new Date(),
    updatedAt: new Date(),
    isArchived: false,
  }, { merge: true });
  if (role === 'admin') await auth.setCustomUserClaims(userRecord.uid, { admin: true });
  return { uid: userRecord.uid, referenceId };
}

async function updateManagedUser(data) {
  const role = mustString(data.role, 'role');
  const name = mustString(data.name, 'name');
  const schoolId = role === 'teacher' ? mustString(data.schoolId, 'schoolId') : (data.schoolId || '');
  const appUser = await resolveManagedAppUser(data);
  const updates = { displayName: name };
  if (data.email) updates.email = data.email;
  if (data.password) updates.password = mustPassword(data.password);
  await auth.updateUser(appUser.id, updates);
  await upsertRoleDocument({
    role,
    referenceId: appUser.referenceId,
    name,
    email: data.email || appUser.email || '',
    phone: data.phone || '',
    licenseNumber: data.licenseNumber || '',
    schoolId,
    busId: data.busId || '',
    archived: false,
  });
  await db.collection('app_users').doc(appUser.id).set({
    name,
    email: data.email || appUser.email || '',
    updatedAt: new Date(),
  }, { merge: true });
  return { ok: true };
}

async function setManagedUserArchived(data, archived) {
  const role = mustString(data.role, 'role');
  const appUser = await resolveManagedAppUser(data);
  await assertArchiveAllowed(role, appUser.referenceId);
  await auth.updateUser(appUser.id, { disabled: archived });
  if (role === 'admin') await auth.setCustomUserClaims(appUser.id, archived ? {} : { admin: true });
  const entityRef = roleCollection(role).doc(appUser.referenceId);
  await entityRef.set({ isArchived: archived, archivedAt: archived ? new Date() : null, updatedAt: new Date() }, { merge: true });
  await db.collection('app_users').doc(appUser.id).set({
    isArchived: archived,
    archivedAt: archived ? new Date() : null,
    updatedAt: new Date(),
  }, { merge: true });
  return { ok: true };
}

async function deleteManagedUser(data) {
  const role = mustString(data.role, 'role');
  const uid = mustString(data.uid, 'uid');
  const referenceId = mustString(data.referenceId, 'referenceId');
  if (!['parent', 'teacher', 'driver'].includes(role)) {
    throw new HttpsError('invalid-argument', `Unsupported role ${role}.`);
  }

  const appUserRef = db.collection('app_users').doc(uid);
  const entityRef = roleCollection(role).doc(referenceId);
  const [appUserSnap, entitySnap] = await Promise.all([
    appUserRef.get(),
    entityRef.get(),
  ]);

  if (!appUserSnap.exists) {
    let authUserExists = true;
    try {
      await auth.getUser(uid);
    } catch (error) {
      if (error?.code !== 'auth/user-not-found') throw error;
      authUserExists = false;
    }
    if (!authUserExists && !entitySnap.exists) return { ok: true };
    throw new HttpsError('not-found', 'Managed user account not found.');
  }

  const appUser = appUserSnap.data() || {};
  if (appUser.role !== role || appUser.referenceId !== referenceId) {
    throw new HttpsError('failed-precondition', 'Managed user reference does not match.');
  }

  await assertManagedUserDeleteAllowed(role, referenceId);
  await storage.bucket().deleteFiles({ prefix: `profile_photos/${uid}/` });
  try {
    await auth.deleteUser(uid);
  } catch (error) {
    if (error?.code !== 'auth/user-not-found') throw error;
  }

  // Delete the role document first so a partial failure can still be retried
  // using the authoritative app_users record.
  await entityRef.delete();
  await db.recursiveDelete(appUserRef);
  return { ok: true };
}

async function assertManagedUserDeleteAllowed(role, referenceId) {
  if (role === 'parent') {
    const childrenSnap = await db.collection('children')
      .where('parentId', '==', referenceId)
      .limit(1)
      .get();
    if (!childrenSnap.empty) {
      throw new HttpsError(
        'failed-precondition',
        'Parent still has students. Reassign or delete them first.',
      );
    }
  }
  if (role === 'driver') {
    const busesSnap = await db.collection('buses')
      .where('driverId', '==', referenceId)
      .limit(1)
      .get();
    if (!busesSnap.empty) {
      throw new HttpsError(
        'failed-precondition',
        'Driver is still assigned to a bus. Unassign the bus first.',
      );
    }
  }
}

async function saveSchool(data) {
  const schoolId = data.id || `school_${db.collection('_').doc().id.slice(0, 8)}`;
  const busLimit = mustNonNegativeInteger(data.busLimit, 'busLimit');
  const schoolRef = db.collection('schools').doc(schoolId);
  const busesQuery = db.collection('buses').where('schoolId', '==', schoolId);

  await db.runTransaction(async (tx) => {
    const [existingSnap, busesSnap] = await Promise.all([
      tx.get(schoolRef),
      tx.get(busesQuery),
    ]);
    const existing = existingSnap.exists ? existingSnap.data() : null;
    const activeBusCount = busesSnap.docs.filter((doc) => doc.data()?.isArchived !== true).length;
    if (busLimit < activeBusCount) {
      throw new HttpsError(
        'failed-precondition',
        `Bus limit cannot be lower than ${activeBusCount} active buses.`,
      );
    }

    const now = new Date();
    tx.set(schoolRef, {
      name: data.name || existing?.name || '',
      address: data.address || existing?.address || '',
      lat: coerceNumber(data.lat, existing?.lat ?? 0),
      lng: coerceNumber(data.lng, existing?.lng ?? 0),
      morningPickup: data.morningPickup || existing?.morningPickup || '',
      morningDropoff: data.morningDropoff || existing?.morningDropoff || '',
      eveningPickup: data.eveningPickup || existing?.eveningPickup || '',
      eveningDropoff: data.eveningDropoff || existing?.eveningDropoff || '',
      busLimit,
      fleetUpdatedAt: now,
      isArchived: existing?.isArchived || false,
      archivedAt: existing?.archivedAt || null,
      updatedAt: now,
    }, { merge: true });
  });
  return { ok: true, id: schoolId };
}

async function setSchoolArchived(schoolId, archived) {
  if (!schoolId) throw new HttpsError('invalid-argument', 'Missing school id.');
  if (archived) await assertArchiveAllowed('school', schoolId);
  await db.collection('schools').doc(schoolId).set({
    isArchived: archived,
    archivedAt: archived ? new Date() : null,
    updatedAt: new Date(),
  }, { merge: true });
  return { ok: true };
}

async function saveBus(data) {
  const busId = data.id || `bus_${db.collection('_').doc().id.slice(0, 8)}`;
  const nextSchoolId = mustString(data.schoolId, 'schoolId');
  await db.runTransaction(async (tx) => {
    const busRef = db.collection('buses').doc(busId);
    const existingSnap = await tx.get(busRef);
    const existing = existingSnap.exists ? existingSnap.data() : null;
    const previousDriverId = existing?.driverId || '';
    const previousSchoolId = existing?.schoolId || '';
    const nextDriverId = data.driverId || '';
    const nextSchoolRef = db.collection('schools').doc(nextSchoolId);
    const activeBusesQuery = db.collection('buses').where('schoolId', '==', nextSchoolId);
    const nextDriverRef = nextDriverId ? db.collection('drivers').doc(nextDriverId) : null;
    const previousSchoolRef = previousSchoolId && previousSchoolId !== nextSchoolId
      ? db.collection('schools').doc(previousSchoolId)
      : null;

    const nextSchoolSnap = await tx.get(nextSchoolRef);
    const activeBusesSnap = await tx.get(activeBusesQuery);
    const nextDriverSnap = nextDriverRef ? await tx.get(nextDriverRef) : null;
    const previousSchoolSnap = previousSchoolRef ? await tx.get(previousSchoolRef) : null;

    if (!nextSchoolSnap.exists || nextSchoolSnap.data()?.isArchived === true) {
      throw new HttpsError('failed-precondition', 'Selected school is unavailable.');
    }
    const willBeActive = existing?.isArchived !== true;
    const otherActiveBusCount = activeBusesSnap.docs.filter(
      (doc) => doc.id !== busId && doc.data()?.isArchived !== true,
    ).length;
    if (willBeActive) assertSchoolHasBusCapacity(nextSchoolSnap.data(), otherActiveBusCount);

    if (nextDriverId) {
      if (!nextDriverSnap.exists || nextDriverSnap.data()?.isArchived) {
        throw new HttpsError('failed-precondition', 'Assigned driver is unavailable.');
      }
    }

    const now = new Date();
    if (previousDriverId && previousDriverId !== nextDriverId) {
      tx.set(
        db.collection('drivers').doc(previousDriverId),
        { busId: '', updatedAt: now },
        { merge: true },
      );
    }
    if (nextDriverRef && nextDriverSnap) {
      const driverBusId = nextDriverSnap.data()?.busId || '';
      if (driverBusId && driverBusId !== busId) {
        tx.set(
          db.collection('buses').doc(driverBusId),
          { driverId: '', updatedAt: now },
          { merge: true },
        );
      }
      tx.set(nextDriverRef, { busId, updatedAt: now }, { merge: true });
    }
    tx.set(busRef, {
      busNumber: data.busNumber || existing?.busNumber || '',
      driverId: nextDriverId,
      schoolId: nextSchoolId,
      childIds: existing?.childIds || [],
      licensePlate: data.licensePlate || existing?.licensePlate || '',
      status: existing?.status || 'waiting',
      currentLat: coerceNumber(data.currentLat, existing?.currentLat ?? 0),
      currentLng: coerceNumber(data.currentLng, existing?.currentLng ?? 0),
      estimatedArrival: existing?.estimatedArrival || null,
      isArchived: existing?.isArchived || false,
      archivedAt: existing?.archivedAt || null,
      updatedAt: now,
    }, { merge: true });
    tx.set(nextSchoolRef, { fleetUpdatedAt: now }, { merge: true });
    if (previousSchoolRef && previousSchoolSnap?.exists) {
      tx.set(previousSchoolRef, { fleetUpdatedAt: now }, { merge: true });
    }
  });
  return { ok: true, id: busId };
}

async function setBusArchived(busId, archived) {
  if (!busId) throw new HttpsError('invalid-argument', 'Missing bus id.');
  if (archived) await assertArchiveAllowed('bus', busId);
  await db.runTransaction(async (tx) => {
    const busRef = db.collection('buses').doc(busId);
    const busSnap = await tx.get(busRef);
    if (!busSnap.exists) throw new HttpsError('not-found', 'Bus not found.');
    const bus = busSnap.data() || {};
    const schoolId = bus.schoolId || '';
    if (!archived && !schoolId) {
      throw new HttpsError(
        'failed-precondition',
        'Assign the bus to a school before restoring it.',
      );
    }

    const schoolRef = schoolId ? db.collection('schools').doc(schoolId) : null;
    const schoolSnap = schoolRef ? await tx.get(schoolRef) : null;
    const activeBusesSnap = !archived && schoolId
      ? await tx.get(db.collection('buses').where('schoolId', '==', schoolId))
      : null;

    if (!archived) {
      if (!schoolSnap?.exists || schoolSnap.data()?.isArchived === true) {
        throw new HttpsError('failed-precondition', 'Selected school is unavailable.');
      }
      const otherActiveBusCount = activeBusesSnap.docs.filter(
        (doc) => doc.id !== busId && doc.data()?.isArchived !== true,
      ).length;
      assertSchoolHasBusCapacity(schoolSnap.data(), otherActiveBusCount);
    }

    const now = new Date();
    tx.set(busRef, {
      isArchived: archived,
      archivedAt: archived ? now : null,
      updatedAt: now,
    }, { merge: true });
    if (schoolRef && schoolSnap?.exists) {
      tx.set(schoolRef, { fleetUpdatedAt: now }, { merge: true });
    }
  });
  return { ok: true };
}

function assertSchoolHasBusCapacity(school, otherActiveBusCount) {
  const busLimit = optionalNonNegativeInteger(school?.busLimit);
  if (busLimit !== null && otherActiveBusCount >= busLimit) {
    throw new HttpsError(
      'resource-exhausted',
      `School bus limit reached (${otherActiveBusCount}/${busLimit}).`,
    );
  }
}

async function saveChild(data) {
  const childId = data.id || db.collection('children').doc().id;
  const nextSchoolId = mustString(data.schoolId, 'schoolId');
  const schoolSnap = await db.collection('schools').doc(nextSchoolId).get();
  if (!schoolSnap.exists || schoolSnap.data()?.isArchived) {
    throw new HttpsError('failed-precondition', 'Selected school is unavailable.');
  }
  let touchedParentIds = [];
  await db.runTransaction(async (tx) => {
    const childRef = db.collection('children').doc(childId);
    const existingSnap = await tx.get(childRef);
    const existing = existingSnap.exists ? existingSnap.data() : null;
    const nextParentId = data.parentId || existing?.parentId || '';
    if (!nextParentId) throw new HttpsError('invalid-argument', 'Child must have a parent.');
    const parentRef = db.collection('parents').doc(nextParentId);
    const parentSnap = await tx.get(parentRef);
    if (!parentSnap.exists || parentSnap.data()?.isArchived) {
      throw new HttpsError('failed-precondition', 'Selected parent is unavailable.');
    }
    touchedParentIds = [nextParentId];
    if (existing?.parentId && existing.parentId !== nextParentId) {
      touchedParentIds.push(existing.parentId);
      tx.set(db.collection('parents').doc(existing.parentId), { childIds: FieldValue.arrayRemove([childId]) }, { merge: true });
    }
    tx.set(parentRef, { childIds: FieldValue.arrayUnion([childId]) }, { merge: true });
    tx.set(childRef, {
      name: data.name || existing?.name || '',
      parentId: nextParentId,
      tripId: existing?.tripId || null,
      busId: existing?.busId || null,
      busStopId: FieldValue.delete(),
      schoolId: nextSchoolId,
      homeAddress: data.homeAddress || existing?.homeAddress || '',
      pickupLabel: data.pickupLabel || existing?.pickupLabel || '',
      pickupLat: data.pickupLat ?? existing?.pickupLat ?? null,
      pickupLng: data.pickupLng ?? existing?.pickupLng ?? null,
      qrCodeValue: existing?.qrCodeValue || `SKS-CHILD-${childId.toUpperCase()}`,
      photoUrl: data.photoUrl || existing?.photoUrl || '',
      schoolName: schoolSnap.data()?.name || data.schoolName || existing?.schoolName || '',
      gradeLevel: data.gradeLevel || existing?.gradeLevel || '',
      emergencyContactName: data.emergencyContactName || existing?.emergencyContactName || '',
      emergencyContactPhone: data.emergencyContactPhone || existing?.emergencyContactPhone || '',
      assignmentStatus: existing?.tripId || existing?.busId ? 'assigned' : 'pending',
      isArchived: existing?.isArchived || false,
      archivedAt: existing?.archivedAt || null,
      hasBoarded: existing?.hasBoarded || false,
      hasArrived: existing?.hasArrived || false,
      updatedAt: new Date(),
    }, { merge: true });
  });
  await Promise.all(touchedParentIds.map((parentId) => syncParentSchoolIds(parentId)));
  return { ok: true, id: childId };
}

async function setChildArchived(childId, archived) {
  if (!childId) throw new HttpsError('invalid-argument', 'Missing child id.');
  let parentId = '';
  await db.runTransaction(async (tx) => {
    const childRef = db.collection('children').doc(childId);
    const childSnap = await tx.get(childRef);
    if (!childSnap.exists) throw new HttpsError('not-found', 'Child not found.');
    const child = childSnap.data();
    parentId = child.parentId || '';
    if (archived) removeChildAssignmentInTransaction(tx, childId, child);
    tx.set(childRef, {
      isArchived: archived,
      archivedAt: archived ? new Date() : null,
      updatedAt: new Date(),
      hasBoarded: archived ? false : (child.hasBoarded || false),
      hasArrived: archived ? false : (child.hasArrived || false),
      assignmentStatus: archived ? 'pending' : (child.assignmentStatus || 'pending'),
      tripId: archived ? null : (child.tripId || null),
      busId: archived ? null : (child.busId || null),
      busStopId: FieldValue.delete(),
    }, { merge: true });
  });
  if (parentId) await syncParentSchoolIds(parentId);
  return { ok: true };
}

async function calculateTripRoute(data) {
  const inputs = await buildTripRouteInputs(data);
  const serviceDate = mustDate(data.serviceDate, 'serviceDate');
  await validateTripConflicts({
    tripId: typeof data.id === 'string' ? data.id : '',
    busId: inputs.busId,
    childIds: inputs.childIds,
    serviceDateKey: toDateKey(serviceDate),
    round: inputs.round,
  });
  const manual = data.manual === true;
  const calculated = manual
    ? buildManualRoute(inputs)
    : await optimizeTripRoute(inputs);
  return {
    ok: true,
    schoolIds: inputs.schoolIds,
    origin: inputs.origin,
    routePlan: {
      ...calculated,
      inputHash: inputs.inputHash,
      calculatedAt: new Date().toISOString(),
    },
  };
}

class RouteApiError extends Error {}

async function startTripForDriver(request) {
  const driverId = await assertDriver(request);
  const tripId = mustString(request.data?.tripId, 'tripId');
  const tripRef = db.collection('trips').doc(tripId);
  const tripSnap = await tripRef.get();
  if (!tripSnap.exists) throw new HttpsError('not-found', 'Trip not found.');
  const trip = tripSnap.data() || {};
  const busId = mustString(trip.busId, 'trip busId');
  const busRef = db.collection('buses').doc(busId);
  const busSnap = await busRef.get();
  assertDriverTripCanStart(trip, busSnap, driverId);

  if (trip.status === 'active') {
    return {
      ok: true,
      routeRecalculated: false,
      fallbackReason: '',
      alreadyActive: true,
    };
  }

  const origin = optionalRoutePoint(request.data?.origin);
  const routeVersion = Number(trip.routeVersion || 1);
  const sourceRevision = tripStartRevision(trip);
  let recalculated = null;
  let fallbackReason = '';

  if (routeVersion < 2) {
    fallbackReason = 'legacyTrip';
  } else if (!origin) {
    fallbackReason = 'locationUnavailable';
  } else {
    const serviceDate = firestoreDate(trip.serviceDate, 'serviceDate');
    const scheduledStartAt = trip.scheduledStartAt
      ? firestoreDate(trip.scheduledStartAt, 'scheduledStartAt')
      : null;
    const inputs = await buildTripRouteInputs({
      busId: trip.busId,
      round: trip.round,
      childIds: trip.childIds,
      serviceDate,
      scheduledStartAt,
      origin,
    });
    try {
      const routePlan = await optimizeGreedyTripRoute(inputs);
      recalculated = {
        schoolIds: inputs.schoolIds,
        origin: inputs.origin,
        stops: routePlan.stops,
        routePlan,
      };
    } catch (error) {
      if (!(error instanceof RouteApiError)) throw error;
      console.error('Driver route recalculation failed', error.message);
      fallbackReason = 'routeCalculationFailed';
    }
  }

  await db.runTransaction(async (tx) => {
    const [currentTripSnap, currentBusSnap] = await Promise.all([
      tx.get(tripRef),
      tx.get(busRef),
    ]);
    if (!currentTripSnap.exists) {
      throw new HttpsError('not-found', 'Trip not found.');
    }
    const currentTrip = currentTripSnap.data() || {};
    assertDriverTripCanStart(currentTrip, currentBusSnap, driverId);
    if (currentTrip.status === 'active') {
      throw new HttpsError('aborted', 'Trip was started by another request.');
    }
    if (tripStartRevision(currentTrip) !== sourceRevision) {
      throw new HttpsError(
        'aborted',
        'Trip details changed while the route was being calculated.',
      );
    }

    const now = FieldValue.serverTimestamp();
    const tripUpdate = {
      status: 'active',
      currentStopIndex: 0,
      startedAt: now,
      updatedAt: now,
    };
    if (recalculated) {
      tripUpdate.schoolId = FieldValue.delete();
      tripUpdate.schoolIds = recalculated.schoolIds;
      tripUpdate.origin = recalculated.origin;
      tripUpdate.stops = recalculated.stops;
      tripUpdate.routePlan = {
        provider: recalculated.routePlan.provider,
        metric: recalculated.routePlan.metric,
        inputHash: recalculated.routePlan.inputHash,
        distanceMeters: recalculated.routePlan.distanceMeters,
        durationSeconds: recalculated.routePlan.durationSeconds,
        polylines: recalculated.routePlan.polylines,
        calculatedAt: now,
      };
    }
    tx.set(tripRef, tripUpdate, { merge: true });

    const busUpdate = {
      status: 'enRoute',
      updatedAt: now,
    };
    if (origin) {
      busUpdate.currentLat = origin.lat;
      busUpdate.currentLng = origin.lng;
    }
    tx.set(busRef, busUpdate, { merge: true });
  });

  return {
    ok: true,
    routeRecalculated: recalculated !== null,
    fallbackReason,
    alreadyActive: false,
  };
}

function assertDriverTripCanStart(trip, busSnap, driverId) {
  if (trip.isArchived === true) {
    throw new HttpsError('failed-precondition', 'Archived trips cannot be started.');
  }
  if (!['draft', 'active'].includes(trip.status || 'draft')) {
    throw new HttpsError(
      'failed-precondition',
      'Only draft trips can be started.',
    );
  }
  if (!Array.isArray(trip.stops) || trip.stops.length === 0) {
    throw new HttpsError('failed-precondition', 'Trip has no route stops.');
  }
  if (!busSnap.exists || busSnap.data()?.isArchived === true) {
    throw new HttpsError('failed-precondition', 'Assigned bus is unavailable.');
  }
  if (busSnap.data()?.driverId !== driverId) {
    throw new HttpsError(
      'permission-denied',
      'This trip is assigned to another driver.',
    );
  }
}

function tripStartRevision(trip) {
  return hashRouteInputs({
    busId: trip.busId || '',
    childIds: uniqueStrings(trip.childIds || []).sort(),
    round: trip.round || '',
    routeVersion: Number(trip.routeVersion || 1),
    status: trip.status || 'draft',
    updatedAt: firestoreDateMillis(trip.updatedAt),
  });
}

async function optimizeGreedyTripRoute(inputs) {
  let phaseOrigin = inputs.origin;
  const orderedStops = [];
  const accessToken = await getGoogleMapsAccessToken();
  const deadline = Date.now() + 75000;

  for (const phaseStops of inputs.phases) {
    if (phaseStops.length === 0) continue;
    let orderedPhase;
    try {
      const distances = await computeDrivingDistanceMatrix(
        phaseOrigin,
        phaseStops,
        accessToken,
        deadline,
      );
      orderedPhase = greedyStopOrder(phaseStops, distances);
    } catch (error) {
      if (error instanceof RouteApiError) throw error;
      throw new RouteApiError(error?.message || 'Unable to order route stops.');
    }
    orderedStops.push(...orderedPhase);
    phaseOrigin = orderedPhase[orderedPhase.length - 1];
  }

  const path = await computeFixedRoutePath(
    inputs.origin,
    orderedStops,
    accessToken,
    deadline,
  );
  return {
    provider: 'googleRoutesGreedy',
    metric: 'drivingDistance',
    inputHash: inputs.inputHash,
    distanceMeters: path.distanceMeters,
    durationSeconds: path.durationSeconds,
    polylines: path.polylines,
    stops: orderedStops.map((stop, sequence) =>
      materializeRouteStop(stop, sequence)
    ),
  };
}

async function computeDrivingDistanceMatrix(
  origin,
  stops,
  accessToken,
  deadline,
) {
  const origins = [origin, ...stops];
  const distances = origins.map(() =>
    stops.map(() => Number.POSITIVE_INFINITY)
  );
  const batchSize = 25;

  for (let originOffset = 0; originOffset < origins.length; originOffset += batchSize) {
    const originBatch = origins.slice(originOffset, originOffset + batchSize);
    for (let destinationOffset = 0; destinationOffset < stops.length; destinationOffset += batchSize) {
      const destinationBatch = stops.slice(
        destinationOffset,
        destinationOffset + batchSize,
      );
      const elements = await callRoutesApi(
        'https://routes.googleapis.com/distanceMatrix/v2:computeRouteMatrix',
        {
          origins: originBatch.map((point) => ({
            waypoint: routeWaypoint(point),
          })),
          destinations: destinationBatch.map((point) => ({
            waypoint: routeWaypoint(point),
          })),
          travelMode: 'DRIVE',
          routingPreference: 'TRAFFIC_UNAWARE',
        },
        accessToken,
        'originIndex,destinationIndex,status,condition,distanceMeters',
        deadline,
      );
      if (!Array.isArray(elements)) {
        throw new RouteApiError('Google returned an invalid route matrix.');
      }
      for (const element of elements) {
        const statusCode = Number(element.status?.code || 0);
        if (statusCode !== 0 || element.condition !== 'ROUTE_EXISTS') continue;
        const distance = Number(element.distanceMeters);
        if (!Number.isFinite(distance)) continue;
        const row = originOffset + Number(element.originIndex);
        const column = destinationOffset + Number(element.destinationIndex);
        if (distances[row] && column >= 0 && column < stops.length) {
          distances[row][column] = distance;
        }
      }
    }
  }
  return distances;
}

async function computeFixedRoutePath(origin, stops, accessToken, deadline) {
  const points = [origin, ...stops];
  const polylines = [];
  let distanceMeters = 0;
  let durationSeconds = 0;

  for (let startIndex = 0; startIndex < points.length - 1;) {
    const endIndex = Math.min(startIndex + 26, points.length - 1);
    const intermediates = points.slice(startIndex + 1, endIndex);
    const body = {
      origin: routeWaypoint(points[startIndex]),
      destination: routeWaypoint(points[endIndex]),
      travelMode: 'DRIVE',
      routingPreference: 'TRAFFIC_UNAWARE',
      polylineQuality: 'OVERVIEW',
    };
    if (intermediates.length > 0) {
      body.intermediates = intermediates.map(routeWaypoint);
    }
    const payload = await callRoutesApi(
      'https://routes.googleapis.com/directions/v2:computeRoutes',
      body,
      accessToken,
      'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline',
      deadline,
    );
    const route = payload?.routes?.[0];
    if (!route) throw new RouteApiError('Google returned no route path.');
    const polyline = route.polyline?.encodedPolyline;
    if (typeof polyline === 'string' && polyline) polylines.push(polyline);
    distanceMeters += Number(route.distanceMeters || 0);
    durationSeconds += parseGoogleDuration(route.duration);
    startIndex = endIndex;
  }

  return {
    polylines,
    distanceMeters: Math.round(distanceMeters),
    durationSeconds: Math.round(durationSeconds),
  };
}

async function getGoogleMapsAccessToken() {
  try {
    const authClient = await new GoogleAuth({
      scopes: ['https://www.googleapis.com/auth/cloud-platform'],
    }).getClient();
    const result = await authClient.getAccessToken();
    const token = typeof result === 'string' ? result : result?.token;
    if (!token) throw new Error('Missing access token.');
    return token;
  } catch (error) {
    throw new RouteApiError(
      error?.message || 'Unable to authenticate with Google Routes.',
    );
  }
}

async function callRoutesApi(url, body, accessToken, fieldMask, deadline) {
  const remainingMs = deadline - Date.now();
  if (remainingMs <= 0) {
    throw new RouteApiError('Driver route recalculation timed out.');
  }
  const controller = new AbortController();
  const timeout = setTimeout(
    () => controller.abort(),
    Math.min(20000, remainingMs),
  );
  let response;
  try {
    response = await fetch(url, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
        'X-Goog-FieldMask': fieldMask,
      },
      body: JSON.stringify(body),
      signal: controller.signal,
    });
  } catch (error) {
    throw new RouteApiError(
      error?.name === 'AbortError'
        ? 'Google Routes request timed out.'
        : 'Google Routes is temporarily unavailable.',
    );
  } finally {
    clearTimeout(timeout);
  }
  if (!response.ok) {
    const details = await response.text();
    console.error('Google Routes API error', response.status, details);
    throw new RouteApiError(`Google Routes request failed (${response.status}).`);
  }
  try {
    return await response.json();
  } catch {
    throw new RouteApiError('Google Routes returned an invalid response.');
  }
}

function routeWaypoint(point) {
  return {
    location: {
      latLng: {
        latitude: Number(point.lat),
        longitude: Number(point.lng),
      },
    },
  };
}

function firestoreDate(value, field) {
  const candidate = typeof value?.toDate === 'function' ? value.toDate() : value;
  return mustDate(candidate, field);
}

function firestoreDateMillis(value) {
  if (!value) return null;
  if (typeof value.toMillis === 'function') return value.toMillis();
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date.getTime();
}

async function saveTrip(data) {
  const tripId = data.id || `trip_${db.collection('_').doc().id.slice(0, 8)}`;
  const busId = mustString(data.busId, 'busId');
  const serviceDate = mustDate(data.serviceDate, 'serviceDate');
  const round = mustTripRound(data.round);
  const serviceDateKey = toDateKey(serviceDate);
  const childIds = uniqueStrings(data.childIds || []);
  if (childIds.length === 0) {
    throw new HttpsError('invalid-argument', 'Select at least one student.');
  }
  const scheduledStartAt = data.scheduledStartAt ? mustDate(data.scheduledStartAt, 'scheduledStartAt') : null;
  const inputs = await buildTripRouteInputs({
    ...data,
    busId,
    serviceDate,
    round,
    childIds,
    scheduledStartAt,
  });
  const routePlan = validateSubmittedRoutePlan(data.routePlan, inputs);

  await validateTripConflicts({ tripId, busId, childIds, serviceDateKey, round });
  const touchedParentIds = new Set();
  await db.runTransaction(async (tx) => {
    const tripRef = db.collection('trips').doc(tripId);
    const tripSnap = await tx.get(tripRef);
    const existing = tripSnap.exists ? tripSnap.data() : null;
    if (existing?.status === 'active') {
      throw new HttpsError('failed-precondition', 'An active trip cannot be edited.');
    }
    const existingChildIds = uniqueStrings(existing?.childIds || []);
    const removedChildIds = existingChildIds.filter((id) => !childIds.includes(id));

    const childSnaps = new Map();
    for (const childId of uniqueStrings([...removedChildIds, ...childIds])) {
      childSnaps.set(childId, await tx.get(db.collection('children').doc(childId)));
    }
    for (const childId of childIds) {
      const childSnap = childSnaps.get(childId);
      if (!childSnap?.exists || childSnap.data()?.isArchived === true) {
        throw new HttpsError('failed-precondition', 'Selected child is unavailable.');
      }
    }

    const now = new Date();
    tx.set(tripRef, {
      schoolId: FieldValue.delete(),
      schoolIds: inputs.schoolIds,
      busId,
      serviceDate,
      serviceDateKey,
      round,
      scheduledStartAt,
      childIds,
      origin: inputs.origin,
      routeVersion: 2,
      stops: routePlan.stops,
      routePlan: {
        provider: routePlan.provider,
        inputHash: routePlan.inputHash,
        distanceMeters: routePlan.distanceMeters,
        durationSeconds: routePlan.durationSeconds,
        polylines: routePlan.polylines,
        calculatedAt: routePlan.calculatedAt || now,
      },
      currentStopIndex: -1,
      status: existing?.status || 'draft',
      isArchived: existing?.isArchived || false,
      archivedAt: existing?.archivedAt || null,
      createdAt: existing?.createdAt || now,
      updatedAt: now,
    }, { merge: true });

    for (const childId of removedChildIds) {
      const childSnap = childSnaps.get(childId);
      if (!childSnap?.exists) continue;
      const child = childSnap.data();
      touchedParentIds.add(child.parentId || '');
      tx.set(childSnap.ref, {
        tripId: null,
        busId: null,
        busStopId: FieldValue.delete(),
        assignmentStatus: 'pending',
        hasBoarded: false,
        hasArrived: false,
        updatedAt: now,
      }, { merge: true });
    }
    for (const childId of childIds) {
      const childSnap = childSnaps.get(childId);
      const child = childSnap.data();
      touchedParentIds.add(child.parentId || '');
      tx.set(childSnap.ref, {
        tripId,
        busId,
        busStopId: FieldValue.delete(),
        assignmentStatus: 'assigned',
        hasBoarded: false,
        hasArrived: false,
        updatedAt: now,
      }, { merge: true });
    }
  });
  await Promise.all([...touchedParentIds].filter(Boolean).map((parentId) => syncParentSchoolIds(parentId)));
  return { ok: true, id: tripId };
}

async function buildTripRouteInputs(data) {
  const busId = mustString(data.busId, 'busId');
  const round = mustTripRound(data.round);
  const childIds = uniqueStrings(data.childIds || []);
  if (childIds.length === 0) {
    throw new HttpsError('invalid-argument', 'Select at least one student.');
  }
  const busRef = db.collection('buses').doc(busId);
  const childRefs = childIds.map((id) => db.collection('children').doc(id));
  const [busSnap, ...childSnaps] = await Promise.all([
    busRef.get(),
    ...childRefs.map((ref) => ref.get()),
  ]);
  if (!busSnap.exists || busSnap.data()?.isArchived === true) {
    throw new HttpsError('failed-precondition', 'Selected bus is unavailable.');
  }

  const children = childSnaps.map((snap, index) => {
    if (!snap.exists || snap.data()?.isArchived === true) {
      throw new HttpsError(
        'failed-precondition',
        `Student ${childIds[index]} is unavailable.`,
      );
    }
    const child = snap.data() || {};
    const schoolId = mustString(child.schoolId, `schoolId for ${child.name || childIds[index]}`);
    if (!validRouteCoordinatePair(child.pickupLat, child.pickupLng)) {
      throw new HttpsError(
        'failed-precondition',
        `Missing pickup coordinates for ${child.name || childIds[index]}.`,
      );
    }
    const lat = Number(child.pickupLat);
    const lng = Number(child.pickupLng);
    return {
      id: snap.id,
      name: child.name || snap.id,
      parentId: child.parentId || '',
      schoolId,
      pickupLabel: child.pickupLabel || child.homeAddress || child.name || snap.id,
      lat,
      lng,
    };
  });

  const schoolIds = uniqueStrings(children.map((child) => child.schoolId)).sort();
  const schoolSnaps = await Promise.all(
    schoolIds.map((id) => db.collection('schools').doc(id).get()),
  );
  const schools = schoolSnaps.map((snap, index) => {
    if (!snap.exists || snap.data()?.isArchived === true) {
      throw new HttpsError(
        'failed-precondition',
        `School ${schoolIds[index]} is unavailable.`,
      );
    }
    const school = snap.data() || {};
    if (!validRouteCoordinatePair(school.lat, school.lng)) {
      throw new HttpsError(
        'failed-precondition',
        `Missing coordinates for ${school.name || schoolIds[index]}.`,
      );
    }
    return {
      id: snap.id,
      name: school.name || snap.id,
      lat: Number(school.lat),
      lng: Number(school.lng),
    };
  });

  const bus = busSnap.data() || {};
  let origin = optionalRoutePoint(data.origin);
  if (!origin && validRouteCoordinatePair(bus.currentLat, bus.currentLng)) {
    origin = {
      lat: Number(bus.currentLat),
      lng: Number(bus.currentLng),
      label: `Bus ${bus.busNumber || busId} current location`,
    };
  }
  if (!origin && typeof bus.schoolId === 'string' && bus.schoolId) {
    const baseSchool = await db.collection('schools').doc(bus.schoolId).get();
    const base = baseSchool.data();
    if (baseSchool.exists && base?.isArchived !== true &&
        validRouteCoordinatePair(base?.lat, base?.lng)) {
      origin = {
        lat: Number(base.lat),
        lng: Number(base.lng),
        label: base.name || 'Bus base school',
      };
    }
  }
  if (!origin) {
    throw new HttpsError(
      'failed-precondition',
      'Choose a valid trip start location.',
    );
  }

  const homeStopsByKey = new Map();
  for (const child of children) {
    const key = `${child.lat.toFixed(5)},${child.lng.toFixed(5)}`;
    const existing = homeStopsByKey.get(key);
    if (existing) {
      existing.childIds.push(child.id);
      existing.childNames.push(child.name);
      existing.schoolIds = uniqueStrings([...existing.schoolIds, child.schoolId]).sort();
    } else {
      homeStopsByKey.set(key, {
        id: `home:${key}`,
        type: 'home',
        action: round === 'toSchool' ? 'pickup' : 'dropoff',
        childIds: [child.id],
        childNames: [child.name],
        schoolIds: [child.schoolId],
        schoolId: '',
        lat: child.lat,
        lng: child.lng,
        label: child.pickupLabel,
      });
    }
  }

  const childrenBySchool = new Map();
  for (const child of children) {
    const ids = childrenBySchool.get(child.schoolId) || [];
    ids.push(child.id);
    childrenBySchool.set(child.schoolId, ids);
  }
  const schoolStops = schools.map((school) => ({
    id: `school:${school.id}`,
    type: 'school',
    action: round === 'toSchool' ? 'dropoff' : 'pickup',
    childIds: childrenBySchool.get(school.id) || [],
    childNames: children
      .filter((child) => child.schoolId === school.id)
      .map((child) => child.name),
    schoolIds: [school.id],
    schoolId: school.id,
    lat: school.lat,
    lng: school.lng,
    label: school.name,
  }));
  const homeStops = [...homeStopsByKey.values()];
  const phases = round === 'toSchool'
    ? [homeStops, schoolStops]
    : [schoolStops, homeStops];
  const scheduledStartAt = data.scheduledStartAt
    ? mustDate(data.scheduledStartAt, 'scheduledStartAt')
    : mustDate(data.serviceDate || new Date(), 'serviceDate');
  const serviceDateKey = toDateKey(
    mustDate(data.serviceDate, 'serviceDate'),
  );
  const signature = {
    busId,
    round,
    serviceDateKey,
    scheduledStartAt: scheduledStartAt.toISOString(),
    origin,
    schoolIds,
    stops: phases.flat().map(routeStopSignature),
  };
  return {
    busId,
    round,
    childIds,
    children,
    schools,
    schoolIds,
    origin,
    phases,
    scheduledStartAt,
    inputHash: hashRouteInputs(signature),
  };
}

function buildManualRoute(inputs) {
  const stops = inputs.phases.flat().map((stop, sequence) =>
    materializeRouteStop(stop, sequence)
  );
  return {
    provider: 'manual',
    distanceMeters: null,
    durationSeconds: null,
    polylines: [],
    stops,
  };
}

async function optimizeTripRoute(inputs) {
  let phaseOrigin = inputs.origin;
  let phaseStart = inputs.scheduledStartAt;
  const orderedStops = [];
  const polylines = [];
  let distanceMeters = 0;
  let durationSeconds = 0;

  for (const phaseStops of inputs.phases) {
    if (phaseStops.length === 0) continue;
    const result = await optimizeRoutePhase(phaseStops, phaseOrigin, phaseStart);
    orderedStops.push(...result.stops);
    if (result.polyline) polylines.push(result.polyline);
    distanceMeters += result.distanceMeters;
    durationSeconds += result.durationSeconds;
    phaseOrigin = result.stops[result.stops.length - 1];
    phaseStart = new Date(phaseStart.getTime() + (result.durationSeconds * 1000));
  }
  return {
    provider: 'googleRouteOptimization',
    distanceMeters: Math.round(distanceMeters),
    durationSeconds: Math.round(durationSeconds),
    polylines,
    stops: orderedStops.map((stop, sequence) =>
      materializeRouteStop(stop, sequence)
    ),
  };
}

async function optimizeRoutePhase(stops, origin, scheduledStartAt) {
  const projectId = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT;
  if (!projectId) {
    throw new HttpsError(
      'failed-precondition',
      'Google Cloud project is not configured for route optimization.',
    );
  }
  const authClient = await new GoogleAuth({
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
  }).getClient();
  const accessTokenResult = await authClient.getAccessToken();
  const accessToken = typeof accessTokenResult === 'string'
    ? accessTokenResult
    : accessTokenResult?.token;
  if (!accessToken) {
    throw new HttpsError('internal', 'Unable to authenticate route optimization.');
  }

  const start = scheduledStartAt instanceof Date
    ? scheduledStartAt
    : new Date(scheduledStartAt);
  const end = new Date(start.getTime() + (12 * 60 * 60 * 1000));
  const requestBody = {
    populatePolylines: true,
    populateTransitionPolylines: false,
    considerRoadTraffic: true,
    model: {
      globalStartTime: start.toISOString(),
      globalEndTime: end.toISOString(),
      shipments: stops.map((stop) => ({
        label: stop.id,
        deliveries: [{
          arrivalLocation: {
            latitude: stop.lat,
            longitude: stop.lng,
          },
        }],
      })),
      vehicles: [{
        label: 'trip-bus',
        startLocation: {
          latitude: origin.lat,
          longitude: origin.lng,
        },
        costPerKilometer: 1,
        costPerHour: 1,
      }],
    },
  };

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 45000);
  let response;
  try {
    response = await fetch(
      `https://routeoptimization.googleapis.com/v1/projects/${projectId}/locations/global:optimizeTours`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestBody),
        signal: controller.signal,
      },
    );
  } catch (error) {
    throw new HttpsError(
      'unavailable',
      error?.name === 'AbortError'
        ? 'Route calculation timed out.'
        : 'Route calculation is temporarily unavailable.',
    );
  } finally {
    clearTimeout(timeout);
  }
  if (!response.ok) {
    const details = await response.text();
    console.error('Route Optimization API error', response.status, details);
    throw new HttpsError(
      response.status === 429 ? 'resource-exhausted' : 'unavailable',
      response.status === 429
        ? 'Route calculation quota has been reached.'
        : 'Google could not calculate this route.',
    );
  }
  const payload = await response.json();
  const route = payload.routes?.[0];
  if (!route || payload.skippedShipments?.length) {
    throw new HttpsError('failed-precondition', 'No feasible route was found.');
  }
  const ordered = (route.visits || []).map((visit) => {
    const stop = stops[visit.shipmentIndex];
    if (!stop) {
      throw new HttpsError('internal', 'Google returned an invalid stop order.');
    }
    return stop;
  });
  if (ordered.length !== stops.length) {
    throw new HttpsError('failed-precondition', 'The optimized route omitted a stop.');
  }
  return {
    stops: ordered,
    polyline: route.routePolyline?.points || '',
    distanceMeters: Number(route.metrics?.travelDistanceMeters || 0),
    durationSeconds: parseGoogleDuration(route.metrics?.totalDuration),
  };
}

function validateSubmittedRoutePlan(plan, inputs) {
  if (!plan || typeof plan !== 'object') {
    throw new HttpsError('failed-precondition', 'Calculate the route before saving.');
  }
  if (plan.inputHash !== inputs.inputHash) {
    throw new HttpsError(
      'failed-precondition',
      'Trip details changed. Recalculate the route before saving.',
    );
  }
  if (!['googleRouteOptimization', 'manual'].includes(plan.provider)) {
    throw new HttpsError('invalid-argument', 'Unsupported route provider.');
  }
  const submittedStops = Array.isArray(plan.stops) ? plan.stops : [];
  const canonicalById = new Map(
    inputs.phases.flat().map((stop) => [stop.id, stop]),
  );
  const expectedIds = [...canonicalById.keys()].sort();
  const submittedIds = submittedStops.map((stop) => stop?.id).sort();
  if (JSON.stringify(expectedIds) !== JSON.stringify(submittedIds)) {
    throw new HttpsError('failed-precondition', 'Route stops do not match selected students.');
  }
  let cursor = 0;
  const normalizedStops = [];
  for (const phase of inputs.phases) {
    const phaseIds = new Set(phase.map((stop) => stop.id));
    const submittedPhase = submittedStops.slice(cursor, cursor + phase.length);
    if (submittedPhase.some((stop) => !phaseIds.has(stop?.id))) {
      throw new HttpsError(
        'failed-precondition',
        'Manual route order cannot move stops between phases.',
      );
    }
    for (const stop of submittedPhase) {
      normalizedStops.push(
        materializeRouteStop(canonicalById.get(stop.id), normalizedStops.length),
      );
    }
    cursor += phase.length;
  }
  const calculatedAt = plan.calculatedAt
    ? new Date(plan.calculatedAt)
    : new Date();
  return {
    provider: plan.provider,
    inputHash: plan.inputHash,
    distanceMeters: Number.isFinite(plan.distanceMeters) ? plan.distanceMeters : null,
    durationSeconds: Number.isFinite(plan.durationSeconds) ? plan.durationSeconds : null,
    polylines: Array.isArray(plan.polylines)
      ? plan.polylines.filter((value) => typeof value === 'string')
      : [],
    calculatedAt: Number.isNaN(calculatedAt.getTime())
      ? new Date()
      : calculatedAt,
    stops: normalizedStops,
  };
}

function materializeRouteStop(stop, sequence) {
  return {
    id: stop.id,
    type: stop.type,
    action: stop.action,
    childId: stop.childIds[0] || '',
    childIds: [...stop.childIds],
    childName: stop.childNames.join(', '),
    childNames: [...stop.childNames],
    schoolId: stop.schoolId || '',
    schoolIds: [...stop.schoolIds],
    sequence,
    lat: stop.lat,
    lng: stop.lng,
    pickupLabel: stop.label,
    label: stop.label,
    status: 'pending',
    arrivedAt: null,
    pickedUpAt: null,
    completedAt: null,
  };
}

function routeStopSignature(stop) {
  return {
    id: stop.id,
    type: stop.type,
    action: stop.action,
    childIds: [...stop.childIds].sort(),
    schoolIds: [...stop.schoolIds].sort(),
    lat: Number(stop.lat.toFixed(6)),
    lng: Number(stop.lng.toFixed(6)),
  };
}

function hashRouteInputs(value) {
  return createHash('sha256').update(JSON.stringify(value)).digest('hex');
}

function optionalRoutePoint(value) {
  if (!value || typeof value !== 'object') return null;
  if (!validRouteCoordinatePair(value.lat, value.lng)) return null;
  return {
    lat: Number(value.lat),
    lng: Number(value.lng),
    label: typeof value.label === 'string' && value.label.trim()
      ? value.label.trim()
      : 'Custom start location',
  };
}

function validRouteCoordinatePair(lat, lng) {
  const parsedLat = Number(lat);
  const parsedLng = Number(lng);
  return Number.isFinite(parsedLat) &&
    Number.isFinite(parsedLng) &&
    parsedLat >= -90 && parsedLat <= 90 &&
    parsedLng >= -180 && parsedLng <= 180 &&
    !(parsedLat === 0 && parsedLng === 0);
}

function mustTripRound(value) {
  const round = mustString(value, 'round');
  if (!['toSchool', 'toHome'].includes(round)) {
    throw new HttpsError('invalid-argument', 'Unsupported trip round.');
  }
  return round;
}

function parseGoogleDuration(value) {
  if (typeof value !== 'string') return 0;
  const parsed = Number(value.replace(/s$/, ''));
  return Number.isFinite(parsed) ? parsed : 0;
}

async function setTripArchived(tripId, archived) {
  if (!tripId) throw new HttpsError('invalid-argument', 'Missing trip id.');
  const touchedParentIds = new Set();
  await db.runTransaction(async (tx) => {
    const tripRef = db.collection('trips').doc(tripId);
    const tripSnap = await tx.get(tripRef);
    if (!tripSnap.exists) throw new HttpsError('not-found', 'Trip not found.');
    const trip = tripSnap.data();
    const childIds = uniqueStrings(trip.childIds || []);
    if (archived) {
      for (const childId of childIds) {
        const childRef = db.collection('children').doc(childId);
        const childSnap = await tx.get(childRef);
        if (!childSnap.exists) continue;
        const child = childSnap.data();
        touchedParentIds.add(child.parentId || '');
        tx.set(childRef, {
          tripId: null,
          busId: null,
          busStopId: FieldValue.delete(),
          assignmentStatus: 'pending',
          hasBoarded: false,
          hasArrived: false,
          updatedAt: new Date(),
        }, { merge: true });
      }
      tx.set(tripRef, { childIds: [] }, { merge: true });
    }
    tx.set(tripRef, {
      isArchived: archived,
      archivedAt: archived ? new Date() : null,
      updatedAt: new Date(),
    }, { merge: true });
  });
  await Promise.all([...touchedParentIds].filter(Boolean).map((parentId) => syncParentSchoolIds(parentId)));
  return { ok: true };
}

async function setTripStatus(tripId, status) {
  if (!tripId || !status) throw new HttpsError('invalid-argument', 'Missing trip status payload.');
  await db.collection('trips').doc(tripId).set({ status, updatedAt: new Date() }, { merge: true });
  return { ok: true };
}

async function assignChildToTripTx(childId, tripId) {
  let parentId = '';
  await db.runTransaction(async (tx) => {
    const childRef = db.collection('children').doc(childId);
    const tripRef = db.collection('trips').doc(tripId);
    const [childSnap, tripSnap] = await Promise.all([tx.get(childRef), tx.get(tripRef)]);
    if (!childSnap.exists || !tripSnap.exists) {
      throw new HttpsError('not-found', 'Trip assignment target is missing.');
    }
    const child = childSnap.data();
    const trip = tripSnap.data();
    parentId = child.parentId || '';
    if (child.isArchived || trip.isArchived) {
      throw new HttpsError('failed-precondition', 'Archived records cannot be assigned.');
    }
    const tripSchoolIds = uniqueStrings(
      trip.schoolIds || (trip.schoolId ? [trip.schoolId] : []),
    );
    if (!tripSchoolIds.includes(child.schoolId || '')) {
      throw new HttpsError('failed-precondition', 'Child school does not match the trip school.');
    }
    removeChildAssignmentInTransaction(tx, childId, child);
    tx.set(tripRef, { childIds: FieldValue.arrayUnion([childId]) }, { merge: true });
    tx.set(childRef, {
      tripId,
      busId: trip.busId || null,
      busStopId: FieldValue.delete(),
      assignmentStatus: 'assigned',
      hasBoarded: false,
      hasArrived: false,
      updatedAt: new Date(),
    }, { merge: true });
  });
  if (parentId) await syncParentSchoolIds(parentId);
}

async function removeChildFromTripTx(childId) {
  let parentId = '';
  await db.runTransaction(async (tx) => {
    const childRef = db.collection('children').doc(childId);
    const childSnap = await tx.get(childRef);
    if (!childSnap.exists) throw new HttpsError('not-found', 'Child not found.');
    const child = childSnap.data();
    parentId = child.parentId || '';
    removeChildAssignmentInTransaction(tx, childId, child);
    tx.set(childRef, {
      tripId: null,
      busId: null,
      busStopId: FieldValue.delete(),
      assignmentStatus: 'pending',
      hasBoarded: false,
      hasArrived: false,
      updatedAt: new Date(),
    }, { merge: true });
  });
  if (parentId) await syncParentSchoolIds(parentId);
}

function removeChildAssignmentInTransaction(tx, childId, child) {
  if (child.tripId) {
    tx.set(db.collection('trips').doc(child.tripId), { childIds: FieldValue.arrayRemove([childId]) }, { merge: true });
  }
  if (child.busId) {
    tx.set(db.collection('buses').doc(child.busId), { childIds: FieldValue.arrayRemove([childId]) }, { merge: true });
  }
}

async function validateTripConflicts({ tripId, busId, childIds, serviceDateKey, round }) {
  const snapshot = await db.collection('trips').where('serviceDateKey', '==', serviceDateKey).where('round', '==', round).get();
  for (const doc of snapshot.docs) {
    if (doc.id === tripId) continue;
    const trip = doc.data();
    if (!tripIsOpen(trip)) continue;
    if ((trip.busId || '') === busId) {
      throw new HttpsError('failed-precondition', 'Selected bus already has an active trip in this round.');
    }
    if (uniqueStrings(trip.childIds || []).some((id) => childIds.includes(id))) {
      throw new HttpsError('failed-precondition', 'A selected student already belongs to another active trip in this round.');
    }
  }
}

async function syncParentSchoolIds(parentId) {
  const snapshot = await db.collection('children').where('parentId', '==', parentId).get();
  const schoolIds = snapshot.docs
    .map((doc) => doc.data())
    .filter((child) => !child.isArchived && typeof child.schoolId === 'string' && child.schoolId.trim())
    .map((child) => child.schoolId.trim())
    .filter((value, index, array) => array.indexOf(value) === index)
    .sort();
  await db.collection('parents').doc(parentId).set({ schoolIds, updatedAt: new Date() }, { merge: true });
}

async function deleteParentData(parentId) {
  const childrenSnap = await db.collection('children').where('parentId', '==', parentId).get();
  const children = childrenSnap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  const writer = db.bulkWriter();

  for (const child of children) {
    if (child.tripId) {
      writer.set(
        db.collection('trips').doc(child.tripId),
        { childIds: FieldValue.arrayRemove(child.id) },
        { merge: true },
      );
    }
    if (child.busId) {
      writer.set(
        db.collection('buses').doc(child.busId),
        { childIds: FieldValue.arrayRemove(child.id) },
        { merge: true },
      );
    }
    await storage.bucket().deleteFiles({ prefix: `child_photos/${child.id}/` });
    writer.delete(db.collection('children').doc(child.id));
  }
  writer.delete(db.collection('parents').doc(parentId));
  await writer.close();
}

async function deleteDriverData(driverId) {
  const busesSnap = await db.collection('buses').where('driverId', '==', driverId).get();
  const writer = db.bulkWriter();
  for (const bus of busesSnap.docs) {
    writer.update(bus.ref, {
      driverId: '',
      currentLat: 0,
      currentLng: 0,
      estimatedArrival: null,
      status: 'waiting',
      updatedAt: new Date(),
    });
  }
  writer.delete(db.collection('drivers').doc(driverId));
  await writer.close();
}

async function deleteNotificationsForRole(role, referenceId) {
  if (!referenceId) return;
  const field = role === 'parent' ? 'targetParentId' : role === 'driver' ? 'targetDriverId' : null;
  if (!field) return;
  const snapshot = await db.collection('notifications').where(field, '==', referenceId).get();
  const writer = db.bulkWriter();
  for (const doc of snapshot.docs) writer.delete(doc.ref);
  await writer.close();
}

async function assertArchiveAllowed(kind, referenceId) {
  switch (kind) {
    case 'parent': {
      const snapshot = await db.collection('children').where('parentId', '==', referenceId).get();
      if (snapshot.docs.some((doc) => !doc.data().isArchived)) {
        throw new HttpsError('failed-precondition', 'Parent still has active students.');
      }
      return;
    }
    case 'driver': {
      const snapshot = await db.collection('buses').where('driverId', '==', referenceId).get();
      if (snapshot.docs.some((doc) => !doc.data().isArchived)) {
        throw new HttpsError('failed-precondition', 'Driver is still linked to an active bus.');
      }
      return;
    }
    case 'bus': {
      const [childrenSnap, tripsSnap] = await Promise.all([
        db.collection('children').where('busId', '==', referenceId).get(),
        db.collection('trips').where('busId', '==', referenceId).get(),
      ]);
      if (childrenSnap.docs.some((doc) => !doc.data().isArchived)) {
        throw new HttpsError('failed-precondition', 'Bus still has active students assigned.');
      }
      if (tripsSnap.docs.some((doc) => tripIsOpen(doc.data()))) {
        throw new HttpsError('failed-precondition', 'Bus still has active trips.');
      }
      return;
    }
    case 'school': {
      const [teachersSnap, childrenSnap, legacyTripsSnap, multiSchoolTripsSnap] = await Promise.all([
        db.collection('teachers').where('schoolId', '==', referenceId).get(),
        db.collection('children').where('schoolId', '==', referenceId).get(),
        db.collection('trips').where('schoolId', '==', referenceId).get(),
        db.collection('trips').where('schoolIds', 'array-contains', referenceId).get(),
      ]);
      if (teachersSnap.docs.some((doc) => !doc.data().isArchived)) {
        throw new HttpsError('failed-precondition', 'School still has active teachers.');
      }
      if (childrenSnap.docs.some((doc) => !doc.data().isArchived)) {
        throw new HttpsError('failed-precondition', 'School still has active students.');
      }
      const tripDocs = new Map(
        [...legacyTripsSnap.docs, ...multiSchoolTripsSnap.docs]
          .map((doc) => [doc.id, doc]),
      );
      if ([...tripDocs.values()].some((doc) => tripIsOpen(doc.data()))) {
        throw new HttpsError('failed-precondition', 'School still has active trips.');
      }
      return;
    }
    default:
      return;
  }
}

async function upsertRoleDocument({ role, referenceId, name, phone, licenseNumber, schoolId, busId, archived }) {
  const ref = roleCollection(role).doc(referenceId);
  const common = {
    name,
    schoolId,
    isArchived: archived,
    archivedAt: archived ? new Date() : null,
    updatedAt: new Date(),
  };
  if (role === 'parent') {
    await ref.set({ ...common, phone, childIds: [], schoolIds: schoolId ? [schoolId] : [] }, { merge: true });
    return;
  }
  if (role === 'teacher') {
    await ref.set(common, { merge: true });
    return;
  }
  if (role === 'driver') {
    await ref.set({ ...common, phone, busId, licenseNumber }, { merge: true });
    return;
  }
  if (role === 'admin') {
    await ref.set(common, { merge: true });
    return;
  }
  throw new HttpsError('invalid-argument', `Unsupported role ${role}.`);
}

function roleCollection(role) {
  if (role === 'parent') return db.collection('parents');
  if (role === 'teacher') return db.collection('teachers');
  if (role === 'driver') return db.collection('drivers');
  if (role === 'admin') return db.collection('admins');
  throw new HttpsError('invalid-argument', `Unsupported role ${role}.`);
}

async function resolveManagedAppUser(data) {
  if (data.uid) {
    const direct = await db.collection('app_users').doc(data.uid).get();
    if (direct.exists) return { id: direct.id, ...direct.data() };
  }
  if (!data.referenceId || !data.role) throw new HttpsError('invalid-argument', 'Missing user reference.');
  const snapshot = await db.collection('app_users').where('referenceId', '==', data.referenceId).where('role', '==', data.role).limit(1).get();
  if (snapshot.empty) throw new HttpsError('not-found', 'Managed user account not found.');
  return { id: snapshot.docs[0].id, ...snapshot.docs[0].data() };
}

async function assertAdmin(request) {
  const authContext = request.auth;
  if (!authContext?.uid) throw new HttpsError('unauthenticated', 'Authentication is required.');
  if (authContext.token?.admin === true) return;
  const appUser = await db.collection('app_users').doc(authContext.uid).get();
  if (appUser.exists && appUser.data()?.role === 'admin' && appUser.data()?.isArchived !== true) return;
  throw new HttpsError('permission-denied', 'Admin access is required.');
}

async function assertDriver(request) {
  const authContext = request.auth;
  if (!authContext?.uid) {
    throw new HttpsError('unauthenticated', 'Authentication is required.');
  }
  const appUser = await db.collection('app_users').doc(authContext.uid).get();
  const data = appUser.data();
  if (!appUser.exists || data?.role !== 'driver' ||
      data?.isArchived === true || !data?.referenceId) {
    throw new HttpsError('permission-denied', 'Driver access is required.');
  }
  const driver = await db.collection('drivers').doc(data.referenceId).get();
  if (!driver.exists || driver.data()?.isArchived === true) {
    throw new HttpsError('permission-denied', 'Driver account is unavailable.');
  }
  return data.referenceId;
}

function mustString(value, field) {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new HttpsError('invalid-argument', `Missing ${field}.`);
  }
  return value.trim();
}

function mustNonNegativeInteger(value, field) {
  const parsed = typeof value === 'number' ? value : Number(value);
  if (!Number.isInteger(parsed) || parsed < 0) {
    throw new HttpsError(
      'invalid-argument',
      `${field} must be a non-negative integer.`,
    );
  }
  return parsed;
}

function optionalNonNegativeInteger(value) {
  if (value === null || value === undefined || value === '') return null;
  const parsed = typeof value === 'number' ? value : Number(value);
  return Number.isInteger(parsed) && parsed >= 0 ? parsed : null;
}

function mustPassword(value) {
  const password = mustString(value, 'password');
  if (password.length < 6) throw new HttpsError('invalid-argument', 'Password must be at least 6 characters.');
  return password;
}

function mustDate(value, field) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) throw new HttpsError('invalid-argument', `Missing ${field}.`);
  return date;
}

function coerceNumber(value, fallback = 0) {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function uniqueStrings(values) {
  return [...new Set((values || []).filter((value) => typeof value === 'string' && value.trim()).map((value) => value.trim()))];
}

function toDateKey(value) {
  const date = value instanceof Date ? value : new Date(value);
  return date.toISOString().slice(0, 10);
}

function tripIsOpen(trip) {
  return !trip.isArchived && trip.status !== 'completed' && trip.status !== 'cancelled';
}

async function resolveTargetAppUserIds(payload) {
  if (payload.targetParentId) {
    const parents = await db.collection('app_users').where('role', '==', 'parent').where('referenceId', '==', payload.targetParentId).get();
    return parents.docs.map((doc) => doc.id);
  }
  if (payload.targetDriverId) {
    const drivers = await db.collection('app_users').where('role', '==', 'driver').where('referenceId', '==', payload.targetDriverId).get();
    return drivers.docs.map((doc) => doc.id);
  }
  if (payload.targetRole === 'teacher' && payload.schoolId) {
    const teachers = await db.collection('teachers').where('schoolId', '==', payload.schoolId).get();
    const teacherIds = teachers.docs.map((doc) => doc.id);
    if (teacherIds.length === 0) return [];
    const users = await db.collection('app_users').where('role', '==', 'teacher').where('referenceId', 'in', teacherIds).get();
    return users.docs.map((doc) => doc.id);
  }
  return [];
}

function buildTitle(payload) {
  if (payload.type === 'arrived') return 'SmartKids Arrival';
  if (payload.type === 'boarded') return 'SmartKids Boarding';
  if (payload.type === 'trip_started') return 'SmartKids - รถออกเดินทาง';
  if (payload.type === 'bus_approaching') return 'SmartKids - รถใกล้ถึง';
  if (payload.type === 'child_skipped') return 'SmartKids - ข้ามจุดรับ';
  if (payload.type === 'message') return payload.sender || 'SmartKids Message';
  return 'SmartKids Notification';
}

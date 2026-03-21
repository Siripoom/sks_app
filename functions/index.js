import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

initializeApp();

const REGION = 'asia-southeast1';
const db = getFirestore();
const auth = getAuth();

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
  throw new HttpsError('invalid-argument', `Unsupported action ${action}.`);
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
  if (action === 'create' || action === 'update') return saveTrip(request.data);
  if (action === 'archive') return setTripArchived(request.data.id, true);
  if (action === 'restore') return setTripArchived(request.data.id, false);
  if (action === 'setStatus') return setTripStatus(request.data.id, request.data.status);
  throw new HttpsError('invalid-argument', 'Unsupported trip action.');
});

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

async function saveSchool(data) {
  const schoolId = data.id || `school_${db.collection('_').doc().id.slice(0, 8)}`;
  const schoolRef = db.collection('schools').doc(schoolId);
  const existingSnap = await schoolRef.get();
  const existing = existingSnap.exists ? existingSnap.data() : null;
  await schoolRef.set({
    name: data.name || existing?.name || '',
    address: data.address || existing?.address || '',
    lat: coerceNumber(data.lat, existing?.lat ?? 0),
    lng: coerceNumber(data.lng, existing?.lng ?? 0),
    morningPickup: data.morningPickup || existing?.morningPickup || '',
    morningDropoff: data.morningDropoff || existing?.morningDropoff || '',
    eveningPickup: data.eveningPickup || existing?.eveningPickup || '',
    eveningDropoff: data.eveningDropoff || existing?.eveningDropoff || '',
    isArchived: existing?.isArchived || false,
    archivedAt: existing?.archivedAt || null,
    updatedAt: new Date(),
  }, { merge: true });
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
  await db.runTransaction(async (tx) => {
    const busRef = db.collection('buses').doc(busId);
    const existingSnap = await tx.get(busRef);
    const existing = existingSnap.exists ? existingSnap.data() : null;
    const previousDriverId = existing?.driverId || '';
    const nextDriverId = data.driverId || '';
    if (previousDriverId && previousDriverId !== nextDriverId) {
      tx.set(db.collection('drivers').doc(previousDriverId), { busId: '' }, { merge: true });
    }
    if (nextDriverId) {
      const driverRef = db.collection('drivers').doc(nextDriverId);
      const driverSnap = await tx.get(driverRef);
      if (!driverSnap.exists || driverSnap.data()?.isArchived) {
        throw new HttpsError('failed-precondition', 'Assigned driver is unavailable.');
      }
      const driverBusId = driverSnap.data()?.busId || '';
      if (driverBusId && driverBusId !== busId) {
        tx.set(db.collection('buses').doc(driverBusId), { driverId: '' }, { merge: true });
      }
      tx.set(driverRef, { busId }, { merge: true });
    }
    tx.set(busRef, {
      busNumber: data.busNumber || existing?.busNumber || '',
      driverId: nextDriverId,
      schoolId: data.schoolId || existing?.schoolId || '',
      childIds: existing?.childIds || [],
      licensePlate: data.licensePlate || existing?.licensePlate || '',
      status: existing?.status || 'waiting',
      currentLat: coerceNumber(data.currentLat, existing?.currentLat ?? 0),
      currentLng: coerceNumber(data.currentLng, existing?.currentLng ?? 0),
      estimatedArrival: existing?.estimatedArrival || null,
      isArchived: existing?.isArchived || false,
      archivedAt: existing?.archivedAt || null,
      updatedAt: new Date(),
    }, { merge: true });
  });
  return { ok: true, id: busId };
}

async function setBusArchived(busId, archived) {
  if (!busId) throw new HttpsError('invalid-argument', 'Missing bus id.');
  if (archived) await assertArchiveAllowed('bus', busId);
  await db.collection('buses').doc(busId).set({
    isArchived: archived,
    archivedAt: archived ? new Date() : null,
    updatedAt: new Date(),
  }, { merge: true });
  return { ok: true };
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

async function saveTrip(data) {
  const tripId = data.id || `trip_${db.collection('_').doc().id.slice(0, 8)}`;
  const schoolId = mustString(data.schoolId, 'schoolId');
  const busId = mustString(data.busId, 'busId');
  const serviceDate = mustDate(data.serviceDate, 'serviceDate');
  const round = mustString(data.round, 'round');
  const serviceDateKey = toDateKey(serviceDate);
  const childIds = uniqueStrings(data.childIds || []);
  const scheduledStartAt = data.scheduledStartAt ? new Date(data.scheduledStartAt) : null;
  const [schoolSnap, busSnap] = await Promise.all([
    db.collection('schools').doc(schoolId).get(),
    db.collection('buses').doc(busId).get(),
  ]);
  if (!schoolSnap.exists || schoolSnap.data()?.isArchived) {
    throw new HttpsError('failed-precondition', 'Selected school is unavailable.');
  }
  if (!busSnap.exists || busSnap.data()?.isArchived) {
    throw new HttpsError('failed-precondition', 'Selected bus is unavailable.');
  }
  await validateTripConflicts({ tripId, schoolId, busId, childIds, serviceDateKey, round });
  const touchedParentIds = new Set();
  await db.runTransaction(async (tx) => {
    const tripRef = db.collection('trips').doc(tripId);
    const tripSnap = await tx.get(tripRef);
    const existing = tripSnap.exists ? tripSnap.data() : null;
    const existingChildIds = uniqueStrings(existing?.childIds || []);
    const removedChildIds = existingChildIds.filter((id) => !childIds.includes(id));
    tx.set(tripRef, {
      schoolId,
      busId,
      serviceDate,
      serviceDateKey,
      round,
      scheduledStartAt,
      childIds,
      status: existing?.status || 'draft',
      isArchived: existing?.isArchived || false,
      archivedAt: existing?.archivedAt || null,
      createdAt: existing?.createdAt || new Date(),
      updatedAt: new Date(),
    }, { merge: true });
    for (const childId of removedChildIds) {
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
    for (const childId of childIds) {
      const childRef = db.collection('children').doc(childId);
      const childSnap = await tx.get(childRef);
      if (!childSnap.exists || childSnap.data()?.isArchived) {
        throw new HttpsError('failed-precondition', 'Selected child is unavailable.');
      }
      const child = childSnap.data();
      if ((child.schoolId || '') !== schoolId) {
        throw new HttpsError('failed-precondition', 'Child school does not match the trip school.');
      }
      touchedParentIds.add(child.parentId || '');
      tx.set(childRef, {
        tripId,
        busId,
        busStopId: FieldValue.delete(),
        schoolId,
        schoolName: schoolSnap.data()?.name || child.schoolName || '',
        assignmentStatus: 'assigned',
        hasBoarded: false,
        hasArrived: false,
        updatedAt: new Date(),
      }, { merge: true });
    }
  });
  await Promise.all([...touchedParentIds].filter(Boolean).map((parentId) => syncParentSchoolIds(parentId)));
  return { ok: true, id: tripId };
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
    if ((child.schoolId || '') !== (trip.schoolId || '')) {
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
      schoolId: trip.schoolId || child.schoolId || '',
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

async function validateTripConflicts({ tripId, schoolId, busId, childIds, serviceDateKey, round }) {
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
    if ((trip.schoolId || '') !== schoolId) continue;
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
      const [teachersSnap, childrenSnap, tripsSnap] = await Promise.all([
        db.collection('teachers').where('schoolId', '==', referenceId).get(),
        db.collection('children').where('schoolId', '==', referenceId).get(),
        db.collection('trips').where('schoolId', '==', referenceId).get(),
      ]);
      if (teachersSnap.docs.some((doc) => !doc.data().isArchived)) {
        throw new HttpsError('failed-precondition', 'School still has active teachers.');
      }
      if (childrenSnap.docs.some((doc) => !doc.data().isArchived)) {
        throw new HttpsError('failed-precondition', 'School still has active students.');
      }
      if (tripsSnap.docs.some((doc) => tripIsOpen(doc.data()))) {
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

function mustString(value, field) {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new HttpsError('invalid-argument', `Missing ${field}.`);
  }
  return value.trim();
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

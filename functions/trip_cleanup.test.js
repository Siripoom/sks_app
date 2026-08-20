import assert from 'node:assert/strict';
import test from 'node:test';
import { buildTripDeletionPlan } from './trip_cleanup.js';

test('active trip cleanup resets linked children and every referenced bus', () => {
  const plan = buildTripDeletionPlan({
    tripId: 'trip_1',
    trip: {
      busId: 'bus_1',
      childIds: ['child_1'],
      status: 'active',
    },
    children: [
      { id: 'child_1', tripId: 'trip_1', busId: 'bus_1' },
      { id: 'child_2', tripId: 'trip_1', busId: 'bus_2' },
    ],
  });

  assert.deepEqual(plan, {
    childIdsToReset: ['child_1', 'child_2'],
    busChildRemovals: [
      { busId: 'bus_1', childIds: ['child_1', 'child_2'] },
      { busId: 'bus_2', childIds: ['child_2'] },
    ],
    activeBusId: 'bus_1',
  });
});

test('completed or archived trip cleanup does not reset the bus status', () => {
  const plan = buildTripDeletionPlan({
    tripId: 'trip_1',
    trip: {
      busId: 'bus_1',
      childIds: ['child_1'],
      status: 'completed',
      isArchived: true,
    },
    children: [{ id: 'child_1', tripId: null, busId: 'bus_1' }],
  });

  assert.deepEqual(plan.childIdsToReset, ['child_1']);
  assert.equal(plan.activeBusId, '');
});

test('stale trip child list does not clear a child assigned to another trip', () => {
  const plan = buildTripDeletionPlan({
    tripId: 'trip_1',
    trip: {
      busId: 'bus_1',
      childIds: ['child_moved'],
      status: 'draft',
    },
    children: [
      { id: 'child_moved', tripId: 'trip_2', busId: 'bus_2' },
    ],
  });

  assert.deepEqual(plan.childIdsToReset, []);
  assert.deepEqual(plan.busChildRemovals, []);
});

test('child query result catches a child missing from trip childIds', () => {
  const plan = buildTripDeletionPlan({
    tripId: 'trip_1',
    trip: { busId: 'bus_1', childIds: [], status: 'cancelled' },
    children: [{ id: 'child_orphan', tripId: 'trip_1', busId: 'bus_1' }],
  });

  assert.deepEqual(plan.childIdsToReset, ['child_orphan']);
});

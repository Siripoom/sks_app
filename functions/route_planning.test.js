import assert from 'node:assert/strict';
import test from 'node:test';
import { greedyStopOrder } from './route_planning.js';

test('greedyStopOrder selects the nearest stop from each current point', () => {
  const stops = [{ id: 'a' }, { id: 'b' }, { id: 'c' }];
  const distances = [
    [30, 10, 20],
    [0, 5, 7],
    [5, 0, 3],
    [2, 9, 0],
  ];

  assert.deepEqual(
    greedyStopOrder(stops, distances).map((stop) => stop.id),
    ['b', 'c', 'a'],
  );
});

test('greedyStopOrder uses stop id as a deterministic distance tie-breaker', () => {
  const stops = [{ id: 'school-b' }, { id: 'school-a' }];
  const distances = [
    [100, 100],
    [0, 25],
    [25, 0],
  ];

  assert.deepEqual(
    greedyStopOrder(stops, distances).map((stop) => stop.id),
    ['school-a', 'school-b'],
  );
});

test('greedyStopOrder rejects an unreachable remaining stop', () => {
  const stops = [{ id: 'a' }, { id: 'b' }];
  const distances = [
    [10, Number.POSITIVE_INFINITY],
    [0, Number.POSITIVE_INFINITY],
    [10, 0],
  ];

  assert.throws(
    () => greedyStopOrder(stops, distances),
    /No driving route exists/,
  );
});

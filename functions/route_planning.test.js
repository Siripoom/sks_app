import assert from 'node:assert/strict';
import test from 'node:test';
import {
  classifyRouteApiError,
  classifyRouteNetworkError,
  formatRouteTimestamp,
  greedyStopOrder,
  orderStopsFromRouteVisits,
  routeOptimizationPath,
} from './route_planning.js';

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

test('classifyRouteApiError identifies a disabled API', () => {
  const result = classifyRouteApiError(403, {
    error: {
      status: 'PERMISSION_DENIED',
      details: [{ reason: 'SERVICE_DISABLED' }],
    },
  });

  assert.equal(result.code, 'failed-precondition');
  assert.equal(
    result.message,
    'Route Optimization API is not enabled for this project.',
  );
  assert.equal(result.diagnostic.reason, 'SERVICE_DISABLED');
});

test('classifyRouteApiError identifies service-account permission errors', () => {
  const result = classifyRouteApiError(403, {
    error: {
      status: 'PERMISSION_DENIED',
      details: [{ reason: 'IAM_PERMISSION_DENIED' }],
    },
  });

  assert.equal(result.code, 'permission-denied');
  assert.match(result.message, /service account/);
});

test('classifyRouteApiError identifies exhausted quota', () => {
  const result = classifyRouteApiError(429, {
    error: { status: 'RESOURCE_EXHAUSTED' },
  });

  assert.equal(result.code, 'resource-exhausted');
  assert.match(result.message, /quota/);
});

test('classifyRouteNetworkError distinguishes timeout and network failures', () => {
  const timeout = classifyRouteNetworkError('AbortError');
  const network = classifyRouteNetworkError('TypeError');

  assert.equal(timeout.code, 'unavailable');
  assert.match(timeout.message, /timed out/);
  assert.equal(timeout.diagnostic.reason, 'TIMEOUT');
  assert.equal(network.code, 'unavailable');
  assert.match(network.message, /temporarily unavailable/);
  assert.equal(network.diagnostic.reason, 'NETWORK_ERROR');
});

test('route optimization uses the project-level endpoint', () => {
  assert.equal(
    routeOptimizationPath('sks-app-d980c'),
    '/v1/projects/sks-app-d980c:optimizeTours',
  );
});

test('formatRouteTimestamp removes unsupported fractional seconds', () => {
  assert.equal(
    formatRouteTimestamp(new Date('2026-07-31T09:15:30.456Z')),
    '2026-07-31T09:15:30Z',
  );
  assert.throws(() => formatRouteTimestamp('not-a-date'), /Invalid/);
});

test('orderStopsFromRouteVisits uses a label when index zero is omitted', () => {
  const stops = [{ id: 'first' }, { id: 'second' }];

  assert.deepEqual(
    orderStopsFromRouteVisits(stops, [
      { shipmentLabel: 'first' },
      { shipmentLabel: 'second', shipmentIndex: 1 },
    ]),
    stops,
  );
});

test('orderStopsFromRouteVisits follows shipment indexes in route order', () => {
  const stops = [{ id: 'first' }, { id: 'second' }];

  assert.deepEqual(
    orderStopsFromRouteVisits(stops, [
      { shipmentIndex: 1 },
      { shipmentIndex: 0 },
    ]),
    [stops[1], stops[0]],
  );
});

test('orderStopsFromRouteVisits treats an omitted index as zero', () => {
  const stops = [{ id: 'first' }];

  assert.deepEqual(orderStopsFromRouteVisits(stops, [{}]), stops);
});

test('orderStopsFromRouteVisits rejects an unknown shipment label', () => {
  assert.throws(
    () => orderStopsFromRouteVisits(
      [{ id: 'first' }],
      [{ shipmentLabel: 'unknown' }],
    ),
    (error) => error.reason === 'UNKNOWN_SHIPMENT_LABEL',
  );
});

test('orderStopsFromRouteVisits rejects an out-of-range shipment index', () => {
  assert.throws(
    () => orderStopsFromRouteVisits(
      [{ id: 'first' }],
      [{ shipmentIndex: 2 }],
    ),
    (error) => error.reason === 'SHIPMENT_INDEX_OUT_OF_RANGE',
  );
});

test('orderStopsFromRouteVisits rejects a duplicate shipment', () => {
  assert.throws(
    () => orderStopsFromRouteVisits(
      [{ id: 'first' }, { id: 'second' }],
      [{ shipmentLabel: 'first' }, { shipmentIndex: 0 }],
    ),
    (error) => error.reason === 'DUPLICATE_SHIPMENT',
  );
});

test('orderStopsFromRouteVisits rejects an omitted stop', () => {
  assert.throws(
    () => orderStopsFromRouteVisits(
      [{ id: 'first' }, { id: 'second' }],
      [{ shipmentLabel: 'first' }],
    ),
    (error) => error.reason === 'OMITTED_STOP',
  );
});

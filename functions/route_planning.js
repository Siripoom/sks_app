export function greedyStopOrder(stops, distances) {
  if (stops.length === 0) return [];
  if (!Array.isArray(distances) || distances.length !== stops.length + 1) {
    throw new Error('Distance matrix shape does not match the route stops.');
  }

  const remaining = new Set(stops.map((_, index) => index));
  const ordered = [];
  let originIndex = 0;

  while (remaining.size > 0) {
    let nearestIndex = -1;
    let nearestDistance = Number.POSITIVE_INFINITY;
    for (const stopIndex of remaining) {
      const distance = Number(distances[originIndex]?.[stopIndex]);
      if (!Number.isFinite(distance)) continue;
      const isCloser = distance < nearestDistance;
      const isStableTie = distance === nearestDistance &&
        (nearestIndex < 0 || stops[stopIndex].id.localeCompare(
          stops[nearestIndex].id,
        ) < 0);
      if (isCloser || isStableTie) {
        nearestIndex = stopIndex;
        nearestDistance = distance;
      }
    }
    if (nearestIndex < 0) {
      throw new Error('No driving route exists for a remaining stop.');
    }
    ordered.push(stops[nearestIndex]);
    remaining.delete(nearestIndex);
    originIndex = nearestIndex + 1;
  }

  return ordered;
}

export function classifyRouteApiError(httpStatus, payload = {}) {
  const apiError = payload && typeof payload === 'object'
    ? payload.error || {}
    : {};
  const reasons = Array.isArray(apiError.details)
    ? apiError.details.map((detail) => detail?.reason).filter(Boolean)
    : [];
  const reason = reasons[0] || apiError.status || 'UNKNOWN';
  const diagnostic = {
    httpStatus,
    apiStatus: apiError.status || '',
    reason,
  };

  if (httpStatus === 429 || apiError.status === 'RESOURCE_EXHAUSTED') {
    return {
      code: 'resource-exhausted',
      message: 'Route calculation quota has been reached.',
      diagnostic,
    };
  }
  if (reasons.includes('SERVICE_DISABLED')) {
    return {
      code: 'failed-precondition',
      message: 'Route Optimization API is not enabled for this project.',
      diagnostic,
    };
  }
  if (httpStatus === 403 || apiError.status === 'PERMISSION_DENIED') {
    return {
      code: 'permission-denied',
      message: 'The route service account does not have permission to calculate routes.',
      diagnostic,
    };
  }
  if (httpStatus >= 400 && httpStatus < 500) {
    return {
      code: 'failed-precondition',
      message: 'Google rejected the route calculation request.',
      diagnostic,
    };
  }
  return {
    code: 'unavailable',
    message: 'Route calculation is temporarily unavailable.',
    diagnostic,
  };
}

export function classifyRouteNetworkError(errorName) {
  const timedOut = errorName === 'AbortError';
  return {
    code: 'unavailable',
    message: timedOut
      ? 'Route calculation timed out.'
      : 'Route calculation is temporarily unavailable.',
    diagnostic: {
      reason: timedOut ? 'TIMEOUT' : 'NETWORK_ERROR',
      errorName: typeof errorName === 'string' ? errorName : '',
    },
  };
}

export function routeOptimizationPath(projectId) {
  return `/v1/projects/${encodeURIComponent(projectId)}:optimizeTours`;
}

export function formatRouteTimestamp(value) {
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) {
    throw new Error('Invalid route timestamp.');
  }
  return date.toISOString().replace(/\.\d{3}Z$/, 'Z');
}

function routeVisitOrderError(reason, stopCount, visitCount) {
  const error = new Error('Invalid route visit order.');
  error.name = 'RouteVisitOrderError';
  error.reason = reason;
  error.diagnostic = {
    reason,
    stopCount,
    visitCount,
  };
  return error;
}

export function orderStopsFromRouteVisits(stops, visits) {
  const stopCount = Array.isArray(stops) ? stops.length : 0;
  const visitCount = Array.isArray(visits) ? visits.length : 0;
  if (!Array.isArray(stops) || !Array.isArray(visits)) {
    throw routeVisitOrderError('INVALID_VISIT_LIST', stopCount, visitCount);
  }

  const stopIndexByLabel = new Map();
  for (const [index, stop] of stops.entries()) {
    if (typeof stop?.id !== 'string' || !stop.id ||
        stopIndexByLabel.has(stop.id)) {
      throw routeVisitOrderError(
        'INVALID_STOP_LABELS',
        stopCount,
        visitCount,
      );
    }
    stopIndexByLabel.set(stop.id, index);
  }

  const seenIndexes = new Set();
  const ordered = visits.map((visit) => {
    const shipmentLabel = typeof visit?.shipmentLabel === 'string'
      ? visit.shipmentLabel
      : '';
    let stopIndex;
    if (shipmentLabel) {
      stopIndex = stopIndexByLabel.get(shipmentLabel);
      if (stopIndex === undefined) {
        throw routeVisitOrderError(
          'UNKNOWN_SHIPMENT_LABEL',
          stopCount,
          visitCount,
        );
      }
    } else {
      // Protobuf JSON omits integer fields at their default value of zero.
      stopIndex = visit?.shipmentIndex ?? 0;
      if (!Number.isInteger(stopIndex) ||
          stopIndex < 0 || stopIndex >= stopCount) {
        throw routeVisitOrderError(
          'SHIPMENT_INDEX_OUT_OF_RANGE',
          stopCount,
          visitCount,
        );
      }
    }

    if (seenIndexes.has(stopIndex)) {
      throw routeVisitOrderError(
        'DUPLICATE_SHIPMENT',
        stopCount,
        visitCount,
      );
    }
    seenIndexes.add(stopIndex);
    return stops[stopIndex];
  });

  if (ordered.length !== stopCount) {
    throw routeVisitOrderError('OMITTED_STOP', stopCount, visitCount);
  }
  return ordered;
}

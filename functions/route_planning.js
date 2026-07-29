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

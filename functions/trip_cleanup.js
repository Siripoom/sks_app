function uniqueStrings(values) {
  return [...new Set(
    (values || [])
      .filter((value) => typeof value === 'string' && value.trim())
      .map((value) => value.trim()),
  )];
}

export function buildTripDeletionPlan({ tripId, trip, children }) {
  const listedChildIds = new Set(uniqueStrings(trip?.childIds || []));
  const tripBusId = typeof trip?.busId === 'string' ? trip.busId.trim() : '';
  const childIdsToReset = [];
  const busRemovals = new Map();

  for (const child of children || []) {
    const childId = typeof child?.id === 'string' ? child.id.trim() : '';
    if (!childId) continue;

    const currentTripId = typeof child.tripId === 'string'
      ? child.tripId.trim()
      : '';
    const belongsToTrip = currentTripId === tripId ||
      (!currentTripId && listedChildIds.has(childId));
    if (!belongsToTrip) continue;

    childIdsToReset.push(childId);
    const busIds = uniqueStrings([child.busId, tripBusId]);
    for (const busId of busIds) {
      const childIds = busRemovals.get(busId) || [];
      childIds.push(childId);
      busRemovals.set(busId, childIds);
    }
  }

  return {
    childIdsToReset: uniqueStrings(childIdsToReset).sort(),
    busChildRemovals: [...busRemovals.entries()]
      .map(([busId, childIds]) => ({
        busId,
        childIds: uniqueStrings(childIds).sort(),
      }))
      .sort((a, b) => a.busId.localeCompare(b.busId)),
    activeBusId: trip?.status === 'active' ? tripBusId : '',
  };
}

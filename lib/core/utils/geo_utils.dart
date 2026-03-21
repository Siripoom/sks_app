import 'dart:math';

const double _earthRadiusKm = 6371.0;
const double _roadFactor = 1.4;
const double _averageSpeedKmh = 30.0;

double haversineDistanceKm(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  final dLat = _toRadians(lat2 - lat1);
  final dLng = _toRadians(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) *
          cos(_toRadians(lat2)) *
          sin(dLng / 2) *
          sin(dLng / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return _earthRadiusKm * c;
}

int estimateMinutes(double straightLineKm) {
  if (straightLineKm <= 0) return 0;
  final roadKm = straightLineKm * _roadFactor;
  final minutes = (roadKm / _averageSpeedKmh) * 60;
  return minutes.ceil();
}

int estimateMinutesBetween(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  return estimateMinutes(haversineDistanceKm(lat1, lng1, lat2, lng2));
}

double _toRadians(double degrees) => degrees * pi / 180;

import 'dart:math';

/// Haversine great-circle distance between two coordinates, in km.
///
/// This is the only place that converts coordinates into a distance.
/// [Trip.gpsDistanceKm] sums these segments over all recorded points.
double haversineDistanceKm({
  required double latitude1,
  required double longitude1,
  required double latitude2,
  required double longitude2,
}) {
  const double earthRadiusKm = 6371.0088;
  final double dLat = _toRadians(latitude2 - latitude1);
  final double dLon = _toRadians(longitude2 - longitude1);

  final double a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(latitude1)) *
          cos(_toRadians(latitude2)) *
          sin(dLon / 2) *
          sin(dLon / 2);

  return 2 * earthRadiusKm * asin(min(1.0, sqrt(a)));
}

double _toRadians(double degrees) => degrees * pi / 180;

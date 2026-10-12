import 'dart:math';

/// Calculates the great-circle distance between two GPS coordinates in kilometers
/// using the Haversine formula.
///
/// Explanation for University Presentation:
/// The Haversine formula calculates the shortest distance over the Earth's spherical surface
/// given two pairs of latitude and longitude (in degrees).
///
/// Formula:
/// a = sin²(Δlat/2) + cos(lat1) * cos(lat2) * sin²(Δlon/2)
/// c = 2 * atan2(√a, √(1-a)) = 2 * asin(√a)
/// distance = R * c  (where R = Earth's radius ≈ 6371 km)
double haversineDistanceKm({
  required double latitude1,
  required double longitude1,
  required double latitude2,
  required double longitude2,
}) {
  const double earthRadiusKm = 6371.0088; // Earth's mean radius in km

  final double dLat = _toRadians(latitude2 - latitude1);
  final double dLon = _toRadians(longitude2 - longitude1);

  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(latitude1)) *
          cos(_toRadians(latitude2)) *
          sin(dLon / 2) *
          sin(dLon / 2);

  // Compute central angle c = 2 * asin(sqrt(a))
  final double c = 2 * asin(min(1.0, sqrt(a)));

  return earthRadiusKm * c;
}

/// Converts degrees to radians: radians = degrees * (π / 180)
double _toRadians(double degrees) => degrees * pi / 180;

import 'dart:math' as math;

import 'location_point.dart';

/// One vehicle trip: a driver, an odometer reading, and the GPS points
/// collected while moving. Distance is derived from the collected points.
class Trip {
  Trip({
    required this.driverName,
    required this.startKilometerstand,
    required this.startTime,
    this.endTime,
  });

  final String driverName;
  /// Odometer reading entered manually at the start of the trip.
  final double startKilometerstand;
  final DateTime startTime;
  DateTime? endTime;

  /// All GPS fixes captured between start and stop.
  final List<LocationPoint> points = <LocationPoint>[];

  bool get isFinished => endTime != null;

  /// Total travelled distance (meters) by summing the great-circle distance
  /// between consecutive fixes, using the Haversine formula.
  double get distanceMeters {
    double total = 0;
    for (int i = 1; i < points.length; i++) {
      total += haversineMeters(
        points[i - 1].latitude,
        points[i - 1].longitude,
        points[i].latitude,
        points[i].longitude,
      );
    }
    return total;
  }

  /// [distanceMeters] expressed in kilometers.
  double get distanceKm => distanceMeters / 1000.0;

  /// Distance between two coordinates in meters (Haversine).
  static double haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusMeters = 6371000;
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusMeters * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;
}

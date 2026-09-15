import 'location_point.dart';

/// One vehicle trip (a Fahrtenbuch entry).
///
/// The official distance is always `endKm - startKm` (odometer).
/// GPS data is only stored for location documentation and future
/// route visualization — it is never used to calculate the distance.
class Trip {
  Trip({
    required this.driverName,
    required this.startKm,
    required this.startTime,
    this.startLatitude,
    this.startLongitude,
    this.startLocationText,
    this.endKm,
    this.endTime,
    this.endLatitude,
    this.endLongitude,
    this.endLocationText,
    this.routePoints = const [],
  });

  final String driverName;
  final DateTime startTime;

  /// Odometer reading at the start (manually entered).
  final double startKm;

  /// GPS coordinates at the start, if a fix was available.
  final double? startLatitude;
  final double? startLongitude;

  /// Free-text start location: either "GPS (lat, lon)" or a manually
  /// entered name when no GPS fix was available.
  String? startLocationText;

  // Filled in when the trip is stopped.
  double? endKm;
  DateTime? endTime;
  double? endLatitude;
  double? endLongitude;
  String? endLocationText;

  /// Meaningful GPS points collected during the trip (future route data).
  final List<LocationPoint> routePoints;

  bool get isFinished => endTime != null;

  /// Official distance in km: odometer end minus odometer start.
  double get distanceKm => (endKm ?? startKm) - startKm;

  /// Trip duration, from start time to end time (zero while running).
  Duration get duration {
    final end = endTime;
    if (end == null) return Duration.zero;
    return end.difference(startTime);
  }

  /// Number of intermediate points (start and end locations are not
  /// counted as intermediate).
  int get intermediatePointCount => routePoints.length;
}

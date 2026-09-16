import '../utils/geo.dart';
import 'location_point.dart';

/// One vehicle trip (a Fahrtenbuch entry).
///
/// The trip distance is calculated from the recorded GPS points
/// (Haversine, see [distanceKm]) — the user does not have to enter an
/// end odometer reading. The odometer reading at start is still stored
/// for documentation, but it is not used for the distance.
class Trip {
  Trip({
    required this.driverName,
    required this.startKm,
    required this.startTime,
    this.startLatitude,
    this.startLongitude,
    this.startLocationText,
    this.endTime,
    this.endLatitude,
    this.endLongitude,
    this.endLocationText,
    this.routePoints = const [],
  });

  final String driverName;
  final DateTime startTime;

  /// Odometer reading at the start (manually entered, documentation only).
  final double startKm;

  /// GPS coordinates at the start, if a fix was available.
  final double? startLatitude;
  final double? startLongitude;

  /// Free-text start location: either "GPS (lat, lon)" or a manually
  /// entered name when no GPS fix was available.
  String? startLocationText;

  // Filled in when the trip is stopped.
  DateTime? endTime;
  double? endLatitude;
  double? endLongitude;
  String? endLocationText;

  /// GPS points collected during the trip (roughly one every 5 minutes).
  final List<LocationPoint> routePoints;

  bool get isFinished => endTime != null;

  /// Distance in km, summed over the recorded GPS points (Haversine):
  /// start point -> intermediate points -> end point. Returns 0 when
  /// fewer than two GPS positions were recorded (e.g. no GPS at all).
  double get distanceKm {
    final List<LocationPoint> points = allGpsPoints();
    if (points.length < 2) return 0;
    double total = 0;
    for (int i = 1; i < points.length; i++) {
      total += haversineDistanceKm(
        latitude1: points[i - 1].latitude,
        longitude1: points[i - 1].longitude,
        latitude2: points[i].latitude,
        longitude2: points[i].longitude,
      );
    }
    return total;
  }

  /// Distance below which two consecutive points are considered the same
  /// position (GPS jitter / car not moved yet) and the second one is
  /// dropped from the route.
  static const double _minRouteSegmentKm = 0.01; // 10 m

  /// All recorded GPS positions in chronological order: start point,
  /// intermediate points, end point. This is the answer to "which way
  /// did I drive" and the basis for future route visualization.
  ///
  /// Consecutive points closer than [_minRouteSegmentKm] are skipped, so
  /// the route never shows the same position twice.
  List<LocationPoint> allGpsPoints() {
    final List<LocationPoint> points = [];

    void addIfNotDuplicate(LocationPoint point) {
      final LocationPoint? last = points.lastOrNull;
      if (last == null ||
          haversineDistanceKm(
            latitude1: last.latitude,
            longitude1: last.longitude,
            latitude2: point.latitude,
            longitude2: point.longitude,
          ) >=
              _minRouteSegmentKm) {
        points.add(point);
      }
    }

    final double? sLat = startLatitude;
    final double? sLon = startLongitude;
    if (sLat != null && sLon != null) {
      points.add(
        LocationPoint(
          latitude: sLat,
          longitude: sLon,
          timestamp: startTime,
        ),
      );
    }
    routePoints.forEach(addIfNotDuplicate);
    final double? eLat = endLatitude;
    final double? eLon = endLongitude;
    final DateTime? eTime = endTime;
    if (eLat != null && eLon != null && eTime != null) {
      addIfNotDuplicate(
        LocationPoint(
          latitude: eLat,
          longitude: eLon,
          timestamp: eTime,
        ),
      );
    }
    return points;
  }

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

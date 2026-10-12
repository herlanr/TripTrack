import '../utils/geo.dart';
import 'location_point.dart';

/// Represents a single completed or active vehicle trip (Fahrtenbuch entry).
class Trip {
  Trip({
    String? id,
    required this.driverName,
    this.driverId,
    this.vehicleId,
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
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  final String id;
  final String driverName;
  final String? driverId; // Personen_ID (FK)
  final String? vehicleId; // Fahrzeug_ID (FK)
  final DateTime startTime;

  /// Odometer reading at start
  final double startKm;

  /// GPS coordinates at start
  final double? startLatitude;
  final double? startLongitude;

  /// Resolved street address for start
  String? startLocationText;

  // Filled in when the trip is stopped
  DateTime? endTime;
  double? endLatitude;
  double? endLongitude;
  String? endLocationText;

  /// GPS points collected during driving (recorded every 3 minutes)
  final List<LocationPoint> routePoints;

  bool get isFinished => endTime != null;

  /// Total distance in km calculated via Haversine sum over all GPS route points
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

  static const double _minRouteSegmentKm = 0.01; // 10 meters threshold

  /// Returns all recorded GPS positions in chronological order
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

  /// Trip duration
  Duration get duration {
    final end = endTime;
    if (end == null) return Duration.zero;
    return end.difference(startTime);
  }

  int get intermediatePointCount => routePoints.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'driverName': driverName,
        'driverId': driverId,
        'vehicleId': vehicleId,
        'startKm': startKm,
        'startTime': startTime.toIso8601String(),
        'startLatitude': startLatitude,
        'startLongitude': startLongitude,
        'startLocationText': startLocationText,
        'endTime': endTime?.toIso8601String(),
        'endLatitude': endLatitude,
        'endLongitude': endLongitude,
        'endLocationText': endLocationText,
        'routePoints': routePoints.map((p) => p.toJson()).toList(),
      };

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: json['id'] as String?,
        driverName: json['driverName'] as String,
        driverId: json['driverId'] as String?,
        vehicleId: json['vehicleId'] as String?,
        startKm: (json['startKm'] as num).toDouble(),
        startTime: DateTime.parse(json['startTime'] as String),
        startLatitude: (json['startLatitude'] as num?)?.toDouble(),
        startLongitude: (json['startLongitude'] as num?)?.toDouble(),
        startLocationText: json['startLocationText'] as String?,
        endTime: json['endTime'] != null
            ? DateTime.parse(json['endTime'] as String)
            : null,
        endLatitude: (json['endLatitude'] as num?)?.toDouble(),
        endLongitude: (json['endLongitude'] as num?)?.toDouble(),
        endLocationText: json['endLocationText'] as String?,
        routePoints: (json['routePoints'] as List<dynamic>?)
                ?.map((e) => LocationPoint.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

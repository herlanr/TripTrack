import 'package:json_annotation/json_annotation.dart';

import '../utils/geo.dart';
import 'location_point.dart';

part 'trip.g.dart';

/// Repräsentiert eine Fahrt (Fahrt-Entität aus dem ER-Diagramm).
@JsonSerializable(explicitToJson: true)
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

  /// Zuordnung zum Fahrer (Personen_ID als Fremdschlüssel)
  final String? driverId;

  /// Zuordnung zum Fahrzeug (Fahrzeug_ID als Fremdschlüssel)
  final String? vehicleId;

  final DateTime startTime;

  final double startKm;

  final double? startLatitude;

  final double? startLongitude;

  String? startLocationText;

  DateTime? endTime;

  double? endLatitude;

  double? endLongitude;

  String? endLocationText;

  /// Liste aller während der Fahrt erfassten GPS-Routenpunkte
  final List<LocationPoint> routePoints;

  /// Gibt an, ob die Fahrt bereits beendet ist.
  bool get isFinished => endTime != null;

  /// Berechnet die Gesamtstrecke der Fahrt in km über die Haversine-Formel.
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

  static const double _minRouteSegmentKm = 0.01; // Mindestabstand 10 Meter

  /// Gibt alle erfassten GPS-Punkte in chronologischer Reihenfolge zurück.
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

  /// Berechnet die Gesamtdauer der Fahrt.
  Duration get duration {
    final end = endTime;
    if (end == null) return Duration.zero;
    return end.difference(startTime);
  }

  /// Anzahl der Zwischenpunkte auf der Route
  int get intermediatePointCount => routePoints.length;

  /// Erstellt eine Fahrt-Instanz aus einem JSON-Map.
  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);

  /// Konvertiert die Fahrt-Instanz in ein JSON-Map.
  Map<String, dynamic> toJson() => _$TripToJson(this);
}

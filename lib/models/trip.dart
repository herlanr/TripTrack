import 'package:json_annotation/json_annotation.dart';

import '../utils/geo.dart';
import 'location_point.dart';

part 'trip.g.dart';

/// Repräsentiert das Datenmodell für eine Fahrt im Fahrtenbuch von TripTrack.
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

  /// Eindeutige ID der Fahrt
  final String id;

  /// Name des Fahrers
  final String driverName;

  /// Zuordnung zum Fahrer (Fremdschlüssel)
  final String? driverId;

  /// Zuordnung zum Fahrzeug (Fremdschlüssel)
  final String? vehicleId;

  /// Startzeitpunkt der Fahrt
  final DateTime startTime;

  /// Tacho-Kilometerstand zu Beginn der Fahrt
  final double startKm;

  /// Breitengrad der Startposition
  final double? startLatitude;

  /// Längengrad der Startposition
  final double? startLongitude;

  /// Lesbare Startadresse oder Ortsbezeichnung
  String? startLocationText;

  /// Endzeitpunkt der Fahrt
  DateTime? endTime;

  /// Breitengrad der Zielposition
  double? endLatitude;

  /// Längengrad der Zielposition
  double? endLongitude;

  /// Lesbare Zieladresse oder Ortsbezeichnung
  String? endLocationText;

  /// Liste aller während der Fahrt erfassten GPS-Routenpunkte
  final List<LocationPoint> routePoints;

  /// Beschreibung: Gibt an, ob die Fahrt bereits beendet ist.
  /// Eingabe: Keine
  /// Ausgabe: bool
  bool get isFinished => endTime != null;

  /// Beschreibung: Berechnet die Gesamtstrecke der Fahrt in km über die Haversine-Formel.
  /// Eingabe: Keine
  /// Ausgabe: double
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

  /// Mindestabstand in Kilometern zwischen zwei aufeinanderfolgenden Routenpunkten (2 Meter).
  static const double _minRouteSegmentKm = 0.002;

  /// Beschreibung: Gibt alle erfassten GPS-Punkte (Start, Zwischenpunkte, Ziel) chronologisch zurück.
  /// Eingabe: Keine
  /// Ausgabe: List<[LocationPoint]>
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

  /// Beschreibung: Berechnet die Gesamtdauer der Fahrt.
  /// Eingabe: Keine
  /// Ausgabe: Duration
  Duration get duration {
    final end = endTime;
    if (end == null) return Duration.zero;
    return end.difference(startTime);
  }

  /// Beschreibung: Gibt die Anzahl der Zwischenpunkte auf der Route zurück.
  /// Eingabe: Keine
  /// Ausgabe: int
  int get intermediatePointCount => routePoints.length;

  /// Beschreibung: Erstellt eine Fahrt-Instanz aus einem JSON-Map.
  /// Eingabe: json (`Map<String, dynamic>`)
  /// Ausgabe: [Trip]
  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);

  /// Beschreibung: Konvertiert die Fahrt-Instanz in ein JSON-Map.
  /// Eingabe: Keine
  /// Ausgabe: `Map<String, dynamic>`
  Map<String, dynamic> toJson() => _$TripToJson(this);
}

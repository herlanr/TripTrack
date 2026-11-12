import 'dart:async';

import '../models/location_point.dart';
import '../models/trip.dart';
import '../models/trip_phase.dart';
import '../utils/geo.dart';
import '../utils/geocoding_helper.dart';
import 'location_tracking_service.dart';

/// Verwaltet den gesamten Lebenszyklus einer Fahrt (Starten, Routenpunkterfassung, Beenden).
class TripService {
  /// Erstellt eine neue TripService-Instanz mit dem übergebenen LocationTrackingService.
  TripService(this._locationService);

  final LocationTrackingService _locationService;

  /// Zeitintervall für das Speichern von Zwischen-GPS-Punkten auf der Route (5 Sekunden).
  static const Duration minPointInterval = Duration(seconds: 5);

  /// Maximale Anzahl an speicherbaren GPS-Routenpunkten pro Fahrt.
  static const int maxPoints = 500;

  Trip? _trip;
  StreamSubscription<LocationPoint>? _subscription;
  final StreamController<int> _pointCountController =
      StreamController<int>.broadcast();

  /// Beschreibung: Gibt die aktuell laufende oder zuletzt beendete Fahrt zurück.
  /// Eingabe: Keine
  /// Ausgabe: [Trip]?
  Trip? get currentTrip => _trip;

  /// Beschreibung: Gibt den aktuellen Status des Fahrt-Lebenszyklus zurück.
  /// Eingabe: Keine
  /// Ausgabe: [TripPhase]
  TripPhase get phase => _trip == null
      ? TripPhase.idle
      : _trip!.isFinished
          ? TripPhase.finished
          : TripPhase.active;

  /// Beschreibung: Stream für Live-Aktualisierungen der Anzahl erfasster GPS-Punkte.
  /// Eingabe: Keine
  /// Ausgabe: `Stream<int>`
  Stream<int> get pointCountUpdates => _pointCountController.stream;

  /// Beschreibung: Startet eine neue Fahrt und löst die Startadresse über Geocoding auf.
  /// Eingabe: driverName (String), driverId (String?), vehicleId (String?), startKm (double)
  /// Ausgabe: `Future<Trip>`
  Future<Trip> startTrip({
    required String driverName,
    String? driverId,
    String? vehicleId,
    required double startKm,
  }) async {
    if (phase == TripPhase.active) {
      throw StateError('Eine Fahrt läuft bereits.');
    }

    final LocationPoint? startFix =
        await _locationService.requestFixWithPermission();

    final trip = Trip(
      driverName: driverName,
      driverId: driverId,
      vehicleId: vehicleId,
      startKm: startKm,
      startTime: DateTime.now(),
      startLatitude: startFix?.latitude,
      startLongitude: startFix?.longitude,
    );

    if (startFix != null) {
      final address = await GeocodingHelper.getAddressFromCoordinates(
        startFix.latitude,
        startFix.longitude,
      );
      trip.startLocationText = address;
    }

    _trip = trip;
    _startCollectingPoints();
    return trip;
  }

  /// Beschreibung: Speichert einen manuell eingegebenen Startort (wenn GPS nicht verfügbar war).
  /// Eingabe: text (String)
  /// Ausgabe: void
  void setManualStartLocation(String text) {
    final trip = _trip;
    if (trip != null && !trip.isFinished) {
      trip.startLocationText = text;
    }
  }

  /// Beschreibung: Beendet die aktuelle Fahrt sofort und löst die Zieladresse auf.
  /// Eingabe: Keine
  /// Ausgabe: `Future<Trip>`
  Future<Trip> stopTrip() async {
    final trip = _trip;
    if (trip == null || trip.isFinished) {
      throw StateError('Keine aktive Fahrt zum Beenden.');
    }

    trip.endTime = DateTime.now();

    final LocationPoint? endFix = _locationService.lastKnownPoint ??
        await _locationService.getCurrentPosition();

    if (endFix != null) {
      trip.endLatitude = endFix.latitude;
      trip.endLongitude = endFix.longitude;

      final address = await GeocodingHelper.getAddressFromCoordinates(
        endFix.latitude,
        endFix.longitude,
      );
      trip.endLocationText = address;
    }

    _stopCollectingPoints();
    return trip;
  }

  /// Beschreibung: Speichert einen manuell eingegebenen Zielort (wenn GPS nicht verfügbar war).
  /// Eingabe: text (String)
  /// Ausgabe: void
  void setManualEndLocation(String text) {
    _trip?.endLocationText = text;
  }

  /// Beschreibung: Setzt den Dienst zurück und gibt die aktuelle Fahrt frei.
  /// Eingabe: Keine
  /// Ausgabe: void
  void reset() {
    _stopCollectingPoints();
    _trip = null;
  }

  /// Beschreibung: Gibt alle verwendeten Ressourcen und StreamController frei.
  /// Eingabe: Keine
  /// Ausgabe: void
  void dispose() {
    _stopCollectingPoints();
    _pointCountController.close();
  }

  /// Beschreibung: Startet das Erfassen von GPS-Routenpunkten über den LocationTrackingService.
  /// Eingabe: Keine
  /// Ausgabe: void
  void _startCollectingPoints() {
    _subscription = _locationService.startTracking().listen(_onLiveFix);
  }

  /// Beschreibung: Stoppt das Erfassen von GPS-Routenpunkten.
  /// Eingabe: Keine
  /// Ausgabe: void
  void _stopCollectingPoints() {
    _subscription?.cancel();
    _subscription = null;
    _locationService.stop();
  }

  /// Beschreibung: Verarbeitet ein eingehendes GPS-Signal und speichert es bei ausreichender Zeit und Distanz.
  /// Eingabe: point ([LocationPoint])
  /// Ausgabe: void
  void _onLiveFix(LocationPoint point) {
    final trip = _trip;
    if (trip == null || trip.isFinished) return;
    if (trip.routePoints.length >= maxPoints) return;

    final LocationPoint? last = trip.routePoints.lastOrNull;
    final bool timeElapsed = last == null ||
        point.timestamp.difference(last.timestamp) >= minPointInterval;
    final bool moved = last == null ||
        haversineDistanceKm(
              latitude1: last.latitude,
              longitude1: last.longitude,
              latitude2: point.latitude,
              longitude2: point.longitude,
            ) >=
            0.005;

    if (timeElapsed && moved) {
      trip.routePoints.add(point);
      _pointCountController.add(trip.routePoints.length);

      GeocodingHelper.getAddressFromCoordinates(
        point.latitude,
        point.longitude,
      ).then((address) {
        final index = trip.routePoints.indexOf(point);
        if (index != -1) {
          trip.routePoints[index] = LocationPoint(
            latitude: point.latitude,
            longitude: point.longitude,
            timestamp: point.timestamp,
            addressText: address,
          );
        }
      }).catchError((_) {});
    }
  }
}

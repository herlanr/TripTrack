import 'dart:async';

import '../models/location_point.dart';
import '../models/trip.dart';
import '../models/trip_phase.dart';
import '../utils/geocoding_helper.dart';
import 'location_tracking_service.dart';

/// SERVICE PATTERN IMPLEMENTATION (Fahrt-Verwaltungsdienst)
///
/// Verwaltet den gesamten Lebenszyklus einer Fahrt:
/// - Starten und sofortiges Beenden von Fahrten.
/// - Erfassen von GPS-Routenpunkten in 3-Minuten-Intervallen.
/// - Automatische Adressauflösung für Start- und Zielort über GeocodingHelper.
class TripService {
  /// Erstellt eine neue TripService-Instanz mit dem übergebenen LocationTrackingService.
  TripService(this._locationService);

  final LocationTrackingService _locationService;

  /// Zeitintervall für das Speichern von Zwischen-GPS-Punkten auf der Route (3 Minuten).
  static const Duration minPointInterval = Duration(minutes: 3);

  /// Maximale Anzahl an speicherbaren GPS-Routenpunkten pro Fahrt.
  static const int maxPoints = 500;

  Trip? _trip;
  StreamSubscription<LocationPoint>? _subscription;
  final StreamController<int> _pointCountController =
      StreamController<int>.broadcast();

  /// Die aktuell laufende oder zuletzt beendete Fahrt.
  Trip? get currentTrip => _trip;

  /// Der aktuelle Status des Fahrt-Lebenszyklus (idle, active, finished).
  TripPhase get phase => _trip == null
      ? TripPhase.idle
      : _trip!.isFinished
          ? TripPhase.finished
          : TripPhase.active;

  /// Stream für Live-Aktualisierungen der Anzahl erfasster GPS-Punkte.
  Stream<int> get pointCountUpdates => _pointCountController.stream;

  /// Startet eine neue Fahrt und löst die Startadresse über Reverse Geocoding auf.
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

  /// Speichert einen manuell eingegebenen Startort (wenn GPS nicht verfügbar war).
  void setManualStartLocation(String text) {
    final trip = _trip;
    if (trip != null && !trip.isFinished) {
      trip.startLocationText = text;
    }
  }

  /// Beendet die aktuelle Fahrt sofort (<0,1s) und löst die Zieladresse auf.
  Future<Trip> stopTrip() async {
    final trip = _trip;
    if (trip == null || trip.isFinished) {
      throw StateError('Keine aktive Fahrt zum Beenden.');
    }

    trip.endTime = DateTime.now();

    // Sofortiger Zugriff auf den gekauften letzten GPS-Fix
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

  /// Speichert einen manuell eingegebenen Zielort (wenn GPS nicht verfügbar war).
  void setManualEndLocation(String text) {
    _trip?.endLocationText = text;
  }

  /// Setzt den Dienst zurück und gibt die aktuelle Fahrt frei.
  void reset() {
    _stopCollectingPoints();
    _trip = null;
  }

  /// Gibt alle verwendeten Ressourcen frei.
  void dispose() {
    _stopCollectingPoints();
    _pointCountController.close();
  }

  void _startCollectingPoints() {
    _subscription = _locationService.startTracking().listen(_onLiveFix);
  }

  void _stopCollectingPoints() {
    _subscription?.cancel();
    _subscription = null;
    _locationService.stop();
  }

  void _onLiveFix(LocationPoint point) {
    final trip = _trip;
    if (trip == null || trip.isFinished) return;
    if (trip.routePoints.length >= maxPoints) return;

    final LocationPoint? last = trip.routePoints.lastOrNull;
    if (last == null ||
        point.timestamp.difference(last.timestamp) >= minPointInterval) {
      trip.routePoints.add(point);
      _pointCountController.add(trip.routePoints.length);
    }
  }
}

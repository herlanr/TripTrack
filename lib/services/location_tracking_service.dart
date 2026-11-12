import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/location_point.dart';

/// Status des Standortberechtigungs- und Dienstchecks.
enum LocationPermissionResult {
  /// Berechtigung erteilt
  granted,

  /// Berechtigung abgelehnt
  denied,

  /// Berechtigung dauerhaft abgelehnt
  deniedForever,

  /// Standortdienste (GPS) am Gerät ausgeschaltet
  serviceDisabled,
}

/// Dienst für die Standortberechtigungsprüfung, GPS-Fix-Abfrage und Live-Tracking.
class LocationTrackingService {
  /// Abonnement des Geolocator-Streams
  StreamSubscription<Position>? _subscription;

  /// StreamController für Live-GPS-Updates
  StreamController<LocationPoint>? _controller;

  /// Die zuletzt empfangene GPS-Position
  LocationPoint? lastKnownPoint;

  /// Beschreibung: Gibt an, ob aktuell ein GPS-Tracking-Stream läuft.
  /// Eingabe: Keine
  /// Ausgabe: bool
  bool get isTracking => _subscription != null;

  /// Beschreibung: Stream für Live-GPS-Koordinaten während einer aktiven Fahrt.
  /// Eingabe: Keine
  /// Ausgabe: `Stream<LocationPoint>`
  Stream<LocationPoint> get liveUpdates {
    final controller = _controller;
    return controller != null ? controller.stream : const Stream.empty();
  }

  /// Beschreibung: Prüft den GPS-Status und die Standortberechtigungen des Geräts.
  /// Eingabe: Keine
  /// Ausgabe: `Future<LocationPermissionResult>`
  Future<LocationPermissionResult> checkPermissionStatus() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationPermissionResult.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return LocationPermissionResult.denied;
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionResult.deniedForever;
    }

    return LocationPermissionResult.granted;
  }

  /// Beschreibung: Öffnet die App-Einstellungen auf dem Gerät.
  /// Eingabe: Keine
  /// Ausgabe: `Future<void>`
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Beschreibung: Öffnet die GPS-Standorteinstellungen auf dem Gerät.
  /// Eingabe: Keine
  /// Ausgabe: `Future<void>`
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Beschreibung: Prüft die Berechtigungen und fordert bei Erfolg eine schnelle GPS-Position an.
  /// Eingabe: Keine
  /// Ausgabe: `Future<LocationPoint?>`
  Future<LocationPoint?> requestFixWithPermission() async {
    final status = await checkPermissionStatus();
    if (status != LocationPermissionResult.granted) {
      return lastKnownPoint;
    }
    return getCurrentPosition();
  }

  /// Beschreibung: Fragt die aktuelle GPS-Position mit einem 2-Sekunden-Timeout ab.
  /// Eingabe: Keine
  /// Ausgabe: `Future<LocationPoint?>`
  Future<LocationPoint?> getCurrentPosition() async {
    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 2),
        ),
      );
      final point = _toPoint(position);
      if (point != null) lastKnownPoint = point;
      return point;
    } catch (_) {
      final Position? last = await Geolocator.getLastKnownPosition();
      final point = _toPoint(last) ?? lastKnownPoint;
      if (point != null) lastKnownPoint = point;
      return point;
    }
  }

  /// Beschreibung: Startet den Live-GPS-Position-Stream.
  /// Eingabe: Keine
  /// Ausgabe: `Stream<LocationPoint>`
  Stream<LocationPoint> startTracking() {
    if (isTracking) {
      stop();
    }

    _controller = StreamController<LocationPoint>.broadcast();
    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      final LocationPoint? point = _toPoint(position);
      if (point != null) {
        lastKnownPoint = point;
        _controller?.add(point);
      }
    }, onError: (_) {
      stop();
    });

    return liveUpdates;
  }

  /// Beschreibung: Beendet den GPS-Stream.
  /// Eingabe: Keine
  /// Ausgabe: `Future<void>`
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _controller?.close();
    _controller = null;
  }

  /// Beschreibung: Gibt verwendete Ressourcen frei.
  /// Eingabe: Keine
  /// Ausgabe: void
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _controller?.close();
    _controller = null;
  }

  /// Beschreibung: Konvertiert eine Geolocator-Position in ein LocationPoint-Objekt.
  /// Eingabe: position (Position?)
  /// Ausgabe: [LocationPoint]?
  LocationPoint? _toPoint(Position? position) {
    if (position == null) return null;
    return LocationPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
    );
  }
}

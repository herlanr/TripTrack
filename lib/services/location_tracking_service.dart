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

/// Kapselt das Geolocator-Plugin für schnelle GPS-Messergebnisse:
/// 1. Überprüfung von Standortberechtigungen.
/// 2. Schnelle Abfrage der GPS-Position mit 2-Sekunden-Timeout.
/// 3. Live-Streaming von GPS-Koordinaten während einer aktiven Fahrt.
class LocationTrackingService {
  StreamSubscription<Position>? _subscription;
  StreamController<LocationPoint>? _controller;

  /// Die zuletzt empfangene GPS-Position
  LocationPoint? lastKnownPoint;

  /// Gibt an, ob aktuell ein GPS-Tracking-Stream läuft.
  bool get isTracking => _subscription != null;

  /// Stream für Live-GPS-Koordinaten während einer aktiven Fahrt.
  Stream<LocationPoint> get liveUpdates {
    final controller = _controller;
    return controller != null ? controller.stream : const Stream.empty();
  }

  /// Prüft den GPS-Status und die Standortberechtigungen des Geräts.
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

  /// Öffnet die App-Einstellungen auf dem Gerät.
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Öffnet die GPS-Standorteinstellungen auf dem Gerät.
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Prüft die Berechtigungen und fordert bei Erfolg eine schnelle GPS-Position an.
  Future<LocationPoint?> requestFixWithPermission() async {
    final status = await checkPermissionStatus();
    if (status != LocationPermissionResult.granted) {
      return lastKnownPoint;
    }
    return getCurrentPosition();
  }

  /// Fragt die aktuelle GPS-Position mit einem 2-Sekunden-Timeout ab,
  /// um lange Verzögerungen beim Beenden einer Fahrt zu vermeiden.
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

  /// Startet den Live-GPS-Position-Stream.
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

  /// Beendet den GPS-Stream.
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _controller?.close();
    _controller = null;
  }

  /// Gibt Ressourcen frei.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _controller?.close();
    _controller = null;
  }

  LocationPoint? _toPoint(Position? position) {
    if (position == null) return null;
    return LocationPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
    );
  }
}

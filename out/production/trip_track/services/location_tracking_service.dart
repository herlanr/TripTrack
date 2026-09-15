import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/location_point.dart';

/// Thin wrapper around the geolocator plugin.
///
/// Responsibilities:
///  * One-shot position reads (the "Get Current Location" button).
///  * Continuous position streaming while a trip is active.
///
/// Keeping all plugin calls in one place means the UI never touches
/// `geolocator` directly, which makes it easy to swap the source of truth
/// later (e.g. a backend or a mock) without changing the screens.
class LocationTrackingService {
  StreamSubscription<Position>? _subscription;
  StreamController<LocationPoint>? _controller;

  bool get isTracking => _subscription != null;

  /// Broadcast stream of live GPS fixes while tracking.
  /// Empty when not tracking.
  Stream<LocationPoint> get liveUpdates {
    final controller = _controller;
    return controller != null ? controller.stream : const Stream.empty();
  }

  /// Checks the location permission (requesting it when denied) and then
  /// returns a single GPS fix. Returns `null` if the permission was refused
  /// or no fix could be obtained.
  Future<LocationPoint?> requestFixWithPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return getCurrentPosition();
  }

  /// Requests a single GPS fix.
  Future<LocationPoint?> getCurrentPosition() async {
    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    return _toPoint(position);
  }

  /// Starts continuous GPS tracking. Safe to call again; any existing
  /// tracking session is stopped first.
  Stream<LocationPoint> startTracking() {
    // Fire and forget the stop; it only cancels the previous session.
    unawaited(stop());

    _controller = StreamController<LocationPoint>.broadcast();
    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).listen((position) {
      final LocationPoint? point = _toPoint(position);
      if (point != null) {
        _controller?.add(point);
      }
    });

    return liveUpdates;
  }

  /// Stops continuous tracking and releases the subscription.
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _controller?.close();
    _controller = null;
  }

  LocationPoint? _toPoint(Position? position) {
    if (position == null) return null;
    return LocationPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: position.timestamp,
    );
  }
}

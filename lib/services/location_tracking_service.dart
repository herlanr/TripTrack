import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/location_point.dart';

/// Thin wrapper around the geolocator plugin.
///
/// Responsibilities:
///  * One-shot permission check + GPS fix (start/end location capture).
///  * Continuous position streaming while a trip is active.
///
/// Keeping all plugin calls in one place means the UI never touches
/// `geolocator` directly, which makes it easy to swap the source of truth
/// later (e.g. a backend or a mock) without changing the screens.
///
/// The recorded points are the basis for both the trip distance
/// (Haversine, see [TripService]) and future route visualization.
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

  /// Starts continuous GPS tracking. Safe to call again: if a session is
  /// already active, its subscription and controller are cancelled and
  /// replaced **synchronously**, so [isTracking] and [liveUpdates] are
  /// consistent immediately after this call returns.
  ///
  /// (The previous version awaited the old session's teardown here, which
  /// rescheduled it to run *after* the new session was created and silently
  /// nulled the new subscription out — the trip UI stayed "stopped".)
  Stream<LocationPoint> startTracking() {
    if (isTracking) {
      _subscription?.cancel();
      _subscription = null;
      _controller?.close();
      _controller = null;
    }

    _controller = StreamController<LocationPoint>.broadcast();
    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        // We are not doing route visualization yet; a small distance
        // filter keeps the stream from flooding us with noise.
        distanceFilter: 5,
      ),
    ).listen((position) {
      final LocationPoint? point = _toPoint(position);
      if (point != null) {
        _controller?.add(point);
      }
    }, onError: (Object error) {
      // Surface stream errors as a dead session instead of a silent hang.
      stop();
    });

    return liveUpdates;
  }

  /// Stops continuous tracking and releases the subscription. Safe to call
  /// when not tracking.
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _controller?.close();
    _controller = null;
  }

  /// Stops tracking and releases everything. Call when the owning
  /// service/screen is disposed.
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

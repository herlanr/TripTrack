import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/location_point.dart';

/// Result status of location permission and service checks.
enum LocationPermissionResult {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

/// Wraps the geolocator plugin to provide:
/// 1. Location permission checks and user advice status.
/// 2. Fast, non-blocking GPS fix retrieval (with timeout + last-known fallback).
/// 3. Continuous position streaming during an active trip.
class LocationTrackingService {
  StreamSubscription<Position>? _subscription;
  StreamController<LocationPoint>? _controller;

  /// Latest GPS fix received during active stream or manual check.
  LocationPoint? lastKnownPoint;

  bool get isTracking => _subscription != null;

  Stream<LocationPoint> get liveUpdates {
    final controller = _controller;
    return controller != null ? controller.stream : const Stream.empty();
  }

  /// Checks location service status and permission level.
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

  /// Opens app settings on the device.
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Opens system location settings on the device.
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Checks location permissions and returns a fast GPS fix if granted.
  Future<LocationPoint?> requestFixWithPermission() async {
    final status = await checkPermissionStatus();
    if (status != LocationPermissionResult.granted) {
      return lastKnownPoint;
    }
    return getCurrentPosition();
  }

  /// Retrieves current position with a 2-second timeout, falling back to
  /// `getLastKnownPosition` or `lastKnownPoint` so the app NEVER hangs.
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
      // Timeout or fix unavailable: fall back to last known cached position
      final Position? last = await Geolocator.getLastKnownPosition();
      final point = _toPoint(last) ?? lastKnownPoint;
      if (point != null) lastKnownPoint = point;
      return point;
    }
  }

  /// Starts live GPS tracking stream.
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

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _controller?.close();
    _controller = null;
  }

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

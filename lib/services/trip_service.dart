import 'dart:async';

import '../models/location_point.dart';
import '../models/trip.dart';
import '../models/trip_phase.dart';
import '../utils/geocoding_helper.dart';
import 'location_tracking_service.dart';

/// Business logic service for the trip lifecycle:
/// - Starts and stops trips cleanly.
/// - Collects GPS route points during active driving.
/// - Resolves GPS coordinates into street addresses via GeocodingHelper.
class TripService {
  TripService(this._locationService);

  final LocationTrackingService _locationService;

  static const Duration minPointInterval = Duration(minutes: 3);
  static const int maxPoints = 500;

  Trip? _trip;
  StreamSubscription<LocationPoint>? _subscription;
  final StreamController<int> _pointCountController =
      StreamController<int>.broadcast();

  Trip? get currentTrip => _trip;

  TripPhase get phase => _trip == null
      ? TripPhase.idle
      : _trip!.isFinished
          ? TripPhase.finished
          : TripPhase.active;

  Stream<int> get pointCountUpdates => _pointCountController.stream;

  /// Starts a new trip and resolves the start location address.
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

  void setManualStartLocation(String text) {
    final trip = _trip;
    if (trip != null && !trip.isFinished) {
      trip.startLocationText = text;
    }
  }

  /// Stops the current trip and resolves the end location address before returning.
  Future<Trip> stopTrip() async {
    final trip = _trip;
    if (trip == null || trip.isFinished) {
      throw StateError('Keine aktive Fahrt zum Beenden.');
    }

    trip.endTime = DateTime.now();

    // Instant location lookup using cached lastKnownPoint or fast position fix
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

  void setManualEndLocation(String text) {
    _trip?.endLocationText = text;
  }

  void reset() {
    _stopCollectingPoints();
    _trip = null;
  }

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

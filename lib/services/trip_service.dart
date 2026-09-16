import 'dart:async';

import '../models/location_point.dart';
import '../models/trip.dart';
import '../models/trip_phase.dart';
import 'location_tracking_service.dart';

/// Owns the Fahrtenbuch workflow: starting a trip, collecting GPS points
/// during the trip, and stopping it.
///
/// The trip distance is calculated from the recorded GPS points —
/// the user does not enter an end odometer reading. The start odometer
/// reading is stored for documentation only.
class TripService {
  TripService(this._locationService);

  final LocationTrackingService _locationService;

  /// While a trip is active, at most one point is stored per
  /// [minPointInterval]. A simple time filter keeps the stored list small
  /// ("avoid excessive storage") without any distance math: a 1-hour trip
  /// stores at most 12 points.
  static const Duration minPointInterval = Duration(minutes: 5);

  /// Safety cap so the list can never grow without limit.
  static const int maxPoints = 500;

  Trip? _trip;
  StreamSubscription<LocationPoint>? _subscription;
  final StreamController<int> _pointCountController =
      StreamController<int>.broadcast();

  /// The current trip (null when no trip has been started yet).
  Trip? get currentTrip => _trip;

  /// Which phase of the trip lifecycle we are in. The UI uses this to
  /// enable/disable the Start and Stop buttons.
  TripPhase get phase => _trip == null
      ? TripPhase.idle
      : _trip!.isFinished
          ? TripPhase.finished
          : TripPhase.active;

  /// Live updates of how many points were stored so far (for the UI).
  /// The GPS distance is a pure function of the stored points, so it
  /// changes at exactly the same moments — the UI simply re-reads
  /// [Trip.distanceKm] after each update.
  Stream<int> get pointCountUpdates => _pointCountController.stream;

  /// Starts a new trip.
  ///
  /// Tries to get a GPS fix for the start location. If no fix is available,
  /// the returned trip simply has no start location — the UI then offers a
  /// manual input field (see [setManualStartLocation]).
  Future<Trip> startTrip({
    required String driverName,
    required double startKm,
  }) async {
    if (phase == TripPhase.active) {
      throw StateError('A trip is already running.');
    }

    final LocationPoint? startFix =
        await _locationService.requestFixWithPermission();

    final trip = Trip(
      driverName: driverName,
      startKm: startKm,
      startTime: DateTime.now(),
      startLatitude: startFix?.latitude,
      startLongitude: startFix?.longitude,
      startLocationText: startFix?.describe(),
    );
    _trip = trip;
    _startCollectingPoints();
    return trip;
  }

  /// Stores a manually entered start location (used when GPS was not
  /// available at trip start).
  void setManualStartLocation(String text) {
    final trip = _trip;
    if (trip != null && !trip.isFinished) {
      trip.startLocationText = text;
    }
  }

  /// Stops the current trip.
  ///
  /// Saves the end time, tries to get a GPS fix for the end location, and
  /// stops collecting points. If no fix is available, the UI offers a
  /// manual input (see [setManualEndLocation]).
  Future<Trip> stopTrip() async {
    final trip = _trip;
    if (trip == null || trip.isFinished) {
      throw StateError('No active trip to stop.');
    }

    trip.endTime = DateTime.now();

    final LocationPoint? endFix =
        await _locationService.requestFixWithPermission();
    if (endFix != null) {
      trip.endLatitude = endFix.latitude;
      trip.endLongitude = endFix.longitude;
      trip.endLocationText = endFix.describe();
    }

    _stopCollectingPoints();
    return trip;
  }

  /// Stores a manually entered end location (used when GPS was not
  /// available at trip stop).
  void setManualEndLocation(String text) {
    _trip?.endLocationText = text;
  }

  /// Clears the finished trip and goes back to the idle state.
  void reset() {
    _stopCollectingPoints();
    _trip = null;
  }

  /// Releases all resources. Call from the screen's dispose().
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

  /// Stores a GPS fix only if enough time has passed since the last stored
  /// point. This way a 1-hour trip stores about 12 points instead of
  /// thousands.
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

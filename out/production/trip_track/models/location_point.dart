/// A single GPS fix captured while a trip is active.
class LocationPoint {
  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  /// Horizontal accuracy reported by the GPS receiver, in meters.
  final double accuracy;
  final DateTime timestamp;

  /// Human-readable "lat, lon (±accuracy m)" for display on screen.
  String describe() =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)} '
      '(±${accuracy.toStringAsFixed(0)} m)';

  @override
  String toString() =>
      'LocationPoint($latitude, $longitude, ±$accuracy m, $timestamp)';
}

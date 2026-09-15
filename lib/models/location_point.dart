/// A single GPS fix.
///
/// GPS data is used for **location documentation only** (start location,
/// end location, intermediate points). The official trip distance is
/// always calculated from the odometer, never from GPS.
class LocationPoint {
  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;

  /// Human-readable "lat, lon" for display on screen.
  String describe() =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  @override
  String toString() => 'LocationPoint($latitude, $longitude, $timestamp)';
}

/// A single GPS fix.
///
/// GPS data is used for the trip distance (sum of the Haversine segments
/// between the recorded points) and for location documentation
/// (start location, end location, intermediate points).
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

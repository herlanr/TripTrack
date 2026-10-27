import 'dart:convert';
import 'package:http/http.dart' as http;

/// Helper utility for reverse geocoding (converting GPS coordinates to street addresses).
/// Works cross-platform (Android, iOS, Web/Chrome) using OpenStreetMap Nominatim API
class GeocodingHelper {
  /// Converts latitude and longitude into a human-readable street address or city name.
  /// Example: (50.980454, 11.311514) -> "Nordhäuser Straße, Erfurt"
  /// Falls back to formatted "lat, lon" string if offline or if resolution fails.
  static Future<String> getAddressFromCoordinates(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'TripTrackApp/1.0 (Uni Erfurt)'},
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final road = (address['road'] ??
                  address['pedestrian'] ??
                  address['suburb'] ??
                  '')
              .toString();
          final city = (address['city'] ??
                  address['town'] ??
                  address['village'] ??
                  address['municipality'] ??
                  '')
              .toString();

          if (road.isNotEmpty && city.isNotEmpty) {
            return '$road, $city';
          } else if (city.isNotEmpty) {
            return city;
          } else if (road.isNotEmpty) {
            return road;
          }
        }
      }
    } catch (_) {
      // Fallback on timeout or network error
    }

    // Fallback: Formatted Coordinate String
    return '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
  }
}

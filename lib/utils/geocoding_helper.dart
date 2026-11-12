import 'dart:convert';
import 'package:http/http.dart' as http;

/// Hilfsklasse für Reverse Geocoding (Umwandlung von GPS-Koordinaten in Straßenadressen via OpenStreetMap Nominatim API).
class GeocodingHelper {
  /// Beschreibung: Konvertiert Breitengrad und Längengrad in eine lesbare Straßenadresse oder Ortsbezeichnung.
  /// Eingabe: lat (double), lon (double)
  /// Ausgabe: `Future<String>`
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
      // Fallback bei Timeout oder Netzwerkfehler
    }

    // Fallback: Formatierter Koordinaten-String
    return '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
  }
}

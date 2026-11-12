import 'dart:math';

/// Berechnet die Orthodrome-Distanz (Großkreisdistanz) zwischen zwei GPS-Koordinaten in Kilometern über die Haversine-Formel.

/// Beschreibung: Berechnet die Entfernung zwischen zwei GPS-Punkten in Kilometern.
/// Eingabe: latitude1 (double), longitude1 (double), latitude2 (double), longitude2 (double)
/// Ausgabe: double
double haversineDistanceKm({
  required double latitude1,
  required double longitude1,
  required double latitude2,
  required double longitude2,
}) {
  /// Mittlerer Erdradius in Kilometern
  const double earthRadiusKm = 6371.0088;

  final double dLat = _toRadians(latitude2 - latitude1);
  final double dLon = _toRadians(longitude2 - longitude1);

  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(latitude1)) *
          cos(_toRadians(latitude2)) *
          sin(dLon / 2) *
          sin(dLon / 2);

  final double c = 2 * asin(min(1.0, sqrt(a)));

  return earthRadiusKm * c;
}

/// Beschreibung: Rechnet Gradmaß in Bogenmaß (Radiant) um.
/// Eingabe: degrees (double)
/// Ausgabe: double
double _toRadians(double degrees) => degrees * pi / 180;

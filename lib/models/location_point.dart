import 'package:json_annotation/json_annotation.dart';

part 'location_point.g.dart';

/// Repräsentiert das Datenmodell für einen einzelnen GPS-Standortpunkt in TripTrack.
@JsonSerializable()
class LocationPoint {
  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.addressText,
  });

  /// Breitengrad der GPS-Koordinate
  final double latitude;

  /// Längengrad der GPS-Koordinate
  final double longitude;

  /// Zeitstempel der Standorterfassung
  final DateTime timestamp;

  /// Optionale Orts- oder Straßenbezeichnung (über Geocoding)
  final String? addressText;

  /// Beschreibung: Gibt die Adresse oder die GPS-Koordinaten als lesbaren Text zurück.
  /// Eingabe: Keine
  /// Ausgabe: String
  String describe() {
    if (addressText != null && addressText!.isNotEmpty) {
      return addressText!;
    }
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  /// Beschreibung: Erstellt einen LocationPoint aus einem JSON-Map.
  /// Eingabe: json (`Map<String, dynamic>`)
  /// Ausgabe: [LocationPoint]
  factory LocationPoint.fromJson(Map<String, dynamic> json) =>
      _$LocationPointFromJson(json);

  /// Beschreibung: Konvertiert den LocationPoint in ein JSON-Map.
  /// Eingabe: Keine
  /// Ausgabe: `Map<String, dynamic>`
  Map<String, dynamic> toJson() => _$LocationPointToJson(this);

  /// Beschreibung: Gibt eine Textdarstellung des LocationPoint-Objekts zurück.
  /// Eingabe: Keine
  /// Ausgabe: String
  @override
  String toString() =>
      'LocationPoint($latitude, $longitude, $timestamp, addressText: $addressText)';
}

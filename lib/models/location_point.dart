import 'package:json_annotation/json_annotation.dart';

part 'location_point.g.dart';

/// Repräsentiert einen einzelnen GPS-Standortpunkt (Breitengrad, Längengrad, Zeitstempel, optionale Adresse).
@JsonSerializable()
class LocationPoint {
  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.addressText,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;

  /// Optionale Orts- oder Straßenbezeichnung
  final String? addressText;

  /// Gibt die Adresse oder die Koordinaten als lesbaren Text zurück.
  String describe() {
    if (addressText != null && addressText!.isNotEmpty) {
      return addressText!;
    }
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  /// Erstellt einen LocationPoint aus einem JSON-Map.
  factory LocationPoint.fromJson(Map<String, dynamic> json) =>
      _$LocationPointFromJson(json);

  /// Konvertiert den LocationPoint in ein JSON-Map.
  Map<String, dynamic> toJson() => _$LocationPointToJson(this);

  @override
  String toString() =>
      'LocationPoint($latitude, $longitude, $timestamp, addressText: $addressText)';
}

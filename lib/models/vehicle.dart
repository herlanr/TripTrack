import 'package:json_annotation/json_annotation.dart';

part 'vehicle.g.dart';

/// Repräsentiert das Datenmodell für ein Fahrzeug in TripTrack.
@JsonSerializable()
class Vehicle {
  const Vehicle({
    required this.id,
    required this.driverId,
    required this.licensePlate,
    required this.model,
    required this.brand,
    required this.currentKm,
  });

  /// Eindeutige ID des Fahrzeugs
  final String id;

  /// Zuordnung zum Fahrer (Fremdschlüssel)
  @JsonKey(defaultValue: '')
  final String driverId;

  /// Amtliches Kennzeichen des Fahrzeugs
  final String licensePlate;

  /// Modellbezeichnung des Fahrzeugs
  final String model;

  /// Fahrzeugmarke
  final String brand;

  /// Aktueller Tacho-Kilometerstand in km
  final double currentKm;

  /// Beschreibung: Formatiert den Anzeigenamen des Fahrzeugs ("Marke Modell (Kennzeichen)").
  /// Eingabe: Keine
  /// Ausgabe: String
  String get displayName => '$brand $model ($licensePlate)';

  /// Beschreibung: Erstellt eine Kopie des Fahrzeugs mit optional geänderten Werten.
  /// Eingabe: id (String?), driverId (String?), licensePlate (String?), model (String?), brand (String?), currentKm (double?)
  /// Ausgabe: [Vehicle]
  Vehicle copyWith({
    String? id,
    String? driverId,
    String? licensePlate,
    String? model,
    String? brand,
    double? currentKm,
  }) {
    return Vehicle(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      licensePlate: licensePlate ?? this.licensePlate,
      model: model ?? this.model,
      brand: brand ?? this.brand,
      currentKm: currentKm ?? this.currentKm,
    );
  }

  /// Beschreibung: Erstellt eine Fahrzeug-Instanz aus einem JSON-Map.
  /// Eingabe: json (`Map<String, dynamic>`)
  /// Ausgabe: [Vehicle]
  factory Vehicle.fromJson(Map<String, dynamic> json) => _$VehicleFromJson(json);

  /// Beschreibung: Konvertiert die Fahrzeug-Instanz in ein JSON-Map.
  /// Eingabe: Keine
  /// Ausgabe: `Map<String, dynamic>`
  Map<String, dynamic> toJson() => _$VehicleToJson(this);

  /// Beschreibung: Prüft die Gleichheit zweier Fahrzeuge anhand ihrer ID.
  /// Eingabe: other (Object)
  /// Ausgabe: bool
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vehicle && runtimeType == other.runtimeType && id == other.id;

  /// Beschreibung: Generiert den Hashcode basierend auf der eindeutigen Fahrzeug-ID.
  /// Eingabe: Keine
  /// Ausgabe: int
  @override
  int get hashCode => id.hashCode;
}

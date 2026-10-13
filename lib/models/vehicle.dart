import 'package:json_annotation/json_annotation.dart';

part 'vehicle.g.dart';

/// Repräsentiert ein Fahrzeug (Fahrzeug-Entität aus dem ER-Diagramm).
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

  final String id;

  @JsonKey(defaultValue: '')
  final String driverId;
  final String licensePlate;
  final String model;
  final String brand;
  final double currentKm;

  /// Formatiert den Anzeigenamen des Fahrzeugs ("Marke Modell (Kennzeichen)").
  String get displayName => '$brand $model ($licensePlate)';

  /// Erstellt eine Kopie des Fahrzeugs mit optional geänderten Werten.
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

  /// Erstellt eine Fahrzeug-Instanz aus einem JSON-Map.
  factory Vehicle.fromJson(Map<String, dynamic> json) => _$VehicleFromJson(json);

  /// Konvertiert die Fahrzeug-Instanz in ein JSON-Map.
  Map<String, dynamic> toJson() => _$VehicleToJson(this);

  /// Prüft die Gleichheit zweier Fahrzeuge anhand ihrer ID.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vehicle && runtimeType == other.runtimeType && id == other.id;

  /// Generiert den Hashcode basierend auf der Fahrzeug-ID.
  @override
  int get hashCode => id.hashCode;
}

import 'package:json_annotation/json_annotation.dart';

part 'driver.g.dart';

/// Repräsentiert ein Fahrer-Profil (Fahrer-Entität aus dem ER-Diagramm).
@JsonSerializable()
class Driver {
  const Driver({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
  });

  final String id;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;

  String get fullName => '$firstName $lastName';

  /// Erstellt eine Fahrer-Instanz aus einem JSON-Map.
  factory Driver.fromJson(Map<String, dynamic> json) => _$DriverFromJson(json);

  /// Konvertiert die Fahrer-Instanz in ein JSON-Map.
  Map<String, dynamic> toJson() => _$DriverToJson(this);

  /// Prüft die Gleichheit zweier Fahrer anhand ihrer ID.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Driver && runtimeType == other.runtimeType && id == other.id;

  /// Generiert den Hashcode basierend auf der eindeutigen Fahrer-ID.
  @override
  int get hashCode => id.hashCode;
}

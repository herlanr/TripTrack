import 'package:json_annotation/json_annotation.dart';

part 'driver.g.dart';

/// Repräsentiert das Datenmodell für ein Fahrer-Profil in TripTrack.
@JsonSerializable()
class Driver {
  const Driver({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
  });

  /// Eindeutige ID des Fahrers
  final String id;

  /// Vorname des Fahrers
  final String firstName;

  /// Nachname des Fahrers
  final String lastName;

  /// Geburtsdatum des Fahrers
  final DateTime dateOfBirth;

  /// Beschreibung: Gibt den vollständigen Namen des Fahrers zurück.
  /// Eingabe: Keine
  /// Ausgabe: String
  String get fullName => '$firstName $lastName';

  /// Beschreibung: Erstellt eine Kopie des Fahrers mit optional geänderten Werten.
  /// Eingabe: id (String?), firstName (String?), lastName (String?), dateOfBirth (DateTime?)
  /// Ausgabe: [Driver]
  Driver copyWith({
    String? id,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
  }) {
    return Driver(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    );
  }

  /// Beschreibung: Erstellt eine Fahrer-Instanz aus einem JSON-Map.
  /// Eingabe: json (`Map<String, dynamic>`)
  /// Ausgabe: [Driver]
  factory Driver.fromJson(Map<String, dynamic> json) => _$DriverFromJson(json);

  /// Beschreibung: Konvertiert die Fahrer-Instanz in ein JSON-Map.
  /// Eingabe: Keine
  /// Ausgabe: `Map<String, dynamic>`
  Map<String, dynamic> toJson() => _$DriverToJson(this);

  /// Beschreibung: Prüft die Gleichheit zweier Fahrer anhand ihrer ID.
  /// Eingabe: other (Object)
  /// Ausgabe: bool
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Driver && runtimeType == other.runtimeType && id == other.id;

  /// Beschreibung: Generiert den Hashcode basierend auf der eindeutigen Fahrer-ID.
  /// Eingabe: Keine
  /// Ausgabe: int
  @override
  int get hashCode => id.hashCode;
}

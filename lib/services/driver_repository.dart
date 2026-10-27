import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/driver.dart';

/// Kapselt die lokale Speicherung von Fahrer-Profilen in [SharedPreferences].
///
/// Liest und schreibt direkt in [SharedPreferences] ohne Instanz-Cache,
/// um Synchronisationsprobleme zwischen verschiedenen Screen-Instanzen zu vermeiden.
class DriverRepository {
  /// Maximale Anzahl erlaubter Fahrer-Profile
  static const int maxProfiles = 4;

  /// Schlüssel für die SharedPreferences-Speicherung
  static const String _prefsKey = 'triptrack_drivers_v1';

  /// Standardmäßiges Test-Fahrerprofil für den Schnellstart
  static final Driver defaultTestDriver = Driver(
    id: 'test_driver_101',
    firstName: 'Test',
    lastName: 'Fahrer',
    dateOfBirth: DateTime(1990, 1, 1),
  );

  /// Beschreibung: Liest alle Fahrer-Profile direkt aus dem lokalen Speicher.
  /// Autor: @herlanr
  /// Eingabe: Keine
  /// Ausgabe: Liste von Fahrer-Instanzen
  Future<List<Driver>> _loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_prefsKey);
      if (jsonString == null || jsonString.isEmpty) return [];

      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((e) => Driver.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Fehler beim Laden der Fahrer-Profile: $e');
      }
      return [];
    }
  }

  /// Beschreibung: Schreibt die komplette Fahrerliste als JSON-String in den Speicher.
  /// Autor: @herlanr
  /// Eingabe: drivers (List of Driver)
  /// Ausgabe: Keine
  Future<void> _saveAll(List<Driver> drivers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString =
          jsonEncode(drivers.map((d) => d.toJson()).toList());
      await prefs.setString(_prefsKey, jsonString);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Fehler beim Speichern der Fahrer-Profile: $e');
      }
    }
  }

  /// Beschreibung: Lädt alle gespeicherten Fahrer aus dem lokalen Speicher.
  /// Erstellt automatisch das Test-Fahrerprofil, falls der Speicher komplett leer ist.
  /// Autor: @herlanr
  /// Eingabe: Keine
  /// Ausgabe: Liste von Fahrer-Instanzen
  Future<List<Driver>> getDrivers() async {
    final drivers = await _loadAll();

    // Standardmäßigen Test-Fahrer anlegen, falls noch gar keine Profile existieren
    if (drivers.isEmpty) {
      drivers.add(defaultTestDriver);
      await _saveAll(drivers);
    }

    return drivers;
  }

  /// Beschreibung: Fügt ein neues Fahrer-Profil hinzu. Wirft einen [StateError], wenn das Limit (4) erreicht ist.
  /// Autor: @herlanr
  /// Eingabe: driver ([Driver])
  /// Ausgabe: Keine
  Future<void> addDriver(Driver driver) async {
    final drivers = await _loadAll();

    if (drivers.length >= maxProfiles) {
      throw StateError(
        'Maximale Anzahl von $maxProfiles Fahrer-Profilen erreicht. Bitte zuerst ein Profil löschen.',
      );
    }

    drivers.add(driver);
    await _saveAll(drivers);
  }

  /// Beschreibung: Löscht ein Fahrer-Profil anhand seiner ID.
  /// Autor: @herlanr
  /// Eingabe: driverId (String)
  /// Ausgabe: Keine
  Future<void> deleteDriver(String driverId) async {
    final drivers = await _loadAll();
    drivers.removeWhere((d) => d.id == driverId);
    await _saveAll(drivers);
  }
}

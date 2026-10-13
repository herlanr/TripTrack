import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/driver.dart';

/// Kapselt die lokale Speicherung von Fahrer-Profilen in [SharedPreferences].
class DriverRepository {

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

  final List<Driver> _inMemoryDrivers = [];
  bool _initialized = false;

  /// Lädt alle gespeicherten Fahrer aus dem lokalen Speicher.
  /// Erstellt automatisch das Test-Fahrerprofil, falls der Speicher leer ist.
  Future<List<Driver>> getDrivers() async {
    if (_initialized) return List.unmodifiable(_inMemoryDrivers);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_prefsKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
        _inMemoryDrivers.clear();
        _inMemoryDrivers.addAll(
          decoded.map((e) => Driver.fromJson(e as Map<String, dynamic>)),
        );
      }
    } catch (_) {
      // Rückfalloption bei Speicherfehler
    }

    // Standardmäßigen Test-Fahrer anlegen, falls noch keine Profile existieren
    if (_inMemoryDrivers.isEmpty) {
      _inMemoryDrivers.add(defaultTestDriver);
      await _saveToDisk();
    }

    _initialized = true;
    return List.unmodifiable(_inMemoryDrivers);
  }

  /// Fügt ein neues Fahrer-Profil hinzu. Wirft einen [StateError], wenn das Limit (4) erreicht ist.
  Future<void> addDriver(Driver driver) async {
    await getDrivers(); // Sicherstellen, dass die Daten geladen sind

    if (_inMemoryDrivers.length >= maxProfiles) {
      throw StateError(
        'Maximale Anzahl von $maxProfiles Fahrer-Profilen erreicht. Bitte zuerst ein Profil löschen.',
      );
    }

    _inMemoryDrivers.add(driver);
    await _saveToDisk();
  }

  /// Löscht ein Fahrer-Profil anhand seiner ID.
  Future<void> deleteDriver(String driverId) async {
    await getDrivers();
    _inMemoryDrivers.removeWhere((d) => d.id == driverId);
    await _saveToDisk();
  }

  /// Speichert die aktuelle Fahrerliste als JSON-String auf der Festplatte.
  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(
        _inMemoryDrivers.map((d) => d.toJson()).toList(),
      );
      await prefs.setString(_prefsKey, jsonString);
    } catch (_) {
      // Fehler beim Speichern ignorieren
    }
  }
}

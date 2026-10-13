import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/trip.dart';

/// REPOSITORY PATTERN IMPLEMENTATION (Fahrtenbuch-Datenhaltung)
///
/// Kapselt die dauerhafte Speicherung von beendeten Fahrtenbuch-Einträgen in [SharedPreferences].
/// Jeder Eintrag speichert Metadaten, Orte, Strecken, Dauer und die vollständige GPS-Routenliste (`routePoints`).
class TripRepository {
  static const String _prefsKey = 'triptrack_saved_trips_v1';

  final List<Trip> _inMemoryTrips = [];
  bool _initialized = false;

  /// Lädt alle gespeicherten Fahrten aus dem lokalen Speicher.
  Future<List<Trip>> getTrips() async {
    if (_initialized) return List.unmodifiable(_inMemoryTrips);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_prefsKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
        _inMemoryTrips.clear();
        _inMemoryTrips.addAll(
          decoded.map((e) => Trip.fromJson(e as Map<String, dynamic>)),
        );
      }
    } catch (_) {
      // Fehler beim Laden ignorieren
    }

    _initialized = true;
    return List.unmodifiable(_inMemoryTrips);
  }

  /// Speichert eine neu beendete Fahrt dauerhaft im lokalen Speicher.
  Future<void> saveTrip(Trip trip) async {
    await getTrips(); // Sicherstellen, dass die Daten geladen sind
    _inMemoryTrips.insert(0, trip); // Neueste Fahrt zuerst
    await _saveToDisk();
  }

  /// Löscht einen Fahrtenbuch-Eintrag anhand seiner ID.
  Future<void> deleteTrip(String tripId) async {
    await getTrips();
    _inMemoryTrips.removeWhere((t) => t.id == tripId);
    await _saveToDisk();
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(
        _inMemoryTrips.map((t) => t.toJson()).toList(),
      );
      await prefs.setString(_prefsKey, jsonString);
    } catch (_) {
      // Fehler beim Speichern ignorieren
    }
  }
}

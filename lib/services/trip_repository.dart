import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock_trips.dart';
import '../models/trip.dart';

/// REPOSITORY PATTERN IMPLEMENTATION (Fahrtenbuch-Datenhaltung)
///
/// Kapselt die dauerhafte Speicherung von beendeten Fahrtenbuch-Einträgen in [SharedPreferences].
/// Jeder Eintrag speichert Metadaten, Orte, Strecken, Dauer und die vollständige GPS-Routenliste (`routePoints`).
class TripRepository {
  static const String _prefsKey = 'triptrack_saved_trips_v1';

  /// Erste Beispielfahrt für Schnelltests
  static final Trip defaultTestTrip = mockTrips.first;

  /// Beschreibung: Liest alle gespeicherten Fahrten direkt aus dem lokalen Speicher.
  /// Autor: @herlanr
  /// Eingabe: Keine
  /// Ausgabe: Liste von Trip-Instanzen
  Future<List<Trip>> _loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_prefsKey);
      if (jsonString == null || jsonString.isEmpty) return [];

      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((e) => Trip.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Fehler beim Laden der Fahrten: $e');
      }
      return [];
    }
  }

  /// Beschreibung: Schreibt die komplette Fahrtenliste als JSON-String in den Speicher.
  /// Autor: @herlanr
  /// Eingabe: trips (List of Trip)
  /// Ausgabe: Keine
  Future<void> _saveAll(List<Trip> trips) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString =
          jsonEncode(trips.map((t) => t.toJson()).toList());
      await prefs.setString(_prefsKey, jsonString);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Fehler beim Speichern der Fahrten: $e');
      }
    }
  }

  /// Beschreibung: Lädt alle gespeicherten Fahrten aus dem lokalen Speicher.
  /// Befüllt automatisch die 10 Mock-Fahrten aus [mockTrips], falls der Speicher komplett leer ist.
  /// Autor: @herlanr
  /// Eingabe: Keine
  /// Ausgabe: Liste von Trip-Instanzen
  Future<List<Trip>> getTrips() async {
    final trips = await _loadAll();

    if (trips.isEmpty) {
      trips.addAll(mockTrips);
      await _saveAll(trips);
    }

    return trips;
  }

  /// Beschreibung: Speichert eine neu beendete Fahrt dauerhaft im lokalen Speicher.
  /// Autor: @herlanr
  /// Eingabe: trip ([Trip])
  /// Ausgabe: Keine
  Future<void> saveTrip(Trip trip) async {
    final trips = await _loadAll();
    trips.insert(0, trip); // Neueste Fahrt zuerst
    await _saveAll(trips);
  }

  /// Beschreibung: Löscht einen Fahrtenbuch-Eintrag anhand seiner ID.
  /// Autor: @herlanr
  /// Eingabe: tripId (String)
  /// Ausgabe: Keine
  Future<void> deleteTrip(String tripId) async {
    final trips = await _loadAll();
    trips.removeWhere((t) => t.id == tripId);
    await _saveAll(trips);
  }
}

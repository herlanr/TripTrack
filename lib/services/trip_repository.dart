import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/trip.dart';

/// REPOSITORY PATTERN IMPLEMENTATION (Fahrtenbuch-Datenhaltung)
///
/// Encapsulates persistent storage for completed trip logbook entries in [SharedPreferences].
/// Every trip JSON record permanently stores metadata, start/end locations, distance,
/// duration, and the full list of recorded GPS route points (`routePoints`).
class TripRepository {
  static const String _prefsKey = 'triptrack_saved_trips_v1';

  final List<Trip> _inMemoryTrips = [];
  bool _initialized = false;

  /// Loads all saved trips from disk.
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
      // Fallback on error
    }

    _initialized = true;
    return List.unmodifiable(_inMemoryTrips);
  }

  /// Saves a newly completed trip to local storage.
  Future<void> saveTrip(Trip trip) async {
    await getTrips(); // ensure initialized
    _inMemoryTrips.insert(0, trip); // newest first
    await _saveToDisk();
  }

  /// Deletes a trip by ID.
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
      // Storage error fallback
    }
  }
}

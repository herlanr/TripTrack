import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/driver.dart';

/// Manages driver profile persistence and enforces the 4-profile limit.
class DriverRepository {
  static const int maxProfiles = 4;
  static const String _prefsKey = 'triptrack_drivers_v1';

  static final Driver defaultTestDriver = Driver(
    id: 'test_driver_101',
    firstName: 'Test',
    lastName: 'Fahrer',
    dateOfBirth: DateTime(1990, 1, 1),
  );

  final List<Driver> _inMemoryDrivers = [];
  bool _initialized = false;

  /// Loads stored drivers from local storage, pre-seeding a default test driver if empty.
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
      // Fall back to in-memory list on storage error
    }

    // Pre-seed default test driver if no drivers exist
    if (_inMemoryDrivers.isEmpty) {
      _inMemoryDrivers.add(defaultTestDriver);
      await _saveToDisk();
    }

    _initialized = true;
    return List.unmodifiable(_inMemoryDrivers);
  }

  /// Adds a new driver profile. Throws [StateError] if limit (4) is reached.
  Future<void> addDriver(Driver driver) async {
    await getDrivers(); // ensure initialized

    if (_inMemoryDrivers.length >= maxProfiles) {
      throw StateError(
        'Maximale Anzahl von $maxProfiles Fahrer-Profilen erreicht. Bitte zuerst ein Profil löschen.',
      );
    }

    _inMemoryDrivers.add(driver);
    await _saveToDisk();
  }

  /// Deletes a driver profile by ID.
  Future<void> deleteDriver(String driverId) async {
    await getDrivers(); // ensure initialized
    _inMemoryDrivers.removeWhere((d) => d.id == driverId);
    await _saveToDisk();
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(
        _inMemoryDrivers.map((d) => d.toJson()).toList(),
      );
      await prefs.setString(_prefsKey, jsonString);
    } catch (_) {
      // Storage error fallback
    }
  }
}

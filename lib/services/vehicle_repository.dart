import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vehicle.dart';

/// Kapselt die lokale Speicherung von Fahrzeugen in SharedPreferences.
class VehicleRepository {
  /// Schlüssel für die SharedPreferences-Speicherung
  static const String _prefsKey = 'triptrack_vehicles_v1';

  /// Standardmäßiges Test-Fahrzeug (Volkswagen Golf VIII)
  static final Vehicle defaultTestVehicle = Vehicle(
    id: 'test_vehicle_202',
    driverId: 'test_driver_101',
    brand: 'Volkswagen',
    model: 'Golf VIII',
    licensePlate: 'EF-TT 2026',
    currentKm: 254660.0,
  );

  /// Beschreibung: Liest alle Fahrzeuge direkt aus dem lokalen Speicher.
  /// Eingabe: Keine
  /// Ausgabe: `Future<List<Vehicle>>`
  Future<List<Vehicle>> _loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_prefsKey);
      if (jsonString == null || jsonString.isEmpty) return [];

      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Fehler beim Laden der Fahrzeuge: $e');
      }
      return [];
    }
  }

  /// Beschreibung: Schreibt die komplette Fahrzeugliste als JSON-String in den Speicher.
  /// Eingabe: vehicles (`List<Vehicle>`)
  /// Ausgabe: `Future<void>`
  Future<void> _saveAll(List<Vehicle> vehicles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString =
          jsonEncode(vehicles.map((v) => v.toJson()).toList());
      await prefs.setString(_prefsKey, jsonString);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Fehler beim Speichern der Fahrzeuge: $e');
      }
    }
  }

  /// Beschreibung: Gibt alle Fahrzeuge zurück, die zu einem bestimmten Fahrer gehören.
  /// Eingabe: driverId (String)
  /// Ausgabe: `Future<List<Vehicle>>`
  Future<List<Vehicle>> getVehiclesForDriver(String driverId) async {
    final all = await _loadAll();

    // Standardmäßiges Test-Fahrzeug anlegen, falls für den Test-Fahrer noch kein Fahrzeug existiert
    if (driverId == defaultTestVehicle.driverId &&
        !all.any((v) => v.driverId == driverId)) {
      all.add(defaultTestVehicle);
      await _saveAll(all);
    }

    return all.where((v) => v.driverId == driverId).toList();
  }

  /// Beschreibung: Fügt ein neues Fahrzeug hinzu und speichert es lokal.
  /// Eingabe: vehicle ([Vehicle])
  /// Ausgabe: `Future<void>`
  Future<void> addVehicle(Vehicle vehicle) async {
    final all = await _loadAll();
    all.add(vehicle);
    await _saveAll(all);
  }

  /// Beschreibung: Aktualisiert den Tacho-Stand eines bestimmten Fahrzeugs.
  /// Eingabe: vehicleId (String), newKm (double)
  /// Ausgabe: `Future<void>`
  Future<void> updateVehicleKm(String vehicleId, double newKm) async {
    final all = await _loadAll();
    final index = all.indexWhere((v) => v.id == vehicleId);
    if (index == -1) return;
    all[index] = all[index].copyWith(currentKm: newKm);
    await _saveAll(all);
  }

  /// Beschreibung: Aktualisiert die Daten eines bestehenden Fahrzeugs.
  /// Eingabe: vehicle ([Vehicle])
  /// Ausgabe: `Future<void>`
  Future<void> updateVehicle(Vehicle vehicle) async {
    final all = await _loadAll();
    final index = all.indexWhere((v) => v.id == vehicle.id);
    if (index == -1) return;
    all[index] = vehicle;
    await _saveAll(all);
  }

  /// Beschreibung: Löscht ein Fahrzeug anhand seiner ID.
  /// Eingabe: vehicleId (String)
  /// Ausgabe: `Future<void>`
  Future<void> deleteVehicle(String vehicleId) async {
    final all = await _loadAll();
    all.removeWhere((v) => v.id == vehicleId);
    await _saveAll(all);
  }

  /// Beschreibung: Löscht alle Fahrzeuge eines bestimmten Fahrers.
  /// Eingabe: driverId (String)
  /// Ausgabe: `Future<void>`
  Future<void> deleteVehiclesForDriver(String driverId) async {
    final all = await _loadAll();
    all.removeWhere((v) => v.driverId == driverId);
    await _saveAll(all);
  }
}

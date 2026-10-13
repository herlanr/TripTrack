import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vehicle.dart';

/// REPOSITORY PATTERN IMPLEMENTATION (Fahrzeug-Datenhaltung)
///
/// Kapselt die lokale Speicherung von Fahrzeugen in [SharedPreferences].
/// Bietet Methoden zum Abfragen von Fahrzeugen nach Fahrer-ID (`getVehiclesForDriver`),
/// Hinzufügen von Fahrzeugen (`addVehicle`) und Aktualisieren des Tacho-Standes (`updateVehicleKm`).
class VehicleRepository {
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

  final List<Vehicle> _inMemoryVehicles = [];
  bool _initialized = false;

  Future<List<Vehicle>> _loadAllVehicles() async {
    if (_initialized) return _inMemoryVehicles;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_prefsKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
        _inMemoryVehicles.clear();
        _inMemoryVehicles.addAll(
          decoded.map((e) => Vehicle.fromJson(e as Map<String, dynamic>)),
        );
      }
    } catch (_) {
      // Fehler beim Speichern ignorieren
    }

    // Standardmäßiges Test-Fahrzeug anlegen, falls noch keine Fahrzeuge existieren
    if (_inMemoryVehicles.isEmpty) {
      _inMemoryVehicles.add(defaultTestVehicle);
      await _saveToDisk();
    }

    _initialized = true;
    return _inMemoryVehicles;
  }

  /// Gibt alle Fahrzeuge zurück, die einer bestimmten Fahrer-ID zugeordnet sind.
  /// Falls der Fahrer noch kein Fahrzeug hat, wird ihm automatisch ein Standard-Fahrzeug zugewiesen.
  Future<List<Vehicle>> getVehiclesForDriver(String driverId) async {
    final all = await _loadAllVehicles();
    final driverVehicles = all.where((v) => v.driverId == driverId).toList();

    if (driverVehicles.isEmpty) {
      final newVehicle = Vehicle(
        id: 'v_${DateTime.now().millisecondsSinceEpoch}',
        driverId: driverId,
        brand: 'Volkswagen',
        model: 'Golf VIII',
        licensePlate: 'EF-TT 2026',
        currentKm: 254660.0,
      );
      _inMemoryVehicles.add(newVehicle);
      await _saveToDisk();
      return [newVehicle];
    }

    return driverVehicles;
  }

  /// Fügt ein neues Fahrzeug hinzu und speichert es lokal.
  Future<void> addVehicle(Vehicle vehicle) async {
    await _loadAllVehicles();
    _inMemoryVehicles.add(vehicle);
    await _saveToDisk();
  }

  /// Aktualisiert den aktuellen Kilometerstand eines Fahrzeugs.
  Future<void> updateVehicleKm(String vehicleId, double newKm) async {
    await _loadAllVehicles();
    final index = _inMemoryVehicles.indexWhere((v) => v.id == vehicleId);
    if (index != -1) {
      _inMemoryVehicles[index] =
          _inMemoryVehicles[index].copyWith(currentKm: newKm);
      await _saveToDisk();
    }
  }

  /// Löscht ein Fahrzeug anhand seiner ID.
  Future<void> deleteVehicle(String vehicleId) async {
    await _loadAllVehicles();
    _inMemoryVehicles.removeWhere((v) => v.id == vehicleId);
    await _saveToDisk();
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(
        _inMemoryVehicles.map((v) => v.toJson()).toList(),
      );
      await prefs.setString(_prefsKey, jsonString);
    } catch (_) {
      // Fehler beim Speichern ignorieren
    }
  }
}

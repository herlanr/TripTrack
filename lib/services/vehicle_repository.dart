import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vehicle.dart';

/// REPOSITORY PATTERN IMPLEMENTATION (Fahrzeug-Datenhaltung)
///
/// Encapsulates local vehicle profile storage using [SharedPreferences].
/// Provides methods to query vehicles by driver ID (`getVehiclesForDriver`),
/// add new vehicles (`addVehicle`), and update odometer readings (`updateVehicleKm`).
class VehicleRepository {
  static const String _prefsKey = 'triptrack_vehicles_v1';

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
      // Storage fallback
    }

    // Pre-seed default test vehicle if empty
    if (_inMemoryVehicles.isEmpty) {
      _inMemoryVehicles.add(defaultTestVehicle);
      await _saveToDisk();
    }

    _initialized = true;
    return _inMemoryVehicles;
  }

  /// Returns all vehicles associated with a specific driver ID.
  /// If the driver has no vehicle, automatically assigns a default vehicle.
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

  /// Adds a new vehicle and saves to disk.
  Future<void> addVehicle(Vehicle vehicle) async {
    await _loadAllVehicles();
    _inMemoryVehicles.add(vehicle);
    await _saveToDisk();
  }

  /// Updates the current kilometerstand of a vehicle.
  Future<void> updateVehicleKm(String vehicleId, double newKm) async {
    await _loadAllVehicles();
    final index = _inMemoryVehicles.indexWhere((v) => v.id == vehicleId);
    if (index != -1) {
      _inMemoryVehicles[index] =
          _inMemoryVehicles[index].copyWith(currentKm: newKm);
      await _saveToDisk();
    }
  }

  /// Deletes a vehicle.
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
      // Storage fallback
    }
  }
}

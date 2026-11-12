import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../models/vehicle.dart';
import '../services/driver_repository.dart';
import '../services/vehicle_repository.dart';
import '../theme/app_theme.dart';
import '../utils/logout.dart';
import '../widgets/add_vehicle_dialog.dart';
import '../widgets/edit_driver_dialog.dart';
import '../widgets/edit_vehicle_dialog.dart';
import '../widgets/profile_header.dart';
import '../widgets/vehicle_list_card.dart';

/// Die Profil- und Einstellungsseite ("Profile") für den angemeldeten Fahrer.
class ProfileScreen extends StatefulWidget {
  /// Erstellt die ProfileScreen-Instanz.
  const ProfileScreen({
    super.key,
    this.driver,
    this.onDriverUpdated,
    this.onVehiclesChanged,
    this.vehiclesVersion = 0,
  });

  /// Der angemeldete Fahrer
  final Driver? driver;

  /// Callback bei Aktualisierung des Fahrer-Profils
  final ValueChanged<Driver>? onDriverUpdated;

  /// Callback bei Hinzufügen, Bearbeiten oder Löschen von Fahrzeugen
  final VoidCallback? onVehiclesChanged;

  /// Versionszähler zur automatischen Aktualisierung der Fahrzeuge
  final int vehiclesVersion;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DriverRepository _driverRepository = DriverRepository();
  final VehicleRepository _vehicleRepository = VehicleRepository();
  List<Vehicle> _vehicles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.driver != oldWidget.driver ||
        widget.vehiclesVersion != oldWidget.vehiclesVersion) {
      _loadVehicles();
    }
  }

  /// Beschreibung: Lädt die Fahrzeuge des aktuell angemeldeten Fahrers aus dem VehicleRepository.
  /// Eingabe: Keine
  /// Ausgabe: `Future<void>`
  Future<void> _loadVehicles() async {
    final driver = widget.driver;
    if (driver != null) {
      final list = await _vehicleRepository.getVehiclesForDriver(driver.id);
      if (mounted) {
        setState(() {
          _vehicles = list;
          _loading = false;
        });
      }
    } else {
      setState(() => _loading = false);
    }
  }

  /// Beschreibung: Öffnet den EditDriverDialog zum Bearbeiten der Fahrerdaten.
  /// Eingabe: Keine
  /// Ausgabe: `Future<void>`
  Future<void> _onEditDriverPressed() async {
    final driver = widget.driver;
    if (driver == null) return;

    final Driver? updated = await showDialog<Driver>(
      context: context,
      builder: (context) => EditDriverDialog(driver: driver),
    );

    if (updated != null) {
      await _driverRepository.updateDriver(updated);
      widget.onDriverUpdated?.call(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil "${updated.fullName}" aktualisiert.'),
          ),
        );
      }
    }
  }

  /// Beschreibung: Öffnet den AddVehicleDialog zum Hinzufügen eines neuen Fahrzeugs.
  /// Eingabe: Keine
  /// Ausgabe: `Future<void>`
  Future<void> _onAddVehiclePressed() async {
    final driver = widget.driver;
    if (driver == null) return;

    final Vehicle? newVehicle = await showDialog<Vehicle>(
      context: context,
      builder: (context) => AddVehicleDialog(driverId: driver.id),
    );

    if (newVehicle != null) {
      await _vehicleRepository.addVehicle(newVehicle);
      await _loadVehicles();
      widget.onVehiclesChanged?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fahrzeug "${newVehicle.displayName}" hinzugefügt.'),
          ),
        );
      }
    }
  }

  /// Beschreibung: Öffnet den EditVehicleDialog zum Bearbeiten eines Fahrzeugs.
  /// Eingabe: vehicle ([Vehicle])
  /// Ausgabe: `Future<void>`
  Future<void> _onEditVehiclePressed(Vehicle vehicle) async {
    final Vehicle? updated = await showDialog<Vehicle>(
      context: context,
      builder: (context) => EditVehicleDialog(
        vehicle: vehicle,
        onDelete: () => _onDeleteVehiclePressed(vehicle),
      ),
    );

    if (updated != null) {
      await _vehicleRepository.updateVehicle(updated);
      await _loadVehicles();
      widget.onVehiclesChanged?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fahrzeug "${updated.displayName}" aktualisiert.'),
          ),
        );
      }
    }
  }

  /// Beschreibung: Löscht ein Fahrzeug nach Bestätigung aus dem Repository.
  /// Eingabe: vehicle ([Vehicle])
  /// Ausgabe: `Future<void>`
  Future<void> _onDeleteVehiclePressed(Vehicle vehicle) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fahrzeug löschen?'),
        content: Text(
          'Möchtest du das Fahrzeug "${vehicle.displayName}" wirklich löschen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.stopRed),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _vehicleRepository.deleteVehicle(vehicle.id);
      await _loadVehicles();
      widget.onVehiclesChanged?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fahrzeug "${vehicle.displayName}" gelöscht.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = widget.driver;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Abmelden / Fahrer wechseln',
            onPressed: () => onLogoutPressed(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ProfileHeader(
            driver: driver,
            onEditPressed: _onEditDriverPressed,
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Meine Fahrzeuge',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Neues Fahrzeug hinzufügen',
                onPressed: _onAddVehiclePressed,
              ),
            ],
          ),
          const SizedBox(height: 8),

          VehicleListCard(
            vehicles: _vehicles,
            loading: _loading,
            onAddVehiclePressed: _onAddVehiclePressed,
            onEditVehiclePressed: _onEditVehiclePressed,
            onDeleteVehiclePressed: _onDeleteVehiclePressed,
          ),

          const SizedBox(height: 24),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: AppTheme.stopRed,
              side: const BorderSide(color: AppTheme.stopRed, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => onLogoutPressed(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text(
              'Abmelden / Fahrer wechseln',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

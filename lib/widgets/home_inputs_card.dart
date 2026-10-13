import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../theme/app_theme.dart';

/// Eingabebereich oben auf dem Home-Dashboard:
/// - Angemeldeter Fahrer (schreibgeschützt)
/// - Fahrzeug-Auswahl-Dropdown
/// - Kilometerstand-Eingabefeld
/// - Start-Standort (wenn Fahrt aktiv) & Aktueller Standort
class HomeInputsCard extends StatelessWidget {
  /// Erstellt eine neue HomeInputsCard-Instanz.
  const HomeInputsCard({
    super.key,
    required this.selectedDriverName,
    required this.vehicles,
    required this.selectedVehicle,
    required this.startKmController,
    required this.currentLocationText,
    this.startLocationText,
    required this.canStart,
    required this.isActive,
    required this.onVehicleChanged,
  });

  /// Name des angemeldeten Fahrers
  final String selectedDriverName;

  /// Liste der dem Fahrer zugeordneten Fahrzeuge
  final List<Vehicle> vehicles;

  /// Das aktuell im Dropdown gewählte Fahrzeug
  final Vehicle? selectedVehicle;

  /// Controller für das Kilometerstand-Feld
  final TextEditingController startKmController;

  /// Aktueller Standorttext (GPS / Geocoded)
  final String currentLocationText;

  /// Start-Standorttext (wenn Fahrt aktiv)
  final String? startLocationText;

  /// Gibt an, ob der Start-Button aktiv sein kann
  final bool canStart;

  /// Gibt an, ob aktuell eine Fahrt läuft
  final bool isActive;

  /// Callback bei Änderung der Fahrzeugauswahl im Dropdown
  final ValueChanged<Vehicle?> onVehicleChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Angemeldeter Fahrer
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Fahrer Name',
            prefixIcon:
                Icon(Icons.person_rounded, color: AppTheme.primaryGreen),
          ),
          child: Text(
            selectedDriverName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Fahrzeug-Auswahl-Dropdown
        if (vehicles.isNotEmpty) ...[
          DropdownButtonFormField<Vehicle>(
            initialValue: selectedVehicle,
            decoration: const InputDecoration(
              labelText: 'Fahrzeug auswählen',
              prefixIcon: Icon(Icons.directions_car_outlined),
            ),
            items: vehicles
                .map(
                  (v) => DropdownMenuItem(
                    value: v,
                    child: Text(v.displayName),
                  ),
                )
                .toList(),
            onChanged: canStart ? onVehicleChanged : null,
          ),
          const SizedBox(height: 12),
        ],

        // Kilometerstand
        TextField(
          controller: startKmController,
          enabled: canStart,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Kilometerstand',
            prefixIcon: Icon(Icons.speed_outlined),
            suffixText: 'km',
          ),
        ),
        const SizedBox(height: 12),

        // Start-Standort (wenn Fahrt aktiv)
        if (isActive && startLocationText != null) ...[
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Start-Standort',
              prefixIcon:
                  Icon(Icons.flag_rounded, color: AppTheme.primaryGreen),
            ),
            child: Text(
              startLocationText!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Aktueller Standort
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Aktueller Standort',
            prefixIcon:
                Icon(Icons.location_on_outlined, color: Colors.blue),
          ),
          child: Text(
            currentLocationText,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

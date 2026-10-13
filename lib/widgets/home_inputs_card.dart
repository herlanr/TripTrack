import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../theme/app_theme.dart';

/// Top input section on the Home screen:
/// - Logged-in driver name badge
/// - Vehicle selector dropdown
/// - Start kilometerstand input
/// - Start location (when trip is active) & live location status
class HomeInputsCard extends StatelessWidget {
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

  final String selectedDriverName;
  final List<Vehicle> vehicles;
  final Vehicle? selectedVehicle;
  final TextEditingController startKmController;
  final String currentLocationText;
  final String? startLocationText;
  final bool canStart;
  final bool isActive;
  final ValueChanged<Vehicle?> onVehicleChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Logged-in Driver Badge
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

        // Vehicle Selector Dropdown
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

        // Kilometerstand Input
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

        // Start-Standort (when trip is active)
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

import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../theme/app_theme.dart';

/// Eingabebereich oben auf dem Home-Dashboard:
/// - Angemeldeter Fahrer (schreibgeschützt)
/// - Fahrzeug-Auswahl-Dropdown
/// - Kilometerstand (schreibgeschützt mit Bearbeiten-Button rechts)
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
    required this.onEditKmPressed,
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

  /// Callback beim Klick auf den Editieren-Button beim Kilometerstand
  final VoidCallback onEditKmPressed;

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

        // Kilometerstand (schreibgeschützt, Bearbeiten über Stift-Icon rechts)
        TextField(
          controller: startKmController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Kilometerstand',
            prefixIcon: const Icon(Icons.speed_outlined),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'km',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (canStart && selectedVehicle != null)
                  IconButton(
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                    tooltip: 'Kilometerstand anpassen',
                    onPressed: onEditKmPressed,
                  ),
                const SizedBox(width: 8,),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Start-Standort (wenn Fahrt aktiv)
        if (isActive && startLocationText != null) ...[
          Builder(
            builder: (context) {
              final bool isStartLoading = startLocationText!.contains('wird ermittelt') || startLocationText!.contains('ausstehend');
              return InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Start-Standort',
                  filled: !isStartLoading,
                  fillColor: isStartLoading ? null : Colors.grey.shade100,
                  prefixIcon: Icon(
                    Icons.flag_rounded,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                child: Text(
                  startLocationText!,
                  style: TextStyle(
                    fontSize: 14,
                    color: isStartLoading ? Colors.black87 : AppTheme.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],

        // Aktueller Standort
        Builder(
          builder: (context) {
            final bool isCurrentLoading = currentLocationText.contains('wird ermittelt') || currentLocationText.contains('ausstehend');
            return InputDecorator(
              decoration: InputDecoration(
                labelText: 'Aktueller Standort',
                filled: !isCurrentLoading,
                fillColor: isCurrentLoading ? null : Colors.grey.shade100,
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                  color: AppTheme.primaryGreen,
                ),
              ),
              child: Text(
                currentLocationText,
                style: TextStyle(
                  fontSize: 14,
                  color: isCurrentLoading ? Colors.black87 : AppTheme.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
      ],
    );
  }
}

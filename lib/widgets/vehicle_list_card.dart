import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Card widget displaying the driver's registered vehicles and kilometerstand.
class VehicleListCard extends StatelessWidget {
  const VehicleListCard({
    super.key,
    required this.vehicles,
    required this.loading,
    required this.onAddVehiclePressed,
    this.onEditVehiclePressed,
    this.onDeleteVehiclePressed,
  });

  final List<Vehicle> vehicles;
  final bool loading;
  final VoidCallback onAddVehiclePressed;
  final ValueChanged<Vehicle>? onEditVehiclePressed;
  final ValueChanged<Vehicle>? onDeleteVehiclePressed;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vehicles.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.directions_car_outlined, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Keine Fahrzeuge vorhanden.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              TextButton(
                onPressed: onAddVehiclePressed,
                child: const Text('Hinzufügen'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          for (int i = 0; i < vehicles.length; i++) ...[
            ListTile(
              leading: const Icon(
                Icons.directions_car_rounded,
                color: AppTheme.primaryGreen,
              ),
              title: Text(
                vehicles[i].displayName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Kilometerstand: ${formatKm(vehicles[i].currentKm)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEditVehiclePressed != null)
                    IconButton(
                      icon: const Icon(Icons.edit_rounded,
                          color: AppTheme.primaryGreen, size: 20),
                      tooltip: 'Fahrzeug bearbeiten',
                      onPressed: () => onEditVehiclePressed!(vehicles[i]),
                    ),
                  if (onDeleteVehiclePressed != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppTheme.stopRed, size: 20),
                      tooltip: 'Fahrzeug löschen',
                      onPressed: () => onDeleteVehiclePressed!(vehicles[i]),
                    ),
                ],
              ),
            ),
            if (i < vehicles.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

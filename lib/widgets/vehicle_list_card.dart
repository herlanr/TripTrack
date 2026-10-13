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
  });

  final List<Vehicle> vehicles;
  final bool loading;
  final VoidCallback onAddVehiclePressed;

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
            ),
            if (i < vehicles.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

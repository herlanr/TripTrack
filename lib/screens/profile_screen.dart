import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../models/vehicle.dart';
import '../services/vehicle_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/add_vehicle_dialog.dart';
import '../widgets/profile_header.dart';
import '../widgets/vehicle_list_card.dart';
import 'welcome_screen.dart';

/// User profile and settings screen for the logged-in driver.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.driver});

  final Driver? driver;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final VehicleRepository _vehicleRepository = VehicleRepository();
  List<Vehicle> _vehicles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fahrzeug "${newVehicle.displayName}" hinzugefügt.'),
          ),
        );
      }
    }
  }

  void _onLogoutPressed() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
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
            onPressed: _onLogoutPressed,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Driver Avatar Header Component
          ProfileHeader(driver: driver),

          const SizedBox(height: 24),

          // Vehicles Section Header
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

          // Vehicle List Component
          VehicleListCard(
            vehicles: _vehicles,
            loading: _loading,
            onAddVehiclePressed: _onAddVehiclePressed,
          ),

          const SizedBox(height: 24),

          // Settings & App info
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('Über die App'),
                  subtitle: const Text('TripTrack v1.0.0 (PoC)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout Action Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: AppTheme.stopRed,
              side: const BorderSide(color: AppTheme.stopRed, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _onLogoutPressed,
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

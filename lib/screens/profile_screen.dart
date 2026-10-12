import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../models/vehicle.dart';
import '../services/vehicle_repository.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/add_vehicle_dialog.dart';
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
          SnackBar(content: Text('Fahrzeug "${newVehicle.displayName}" hinzugefügt.')),
        );
      }
    }
  }

  void _onLogoutPressed() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year}';
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
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(
                    Icons.person_rounded,
                    size: 48,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  driver?.fullName ?? 'Fahrer Profil',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (driver != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Geburtsdatum: ${_formatDate(driver.dateOfBirth)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Vehicles section
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

          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_vehicles.isEmpty)
            Card(
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
                      onPressed: _onAddVehiclePressed,
                      child: const Text('Hinzufügen'),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (int i = 0; i < _vehicles.length; i++) ...[
                    ListTile(
                      leading: const Icon(Icons.directions_car_rounded, color: AppTheme.primaryGreen),
                      title: Text(
                        _vehicles[i].displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('Kilometerstand: ${formatKm(_vehicles[i].currentKm)}'),
                    ),
                    if (i < _vehicles.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
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

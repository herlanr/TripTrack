import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../models/vehicle.dart';
import '../services/driver_repository.dart';
import '../services/vehicle_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/add_vehicle_dialog.dart';
import 'main_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final DriverRepository _driverRepository = DriverRepository();
  final VehicleRepository _vehicleRepository = VehicleRepository();

  List<Driver> _drivers = [];
  Driver? _selectedDriver;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() => _loading = true);
    final drivers = await _driverRepository.getDrivers();
    setState(() {
      _drivers = drivers;
      _loading = false;
      if (_selectedDriver == null && drivers.isNotEmpty) {
        _selectedDriver = drivers.first;
      } else if (drivers.isNotEmpty && !drivers.contains(_selectedDriver)) {
        _selectedDriver = drivers.first;
      } else if (drivers.isEmpty) {
        _selectedDriver = null;
      }
    });
  }

  Future<void> _onAddDriverPressed() async {
    if (_drivers.length >= DriverRepository.maxProfiles) {
      _showSnack(
        'Maximal ${DriverRepository.maxProfiles} Profile erlaubt. Bitte zuerst ein Profil löschen.',
      );
      return;
    }

    // Step 1: Driver Creation
    final Driver? newDriver = await showDialog<Driver>(
      context: context,
      builder: (context) => const _AddDriverDialog(),
    );

    if (newDriver == null) return;

    // Step 2: Mandatory Vehicle Creation for the new driver
    if (!mounted) return;
    final Vehicle? newVehicle = await showDialog<Vehicle>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddVehicleDialog(driverId: newDriver.id),
    );

    if (newVehicle == null) {
      _showSnack('Fahrzeug-Eingabe abgebrochen. Fahrer wurde nicht gespeichert.');
      return;
    }

    try {
      await _driverRepository.addDriver(newDriver);
      await _vehicleRepository.addVehicle(newVehicle);
      await _loadDrivers();
      setState(() {
        _selectedDriver = newDriver;
      });
      _showSnack('Fahrer "${newDriver.fullName}" mit Fahrzeug registriert.');
    } on StateError catch (e) {
      _showSnack(e.message);
    }
  }

  Future<void> _onDeleteDriver(Driver driver) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fahrer löschen?'),
        content: Text('Möchtest du das Profil "${driver.fullName}" wirklich löschen?'),
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
      await _driverRepository.deleteDriver(driver.id);
      await _loadDrivers();
      _showSnack('Profil gelöscht.');
    }
  }

  Future<void> _onWeiterPressed() async {
    final driver = _selectedDriver;
    if (driver == null) {
      _showSnack('Bitte wähle oder erstelle zuerst einen Fahrer.');
      return;
    }

    // Ensure selected driver has at least 1 vehicle
    final vehicles = await _vehicleRepository.getVehiclesForDriver(driver.id);
    if (vehicles.isEmpty) {
      if (!mounted) return;
      _showSnack('Dieser Fahrer hat noch kein Fahrzeug. Bitte erstelle eines.');
      final Vehicle? created = await showDialog<Vehicle>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AddVehicleDialog(driverId: driver.id),
      );
      if (created != null) {
        await _vehicleRepository.addVehicle(created);
      } else {
        return;
      }
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainScreen(selectedDriver: driver),
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Willkommen. Wer fährt?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bitte eintragen/auswählen.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 28),

                    if (_loading)
                      const CircularProgressIndicator()
                    else if (_drivers.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Kein Eintrag vorhanden.\nBitte neu Fahrer einfügen.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: RadioGroup<Driver>(
                          groupValue: _selectedDriver,
                          onChanged: (Driver? val) {
                            setState(() => _selectedDriver = val);
                          },
                          child: Column(
                            children: [
                              for (int i = 0; i < _drivers.length; i++) ...[
                                RadioListTile<Driver>(
                                  value: _drivers[i],
                                  activeColor: AppTheme.primaryGreen,
                                  title: Text(
                                    _drivers[i].fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Geb.: ${_formatDate(_drivers[i].dateOfBirth)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  secondary: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    tooltip: 'Fahrer löschen',
                                    onPressed: () => _onDeleteDriver(_drivers[i]),
                                  ),
                                ),
                                if (i < _drivers.length - 1)
                                  const Divider(height: 1),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: const BorderSide(
                                color: AppTheme.primaryGreen,
                                width: 1.5,
                              ),
                            ),
                            onPressed: _onAddDriverPressed,
                            icon: const Icon(
                              Icons.add_rounded,
                              color: AppTheme.primaryGreen,
                            ),
                            label: const Text(
                              'Add',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: AppTheme.primaryGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed:
                                _selectedDriver != null ? _onWeiterPressed : null,
                            child: const Text(
                              'Weiter',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year}';
  }
}

/// Dialog for creating a new Driver.
class _AddDriverDialog extends StatefulWidget {
  const _AddDriverDialog();

  @override
  State<_AddDriverDialog> createState() => _AddDriverDialogState();
}

class _AddDriverDialogState extends State<_AddDriverDialog> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  DateTime? _selectedDob;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  void _submit() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final dob = _selectedDob;

    if (firstName.isEmpty || lastName.isEmpty || dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte fülle alle Felder aus.'),
        ),
      );
      return;
    }

    final driver = Driver(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dob,
    );

    Navigator.of(context).pop(driver);
  }

  String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Neuen Fahrer anlegen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _firstNameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Vorname',
                hintText: 'z. B. Max',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Name / Nachname',
                hintText: 'z. B. Mustermann',
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDateOfBirth,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Geburtsdatum',
                  suffixIcon: Icon(Icons.calendar_today_rounded),
                ),
                child: Text(
                  _selectedDob != null
                      ? _formatDate(_selectedDob!)
                      : 'Datum auswählen',
                  style: TextStyle(
                    color: _selectedDob != null
                        ? Colors.black87
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Weiter to Fahrzeug'),
        ),
      ],
    );
  }
}

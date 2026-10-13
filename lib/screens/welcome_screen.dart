import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../models/vehicle.dart';
import '../services/driver_repository.dart';
import '../services/vehicle_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/add_driver_dialog.dart';
import '../widgets/add_vehicle_dialog.dart';
import '../widgets/welcome_driver_section.dart';
import 'main_screen.dart';

/// Der Begrüßungsbildschirm ("Begrüßung") der Anwendung.
///
/// Aufgaben dieser Seite:
/// - Anzeige aller gespeicherten Fahrer-Profile zur Auswahl per Radio-Button.
/// - Begrenzung auf maximal 4 Fahrer-Profile gemäß Anforderung.
/// - Durchführung des 2-stufigen Registrierungsprozesses für neue Fahrer (Fahrer + Pflicht-Fahrzeug).
/// - Weiterleitung zum Haupt-Dashboard ([MainScreen]) mit dem ausgewählten Fahrer.
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

  /// Lädt alle Fahrer-Profile aus dem [DriverRepository]
  /// und wählt standardmäßig den ersten Fahrer aus der Liste aus.
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

  /// Startet den Vorgang zum Hinzufügen eines neuen Fahrers:
  /// 1. Prüft, ob das Limit von 4 Profilen erreicht ist.
  /// 2. Öffnet den [AddDriverDialog] zur Eingabe der Fahrerdaten (Vorname, Name, Geburtsdatum).
  /// 3. Öffnet direkt danach den [AddVehicleDialog] zur Eingabe des Pflicht-Fahrzeugs.
  /// 4. Speichert beide Entitäten in den Repositories und aktualisiert die Ansicht.
  Future<void> _onAddDriverPressed() async {
    if (_drivers.length >= DriverRepository.maxProfiles) {
      _showSnack(
        'Maximal ${DriverRepository.maxProfiles} Profile erlaubt. Bitte zuerst ein Profil löschen.',
      );
      return;
    }

    // Schritt 1: Fahrer-Erstellung
    final Driver? newDriver = await showDialog<Driver>(
      context: context,
      builder: (context) => const AddDriverDialog(),
    );

    if (newDriver == null) return;

    // Schritt 2: Pflicht-Fahrzeug-Erstellung für den neuen Fahrer
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

  /// Zeigt einen Bestätigungsdialog zum Löschen eines Fahrer-Profils
  /// und entfernt das Profil bei Bestätigung aus dem [DriverRepository].
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

  /// Überprüft, ob der ausgewählte Fahrer mindestens ein Fahrzeug besitzt,
  /// und leitet ihn anschließend mit seiner Fahrer-Session zur [MainScreen] weiter.
  Future<void> _onWeiterPressed() async {
    final driver = _selectedDriver;
    if (driver == null) {
      _showSnack('Bitte wähle oder erstelle zuerst einen Fahrer.');
      return;
    }

    // Sicherstellen, dass der gewählte Fahrer mindestens ein Fahrzeug hat
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

  /// Zeigt eine Snackbar-Benachrichtigung mit der angegebenen Nachricht an.
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

                    // Driver selection area component
                    WelcomeDriverSection(
                      loading: _loading,
                      drivers: _drivers,
                      selectedDriver: _selectedDriver,
                      onDriverSelected: (val) {
                        setState(() => _selectedDriver = val);
                      },
                      onDeleteDriver: _onDeleteDriver,
                    ),

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
}

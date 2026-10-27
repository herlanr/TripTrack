import 'dart:async';

import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../models/trip.dart';
import '../models/trip_phase.dart';
import '../models/vehicle.dart';
import '../services/location_tracking_service.dart';
import '../services/trip_repository.dart';
import '../services/trip_service.dart';
import '../services/vehicle_repository.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/geocoding_helper.dart';
import '../widgets/home_action_row.dart';
import '../widgets/home_inputs_card.dart';
import '../widgets/last_trip_card.dart';
import '../widgets/trip_summary_dialog.dart';
import 'welcome_screen.dart';

/// Das Haupt-Dashboard ("Fahren") der Anwendung.
///
/// Bietet folgende Kernfunktionen:
/// - Anzeige des angemeldeten Fahrers und Fahrzeugauswahl.
/// - Eingabe des aktuellen Tacho-Standes und Ermittlung der GPS-Startadresse.
/// - Live-Stoppuhr-Anzeige und Start/Stopp-Button.
/// - Anzeige einer Zusammenfassung der zuletzt beendeten Fahrt.
class HomeScreen extends StatefulWidget {
  /// Erstellt die HomeScreen-Instanz.
  const HomeScreen({super.key, this.selectedDriver, this.onTripSaved});

  /// Der aktuell angemeldete Fahrer
  final Driver? selectedDriver;

  /// Callback beim Speichern einer neu beendeten Fahrt
  final ValueChanged<Trip>? onTripSaved;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _startKmController = TextEditingController();
  final _locationTracking = LocationTrackingService();
  final VehicleRepository _vehicleRepository = VehicleRepository();
  final TripRepository _tripRepository = TripRepository();
  late final TripService _tripService = TripService(_locationTracking);

  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;
  Trip? _lastTrip;

  Timer? _stopwatchTimer;
  Duration _elapsedTime = Duration.zero;
  String _currentLocationText = 'GPS wird ermittelt...';
  bool _busy = false;

  TripPhase get _phase => _tripService.phase;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    _fetchCurrentLocation();
  }

  /// Lädt die dem aktuellen Fahrer zugeordneten Fahrzeuge und letzten Fahrten aus dem Repository.
  Future<void> _loadVehicles() async {
    final driver = widget.selectedDriver;
    if (driver != null) {
      final vehicles =
          await _vehicleRepository.getVehiclesForDriver(driver.id);
      final trips = await _tripRepository.getTrips();
      final driverTrips = trips
          .where((t) => t.driverId == driver.id || t.driverName == driver.fullName)
          .toList();

      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          if (vehicles.isNotEmpty) {
            final currentId = _selectedVehicle?.id;
            _selectedVehicle = vehicles.firstWhere(
              (v) => v.id == currentId,
              orElse: () => vehicles.first,
            );
            _startKmController.text =
                formatKmValue(_selectedVehicle!.currentKm);
          }
          if (_lastTrip == null && driverTrips.isNotEmpty) {
            _lastTrip = driverTrips.first;
          }
        });
      }
    }
  }

  /// Ermittelt die aktuelle GPS-Position und löst diese über Reverse Geocoding in eine Straße auf.
  Future<void> _fetchCurrentLocation() async {
    final fix = await _locationTracking.requestFixWithPermission();
    if (fix != null && mounted) {
      final address = await GeocodingHelper.getAddressFromCoordinates(
        fix.latitude,
        fix.longitude,
      );
      if (mounted) {
        setState(() {
          _currentLocationText = address;
        });
      }
    } else if (mounted) {
      setState(() {
        _currentLocationText = 'GPS bereit (Ort ausstehend)';
      });
    }
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _startKmController.dispose();
    _tripService.dispose();
    _locationTracking.dispose();
    super.dispose();
  }

  /// Startet den Sekunden-Timer für die Stoppuhr-Anzeige während einer aktiven Fahrt.
  void _startTimer() {
    _stopwatchTimer?.cancel();
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final trip = _tripService.currentTrip;
      if (trip != null && mounted) {
        setState(() {
          _elapsedTime = DateTime.now().difference(trip.startTime);
        });
      }
    });
  }

  /// Stoppt den Stoppuhr-Timer.
  void _stopTimer() {
    _stopwatchTimer?.cancel();
    _stopwatchTimer = null;
  }

  /// Prüft die Standortberechtigung und startet die Fahrtaufzeichnung.
  Future<void> _onStartTrip() async {
    final status = await _locationTracking.checkPermissionStatus();
    if (status != LocationPermissionResult.granted) {
      await _showPermissionRequiredDialog(status);
      return;
    }

    final driver = widget.selectedDriver;
    final String driverName = driver?.fullName ?? 'Fahrer';
    final double? startKm = double.tryParse(_startKmController.text);

    if (startKm == null || startKm < 0) {
      _showSnack('Bitte gib einen gültigen Start-Kilometerstand ein.');
      return;
    }

    setState(() => _busy = true);
    Trip trip;
    try {
      trip = await _tripService.startTrip(
        driverName: driverName,
        driverId: driver?.id,
        vehicleId: _selectedVehicle?.id,
        startKm: startKm,
      );
    } on StateError catch (e) {
      setState(() => _busy = false);
      _showSnack(e.message);
      return;
    }

    // Manueller Fallback, falls kein GPS-Signal vorhanden ist
    if (trip.startLatitude == null) {
      final String? manual = await _promptLocation(
        title: 'Kein GPS-Signal',
        message: 'Startort manuell eingeben (z. B. "Erfurt Hauptbahnhof").',
      );
      if (manual != null) {
        _tripService.setManualStartLocation(manual);
        setState(() => _currentLocationText = manual);
      }
    } else {
      setState(() {
        _currentLocationText =
            trip.startLocationText ?? 'Startort erfasst';
      });
    }

    _startTimer();

    setState(() {
      _busy = false;
      _elapsedTime = Duration.zero;
    });
  }

  /// Zeigt einen Hinweis-Dialog, wenn die Standortberechtigung fehlt oder GPS deaktiviert ist.
  Future<void> _showPermissionRequiredDialog(
    LocationPermissionResult status,
  ) async {
    final String message = status == LocationPermissionResult.serviceDisabled
        ? 'Die Standortdienste (GPS) deines Geräts sind ausgeschaltet. Bitte aktiviere den Standort in den Einstellungen, um eine Fahrt zu starten.'
        : 'TripTrack benötigt Zugriff auf deinen Standort, um Fahrten automatisch aufzuzeichnen und Start/Zielorte zu erfassen. Ohne Standortberechtigung kann keine Fahrt gestartet werden.';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Row(
          children: [
            Icon(Icons.location_off_rounded, color: AppTheme.stopRed, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Standortzugriff erforderlich',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              if (status == LocationPermissionResult.serviceDisabled) {
                _locationTracking.openLocationSettings();
              } else {
                _locationTracking.openAppSettings();
              }
            },
            child: const Text('Einstellungen öffnen'),
          ),
        ],
      ),
    );
  }

  /// Beendet die aktive Fahrt sofort und öffnet den Zusammenfassungs-Dialog.
  Future<void> _onStopTrip() async {
    final Trip? trip = _tripService.currentTrip;
    if (trip == null) return;

    setState(() => _busy = true);
    final Trip finished = await _tripService.stopTrip();
    _stopTimer();

    if (finished.endLatitude == null) {
      final String? manual = await _promptLocation(
        title: 'Kein GPS-Signal',
        message: 'Zielort manuell eingeben (z. B. "Weimar Markt").',
      );
      if (manual != null) {
        _tripService.setManualEndLocation(manual);
      }
    }

    setState(() => _busy = false);
    await _showSummary(finished);
  }

  /// Zeigt die Zusammenfassung der beendeten Fahrt an und speichert sie bei Bestätigung.
  Future<void> _showSummary(Trip trip) async {
    final bool? save = await TripSummaryDialog.show(context, trip: trip);
    if (save == true) {
      widget.onTripSaved?.call(trip);

      // Aktualisiert den Fahrzeug-Kilometerstand nach dem Speichern
      final vehicle = _selectedVehicle;
      if (vehicle != null) {
        final double newKm = trip.startKm + trip.distanceKm;
        await _vehicleRepository.updateVehicleKm(vehicle.id, newKm);
        await _loadVehicles();
      }

      _showSnack('Fahrt gespeichert!');
      _tripService.reset();
      setState(() {
        _lastTrip = trip;
        _elapsedTime = Duration.zero;
      });
    } else if (save == false) {
      _tripService.reset();
      setState(() => _elapsedTime = Duration.zero);
    }
  }

  /// Fordert den Benutzer zur manuellen Eingabe eines Ortsnamens auf.
  Future<String?> _promptLocation({
    required String title,
    required String message,
  }) async {
    final TextEditingController controller = TextEditingController();
    try {
      final String? result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Ort',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return (result == null || result.isEmpty) ? null : result;
    } finally {
      controller.dispose();
    }
  }

  /// Öffnet einen Pop-Up-Dialog zur manuellen Anpassung des Kilometerstands.
  Future<void> _onEditKmPressed() async {
    final vehicle = _selectedVehicle;
    if (vehicle == null) return;

    final controller = TextEditingController(
      text: formatKmValue(vehicle.currentKm),
    );

    final double? newKm = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.edit_rounded, color: AppTheme.primaryGreen),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Kilometerstand anpassen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fahrzeug: ${vehicle.displayName}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Neuer Kilometerstand',
                suffixText: 'km',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val >= 0) {
                Navigator.of(context).pop(val);
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (newKm != null && mounted) {
      await _vehicleRepository.updateVehicleKm(vehicle.id, newKm);
      await _loadVehicles();
      _showSnack('Kilometerstand auf ${formatKmValue(newKm)} km aktualisiert.');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatTimerDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}min ${seconds}s';
    }
    if (minutes > 0) {
      return '${minutes}min ${seconds}s';
    }
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = _phase == TripPhase.active;
    final bool canStart = _phase != TripPhase.active && !_busy;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fahrt',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Fahrer wechseln (Logout)',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Inputs Component
              HomeInputsCard(
                selectedDriverName: widget.selectedDriver?.fullName ?? 'Fahrer',
                vehicles: _vehicles,
                selectedVehicle: _selectedVehicle,
                startKmController: _startKmController,
                currentLocationText: _currentLocationText,
                startLocationText: _tripService.currentTrip?.startLocationText,
                canStart: canStart,
                isActive: isActive,
                onVehicleChanged: (val) {
                  setState(() {
                    _selectedVehicle = val;
                    if (val != null) {
                      _startKmController.text = formatKmValue(val.currentKm);
                    }
                  });
                },
                onEditKmPressed: _onEditKmPressed,
              ),

              const SizedBox(height: 20),

              // Action Row Component: Side-by-Side Timer Badge + Start/Stop Button
              HomeActionRow(
                isActive: isActive,
                isBusy: _busy,
                elapsedFormattedTime: _formatTimerDuration(_elapsedTime),
                onPressed: isActive ? _onStopTrip : _onStartTrip,
              ),

              const SizedBox(height: 24),

              // Bottom Card Component: Letzte Fahrt
              Expanded(
                child: LastTripCard(lastTrip: _lastTrip),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

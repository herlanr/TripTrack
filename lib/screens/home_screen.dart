import 'dart:async';

import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../models/trip.dart';
import '../models/trip_phase.dart';
import '../models/vehicle.dart';
import '../services/location_tracking_service.dart';
import '../services/trip_service.dart';
import '../services/vehicle_repository.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/geocoding_helper.dart';
import '../widgets/info_row.dart';
import '../widgets/trip_summary_dialog.dart';
import 'welcome_screen.dart';

/// Main Home Screen matching the revised Option A design sketch:
/// - No chart/map container to ensure the entire screen fits without scrolling.
/// - Top inputs: Fahrer Name, Fahrzeug & Kilometerstand, Aktueller Standort.
/// - Action Row: Side-by-side Timer + "Fahrt Starten" / "Fahrt Beenden" button.
/// - Bottom Card: "Letzte Fahrt" showing the details of the most recently saved trip.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.selectedDriver, this.onTripSaved});

  final Driver? selectedDriver;
  final ValueChanged<Trip>? onTripSaved;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ---------------------------------------------------------------------
  // 1. STATE & SERVICES
  // ---------------------------------------------------------------------
  final _startKmController = TextEditingController();
  final _locationTracking = LocationTrackingService();
  final VehicleRepository _vehicleRepository = VehicleRepository();
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

  /// Loads vehicles assigned to the current driver.
  Future<void> _loadVehicles() async {
    final driver = widget.selectedDriver;
    if (driver != null) {
      final vehicles =
          await _vehicleRepository.getVehiclesForDriver(driver.id);
      if (mounted) {
        setState(() {
          _vehicles = vehicles;
          if (vehicles.isNotEmpty) {
            _selectedVehicle = vehicles.first;
            _startKmController.text =
                formatKmValue(_selectedVehicle!.currentKm);
          }
        });
      }
    }
  }

  /// Fetches an initial GPS fix and converts to a human-readable street address.
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

  // ---------------------------------------------------------------------
  // 2. TIMERS & ACTIONS
  // ---------------------------------------------------------------------

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

  void _stopTimer() {
    _stopwatchTimer?.cancel();
    _stopwatchTimer = null;
  }

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

    // Manual fallback if GPS fix unavailable
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

  Future<void> _showSummary(Trip trip) async {
    final bool? save = await TripSummaryDialog.show(context, trip: trip);
    if (save == true) {
      widget.onTripSaved?.call(trip);

      // Update vehicle odometer upon saving trip
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
                  hintText: 'z. B. Erfurt',
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

  // ---------------------------------------------------------------------
  // 3. UI BUILD METHODS
  // ---------------------------------------------------------------------

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
              // Top Inputs Section
              _buildInputsSection(canStart),

              const SizedBox(height: 20),

              // Action Row: Side-by-Side Timer Badge + Start/Stop Button
              _buildActionRow(isActive),

              const SizedBox(height: 24),

              // Bottom Card: Letzte Fahrt
              Expanded(
                child: _buildLastTripCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Top inputs: Angemeldeter Fahrer, Fahrzeug Dropdown, Kilometerstand, Aktueller Standort
  Widget _buildInputsSection(bool canStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Fahrer Name (read-only)
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Fahrer Name',
            prefixIcon:
                Icon(Icons.person_rounded, color: AppTheme.primaryGreen),
          ),
          child: Text(
            widget.selectedDriver?.fullName ?? 'Fahrer',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Fahrzeug selector dropdown
        if (_vehicles.isNotEmpty) ...[
          DropdownButtonFormField<Vehicle>(
            initialValue: _selectedVehicle,
            decoration: const InputDecoration(
              labelText: 'Fahrzeug auswählen',
              prefixIcon: Icon(Icons.directions_car_outlined),
            ),
            items: _vehicles
                .map(
                  (v) => DropdownMenuItem(
                    value: v,
                    child: Text(v.displayName),
                  ),
                )
                .toList(),
            onChanged: canStart
                ? (val) {
                    setState(() {
                      _selectedVehicle = val;
                      if (val != null) {
                        _startKmController.text = formatKmValue(val.currentKm);
                      }
                    });
                  }
                : null,
          ),
          const SizedBox(height: 12),
        ],

        // Kilometerstand input
        TextField(
          controller: _startKmController,
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

        // Aktueller Standort / Start-Standort (wenn Fahrt aktiv)
        if (_phase == TripPhase.active &&
            _tripService.currentTrip?.startLocationText != null) ...[
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Start-Standort',
              prefixIcon:
                  Icon(Icons.flag_rounded, color: AppTheme.primaryGreen),
            ),
            child: Text(
              _tripService.currentTrip!.startLocationText!,
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

        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Aktueller Standort',
            prefixIcon:
                Icon(Icons.location_on_outlined, color: Colors.blue),
          ),
          child: Text(
            _currentLocationText,
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

  /// Side-by-side Timer Badge + Toggle Action Button ("Fahrt Starten" / "Fahrt Beenden")
  Widget _buildActionRow(bool isActive) {
    return Row(
      children: [
        // Live Stopwatch Badge
        Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? AppTheme.stopRed : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 22,
                color: isActive ? AppTheme.stopRed : AppTheme.primaryGreen,
              ),
              const SizedBox(width: 8),
              Text(
                _formatTimerDuration(_elapsedTime),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isActive ? AppTheme.stopRed : AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Main Action Button ("Fahrt Starten" / "Fahrt Beenden")
        Expanded(
          child: SizedBox(
            height: 58,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isActive
                    ? AppTheme.stopRed
                    : AppTheme.primaryLightGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
              ),
              onPressed: _busy
                  ? null
                  : (isActive ? _onStopTrip : _onStartTrip),
              child: _busy
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      isActive ? 'Fahrt Beenden' : 'Fahrt Starten',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  /// Card at bottom displaying summary of the most recent saved trip
  Widget _buildLastTripCard() {
    final trip = _lastTrip;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  color: AppTheme.primaryGreen,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Last Fahrt',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const Spacer(),
                if (trip != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      formatKm(trip.distanceKm),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 20),
            if (trip == null)
              Expanded(
                child: Center(
                  child: Text(
                    'Noch keine Fahrt in dieser Sitzung beendet.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      InfoRow(
                        label: 'Zeit',
                        value:
                            '${formatTime(trip.startTime)}${trip.endTime != null ? ' - ${formatTime(trip.endTime!)}' : ''} (${formatDuration(trip.duration)})',
                      ),
                      InfoRow(
                        label: 'KM',
                        value: formatKm(trip.distanceKm),
                      ),
                      InfoRow(
                        label: 'Anfang',
                        value: trip.startLocationText ?? '—',
                      ),
                      InfoRow(
                        label: 'Ende',
                        value: trip.endLocationText ?? '—',
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

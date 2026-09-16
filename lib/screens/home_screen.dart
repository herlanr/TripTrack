import 'dart:async';

import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../models/trip_phase.dart';
import '../services/location_tracking_service.dart';
import '../services/trip_service.dart';
import '../utils/format.dart';
import '../widgets/info_row.dart';
import '../widgets/route_list.dart';
import '../widgets/trip_summary_dialog.dart';

/// Main screen with the Fahrtenbuch workflow:
/// enter driver + start KM -> Start Trip -> (GPS points are collected in
/// the background, distance is calculated from them) -> Stop Trip ->
/// trip summary. The user does not need to enter an end KM; the distance
/// is derived from the recorded GPS positions.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _driverNameController = TextEditingController();
  final _startKmController = TextEditingController();
  final _locationTracking = LocationTrackingService();
  late final TripService _tripService =
      TripService(_locationTracking);

  StreamSubscription<int>? _pointCountSubscription;

  /// The finished trip whose summary is shown (so it survives a
  /// "Discard" press and can be re-opened).
  Trip? _lastTrip;

  int _storedPointCount = 0;

  /// The trip phase drives the buttons: the Start button is enabled in
  /// [TripPhase.idle], the Stop button in [TripPhase.active].
  TripPhase get _phase => _tripService.phase;

  bool get _isBusy => _busy;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _pointCountSubscription = _tripService.pointCountUpdates.listen((count) {
      setState(() => _storedPointCount = count);
    });
  }

  @override
  void dispose() {
    _pointCountSubscription?.cancel();
    _driverNameController.dispose();
    _startKmController.dispose();
    _tripService.dispose();
    _locationTracking.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------

  /// Validates the inputs, starts the trip and - if GPS was not available -
  /// asks the user for a manual start location.
  Future<void> _onStartTrip() async {
    final String driverName = _driverNameController.text.trim();
    final double? startKm = double.tryParse(_startKmController.text);

    if (driverName.isEmpty) {
      _showSnack('Please enter a driver name.');
      return;
    }
    if (startKm == null || startKm < 0) {
      _showSnack('Please enter a valid start kilometerstand.');
      return;
    }

    setState(() => _busy = true);
    Trip trip;
    try {
      trip = await _tripService.startTrip(
        driverName: driverName,
        startKm: startKm,
      );
    } on StateError catch (e) {
      setState(() => _busy = false);
      _showSnack(e.message);
      return;
    }

    // GPS not available at start -> manual location input (see the prompt:
    // "If GPS is unavailable, display a manual location input field").
    if (trip.startLatitude == null) {
      final String? manual = await _promptLocation(
        title: 'No GPS position available',
        message: 'Enter the start location manually (e.g. "Erfurt").',
      );
      if (manual != null) {
        _tripService.setManualStartLocation(manual);
      }
    }

    setState(() {
      _busy = false;
      _storedPointCount = trip.routePoints.length;
    });
  }

  /// Stops the trip: asks for a manual end location when GPS is not
  /// available, and shows the trip summary. The distance is calculated
  /// from the recorded GPS points — no end KM input is needed.
  Future<void> _onStopTrip() async {
    final Trip? trip = _tripService.currentTrip;
    if (trip == null) return;

    setState(() => _busy = true);
    final Trip finished = await _tripService.stopTrip();

    if (finished.endLatitude == null) {
      final String? manual = await _promptLocation(
        title: 'No GPS position available',
        message: 'Enter the end location manually (e.g. "Weimar").',
      );
      if (manual != null) {
        _tripService.setManualEndLocation(manual);
      }
    }

    setState(() {
      _busy = false;
      _lastTrip = finished;
    });
    await _showSummary(finished);
  }

  /// Shows the summary dialog and acts on the user's decision.
  Future<void> _showSummary(Trip trip) async {
    final bool? save = await TripSummaryDialog.show(context, trip);
    if (save == true) {
      // MVP: no persistence yet. Here a trip would be added to a list /
      // saved to a database.
      _showSnack('Trip saved.');
      _tripService.reset();
      _clearInputs();
    } else if (save == false) {
      _tripService.reset();
      _clearInputs();
    }
  }

  /// Simple dialog with one text field. Returns null if cancelled.
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
                  labelText: 'Location',
                  hintText: 'e.g. Erfurt',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
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

  void _clearInputs() {
    _driverNameController.clear();
    _startKmController.clear();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final Trip? trip = _lastTrip ?? _tripService.currentTrip;
    final bool isActive = _phase == TripPhase.active;
    final bool canStart =
        _phase != TripPhase.active && !_isBusy;
    final bool canStop = _phase == TripPhase.active && !_isBusy;

    return Scaffold(
      appBar: AppBar(title: const Text('Fahrtenbuch')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _driverNameController,
            enabled: canStart,
            decoration: const InputDecoration(
              labelText: 'Driver Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _startKmController,
            enabled: canStart,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Start Kilometerstand',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: canStart ? _onStartTrip : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Trip'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canStop ? _onStopTrip : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop Trip'),
                ),
              ),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 8),
            Text(
              _busy
                  ? 'Waiting for GPS…'
                  : 'Trip is running – GPS points are being collected.',
              style: const TextStyle(fontSize: 13),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Trip data',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (trip == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No trip started yet.'),
            )
          else ...[
            InfoRow(label: 'Driver', value: trip.driverName),
            InfoRow(label: 'Start Time', value: formatDateTime(trip.startTime)),
            InfoRow(
              label: 'End Time',
              value:
                  trip.endTime != null ? formatDateTime(trip.endTime!) : '—',
            ),
            InfoRow(
              label: 'Start Location',
              value: trip.startLocationText ?? '—',
            ),
            InfoRow(
              label: 'End Location',
              value: trip.endLocationText ?? '—',
            ),
            InfoRow(
              label: 'Start KM',
              value: formatKmValue(trip.startKm),
            ),
            InfoRow(
              label: 'Distance (GPS)',
              value: formatKm(trip.distanceKm),
            ),
            InfoRow(
              label: 'Intermediate Points',
              value:
                  isActive ? '$_storedPointCount' : '${trip.intermediatePointCount}',
            ),
            InfoRow(
              label: 'Duration',
              value:
                  trip.isFinished ? formatDuration(trip.duration) : '—',
            ),
            const SizedBox(height: 16),
            const Text(
              'Route (recorded GPS points)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            RouteList(trip: trip),
          ],
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../models/location_point.dart';
import '../models/trip.dart';
import '../services/location_tracking_service.dart';

/// Single screen that demonstrates the whole trip lifecycle:
/// read a GPS fix, start a trip, collect fixes while moving, stop the trip,
/// and show the distance derived from the collected points.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _driverNameController = TextEditingController();
  final _kilometerstandController = TextEditingController();
  final _service = LocationTrackingService();

  // Manual input
  String _driverName = '';
  double? _startKilometerstand;

  // "Get Current Location" one-shot result
  LocationPoint? _lastFix;

  // Trip state
  Trip? _trip;
  DateTime? _endTime;
  int _collectedPointCount = 0;
  StreamSubscription<LocationPoint>? _liveSubscription;

  bool get _isTracking => _service.isTracking;

  @override
  void dispose() {
    _driverNameController.dispose();
    _kilometerstandController.dispose();
    _liveSubscription?.cancel();
    _service.stop();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    final LocationPoint? point = await _service.requestFixWithPermission();
    if (!mounted) return;
    if (point == null) {
      _showMessage('Could not read a GPS fix. Check location settings.');
      return;
    }
    setState(() => _lastFix = point);
  }

  Future<void> _startTrip() async {
    _driverName = _driverNameController.text.trim();
    _startKilometerstand = double.tryParse(_kilometerstandController.text);

    if (_driverName.isEmpty) {
      _showMessage('Please enter a driver name.');
      return;
    }
    if (_startKilometerstand == null) {
      _showMessage('Please enter a valid kilometerstand.');
      return;
    }

    final LocationPoint? firstFix = await _service.requestFixWithPermission();
    if (!mounted) return;
    if (firstFix == null) {
      _showMessage('No GPS fix available. Check location settings.');
      return;
    }

    setState(() {
      _trip = Trip(
        driverName: _driverName,
        startKilometerstand: _startKilometerstand!,
        startTime: firstFix.timestamp,
      );
      _trip!.points.add(firstFix);
      _lastFix = firstFix;
      _endTime = null;
      _collectedPointCount = 1;
    });

    _liveSubscription = _service.startTracking().listen((point) {
      _trip?.points.add(point);
      setState(() {
        _lastFix = point;
        _collectedPointCount = _trip?.points.length ?? 0;
      });
    });
  }

  Future<void> _stopTrip() async {
    if (_trip == null) return;
    await _service.stop();
    await _liveSubscription?.cancel();
    _liveSubscription = null;
    setState(() => _endTime = DateTime.now());
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Trip? trip = _trip;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Tracking PoC'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _driverNameController,
            decoration: const InputDecoration(
              labelText: 'Driver Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _kilometerstandController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Current Kilometerstand',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          _infoRow('Current GPS position', _lastFix?.describe() ?? '—'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isTracking ? null : _getCurrentLocation,
            icon: const Icon(Icons.gps_fixed),
            label: const Text('Get Current Location'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _isTracking ? null : _startTrip,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Trip'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isTracking ? _stopTrip : null,
            icon: const Icon(Icons.stop),
            label: const Text('Stop Trip'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Trip data',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _infoRow('Driver Name', trip?.driverName ?? '—'),
          _infoRow(
            'Kilometerstand',
            trip?.startKilometerstand.toString() ?? '—',
          ),
          _infoRow('Start Time', trip?.startTime.toString() ?? '—'),
          _infoRow('End Time', _endTime?.toString() ?? '—'),
          _infoRow('Current GPS coordinates', _lastFix?.describe() ?? '—'),
          _infoRow('GPS points collected', '$_collectedPointCount'),
          _infoRow(
            'Trip Distance',
            trip != null ? '${trip.distanceKm.toStringAsFixed(3)} km' : '—',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

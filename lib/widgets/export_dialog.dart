import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../models/vehicle.dart';
import '../services/export_service.dart';
import '../services/vehicle_repository.dart';
import '../theme/app_theme.dart';

/// Modal-Dialog zur Auswahl des Exportformats (.csv oder pdf) und Fahrzeugfilters.
class ExportDialog extends StatefulWidget {
  /// Erstellt eine neue ExportDialog-Instanz.
  const ExportDialog({
    super.key,
    required this.trips,
    this.driverId,
  });

  /// Die zu exportierenden Fahrten
  final List<Trip> trips;

  /// Optionale Fahrer-ID zur Fahrzeugabfrage
  final String? driverId;

  /// Hilfsmethode zum Öffnen des Export-Dialogs.
  static Future<void> show(
    BuildContext context, {
    required List<Trip> trips,
    String? driverId,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => ExportDialog(
        trips: trips,
        driverId: driverId,
      ),
    );
  }

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  final VehicleRepository _vehicleRepository = VehicleRepository();
  String _selectedFormat = 'csv'; // Standard: .csv (Excel/Tabelle)
  Vehicle? _selectedVehicle;
  List<Vehicle> _vehicles = [];
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final driverId = widget.driverId;
    if (driverId != null) {
      final list = await _vehicleRepository.getVehiclesForDriver(driverId);
      if (mounted) {
        setState(() {
          _vehicles = list;
        });
      }
    }
  }

  /// Stößt den Export über den [ExportService] an.
  Future<void> _onExportPressed() async {
    if (widget.trips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine Fahrten zum Exportieren vorhanden.')),
      );
      return;
    }

    setState(() => _exporting = true);

    try {
      await ExportService.exportTrips(
        trips: widget.trips,
        format: _selectedFormat,
        vehicleFilter: _selectedVehicle,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _exporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export Fehler: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      title: const Text(
        'Bitte Dateiformat auswählen',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.textDark,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Formatauswahl (.csv oder pdf)
            RadioGroup<String>(
              groupValue: _selectedFormat,
              onChanged: (String? val) {
                if (val != null) {
                  setState(() => _selectedFormat = val);
                }
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'csv',
                    activeColor: AppTheme.primaryLightGreen,
                    title: const Text('.csv (Excel / Tabelle)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  RadioListTile<String>(
                    value: 'pdf',
                    activeColor: AppTheme.primaryLightGreen,
                    title: const Text('pdf (Druckdokument)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Fahrzeugauswahl (Filter)
            DropdownButtonFormField<Vehicle?>(
              initialValue: _selectedVehicle,
              decoration: const InputDecoration(
                labelText: 'Auto auswählen',
                prefixIcon: Icon(Icons.directions_car_outlined, color: Colors.grey),
              ),
              items: [
                const DropdownMenuItem<Vehicle?>(
                  value: null,
                  child: Text('Alle Fahrzeuge'),
                ),
                ..._vehicles.map(
                  (v) => DropdownMenuItem<Vehicle?>(
                    value: v,
                    child: Text(v.displayName),
                  ),
                ),
              ],
              onChanged: (val) {
                setState(() => _selectedVehicle = val);
              },
            ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: AppTheme.stopRed,
                  side: const BorderSide(color: AppTheme.stopRed, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Abbrechen',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppTheme.primaryLightGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _exporting ? null : _onExportPressed,
                child: _exporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Export',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

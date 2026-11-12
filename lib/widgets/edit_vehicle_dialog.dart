import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Modal-Dialog zum Bearbeiten oder Löschen eines bestehenden Fahrzeugs.
class EditVehicleDialog extends StatefulWidget {
  /// Erstellt eine neue EditVehicleDialog-Instanz mit den gegebenen Fahrzeugdaten.
  const EditVehicleDialog({
    super.key,
    required this.vehicle,
    this.onDelete,
  });

  /// Das zu bearbeitende Fahrzeug
  final Vehicle vehicle;

  /// Callback beim Bestätigen des Löschens
  final VoidCallback? onDelete;

  @override
  State<EditVehicleDialog> createState() => _EditVehicleDialogState();
}

class _EditVehicleDialogState extends State<EditVehicleDialog> {
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _plateController;
  late final TextEditingController _kmController;

  @override
  void initState() {
    super.initState();
    _brandController = TextEditingController(text: widget.vehicle.brand);
    _modelController = TextEditingController(text: widget.vehicle.model);
    _plateController =
        TextEditingController(text: widget.vehicle.licensePlate);
    _kmController = TextEditingController(
      text: formatKmValue(widget.vehicle.currentKm),
    );
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _plateController.dispose();
    _kmController.dispose();
    super.dispose();
  }

  /// Beschreibung: Validiert die Eingaben und schließt den Dialog mit den aktualisierten Vehicle-Daten.
  /// Eingabe: Keine
  /// Ausgabe: void
  void _submit() {
    final brand = _brandController.text.trim();
    final model = _modelController.text.trim();
    final plate = _plateController.text.trim();
    final km = double.tryParse(_kmController.text.replaceAll(',', '.'));

    if (brand.isEmpty ||
        model.isEmpty ||
        plate.isEmpty ||
        km == null ||
        km < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bitte gib alle Fahrzeugdaten und einen gültigen KM-Stand ein.',
          ),
        ),
      );
      return;
    }

    final updatedVehicle = widget.vehicle.copyWith(
      brand: brand,
      model: model,
      licensePlate: plate,
      currentKm: km,
    );

    Navigator.of(context).pop(updatedVehicle);
  }

  /// Beschreibung: Zeigt einen Bestätigungsdialog zum Löschen des Fahrzeugs.
  /// Eingabe: Keine
  /// Ausgabe: `Future<void>`
  Future<void> _confirmDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fahrzeug löschen?'),
        content: Text(
          'Möchtest du das Fahrzeug "${widget.vehicle.displayName}" wirklich löschen?',
        ),
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
      widget.onDelete?.call();
      if (mounted) {
        Navigator.of(context).pop(null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: Row(
        children: [
          const Icon(Icons.directions_car_rounded,
              color: AppTheme.primaryGreen),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Fahrzeug bearbeiten',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ),
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.stopRed),
              tooltip: 'Fahrzeug löschen',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _brandController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Marke',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _modelController,
            decoration: const InputDecoration(
              labelText: 'Modell',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _plateController,
            decoration: const InputDecoration(
              labelText: 'Kennzeichen',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _kmController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Aktueller Kilometerstand',
              suffixText: 'km',
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
          onPressed: _submit,
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}

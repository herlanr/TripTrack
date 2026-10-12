import 'package:flutter/material.dart';

import '../models/vehicle.dart';

/// Modal dialog for registering a new vehicle (Fahrzeug: Marke, Modell, Kennzeichen, Kilometerstand).
class AddVehicleDialog extends StatefulWidget {
  const AddVehicleDialog({super.key, required this.driverId});

  final String driverId;

  @override
  State<AddVehicleDialog> createState() => _AddVehicleDialogState();
}

class _AddVehicleDialogState extends State<AddVehicleDialog> {
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  final _kmController = TextEditingController();

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _plateController.dispose();
    _kmController.dispose();
    super.dispose();
  }

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

    final vehicle = Vehicle(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      driverId: widget.driverId,
      brand: brand,
      model: model,
      licensePlate: plate,
      currentKm: km,
    );

    Navigator.of(context).pop(vehicle);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Fahrzeug hinzufügen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _brandController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Marke',
                hintText: 'z. B. Volkswagen',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Modell',
                hintText: 'z. B. Golf VIII',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _plateController,
              decoration: const InputDecoration(
                labelText: 'Kennzeichen',
                hintText: 'z. B. EF-TT 2026',
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
                hintText: 'z. B. 254660',
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
          child: const Text('Fahrzeug Speichern'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../models/driver.dart';

/// Modal-Dialog zum Anlegen eines neuen Fahrer-Profils (Vorname, Name, Geburtsdatum).
class AddDriverDialog extends StatefulWidget {
  /// Erstellt die AddDriverDialog-Instanz.
  const AddDriverDialog({super.key});

  @override
  State<AddDriverDialog> createState() => _AddDriverDialogState();
}

class _AddDriverDialogState extends State<AddDriverDialog> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  DateTime? _selectedDob;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  /// Öffnet den Datumswähler (DatePicker) zur Auswahl des Geburtsdatums.
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

  /// Validiert die Eingaben und gibt die erstellte [Driver]-Instanz zurück.
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

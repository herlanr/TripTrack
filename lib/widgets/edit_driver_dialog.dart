import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Modal-Dialog zum Bearbeiten eines bestehenden Fahrer-Profils.
class EditDriverDialog extends StatefulWidget {
  /// Erstellt eine neue EditDriverDialog-Instanz mit den gegebenen Fahrerdaten.
  const EditDriverDialog({super.key, required this.driver});

  /// Das zu bearbeitende Fahrer-Profil
  final Driver driver;

  @override
  State<EditDriverDialog> createState() => _EditDriverDialogState();
}

class _EditDriverDialogState extends State<EditDriverDialog> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late DateTime _selectedDob;

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.driver.firstName);
    _lastNameController =
        TextEditingController(text: widget.driver.lastName);
    _selectedDob = widget.driver.dateOfBirth;
  }

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
      initialEntryMode: DatePickerEntryMode.input,
      initialDate: _selectedDob,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  /// Validiert die Eingaben und gibt die aktualisierte [Driver]-Instanz zurück.
  void _submit() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte fülle alle Namensfelder aus.'),
        ),
      );
      return;
    }

    final updatedDriver = widget.driver.copyWith(
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: _selectedDob,
    );

    Navigator.of(context).pop(updatedDriver);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: const Row(
        children: [
          Icon(Icons.edit_rounded, color: AppTheme.primaryGreen),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Profil bearbeiten',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _firstNameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Vorname',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Name / Nachname',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDateOfBirth,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Geburtsdatum',
                prefixIcon: Icon(Icons.cake_outlined),
                suffixIcon: Icon(Icons.calendar_today_rounded),
              ),
              child: Text(
                formatDate(_selectedDob),
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
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

import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../theme/app_theme.dart';

/// Bereich auf dem WelcomeScreen zur Auswahl oder Verwaltung von Fahrer-Profilen.
class WelcomeDriverSection extends StatelessWidget {
  /// Erstellt eine neue WelcomeDriverSection-Instanz.
  const WelcomeDriverSection({
    super.key,
    required this.loading,
    required this.drivers,
    required this.selectedDriver,
    required this.onDriverSelected,
    required this.onDeleteDriver,
  });

  /// Lade-Status der Fahrertabelle
  final bool loading;

  /// Liste aller Fahrer-Profile
  final List<Driver> drivers;

  /// Aktuell ausgewählter Fahrer
  final Driver? selectedDriver;

  /// Callback bei Änderung der Fahrerauswahl
  final ValueChanged<Driver?> onDriverSelected;

  /// Callback beim Löschen eines Fahrers
  final ValueChanged<Driver> onDeleteDriver;

  /// Beschreibung: Formatiert ein Datum kurz als String (z. B. "15.09.1990").
  /// Eingabe: dt (DateTime)
  /// Ausgabe: String
  String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const CircularProgressIndicator();
    }

    if (drivers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Kein Eintrag vorhanden.\nBitte neuen Fahrer einfügen.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: RadioGroup<Driver>(
        groupValue: selectedDriver,
        onChanged: onDriverSelected,
        child: Column(
          children: [
            for (int i = 0; i < drivers.length; i++) ...[
              RadioListTile<Driver>(
                value: drivers[i],
                activeColor: AppTheme.primaryGreen,
                title: Text(
                  drivers[i].fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'Geb.: ${_formatDate(drivers[i].dateOfBirth)}',
                  style: const TextStyle(fontSize: 12),
                ),
                secondary: IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.grey,
                    size: 20,
                  ),
                  tooltip: 'Fahrer löschen',
                  onPressed: () => onDeleteDriver(drivers[i]),
                ),
              ),
              if (i < drivers.length - 1) const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}

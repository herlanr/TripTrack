import 'package:flutter/material.dart';

/// Stellt eine Schlüssel-Wert-Zeile für Zusammenfassungen und Fahrtdetails dar.
class InfoRow extends StatelessWidget {
  /// Erstellt eine neue InfoRow-Instanz.
  const InfoRow({super.key, required this.label, required this.value});

  /// Beschriftung auf der linken Seite
  final String label;

  /// Wert auf der rechten Seite
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

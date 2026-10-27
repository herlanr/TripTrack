/// UTILITY HELPER FUNCTIONS (Formatierungs-Hilfsfunktionen)
///
/// Bietet einheitliche Funktionen zur Formatierung von Datum, Uhrzeit,
/// Dauer und Kilometerangaben im deutschen Zahlenformat.
library;

/// Formatiert Datum und Uhrzeit im deutschen Format "15.09.2026 14:00".
String formatDateTime(DateTime dateTime) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(dateTime.day)}.${two(dateTime.month)}.${dateTime.year} '
      '${two(dateTime.hour)}:${two(dateTime.minute)}';
}

/// Formatiert das Datum im Format "15.09.2026".
String formatDate(DateTime dateTime) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(dateTime.day)}.${two(dateTime.month)}.${dateTime.year}';
}

/// Formatiert die Uhrzeit im Format "14:00".
String formatTime(DateTime dateTime) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(dateTime.hour)}:${two(dateTime.minute)}';
}

/// Formatiert eine Zeitdauer im Format "1h 05min" oder "42min" oder "15s".
String formatDuration(Duration duration) {
  if (duration.inMinutes < 1) {
    return '${duration.inSeconds}s';
  }
  final int hours = duration.inHours;
  final int minutes = duration.inMinutes % 60;
  if (hours == 0) return '${minutes}min';
  if (minutes == 0) return '${hours}h';
  return '${hours}h ${minutes.toString().padLeft(2, '0')}min';
}

/// Formatiert ein Kilometerschritt-Ergebnis mit Komma als Dezimaltrenner: 24.5 -> "24,5 km".
String formatKm(double km) {
  final bool isWhole = km == km.truncateToDouble();
  final String value =
      km.toStringAsFixed(isWhole ? 0 : 1).replaceAll('.', ',');
  return '$value km';
}

/// Formatiert einen Tacho-Kilometerstand als Ganzzahl: 254660.0 -> "254660".
String formatKmValue(double km) =>
    km.truncateToDouble().toStringAsFixed(0);

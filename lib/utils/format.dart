/// Bietet einheitliche Funktionen zur Formatierung von Datum, Uhrzeit, Dauer und Kilometerangaben.
library;

/// Beschreibung: Formatiert Datum und Uhrzeit im deutschen Format (z. B. "15.09.2026 14:00").
/// Eingabe: dateTime (DateTime)
/// Ausgabe: String
String formatDateTime(DateTime dateTime) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(dateTime.day)}.${two(dateTime.month)}.${dateTime.year} '
      '${two(dateTime.hour)}:${two(dateTime.minute)}';
}

/// Beschreibung: Formatiert ein Datum im deutschen Format (z. B. "15.09.2026").
/// Eingabe: dateTime (DateTime)
/// Ausgabe: String
String formatDate(DateTime dateTime) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(dateTime.day)}.${two(dateTime.month)}.${dateTime.year}';
}

/// Beschreibung: Formatiert die Uhrzeit im 24-Stunden-Format (z. B. "14:00").
/// Eingabe: dateTime (DateTime)
/// Ausgabe: String
String formatTime(DateTime dateTime) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(dateTime.hour)}:${two(dateTime.minute)}';
}

/// Beschreibung: Formatiert eine Zeitdauer als lesbaren Text (z. B. "1h 05min" oder "42min").
/// Eingabe: duration (Duration)
/// Ausgabe: String
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

/// Beschreibung: Formatiert ein Kilometerschritt-Ergebnis mit Komma als Trenner (z. B. "24,5 km").
/// Eingabe: km (double)
/// Ausgabe: String
String formatKm(double km) {
  final bool isWhole = km == km.truncateToDouble();
  final String value =
      km.toStringAsFixed(isWhole ? 0 : 1).replaceAll('.', ',');
  return '$value km';
}

/// Beschreibung: Formatiert einen Tacho-Kilometerstand als Ganzzahl-String (z. B. "254660").
/// Eingabe: km (double)
/// Ausgabe: String
String formatKmValue(double km) =>
    km.truncateToDouble().toStringAsFixed(0);

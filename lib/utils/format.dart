/// Small formatting helpers so the screens don't contain ad-hoc
/// date/number formatting in every place.
library;

/// Formats a date and time as "15.09.2026 14:00".
String formatDateTime(DateTime dateTime) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(dateTime.day)}.${two(dateTime.month)}.${dateTime.year} '
      '${two(dateTime.hour)}:${two(dateTime.minute)}';
}

/// Formats a duration as "1h", "1h 05min" or "42min".
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

/// Formats a kilometer value: 24.0 -> "24 km", 24.5 -> "24,5 km".
/// German number format uses a comma as decimal separator.
String formatKm(double km) {
  final bool isWhole = km == km.truncateToDouble();
  final String value =
      km.toStringAsFixed(isWhole ? 0 : 1).replaceAll('.', ',');
  return '$value km';
}

/// Formats an odometer value: 254660.0 -> "254660".
String formatKmValue(double km) =>
    km.truncateToDouble().toStringAsFixed(0);

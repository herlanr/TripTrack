/// Repräsentiert das Datenmodell für den Lebenszyklus-Status einer Fahrt in TripTrack.
enum TripPhase {
  /// Keine Fahrt ist aktuell aktiv.
  idle,

  /// Eine Fahrt wurde gestartet und läuft aktuell.
  active,

  /// Die Fahrt wurde beendet und die Zusammenfassung wurde angezeigt.
  finished,
}

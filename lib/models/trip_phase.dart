/// Der Lebenszyklus-Status einer Fahrt.
enum TripPhase {
  /// Keine Fahrt ist aktuell aktiv.
  idle,

  /// Eine Fahrt wurde gestartet und läuft aktuell.
  active,

  /// Die Fahrt wurde beendet und die Zusammenfassung wurde angezeigt.
  finished,
}

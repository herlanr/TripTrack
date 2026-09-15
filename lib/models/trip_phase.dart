/// The lifecycle of a trip. The UI switches buttons based on this.
enum TripPhase {
  /// No trip is active.
  idle,

  /// A trip was started and is still running.
  active,

  /// The trip was stopped and the summary was shown.
  finished,
}

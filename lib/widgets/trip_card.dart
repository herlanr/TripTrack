import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'trip_summary_dialog.dart';

/// Kartenelement zur Darstellung eines Fahrtenbuch-Eintrags in der Liste.
/// Layout gemäß Skizze:
/// - Oben: "Start -> Ziel" & Dauer (z. B. "30min")
/// - Unten: "23 km   11.09.2026"
class TripCard extends StatelessWidget {
  /// Erstellt eine neue TripCard-Instanz.
  const TripCard({
    super.key,
    required this.trip,
    this.onDeleteTrip,
  });

  /// Die darzustellende Fahrt
  final Trip trip;

  /// Callback beim Löschen der Fahrt
  final ValueChanged<Trip>? onDeleteTrip;

  @override
  Widget build(BuildContext context) {
    final startCity = _shortenLocation(trip.startLocationText);
    final endCity = _shortenLocation(trip.endLocationText);
    final routeTitle = '$startCity -> $endCity';
    final dateStr = _formatDateShort(trip.startTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          TripSummaryDialog.show(
            context,
            trip: trip,
            isReadOnly: true,
            onDelete: () {
              onDeleteTrip?.call(trip);
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      routeTitle,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    formatDuration(trip.duration),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Text(
                    formatKm(trip.distanceKm),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortenLocation(String? text) {
    if (text == null || text.isEmpty) return '—';
    final parts = text.split(',');
    if (parts.length > 1) {
      return parts.last.trim();
    }
    return text.trim();
  }

  String _formatDateShort(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year}';
  }
}

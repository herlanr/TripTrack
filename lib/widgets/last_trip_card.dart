import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'info_row.dart';

/// Karte unten auf dem Home-Dashboard zur Anzeige der zuletzt beendeten Fahrt.
class LastTripCard extends StatelessWidget {
  /// Erstellt eine neue LastTripCard-Instanz.
  const LastTripCard({super.key, this.lastTrip});

  /// Die zuletzt beendete Fahrt in dieser Sitzung
  final Trip? lastTrip;

  @override
  Widget build(BuildContext context) {
    final trip = lastTrip;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ExpansionTile(
        leading: const Icon(
          Icons.history_rounded,
          color: AppTheme.primaryGreen,
          size: 22,
        ),
        title: const Text(
          'Last Fahrt',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        subtitle: trip == null
            ? Text(
                'Noch keine Fahrt in dieser Sitzung beendet.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              )
            : null,
        enabled: trip != null,
        children: trip == null ? [] : [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      InfoRow(
                        label: 'Zeit',
                        value:
                            '${formatTime(trip.startTime)}${trip.endTime != null ? ' - ${formatTime(trip.endTime!)}' : ''} (${formatDuration(trip.duration)})',
                      ),
                      const SizedBox(height: 8),
                      InfoRow(
                        label: 'KM',
                        value: formatKm(trip.distanceKm),
                      ),
                      const SizedBox(height: 8),
                      InfoRow(
                        label: 'Anfang',
                        value: trip.startLocationText ?? '—',
                      ),
                      const SizedBox(height: 8),
                      InfoRow(
                        label: 'Ende',
                        value: trip.endLocationText ?? '—',
                      ),
                    ],
                  ),
                ),
              ],
      ),
    );
  }
}

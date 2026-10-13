import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'info_row.dart';

/// Card at the bottom of the Home screen displaying a summary of the most recently finished trip.
class LastTripCard extends StatelessWidget {
  const LastTripCard({super.key, this.lastTrip});

  final Trip? lastTrip;

  @override
  Widget build(BuildContext context) {
    final trip = lastTrip;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  color: AppTheme.primaryGreen,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Last Fahrt',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const Spacer(),
                if (trip != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      formatKm(trip.distanceKm),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 20),
            if (trip == null)
              Expanded(
                child: Center(
                  child: Text(
                    'Noch keine Fahrt in dieser Sitzung beendet.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      InfoRow(
                        label: 'Zeit',
                        value:
                            '${formatTime(trip.startTime)}${trip.endTime != null ? ' - ${formatTime(trip.endTime!)}' : ''} (${formatDuration(trip.duration)})',
                      ),
                      InfoRow(
                        label: 'KM',
                        value: formatKm(trip.distanceKm),
                      ),
                      InfoRow(
                        label: 'Anfang',
                        value: trip.startLocationText ?? '—',
                      ),
                      InfoRow(
                        label: 'Ende',
                        value: trip.endLocationText ?? '—',
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

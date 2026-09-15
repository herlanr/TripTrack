import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../utils/format.dart';
import 'info_row.dart';

/// Shows the finished trip as a Fahrtenbuch entry.
class TripSummaryDialog extends StatelessWidget {
  const TripSummaryDialog({super.key, required this.trip});

  final Trip trip;

  /// Opens the dialog. Returns the user's choice so the caller can decide
  /// what happens next (save / discard).
  static Future<bool?> show(BuildContext context, Trip trip) {
    return showDialog<bool?>(
      context: context,
      builder: (context) => TripSummaryDialog(trip: trip),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Trip Summary'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InfoRow(label: 'Driver', value: trip.driverName),
              InfoRow(
                label: 'Start',
                value: formatDateTime(trip.startTime),
              ),
              InfoRow(
                label: 'End',
                value:
                    trip.endTime != null ? formatDateTime(trip.endTime!) : '—',
              ),
              InfoRow(label: 'Start Location', value: trip.startLocationText ?? '—'),
              InfoRow(label: 'End Location', value: trip.endLocationText ?? '—'),
              InfoRow(label: 'Start KM', value: formatKmValue(trip.startKm)),
              InfoRow(label: 'End KM', value: formatKmValue(trip.endKm ?? trip.startKm)),
              InfoRow(label: 'Distance', value: formatKm(trip.distanceKm)),
              InfoRow(
                label: 'Intermediate Points',
                value: '${trip.intermediatePointCount}',
              ),
              InfoRow(label: 'Duration', value: formatDuration(trip.duration)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Discard'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

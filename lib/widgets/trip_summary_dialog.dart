import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'info_row.dart';
import 'route_list.dart';

/// Material 3 dialog showing the trip summary.
/// Supports two modes:
/// - `isReadOnly == false`: Freshly stopped trip from Home (Verwerfen / Speichern).
/// - `isReadOnly == true`: Saved trip view from Fahrtbuch (Upper-right X close button, Fahrt löschen).
class TripSummaryDialog extends StatelessWidget {
  const TripSummaryDialog({
    super.key,
    required this.trip,
    this.isReadOnly = false,
    this.onDelete,
  });

  final Trip trip;
  final bool isReadOnly;
  final VoidCallback? onDelete;

  /// Opens the summary dialog.
  static Future<bool?> show(
    BuildContext context, {
    required Trip trip,
    bool isReadOnly = false,
    VoidCallback? onDelete,
  }) {
    return showDialog<bool?>(
      context: context,
      barrierDismissible: isReadOnly,
      builder: (context) => TripSummaryDialog(
        trip: trip,
        isReadOnly: isReadOnly,
        onDelete: onDelete,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fahrt löschen?'),
        content: const Text(
          'Möchtest du diesen Fahrtenbuch-Eintrag wirklich löschen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.stopRed),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      onDelete?.call();
      if (context.mounted) {
        Navigator.of(context).pop(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 12, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      title: Row(
        children: [
          const Expanded(
            child: Text(
              'Fahrt Zusammenfassung',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ),
          // Upper-Right Close (X) Button matching normal windows / Material 3 dialogs
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 24),
            tooltip: 'Schließen',
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Metric Cards (Strecke & Dauer)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      label: 'Strecke',
                      value: formatKm(trip.distanceKm),
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      label: 'Dauer',
                      value: formatDuration(trip.duration),
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Details List
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    InfoRow(label: 'Fahrer', value: trip.driverName),
                    InfoRow(
                      label: 'Startzeit',
                      value: formatDateTime(trip.startTime),
                    ),
                    InfoRow(
                      label: 'Endzeit',
                      value: trip.endTime != null
                          ? formatDateTime(trip.endTime!)
                          : '—',
                    ),
                    InfoRow(
                      label: 'Startort',
                      value: trip.startLocationText ?? '—',
                    ),
                    InfoRow(
                      label: 'Zielort',
                      value: trip.endLocationText ?? '—',
                    ),
                    InfoRow(
                      label: 'Start-KM',
                      value: '${formatKmValue(trip.startKm)} km',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Route Points Section
              const Text(
                'Routenverlauf (GPS-Punkte)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              RouteList(trip: trip),
            ],
          ),
        ),
      ),
      actions: [
        if (!isReadOnly) ...[
          // New Finished Trip Actions (Home Screen)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: AppTheme.stopRed,
                    side: const BorderSide(color: AppTheme.stopRed, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Verwerfen',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Speichern',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          // Saved Trip View Actions (Fahrtbuch Screen)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: AppTheme.stopRed,
                side: const BorderSide(color: AppTheme.stopRed, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _confirmDelete(context),
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              label: const Text(
                'Fahrt löschen',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

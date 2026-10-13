import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../utils/format.dart';

/// Stellt den chronologischen Routenverlauf einer Fahrt als vertikale Zeitleiste dar.
class RouteList extends StatelessWidget {
  /// Erstellt eine neue RouteList-Instanz für die angegebene Fahrt.
  const RouteList({super.key, required this.trip});

  /// Die darzustellende Fahrt
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final List<_RouteEntry> entries = _buildEntries(trip);
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Keine GPS-Positionen für diese Fahrt erfasst.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }
    return Column(
      children: [
        for (int i = 0; i < entries.length; i++)
          _RouteRow(
            entry: entries[i],
            isLast: i == entries.length - 1,
          ),
      ],
    );
  }

  List<_RouteEntry> _buildEntries(Trip trip) {
    final List<_RouteEntry> entries = [
      _RouteEntry(
        time: trip.startTime,
        label: trip.startLocationText ?? '—',
        isEndpoint: true,
      ),
      for (final point in trip.routePoints)
        _RouteEntry(
          time: point.timestamp,
          label: point.describe(),
          isEndpoint: false,
        ),
    ];

    final DateTime? endTime = trip.endTime;
    if (endTime != null) {
      entries.add(
        _RouteEntry(
          time: endTime,
          label: trip.endLocationText ?? '—',
          isEndpoint: true,
        ),
      );
    }
    return entries;
  }
}

class _RouteEntry {
  const _RouteEntry({
    required this.time,
    required this.label,
    required this.isEndpoint,
  });

  final DateTime time;
  final String label;
  final bool isEndpoint;
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.entry, required this.isLast});

  final _RouteEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final Color dotColor = entry.isEndpoint ? Colors.green : Colors.grey;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Center(
                  child: Text(
                    formatTime(entry.time),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 1.5,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                entry.label,
                style: TextStyle(
                  fontSize: 13,
                  color: entry.isEndpoint ? Colors.black87 : Colors.black54,
                  fontWeight:
                      entry.isEndpoint ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

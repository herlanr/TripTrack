import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../models/trip.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/export_dialog.dart';
import '../widgets/trip_summary_dialog.dart';

/// Screen displaying the history of all completed Fahrtenbuch entries.
/// Redesigned matching the wireframe sketch:
/// - Title: "[Driver Name] Fahrtbuch" + Share/Export icon
/// - Search Bar + Filter button
/// - Trip Cards: "Start -> Ziel", distance, date, duration
class FahrtbuchScreen extends StatefulWidget {
  const FahrtbuchScreen({
    super.key,
    this.driver,
    this.savedTrips = const [],
    this.onDeleteTrip,
  });

  final Driver? driver;
  final List<Trip> savedTrips;
  final ValueChanged<Trip>? onDeleteTrip;

  @override
  State<FahrtbuchScreen> createState() => _FahrtbuchScreenState();
}

class _FahrtbuchScreenState extends State<FahrtbuchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Trip> get _filteredTrips {
    if (_searchQuery.isEmpty) return widget.savedTrips;
    final query = _searchQuery.toLowerCase();
    return widget.savedTrips.where((t) {
      final start = (t.startLocationText ?? '').toLowerCase();
      final end = (t.endLocationText ?? '').toLowerCase();
      final driver = t.driverName.toLowerCase();
      return start.contains(query) ||
          end.contains(query) ||
          driver.contains(query);
    }).toList();
  }

  void _openExportDialog() {
    ExportDialog.show(
      context,
      trips: widget.savedTrips,
      driverId: widget.driver?.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final driver = widget.driver;
    final titleText = driver != null ? '${driver.firstName} Fahrtbuch' : 'Fahrtbuch';
    final trips = _filteredTrips;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titleText,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.share_rounded,
              color: AppTheme.stopRed,
              size: 26,
            ),
            tooltip: 'Fahrtenbuch Exportieren',
            onPressed: _openExportDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              // Search Bar & Filter Button matching sketch
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'Suchen...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.stopRed),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.tune_rounded, color: AppTheme.stopRed),
                      tooltip: 'Filter',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Filter nach Datum / Autoaktiv.')),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Trip List
              Expanded(
                child: trips.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Keine Suchergebnisse'
                                  : 'Noch keine Fahrten gespeichert',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Versuche einen anderen Suchbegriff.'
                                  : 'Starte eine Fahrt im Tab "Fahren".',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: trips.length,
                        itemBuilder: (context, index) {
                          final trip = trips[index];
                          return _buildTripCard(trip);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Trip Card layout matching the wireframe sketch:
  /// - Top row: "Erfurt -> Weimar" (Start -> Ziel) and Duration ("30min")
  /// - Bottom row: "23 km   11.09.2026"
  Widget _buildTripCard(Trip trip) {
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
              widget.onDeleteTrip?.call(trip);
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: "Erfurt -> Weimar" & "30min"
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

              // Bottom Row: "23 km   11.09.2026"
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
    // If text contains a comma (e.g., "Nordhäuser Str., Erfurt"), extract city or last part
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

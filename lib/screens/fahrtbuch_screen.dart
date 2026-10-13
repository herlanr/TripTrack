import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../models/trip.dart';
import '../theme/app_theme.dart';
import '../widgets/export_dialog.dart';
import '../widgets/trip_card.dart';

/// Die Fahrtenbuch-Übersichtsseite ("Fahrtbuch") der Anwendung.
///
/// Bietet folgende Kernfunktionen:
/// - Anzeige aller gespeicherten Fahrtenbuch-Einträge.
/// - Suchleiste zum Filtern nach Orten oder Fahrern.
/// - Anstoß des CSV-/PDF-Exports über die Teilen-Schaltfläche in der AppBar.
/// - Detailansicht und Löschen von Einträgen per Klick auf eine Fahrt-Karte.
class FahrtbuchScreen extends StatefulWidget {
  /// Erstellt eine neue FahrtbuchScreen-Instanz.
  const FahrtbuchScreen({
    super.key,
    this.driver,
    this.savedTrips = const [],
    this.onDeleteTrip,
  });

  /// Der angemeldete Fahrer
  final Driver? driver;

  /// Liste aller gespeicherten Fahrten
  final List<Trip> savedTrips;

  /// Callback zum Löschen einer Fahrt
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

  /// Filtert die Fahrtenliste basierend auf der aktuellen Sucheingabe.
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

  /// Öffnet den Export-Pop-Up-Dialog.
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
              // Suchleiste & Filter-Button
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

              // Fahrtenliste
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
                          return TripCard(
                            trip: trip,
                            onDeleteTrip: widget.onDeleteTrip,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

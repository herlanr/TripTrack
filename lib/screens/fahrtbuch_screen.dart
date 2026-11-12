import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../models/trip.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/date_filter_bottom_sheet.dart';
import '../widgets/export_dialog.dart';
import '../widgets/trip_card.dart';

/// Verfügbare Sortieroptionen für die Fahrtenbuch-Liste.
enum TripSortOption {
  /// Neueste Fahrt zuerst (Standard)
  newestFirst,

  /// Älteste Fahrt zuerst
  oldestFirst,

  /// Längste zurückgelegte Strecke zuerst
  longestDistance,
}

/// Die Fahrtenbuch-Übersichtsseite ("Fahrtbuch") der Anwendung.
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
  DateTimeRange? _selectedDateRange;
  TripSortOption _sortOption = TripSortOption.newestFirst;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Beschreibung: Filtert und sortiert die Fahrtenliste nach Fahrer, Suchtext und Datumsbereich.
  /// Eingabe: Keine
  /// Ausgabe: `List<Trip>`
  List<Trip> get _processedTrips {
    List<Trip> result = List.of(widget.savedTrips);

    // 0. Fahrer-Filter
    final driver = widget.driver;
    if (driver != null) {
      result = result.where((t) {
        return t.driverId == driver.id ||
            (t.driverId == null && t.driverName == driver.fullName);
      }).toList();
    }

    // 1. Textsuche-Filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((t) {
        final start = (t.startLocationText ?? '').toLowerCase();
        final end = (t.endLocationText ?? '').toLowerCase();
        final driverName = t.driverName.toLowerCase();
        return start.contains(query) ||
            end.contains(query) ||
            driverName.contains(query);
      }).toList();
    }

    // 2. Datumsbereichs-Filter
    final range = _selectedDateRange;
    if (range != null) {
      final startOfDay = DateTime(
        range.start.year,
        range.start.month,
        range.start.day,
      );
      final endOfDay = DateTime(
        range.end.year,
        range.end.month,
        range.end.day,
        23,
        59,
        59,
      );
      result = result.where((t) {
        return t.startTime
                .isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
            t.startTime.isBefore(endOfDay.add(const Duration(seconds: 1)));
      }).toList();
    }

    // 3. Sortierung
    switch (_sortOption) {
      case TripSortOption.newestFirst:
        result.sort((a, b) => b.startTime.compareTo(a.startTime));
        break;
      case TripSortOption.oldestFirst:
        result.sort((a, b) => a.startTime.compareTo(b.startTime));
        break;
      case TripSortOption.longestDistance:
        result.sort((a, b) => b.distanceKm.compareTo(a.distanceKm));
        break;
    }

    return result;
  }

  /// Beschreibung: Öffnet das DateFilterBottomSheet zur Auswahl des Start- und Enddatums.
  /// Eingabe: Keine
  /// Ausgabe: `Future<void>`
  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await DateFilterBottomSheet.show(
      context,
      initialRange: _selectedDateRange,
    );

    if (picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  /// Beschreibung: Öffnet ein Modal Bottom Sheet zur Auswahl der Sortierungsoption.
  /// Eingabe: Keine
  /// Ausgabe: `Future<void>`
  Future<void> _showSortOptions() async {
    final selected = await showModalBottomSheet<TripSortOption>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Text(
                'Sortierung auswählen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.arrow_downward_rounded,
                  color: AppTheme.primaryGreen),
              title: const Text('Neueste zuerst'),
              trailing: _sortOption == TripSortOption.newestFirst
                  ? const Icon(Icons.check_rounded, color: AppTheme.primaryGreen)
                  : null,
              onTap: () =>
                  Navigator.of(context).pop(TripSortOption.newestFirst),
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward_rounded,
                  color: AppTheme.primaryGreen),
              title: const Text('Älteste zuerst'),
              trailing: _sortOption == TripSortOption.oldestFirst
                  ? const Icon(Icons.check_rounded, color: AppTheme.primaryGreen)
                  : null,
              onTap: () =>
                  Navigator.of(context).pop(TripSortOption.oldestFirst),
            ),
            ListTile(
              leading: const Icon(Icons.straighten_rounded,
                  color: AppTheme.primaryGreen),
              title: const Text('Längste Strecke'),
              trailing: _sortOption == TripSortOption.longestDistance
                  ? const Icon(Icons.check_rounded, color: AppTheme.primaryGreen)
                  : null,
              onTap: () =>
                  Navigator.of(context).pop(TripSortOption.longestDistance),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _sortOption = selected;
      });
    }
  }

  /// Beschreibung: Öffnet den Export-Dialog für Fahrtenbuch-Daten.
  /// Eingabe: Keine
  /// Ausgabe: void
  void _openExportDialog() {
    ExportDialog.show(
      context,
      trips: _processedTrips,
      driverId: widget.driver?.id,
    );
  }

  /// Beschreibung: Gibt die lesbare Beschriftung für die gewählte Sortierungsoption zurück.
  /// Eingabe: option (TripSortOption)
  /// Ausgabe: String
  String _getSortLabel(TripSortOption option) {
    switch (option) {
      case TripSortOption.newestFirst:
        return 'Neueste';
      case TripSortOption.oldestFirst:
        return 'Älteste';
      case TripSortOption.longestDistance:
        return 'Längste Strecke';
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = widget.driver;
    final titleText =
        driver != null ? '${driver.firstName} Fahrtbuch' : 'Fahrtbuch';
    final trips = _processedTrips;
    final bool hasActiveFilter =
        _selectedDateRange != null || _sortOption != TripSortOption.newestFirst;

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
              color: AppTheme.primaryGreen,
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
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'Suchen...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppTheme.primaryGreen,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: _selectedDateRange != null
                          ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedDateRange != null
                            ? AppTheme.primaryGreen
                            : Colors.grey.shade300,
                        width: _selectedDateRange != null ? 1.5 : 1.0,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.calendar_month_rounded,
                        color: _selectedDateRange != null
                            ? AppTheme.primaryGreen
                            : AppTheme.textDark,
                      ),
                      tooltip: 'Datumsfilter',
                      onPressed: _pickDateRange,
                    ),
                  ),
                  const SizedBox(width: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: _sortOption != TripSortOption.newestFirst
                          ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _sortOption != TripSortOption.newestFirst
                            ? AppTheme.primaryGreen
                            : Colors.grey.shade300,
                        width: _sortOption != TripSortOption.newestFirst
                            ? 1.5
                            : 1.0,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.swap_vert_rounded,
                        color: _sortOption != TripSortOption.newestFirst
                            ? AppTheme.primaryGreen
                            : AppTheme.textDark,
                      ),
                      tooltip: 'Sortierung',
                      onPressed: _showSortOptions,
                    ),
                  ),
                ],
              ),

              if (hasActiveFilter) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (_selectedDateRange != null) ...[
                      InputChip(
                        avatar: const Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: AppTheme.primaryGreen,
                        ),
                        label: Text(
                          '${formatDate(_selectedDateRange!.start)} - ${formatDate(_selectedDateRange!.end)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onDeleted: () {
                          setState(() => _selectedDateRange = null);
                        },
                        deleteIconColor: Colors.grey.shade700,
                        backgroundColor:
                            AppTheme.primaryGreen.withValues(alpha: 0.1),
                        side: BorderSide(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (_sortOption != TripSortOption.newestFirst) ...[
                      InputChip(
                        avatar: const Icon(
                          Icons.sort_rounded,
                          size: 16,
                          color: AppTheme.primaryGreen,
                        ),
                        label: Text(
                          _getSortLabel(_sortOption),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onDeleted: () {
                          setState(
                            () => _sortOption = TripSortOption.newestFirst,
                          );
                        },
                        deleteIconColor: Colors.grey.shade700,
                        backgroundColor:
                            AppTheme.primaryGreen.withValues(alpha: 0.1),
                        side: BorderSide(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              const SizedBox(height: 16),

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
                              _searchQuery.isNotEmpty ||
                                      _selectedDateRange != null
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
                              _searchQuery.isNotEmpty ||
                                      _selectedDateRange != null
                                  ? 'Versuche den Suchbegriff oder Filter zu ändern.'
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

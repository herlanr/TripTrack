import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../models/trip.dart';
import '../services/trip_repository.dart';
import 'fahrtbuch_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// Die Haupt-Navigationsstruktur der Anwendung mit unterer Navigationsleiste (Bottom Navigation Bar).
class MainScreen extends StatefulWidget {
  /// Erstellt die MainScreen-Instanz mit dem ausgewählten Fahrer.
  const MainScreen({super.key, this.selectedDriver});

  /// Der angemeldete Fahrer
  final Driver? selectedDriver;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TripRepository _tripRepository = TripRepository();
  int _currentIndex = 0;
  int _vehiclesVersion = 0;
  List<Trip> _savedTrips = [];
  late Driver? _currentDriver;

  @override
  void initState() {
    super.initState();
    _currentDriver = widget.selectedDriver;
    _loadSavedTrips();
  }

  @override
  void didUpdateWidget(MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDriver != oldWidget.selectedDriver) {
      _currentDriver = widget.selectedDriver;
    }
  }

  /// Beschreibung: Lädt alle gespeicherten Fahrten aus dem TripRepository.
  /// Eingabe: Keine
  /// Ausgabe: `Future<void>`
  Future<void> _loadSavedTrips() async {
    final trips = await _tripRepository.getTrips();
    if (mounted) {
      setState(() {
        _savedTrips = trips;
      });
    }
  }

  /// Beschreibung: Speichert eine neu beendete Fahrt und lädt die Fahrtenliste neu.
  /// Eingabe: trip ([Trip])
  /// Ausgabe: `Future<void>`
  Future<void> _onTripSaved(Trip trip) async {
    await _tripRepository.saveTrip(trip);
    await _loadSavedTrips();
  }

  /// Beschreibung: Löscht eine Fahrt aus dem Speicher und lädt die Liste neu.
  /// Eingabe: trip ([Trip])
  /// Ausgabe: `Future<void>`
  Future<void> _onTripDeleted(Trip trip) async {
    await _tripRepository.deleteTrip(trip.id);
    await _loadSavedTrips();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        selectedDriver: _currentDriver,
        onTripSaved: _onTripSaved,
        vehiclesVersion: _vehiclesVersion,
        onVehiclesChanged: () {
          setState(() {
            _vehiclesVersion++;
          });
        },
      ),
      FahrtbuchScreen(
        driver: _currentDriver,
        savedTrips: _savedTrips,
        onDeleteTrip: _onTripDeleted,
      ),
      ProfileScreen(
        driver: _currentDriver,
        vehiclesVersion: _vehiclesVersion,
        onDriverUpdated: (updatedDriver) {
          setState(() {
            _currentDriver = updatedDriver;
          });
        },
        onVehiclesChanged: () {
          setState(() {
            _vehiclesVersion++;
          });
        },
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
            _vehiclesVersion++;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car_rounded),
            label: 'Fahren',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Fahrtbuch',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

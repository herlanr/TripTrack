import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../models/trip.dart';
import '../services/trip_repository.dart';
import 'fahrtbuch_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// Die Haupt-Navigationsstruktur der Anwendung mit unterer Navigationsleiste (Bottom Navigation Bar).
///
/// Verwaltet die 3 Haupt-Tabs:
/// 1. Tab "Fahren": [HomeScreen]
/// 2. Tab "Fahrtbuch": [FahrtbuchScreen]
/// 3. Tab "Profile": [ProfileScreen]
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
  List<Trip> _savedTrips = [];

  @override
  void initState() {
    super.initState();
    _loadSavedTrips();
  }

  /// Lädt alle gespeicherten Fahrten aus dem [TripRepository].
  Future<void> _loadSavedTrips() async {
    final trips = await _tripRepository.getTrips();
    if (mounted) {
      setState(() {
        _savedTrips = trips;
      });
    }
  }

  /// Callback beim Speichern einer neuen Fahrt
  Future<void> _onTripSaved(Trip trip) async {
    await _tripRepository.saveTrip(trip);
    await _loadSavedTrips();
  }

  /// Callback beim Löschen einer Fahrt
  Future<void> _onTripDeleted(Trip trip) async {
    await _tripRepository.deleteTrip(trip.id);
    await _loadSavedTrips();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        selectedDriver: widget.selectedDriver,
        onTripSaved: _onTripSaved,
      ),
      FahrtbuchScreen(
        driver: widget.selectedDriver,
        savedTrips: _savedTrips,
        onDeleteTrip: _onTripDeleted,
      ),
      ProfileScreen(driver: widget.selectedDriver),
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

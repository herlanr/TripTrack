import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../models/trip.dart';
import '../services/trip_repository.dart';
import 'fahrtbuch_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// Main navigation wrapper housing the bottom navigation bar with 3 tabs:
/// - Fahren (Home)
/// - Fahrtbuch
/// - Profile
class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.selectedDriver});

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

  Future<void> _loadSavedTrips() async {
    final trips = await _tripRepository.getTrips();
    if (mounted) {
      setState(() {
        _savedTrips = trips;
      });
    }
  }

  Future<void> _onTripSaved(Trip trip) async {
    await _tripRepository.saveTrip(trip);
    await _loadSavedTrips();
  }

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

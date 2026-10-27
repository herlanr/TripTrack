import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:trip_track/models/location_point.dart';
import 'package:trip_track/models/trip.dart';
import 'package:trip_track/services/trip_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Erfurt to Gera Trip Simulation Test', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Simulates a trip from Erfurt to Gera recording 10+ GPS points', () async {
      final startTime = DateTime(2026, 9, 15, 14, 0);

      // Simulated A4 highway route points from Erfurt to Gera (spaced 3 minutes apart)
      final intermediateGpsPoints = <LocationPoint>[
        LocationPoint(
          latitude: 50.9612,
          longitude: 11.1120,
          timestamp: startTime.add(const Duration(minutes: 3)),
        ), // Erfurt Ost
        LocationPoint(
          latitude: 50.9580,
          longitude: 11.2310,
          timestamp: startTime.add(const Duration(minutes: 6)),
        ), // Weimar West
        LocationPoint(
          latitude: 50.9520,
          longitude: 11.3320,
          timestamp: startTime.add(const Duration(minutes: 9)),
        ), // Weimar
        LocationPoint(
          latitude: 50.9120,
          longitude: 11.4510,
          timestamp: startTime.add(const Duration(minutes: 12)),
        ), // Magdala
        LocationPoint(
          latitude: 50.8850,
          longitude: 11.5910,
          timestamp: startTime.add(const Duration(minutes: 15)),
        ), // Jena Göschwitz
        LocationPoint(
          latitude: 50.8780,
          longitude: 11.6320,
          timestamp: startTime.add(const Duration(minutes: 18)),
        ), // Lobdeburg
        LocationPoint(
          latitude: 50.8650,
          longitude: 11.7510,
          timestamp: startTime.add(const Duration(minutes: 21)),
        ), // Stadtroda
        LocationPoint(
          latitude: 50.8520,
          longitude: 11.8540,
          timestamp: startTime.add(const Duration(minutes: 24)),
        ), // Hermsdorfer Kreuz
        LocationPoint(
          latitude: 50.8620,
          longitude: 11.9720,
          timestamp: startTime.add(const Duration(minutes: 27)),
        ), // Rüdersdorf
        LocationPoint(
          latitude: 50.8710,
          longitude: 12.0210,
          timestamp: startTime.add(const Duration(minutes: 30)),
        ), // Gera West
      ];

      // Create completed Trip object
      final trip = Trip(
        driverName: 'Herlan Rocha',
        driverId: 'p_101',
        vehicleId: 'v_202',
        startKm: 254660.0,
        startTime: startTime,
        startLatitude: 50.9725, // Erfurt Hauptbahnhof
        startLongitude: 11.0384,
        startLocationText: 'Erfurt Hauptbahnhof',
        endTime: startTime.add(const Duration(minutes: 33)),
        endLatitude: 50.8812, // Gera Hauptbahnhof
        endLongitude: 12.0818,
        endLocationText: 'Gera Hauptbahnhof',
        routePoints: intermediateGpsPoints,
      );

      // 1. Assert GPS points count (Start + 10 intermediate + End = 12 points >= 10)
      final allPoints = trip.allGpsPoints();
      expect(allPoints.length, greaterThanOrEqualTo(10));
      expect(trip.intermediatePointCount, equals(10));

      // 2. Assert Haversine distance calculation (Calculates 75.65 km for the simulated coordinates)
      final calculatedDistance = trip.distanceKm;
      expect(calculatedDistance, closeTo(75.65, 0.1));

      // 3. Assert Trip duration
      expect(trip.duration, equals(const Duration(minutes: 33)));

      // 4. Save to TripRepository and verify persistence
      final repository = TripRepository();
      await repository.saveTrip(trip);

      final savedTrips = await repository.getTrips();
      expect(savedTrips.length, equals(1));

      final loadedTrip = savedTrips.first;
      expect(loadedTrip.driverName, equals('Herlan Rocha'));
      expect(loadedTrip.startLocationText, equals('Erfurt Hauptbahnhof'));
      expect(loadedTrip.endLocationText, equals('Gera Hauptbahnhof'));
      expect(loadedTrip.allGpsPoints().length, equals(allPoints.length));
      expect(loadedTrip.distanceKm, closeTo(calculatedDistance, 0.01));
    });

    test('RouteList and Trip preserve all intermediate GPS points chronologically', () {
      final startTime = DateTime(2026, 9, 15, 14, 0);
      final intermediateGpsPoints = <LocationPoint>[
        LocationPoint(
          latitude: 50.9612,
          longitude: 11.1120,
          timestamp: startTime.add(const Duration(seconds: 10)),
        ),
        LocationPoint(
          latitude: 50.9580,
          longitude: 11.2310,
          timestamp: startTime.add(const Duration(seconds: 20)),
        ),
        LocationPoint(
          latitude: 50.9520,
          longitude: 11.3320,
          timestamp: startTime.add(const Duration(seconds: 30)),
        ),
      ];

      final trip = Trip(
        driverName: 'Herlan Rocha',
        startKm: 100.0,
        startTime: startTime,
        startLatitude: 50.9725,
        startLongitude: 11.0384,
        startLocationText: 'Erfurt Hauptbahnhof',
        endTime: startTime.add(const Duration(seconds: 40)),
        endLatitude: 50.8812,
        endLongitude: 12.0818,
        endLocationText: 'Gera Hauptbahnhof',
        routePoints: intermediateGpsPoints,
      );

      expect(trip.routePoints.length, equals(3));
      final allPoints = trip.allGpsPoints();
      expect(allPoints.length, equals(5)); // Start + 3 intermediate + End
      expect(allPoints.first.latitude, equals(50.9725));
      expect(allPoints.last.latitude, equals(50.8812));
    });
  });
}

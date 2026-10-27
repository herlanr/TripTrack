import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trip_track/models/driver.dart';
import 'package:trip_track/models/trip.dart';
import 'package:trip_track/models/vehicle.dart';
import 'package:trip_track/services/driver_repository.dart';
import 'package:trip_track/services/trip_repository.dart';
import 'package:trip_track/services/vehicle_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  group('DriverRepository Tests', () {
    test('getDrivers pre-seeds defaultTestDriver when storage is empty', () async {
      final repo = DriverRepository();
      final drivers = await repo.getDrivers();

      expect(drivers.length, equals(1));
      expect(drivers.first.id, equals(DriverRepository.defaultTestDriver.id));
      expect(drivers.first.lastName, equals('Fahrer'));
    });

    test('addDriver adds new driver and persists it', () async {
      final repo = DriverRepository();
      await repo.getDrivers();
      final newDriver = Driver(
        id: 'driver_2',
        firstName: 'Anna',
        lastName: 'Müller',
        dateOfBirth: DateTime(1995, 5, 20),
      );

      await repo.addDriver(newDriver);
      final drivers = await repo.getDrivers();

      expect(drivers.length, equals(2));
      expect(drivers.last.firstName, equals('Anna'));
    });

    test('addDriver throws StateError when max profiles (4) is reached', () async {
      final repo = DriverRepository();
      await repo.getDrivers(); // 1 default

      await repo.addDriver(Driver(id: '2', firstName: 'B', lastName: 'B', dateOfBirth: DateTime.now()));
      await repo.addDriver(Driver(id: '3', firstName: 'C', lastName: 'C', dateOfBirth: DateTime.now()));
      await repo.addDriver(Driver(id: '4', firstName: 'D', lastName: 'D', dateOfBirth: DateTime.now()));

      final drivers = await repo.getDrivers();
      expect(drivers.length, equals(4));

      expect(
        () => repo.addDriver(Driver(id: '5', firstName: 'E', lastName: 'E', dateOfBirth: DateTime.now())),
        throwsA(isA<StateError>()),
      );
    });

    test('deleteDriver removes driver by ID', () async {
      final repo = DriverRepository();
      final drivers = await repo.getDrivers();
      final defaultId = drivers.first.id;

      await repo.addDriver(Driver(
        id: 'driver_2',
        firstName: 'Anna',
        lastName: 'Müller',
        dateOfBirth: DateTime(1995, 5, 20),
      ));

      await repo.deleteDriver(defaultId);
      final remaining = await repo.getDrivers();

      expect(remaining.where((d) => d.id == defaultId).isEmpty, isTrue);
      expect(remaining.length, equals(1));
    });
  });

  group('VehicleRepository Tests', () {
    test('getVehiclesForDriver returns empty list if driver has no vehicles', () async {
      final vehicleRepo = VehicleRepository();
      final vehicles = await vehicleRepo.getVehiclesForDriver('unknown_driver');

      expect(vehicles.isEmpty, isTrue);
    });

    test('addVehicle and updateVehicleKm work properly', () async {
      final vehicleRepo = VehicleRepository();
      final car = Vehicle(
        id: 'car_1',
        driverId: 'driver_1',
        licensePlate: 'EF-AB 123',
        model: 'Golf',
        brand: 'VW',
        currentKm: 1000.0,
      );

      await vehicleRepo.addVehicle(car);
      var list = await vehicleRepo.getVehiclesForDriver('driver_1');
      expect(list.length, equals(1));
      expect(list.first.currentKm, equals(1000.0));

      await vehicleRepo.updateVehicleKm('car_1', 1050.5);
      list = await vehicleRepo.getVehiclesForDriver('driver_1');
      expect(list.first.currentKm, equals(1050.5));
    });

    test('deleteVehiclesForDriver removes all vehicles for driver', () async {
      final vehicleRepo = VehicleRepository();
      await vehicleRepo.addVehicle(Vehicle(
        id: 'c1',
        driverId: 'd_del',
        licensePlate: 'P1',
        model: 'M1',
        brand: 'B1',
        currentKm: 100,
      ));
      await vehicleRepo.addVehicle(Vehicle(
        id: 'c2',
        driverId: 'd_del',
        licensePlate: 'P2',
        model: 'M2',
        brand: 'B2',
        currentKm: 200,
      ));

      var list = await vehicleRepo.getVehiclesForDriver('d_del');
      expect(list.length, equals(2));

      await vehicleRepo.deleteVehiclesForDriver('d_del');
      list = await vehicleRepo.getVehiclesForDriver('d_del');
      expect(list.isEmpty, isTrue);
    });
  });

  group('TripRepository Tests', () {
    test('saveTrip and getTrips store entries in newest-first order', () async {
      final repo = TripRepository();
      final trip1 = Trip(
        id: 't1',
        driverName: 'Fahrer 1',
        startKm: 100,
        startTime: DateTime(2026, 1, 1, 10, 0),
      );
      final trip2 = Trip(
        id: 't2',
        driverName: 'Fahrer 1',
        startKm: 150,
        startTime: DateTime(2026, 1, 1, 12, 0),
      );

      await repo.saveTrip(trip1);
      await repo.saveTrip(trip2);

      final trips = await repo.getTrips();
      expect(trips.length, equals(2));
      expect(trips.first.id, equals('t2')); // newest first
    });

    test('deleteTrip removes trip by ID', () async {
      final repo = TripRepository();
      final trip = Trip(
        id: 't_del',
        driverName: 'Test',
        startKm: 50,
        startTime: DateTime.now(),
      );

      await repo.saveTrip(trip);
      await repo.deleteTrip('t_del');
      final trips = await repo.getTrips();

      expect(trips.where((t) => t.id == 't_del').isEmpty, isTrue);
    });
  });
}

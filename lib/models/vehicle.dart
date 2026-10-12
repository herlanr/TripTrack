/// Represents a vehicle (Fahrzeug) entity based on the ER diagram:
/// - id (Fahrzeug_ID)
/// - driverId (Personen_ID - FK)
/// - licensePlate (Kennzeichen)
/// - model (Modell)
/// - brand (Marke)
/// - currentKm (Kilometerstand)
class Vehicle {
  const Vehicle({
    required this.id,
    required this.driverId,
    required this.licensePlate,
    required this.model,
    required this.brand,
    required this.currentKm,
  });

  final String id;
  final String driverId;
  final String licensePlate;
  final String model;
  final String brand;
  final double currentKm;

  String get displayName => '$brand $model ($licensePlate)';

  Vehicle copyWith({
    String? id,
    String? driverId,
    String? licensePlate,
    String? model,
    String? brand,
    double? currentKm,
  }) {
    return Vehicle(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      licensePlate: licensePlate ?? this.licensePlate,
      model: model ?? this.model,
      brand: brand ?? this.brand,
      currentKm: currentKm ?? this.currentKm,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'driverId': driverId,
        'licensePlate': licensePlate,
        'model': model,
        'brand': brand,
        'currentKm': currentKm,
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String,
        driverId: json['driverId'] as String? ?? '',
        licensePlate: json['licensePlate'] as String,
        model: json['model'] as String,
        brand: json['brand'] as String,
        currentKm: (json['currentKm'] as num).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vehicle && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

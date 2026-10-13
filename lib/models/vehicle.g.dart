// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Vehicle _$VehicleFromJson(Map<String, dynamic> json) => Vehicle(
  id: json['id'] as String,
  driverId: json['driverId'] as String? ?? '',
  licensePlate: json['licensePlate'] as String,
  model: json['model'] as String,
  brand: json['brand'] as String,
  currentKm: (json['currentKm'] as num).toDouble(),
);

Map<String, dynamic> _$VehicleToJson(Vehicle instance) => <String, dynamic>{
  'id': instance.id,
  'driverId': instance.driverId,
  'licensePlate': instance.licensePlate,
  'model': instance.model,
  'brand': instance.brand,
  'currentKm': instance.currentKm,
};

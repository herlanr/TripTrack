// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Trip _$TripFromJson(Map<String, dynamic> json) => Trip(
  id: json['id'] as String?,
  driverName: json['driverName'] as String,
  driverId: json['driverId'] as String?,
  vehicleId: json['vehicleId'] as String?,
  startKm: (json['startKm'] as num).toDouble(),
  startTime: DateTime.parse(json['startTime'] as String),
  startLatitude: (json['startLatitude'] as num?)?.toDouble(),
  startLongitude: (json['startLongitude'] as num?)?.toDouble(),
  startLocationText: json['startLocationText'] as String?,
  endTime: json['endTime'] == null
      ? null
      : DateTime.parse(json['endTime'] as String),
  endLatitude: (json['endLatitude'] as num?)?.toDouble(),
  endLongitude: (json['endLongitude'] as num?)?.toDouble(),
  endLocationText: json['endLocationText'] as String?,
  routePoints:
      (json['routePoints'] as List<dynamic>?)
          ?.map((e) => LocationPoint.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$TripToJson(Trip instance) => <String, dynamic>{
  'id': instance.id,
  'driverName': instance.driverName,
  'driverId': instance.driverId,
  'vehicleId': instance.vehicleId,
  'startTime': instance.startTime.toIso8601String(),
  'startKm': instance.startKm,
  'startLatitude': instance.startLatitude,
  'startLongitude': instance.startLongitude,
  'startLocationText': instance.startLocationText,
  'endTime': instance.endTime?.toIso8601String(),
  'endLatitude': instance.endLatitude,
  'endLongitude': instance.endLongitude,
  'endLocationText': instance.endLocationText,
  'routePoints': instance.routePoints.map((e) => e.toJson()).toList(),
};

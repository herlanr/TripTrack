// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationPoint _$LocationPointFromJson(Map<String, dynamic> json) =>
    LocationPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      addressText: json['addressText'] as String?,
    );

Map<String, dynamic> _$LocationPointToJson(LocationPoint instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'timestamp': instance.timestamp.toIso8601String(),
      if (instance.addressText != null) 'addressText': instance.addressText,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_holiday.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PublicHoliday _$PublicHolidayFromJson(Map<String, dynamic> json) =>
    _PublicHoliday(
      id: json['id'] as String,
      name: json['name'] as String,
      date: DateTime.parse(json['date'] as String),
      region: json['region'] as String?,
      isCompensated: json['isCompensated'] as bool? ?? true,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$PublicHolidayToJson(_PublicHoliday instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'date': instance.date.toIso8601String(),
      'region': instance.region,
      'isCompensated': instance.isCompensated,
      'description': instance.description,
    };

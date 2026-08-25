// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_in_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CheckInRequest _$CheckInRequestFromJson(Map<String, dynamic> json) =>
    _CheckInRequest(
      employeeId: json['employeeId'] as String,
      timestamp:
          json['timestamp'] == null
              ? null
              : DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$CheckInRequestToJson(_CheckInRequest instance) =>
    <String, dynamic>{
      'employeeId': instance.employeeId,
      'timestamp': instance.timestamp?.toIso8601String(),
    };

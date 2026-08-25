// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_out_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CheckOutRequest _$CheckOutRequestFromJson(Map<String, dynamic> json) =>
    _CheckOutRequest(
      employeeId: json['employeeId'] as String,
      timestamp:
          json['timestamp'] == null
              ? null
              : DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$CheckOutRequestToJson(_CheckOutRequest instance) =>
    <String, dynamic>{
      'employeeId': instance.employeeId,
      'timestamp': instance.timestamp?.toIso8601String(),
    };

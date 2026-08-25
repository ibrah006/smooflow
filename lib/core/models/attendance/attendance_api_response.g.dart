// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_api_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AttendanceApiResponse<T> _$AttendanceApiResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => _AttendanceApiResponse<T>(
  success: json['success'] as bool,
  data: _$nullableGenericFromJson(json['data'], fromJsonT),
  error: json['error'] as String?,
  flags:
      (json['flags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$AttendanceApiResponseToJson<T>(
  _AttendanceApiResponse<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'success': instance.success,
  'data': _$nullableGenericToJson(instance.data, toJsonT),
  'error': instance.error,
  'flags': instance.flags,
};

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) => input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) => input == null ? null : toJson(input);

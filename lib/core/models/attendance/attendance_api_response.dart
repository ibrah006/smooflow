import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance_api_response.freezed.dart';
part 'attendance_api_response.g.dart';

@Freezed(genericArgumentFactories: true)
class AttendanceApiResponse<T> with _$AttendanceApiResponse<T> {
  const factory AttendanceApiResponse({
    required bool success,
    T? data,
    String? error,
    @Default([]) List<String> flags,
  }) = _AttendanceApiResponse<T>;

  factory AttendanceApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$AttendanceApiResponseFromJson(json, fromJsonT);
}

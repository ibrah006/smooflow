import 'package:freezed_annotation/freezed_annotation.dart';

import 'shift.dart';

part 'attendance_filter.freezed.dart';
part 'attendance_filter.g.dart';

@freezed
class AttendanceFilter with _$AttendanceFilter {
  const factory AttendanceFilter({
    String? employeeId,
    DateTime? startDate,
    DateTime? endDate,
    @Default([]) List<ShiftStatus> statuses,
    @Default(false) bool onlyFlagged,
    @Default(false) bool onlyPending,
  }) = _AttendanceFilter;

  factory AttendanceFilter.fromJson(Map<String, dynamic> json) =>
      _$AttendanceFilterFromJson(json);
}

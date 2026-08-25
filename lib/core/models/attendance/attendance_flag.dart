import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance_flag.freezed.dart';
part 'attendance_flag.g.dart';

@freezed
class AttendanceFlag with _$AttendanceFlag {
  const factory AttendanceFlag({
    required String id,
    required String employeeId,
    required DateTime flagDate,
    required FlagType flagType,
    required String description,
    Map<String, dynamic>? relatedData,
    @Default(false) bool acknowledged,
    String? acknowledgedBy,
    DateTime? acknowledgedAt,
  }) = _AttendanceFlag;

  factory AttendanceFlag.fromJson(Map<String, dynamic> json) =>
      _$AttendanceFlagFromJson(json);
}

enum FlagType {
  @JsonValue('incomplete_checkout')
  incompleteCheckout,

  @JsonValue('break_violation')
  breakViolation,

  @JsonValue('excessive_overtime')
  excessiveOvertime,

  @JsonValue('consecutive_weekends')
  consecutiveWeekends,

  @JsonValue('holiday_worked')
  holidayWorked,

  @JsonValue('excessive_consecutive_days')
  excessiveConsecutiveDays,
}

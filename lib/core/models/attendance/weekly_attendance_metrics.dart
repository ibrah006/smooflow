import 'package:freezed_annotation/freezed_annotation.dart';

import 'compensation_summary.dart';

part 'weekly_attendance_metrics.freezed.dart';
part 'weekly_attendance_metrics.g.dart';

@freezed
abstract class WeeklyAttendanceMetrics with _$WeeklyAttendanceMetrics {
  const WeeklyAttendanceMetrics._();

  const factory WeeklyAttendanceMetrics({
    required String id,
    required String employeeId,
    required DateTime weekStartDate,
    required DateTime weekEndDate,
    required double totalWorkMinutes,
    required double overtimeMinutes,
    @Default([]) List<String> weekendDaysWorked,
    @Default([]) List<String> holidaysWorked,
    @Default(0) int consecutiveDaysWithoutBreak,
    @Default(false) bool hasBreakViolations,
    @Default([]) List<String> breakViolationDates,
    required CompensationSummary compensationSummary,
    required ApprovalStatus approvalStatus,
    String? approvedBy,
    DateTime? approvedAt,
    @Default(false) bool exportedToPayroll,
    DateTime? exportedAt,
  }) = _WeeklyAttendanceMetrics;

  factory WeeklyAttendanceMetrics.fromJson(Map<String, dynamic> json) =>
      _$WeeklyAttendanceMetricsFromJson(json);

  double get totalWorkHours => totalWorkMinutes / 60;

  double get overtimeHours => overtimeMinutes / 60;

  bool get isApproved => approvalStatus == ApprovalStatus.approved;

  bool get isPending => approvalStatus == ApprovalStatus.pendingReview;
}

enum ApprovalStatus {
  @JsonValue('pending_review')
  pendingReview,

  @JsonValue('approved')
  approved,

  @JsonValue('rejected')
  rejected,
}

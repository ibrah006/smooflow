// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_attendance_metrics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WeeklyAttendanceMetrics _$WeeklyAttendanceMetricsFromJson(
  Map<String, dynamic> json,
) => _WeeklyAttendanceMetrics(
  id: json['id'] as String,
  employeeId: json['employeeId'] as String,
  weekStartDate: DateTime.parse(json['weekStartDate'] as String),
  weekEndDate: DateTime.parse(json['weekEndDate'] as String),
  totalWorkMinutes: (json['totalWorkMinutes'] as num).toDouble(),
  overtimeMinutes: (json['overtimeMinutes'] as num).toDouble(),
  weekendDaysWorked:
      (json['weekendDaysWorked'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  holidaysWorked:
      (json['holidaysWorked'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  consecutiveDaysWithoutBreak:
      (json['consecutiveDaysWithoutBreak'] as num?)?.toInt() ?? 0,
  hasBreakViolations: json['hasBreakViolations'] as bool? ?? false,
  breakViolationDates:
      (json['breakViolationDates'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  compensationSummary: CompensationSummary.fromJson(
    json['compensationSummary'] as Map<String, dynamic>,
  ),
  approvalStatus: $enumDecode(_$ApprovalStatusEnumMap, json['approvalStatus']),
  approvedBy: json['approvedBy'] as String?,
  approvedAt:
      json['approvedAt'] == null
          ? null
          : DateTime.parse(json['approvedAt'] as String),
  exportedToPayroll: json['exportedToPayroll'] as bool? ?? false,
  exportedAt:
      json['exportedAt'] == null
          ? null
          : DateTime.parse(json['exportedAt'] as String),
);

Map<String, dynamic> _$WeeklyAttendanceMetricsToJson(
  _WeeklyAttendanceMetrics instance,
) => <String, dynamic>{
  'id': instance.id,
  'employeeId': instance.employeeId,
  'weekStartDate': instance.weekStartDate.toIso8601String(),
  'weekEndDate': instance.weekEndDate.toIso8601String(),
  'totalWorkMinutes': instance.totalWorkMinutes,
  'overtimeMinutes': instance.overtimeMinutes,
  'weekendDaysWorked': instance.weekendDaysWorked,
  'holidaysWorked': instance.holidaysWorked,
  'consecutiveDaysWithoutBreak': instance.consecutiveDaysWithoutBreak,
  'hasBreakViolations': instance.hasBreakViolations,
  'breakViolationDates': instance.breakViolationDates,
  'compensationSummary': instance.compensationSummary,
  'approvalStatus': _$ApprovalStatusEnumMap[instance.approvalStatus]!,
  'approvedBy': instance.approvedBy,
  'approvedAt': instance.approvedAt?.toIso8601String(),
  'exportedToPayroll': instance.exportedToPayroll,
  'exportedAt': instance.exportedAt?.toIso8601String(),
};

const _$ApprovalStatusEnumMap = {
  ApprovalStatus.pendingReview: 'pending_review',
  ApprovalStatus.approved: 'approved',
  ApprovalStatus.rejected: 'rejected',
};

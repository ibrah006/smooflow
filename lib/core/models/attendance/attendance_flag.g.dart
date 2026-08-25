// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_flag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AttendanceFlag _$AttendanceFlagFromJson(Map<String, dynamic> json) =>
    _AttendanceFlag(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      flagDate: DateTime.parse(json['flagDate'] as String),
      flagType: $enumDecode(_$FlagTypeEnumMap, json['flagType']),
      description: json['description'] as String,
      relatedData: json['relatedData'] as Map<String, dynamic>?,
      acknowledged: json['acknowledged'] as bool? ?? false,
      acknowledgedBy: json['acknowledgedBy'] as String?,
      acknowledgedAt:
          json['acknowledgedAt'] == null
              ? null
              : DateTime.parse(json['acknowledgedAt'] as String),
    );

Map<String, dynamic> _$AttendanceFlagToJson(_AttendanceFlag instance) =>
    <String, dynamic>{
      'id': instance.id,
      'employeeId': instance.employeeId,
      'flagDate': instance.flagDate.toIso8601String(),
      'flagType': _$FlagTypeEnumMap[instance.flagType]!,
      'description': instance.description,
      'relatedData': instance.relatedData,
      'acknowledged': instance.acknowledged,
      'acknowledgedBy': instance.acknowledgedBy,
      'acknowledgedAt': instance.acknowledgedAt?.toIso8601String(),
    };

const _$FlagTypeEnumMap = {
  FlagType.incompleteCheckout: 'incomplete_checkout',
  FlagType.breakViolation: 'break_violation',
  FlagType.excessiveOvertime: 'excessive_overtime',
  FlagType.consecutiveWeekends: 'consecutive_weekends',
  FlagType.holidayWorked: 'holiday_worked',
  FlagType.excessiveConsecutiveDays: 'excessive_consecutive_days',
};

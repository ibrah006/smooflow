// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compensation_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CompensationSummary _$CompensationSummaryFromJson(Map<String, dynamic> json) =>
    _CompensationSummary(
      overtimeHours: (json['overtimeHours'] as num).toDouble(),
      overtimeAmount: (json['overtimeAmount'] as num).toDouble(),
      weekendDaysCount: (json['weekendDaysCount'] as num).toInt(),
      weekendCompensationHours:
          (json['weekendCompensationHours'] as num).toDouble(),
      weekendCompensationAmount:
          (json['weekendCompensationAmount'] as num).toDouble(),
      holidaysWorkedCount: (json['holidaysWorkedCount'] as num).toInt(),
      holidayCompensationHours:
          (json['holidayCompensationHours'] as num).toDouble(),
      holidayCompensationAmount:
          (json['holidayCompensationAmount'] as num).toDouble(),
      totalCompensationDue: (json['totalCompensationDue'] as num).toDouble(),
    );

Map<String, dynamic> _$CompensationSummaryToJson(
  _CompensationSummary instance,
) => <String, dynamic>{
  'overtimeHours': instance.overtimeHours,
  'overtimeAmount': instance.overtimeAmount,
  'weekendDaysCount': instance.weekendDaysCount,
  'weekendCompensationHours': instance.weekendCompensationHours,
  'weekendCompensationAmount': instance.weekendCompensationAmount,
  'holidaysWorkedCount': instance.holidaysWorkedCount,
  'holidayCompensationHours': instance.holidayCompensationHours,
  'holidayCompensationAmount': instance.holidayCompensationAmount,
  'totalCompensationDue': instance.totalCompensationDue,
};

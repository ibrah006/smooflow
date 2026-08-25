// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compensation_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CompensationReport _$CompensationReportFromJson(Map<String, dynamic> json) =>
    _CompensationReport(
      employeeId: json['employeeId'] as String,
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      overtimeHours: (json['overtimeHours'] as num).toDouble(),
      overtimeAmount: (json['overtimeAmount'] as num).toDouble(),
      weekendDays: (json['weekendDays'] as num).toInt(),
      weekendCompAmount: (json['weekendCompAmount'] as num).toDouble(),
      holidaysDays: (json['holidaysDays'] as num).toInt(),
      holidayCompAmount: (json['holidayCompAmount'] as num).toDouble(),
      totalCompensationDue: (json['totalCompensationDue'] as num).toDouble(),
      exportDate: DateTime.parse(json['exportDate'] as String),
    );

Map<String, dynamic> _$CompensationReportToJson(_CompensationReport instance) =>
    <String, dynamic>{
      'employeeId': instance.employeeId,
      'periodStart': instance.periodStart.toIso8601String(),
      'periodEnd': instance.periodEnd.toIso8601String(),
      'overtimeHours': instance.overtimeHours,
      'overtimeAmount': instance.overtimeAmount,
      'weekendDays': instance.weekendDays,
      'weekendCompAmount': instance.weekendCompAmount,
      'holidaysDays': instance.holidaysDays,
      'holidayCompAmount': instance.holidayCompAmount,
      'totalCompensationDue': instance.totalCompensationDue,
      'exportDate': instance.exportDate.toIso8601String(),
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Shift _$ShiftFromJson(Map<String, dynamic> json) => _Shift(
  id: json['id'] as String,
  employeeId: json['employeeId'] as String,
  date: DateTime.parse(json['date'] as String),
  checkInTime: DateTime.parse(json['checkInTime'] as String),
  checkOutTime:
      json['checkOutTime'] == null
          ? null
          : DateTime.parse(json['checkOutTime'] as String),
  shiftDurationMinutes: (json['shiftDurationMinutes'] as num).toInt(),
  workMinutes: (json['workMinutes'] as num).toInt(),
  recordedBreakMinutes: (json['recordedBreakMinutes'] as num).toInt(),
  policyBreakMinutes: (json['policyBreakMinutes'] as num).toInt(),
  status: $enumDecode(_$ShiftStatusEnumMap, json['status']),
  statusReason: json['statusReason'] as String?,
  managerNotes: json['managerNotes'] as String?,
  managerApprovedBy: json['managerApprovedBy'] as String?,
  managerApprovedAt:
      json['managerApprovedAt'] == null
          ? null
          : DateTime.parse(json['managerApprovedAt'] as String),
  isHolidayWorked: json['isHolidayWorked'] as bool? ?? false,
  holidayId: json['holidayId'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$ShiftToJson(_Shift instance) => <String, dynamic>{
  'id': instance.id,
  'employeeId': instance.employeeId,
  'date': instance.date.toIso8601String(),
  'checkInTime': instance.checkInTime.toIso8601String(),
  'checkOutTime': instance.checkOutTime?.toIso8601String(),
  'shiftDurationMinutes': instance.shiftDurationMinutes,
  'workMinutes': instance.workMinutes,
  'recordedBreakMinutes': instance.recordedBreakMinutes,
  'policyBreakMinutes': instance.policyBreakMinutes,
  'status': _$ShiftStatusEnumMap[instance.status]!,
  'statusReason': instance.statusReason,
  'managerNotes': instance.managerNotes,
  'managerApprovedBy': instance.managerApprovedBy,
  'managerApprovedAt': instance.managerApprovedAt?.toIso8601String(),
  'isHolidayWorked': instance.isHolidayWorked,
  'holidayId': instance.holidayId,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$ShiftStatusEnumMap = {
  ShiftStatus.incomplete: 'incomplete',
  ShiftStatus.completed: 'completed',
  ShiftStatus.approved: 'approved',
  ShiftStatus.flagged: 'flagged',
};

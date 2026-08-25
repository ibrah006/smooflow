// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AttendanceFilter _$AttendanceFilterFromJson(Map<String, dynamic> json) =>
    _AttendanceFilter(
      employeeId: json['employeeId'] as String?,
      startDate:
          json['startDate'] == null
              ? null
              : DateTime.parse(json['startDate'] as String),
      endDate:
          json['endDate'] == null
              ? null
              : DateTime.parse(json['endDate'] as String),
      statuses:
          (json['statuses'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$ShiftStatusEnumMap, e))
              .toList() ??
          const [],
      onlyFlagged: json['onlyFlagged'] as bool? ?? false,
      onlyPending: json['onlyPending'] as bool? ?? false,
    );

Map<String, dynamic> _$AttendanceFilterToJson(
  _AttendanceFilter instance,
) => <String, dynamic>{
  'employeeId': instance.employeeId,
  'startDate': instance.startDate?.toIso8601String(),
  'endDate': instance.endDate?.toIso8601String(),
  'statuses': instance.statuses.map((e) => _$ShiftStatusEnumMap[e]!).toList(),
  'onlyFlagged': instance.onlyFlagged,
  'onlyPending': instance.onlyPending,
};

const _$ShiftStatusEnumMap = {
  ShiftStatus.incomplete: 'incomplete',
  ShiftStatus.completed: 'completed',
  ShiftStatus.approved: 'approved',
  ShiftStatus.flagged: 'flagged',
};

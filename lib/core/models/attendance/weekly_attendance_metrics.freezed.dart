// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weekly_attendance_metrics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WeeklyAttendanceMetrics {

 String get id; String get employeeId; DateTime get weekStartDate; DateTime get weekEndDate; double get totalWorkMinutes; double get overtimeMinutes; List<String> get weekendDaysWorked; List<String> get holidaysWorked; int get consecutiveDaysWithoutBreak; bool get hasBreakViolations; List<String> get breakViolationDates; CompensationSummary get compensationSummary; ApprovalStatus get approvalStatus; String? get approvedBy; DateTime? get approvedAt; bool get exportedToPayroll; DateTime? get exportedAt;
/// Create a copy of WeeklyAttendanceMetrics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeeklyAttendanceMetricsCopyWith<WeeklyAttendanceMetrics> get copyWith => _$WeeklyAttendanceMetricsCopyWithImpl<WeeklyAttendanceMetrics>(this as WeeklyAttendanceMetrics, _$identity);

  /// Serializes this WeeklyAttendanceMetrics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeeklyAttendanceMetrics&&(identical(other.id, id) || other.id == id)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.weekStartDate, weekStartDate) || other.weekStartDate == weekStartDate)&&(identical(other.weekEndDate, weekEndDate) || other.weekEndDate == weekEndDate)&&(identical(other.totalWorkMinutes, totalWorkMinutes) || other.totalWorkMinutes == totalWorkMinutes)&&(identical(other.overtimeMinutes, overtimeMinutes) || other.overtimeMinutes == overtimeMinutes)&&const DeepCollectionEquality().equals(other.weekendDaysWorked, weekendDaysWorked)&&const DeepCollectionEquality().equals(other.holidaysWorked, holidaysWorked)&&(identical(other.consecutiveDaysWithoutBreak, consecutiveDaysWithoutBreak) || other.consecutiveDaysWithoutBreak == consecutiveDaysWithoutBreak)&&(identical(other.hasBreakViolations, hasBreakViolations) || other.hasBreakViolations == hasBreakViolations)&&const DeepCollectionEquality().equals(other.breakViolationDates, breakViolationDates)&&(identical(other.compensationSummary, compensationSummary) || other.compensationSummary == compensationSummary)&&(identical(other.approvalStatus, approvalStatus) || other.approvalStatus == approvalStatus)&&(identical(other.approvedBy, approvedBy) || other.approvedBy == approvedBy)&&(identical(other.approvedAt, approvedAt) || other.approvedAt == approvedAt)&&(identical(other.exportedToPayroll, exportedToPayroll) || other.exportedToPayroll == exportedToPayroll)&&(identical(other.exportedAt, exportedAt) || other.exportedAt == exportedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,employeeId,weekStartDate,weekEndDate,totalWorkMinutes,overtimeMinutes,const DeepCollectionEquality().hash(weekendDaysWorked),const DeepCollectionEquality().hash(holidaysWorked),consecutiveDaysWithoutBreak,hasBreakViolations,const DeepCollectionEquality().hash(breakViolationDates),compensationSummary,approvalStatus,approvedBy,approvedAt,exportedToPayroll,exportedAt);

@override
String toString() {
  return 'WeeklyAttendanceMetrics(id: $id, employeeId: $employeeId, weekStartDate: $weekStartDate, weekEndDate: $weekEndDate, totalWorkMinutes: $totalWorkMinutes, overtimeMinutes: $overtimeMinutes, weekendDaysWorked: $weekendDaysWorked, holidaysWorked: $holidaysWorked, consecutiveDaysWithoutBreak: $consecutiveDaysWithoutBreak, hasBreakViolations: $hasBreakViolations, breakViolationDates: $breakViolationDates, compensationSummary: $compensationSummary, approvalStatus: $approvalStatus, approvedBy: $approvedBy, approvedAt: $approvedAt, exportedToPayroll: $exportedToPayroll, exportedAt: $exportedAt)';
}


}

/// @nodoc
abstract mixin class $WeeklyAttendanceMetricsCopyWith<$Res>  {
  factory $WeeklyAttendanceMetricsCopyWith(WeeklyAttendanceMetrics value, $Res Function(WeeklyAttendanceMetrics) _then) = _$WeeklyAttendanceMetricsCopyWithImpl;
@useResult
$Res call({
 String id, String employeeId, DateTime weekStartDate, DateTime weekEndDate, double totalWorkMinutes, double overtimeMinutes, List<String> weekendDaysWorked, List<String> holidaysWorked, int consecutiveDaysWithoutBreak, bool hasBreakViolations, List<String> breakViolationDates, CompensationSummary compensationSummary, ApprovalStatus approvalStatus, String? approvedBy, DateTime? approvedAt, bool exportedToPayroll, DateTime? exportedAt
});


$CompensationSummaryCopyWith<$Res> get compensationSummary;

}
/// @nodoc
class _$WeeklyAttendanceMetricsCopyWithImpl<$Res>
    implements $WeeklyAttendanceMetricsCopyWith<$Res> {
  _$WeeklyAttendanceMetricsCopyWithImpl(this._self, this._then);

  final WeeklyAttendanceMetrics _self;
  final $Res Function(WeeklyAttendanceMetrics) _then;

/// Create a copy of WeeklyAttendanceMetrics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? employeeId = null,Object? weekStartDate = null,Object? weekEndDate = null,Object? totalWorkMinutes = null,Object? overtimeMinutes = null,Object? weekendDaysWorked = null,Object? holidaysWorked = null,Object? consecutiveDaysWithoutBreak = null,Object? hasBreakViolations = null,Object? breakViolationDates = null,Object? compensationSummary = null,Object? approvalStatus = null,Object? approvedBy = freezed,Object? approvedAt = freezed,Object? exportedToPayroll = null,Object? exportedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,weekStartDate: null == weekStartDate ? _self.weekStartDate : weekStartDate // ignore: cast_nullable_to_non_nullable
as DateTime,weekEndDate: null == weekEndDate ? _self.weekEndDate : weekEndDate // ignore: cast_nullable_to_non_nullable
as DateTime,totalWorkMinutes: null == totalWorkMinutes ? _self.totalWorkMinutes : totalWorkMinutes // ignore: cast_nullable_to_non_nullable
as double,overtimeMinutes: null == overtimeMinutes ? _self.overtimeMinutes : overtimeMinutes // ignore: cast_nullable_to_non_nullable
as double,weekendDaysWorked: null == weekendDaysWorked ? _self.weekendDaysWorked : weekendDaysWorked // ignore: cast_nullable_to_non_nullable
as List<String>,holidaysWorked: null == holidaysWorked ? _self.holidaysWorked : holidaysWorked // ignore: cast_nullable_to_non_nullable
as List<String>,consecutiveDaysWithoutBreak: null == consecutiveDaysWithoutBreak ? _self.consecutiveDaysWithoutBreak : consecutiveDaysWithoutBreak // ignore: cast_nullable_to_non_nullable
as int,hasBreakViolations: null == hasBreakViolations ? _self.hasBreakViolations : hasBreakViolations // ignore: cast_nullable_to_non_nullable
as bool,breakViolationDates: null == breakViolationDates ? _self.breakViolationDates : breakViolationDates // ignore: cast_nullable_to_non_nullable
as List<String>,compensationSummary: null == compensationSummary ? _self.compensationSummary : compensationSummary // ignore: cast_nullable_to_non_nullable
as CompensationSummary,approvalStatus: null == approvalStatus ? _self.approvalStatus : approvalStatus // ignore: cast_nullable_to_non_nullable
as ApprovalStatus,approvedBy: freezed == approvedBy ? _self.approvedBy : approvedBy // ignore: cast_nullable_to_non_nullable
as String?,approvedAt: freezed == approvedAt ? _self.approvedAt : approvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,exportedToPayroll: null == exportedToPayroll ? _self.exportedToPayroll : exportedToPayroll // ignore: cast_nullable_to_non_nullable
as bool,exportedAt: freezed == exportedAt ? _self.exportedAt : exportedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of WeeklyAttendanceMetrics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompensationSummaryCopyWith<$Res> get compensationSummary {
  
  return $CompensationSummaryCopyWith<$Res>(_self.compensationSummary, (value) {
    return _then(_self.copyWith(compensationSummary: value));
  });
}
}


/// Adds pattern-matching-related methods to [WeeklyAttendanceMetrics].
extension WeeklyAttendanceMetricsPatterns on WeeklyAttendanceMetrics {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeeklyAttendanceMetrics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeeklyAttendanceMetrics() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeeklyAttendanceMetrics value)  $default,){
final _that = this;
switch (_that) {
case _WeeklyAttendanceMetrics():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeeklyAttendanceMetrics value)?  $default,){
final _that = this;
switch (_that) {
case _WeeklyAttendanceMetrics() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String employeeId,  DateTime weekStartDate,  DateTime weekEndDate,  double totalWorkMinutes,  double overtimeMinutes,  List<String> weekendDaysWorked,  List<String> holidaysWorked,  int consecutiveDaysWithoutBreak,  bool hasBreakViolations,  List<String> breakViolationDates,  CompensationSummary compensationSummary,  ApprovalStatus approvalStatus,  String? approvedBy,  DateTime? approvedAt,  bool exportedToPayroll,  DateTime? exportedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeeklyAttendanceMetrics() when $default != null:
return $default(_that.id,_that.employeeId,_that.weekStartDate,_that.weekEndDate,_that.totalWorkMinutes,_that.overtimeMinutes,_that.weekendDaysWorked,_that.holidaysWorked,_that.consecutiveDaysWithoutBreak,_that.hasBreakViolations,_that.breakViolationDates,_that.compensationSummary,_that.approvalStatus,_that.approvedBy,_that.approvedAt,_that.exportedToPayroll,_that.exportedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String employeeId,  DateTime weekStartDate,  DateTime weekEndDate,  double totalWorkMinutes,  double overtimeMinutes,  List<String> weekendDaysWorked,  List<String> holidaysWorked,  int consecutiveDaysWithoutBreak,  bool hasBreakViolations,  List<String> breakViolationDates,  CompensationSummary compensationSummary,  ApprovalStatus approvalStatus,  String? approvedBy,  DateTime? approvedAt,  bool exportedToPayroll,  DateTime? exportedAt)  $default,) {final _that = this;
switch (_that) {
case _WeeklyAttendanceMetrics():
return $default(_that.id,_that.employeeId,_that.weekStartDate,_that.weekEndDate,_that.totalWorkMinutes,_that.overtimeMinutes,_that.weekendDaysWorked,_that.holidaysWorked,_that.consecutiveDaysWithoutBreak,_that.hasBreakViolations,_that.breakViolationDates,_that.compensationSummary,_that.approvalStatus,_that.approvedBy,_that.approvedAt,_that.exportedToPayroll,_that.exportedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String employeeId,  DateTime weekStartDate,  DateTime weekEndDate,  double totalWorkMinutes,  double overtimeMinutes,  List<String> weekendDaysWorked,  List<String> holidaysWorked,  int consecutiveDaysWithoutBreak,  bool hasBreakViolations,  List<String> breakViolationDates,  CompensationSummary compensationSummary,  ApprovalStatus approvalStatus,  String? approvedBy,  DateTime? approvedAt,  bool exportedToPayroll,  DateTime? exportedAt)?  $default,) {final _that = this;
switch (_that) {
case _WeeklyAttendanceMetrics() when $default != null:
return $default(_that.id,_that.employeeId,_that.weekStartDate,_that.weekEndDate,_that.totalWorkMinutes,_that.overtimeMinutes,_that.weekendDaysWorked,_that.holidaysWorked,_that.consecutiveDaysWithoutBreak,_that.hasBreakViolations,_that.breakViolationDates,_that.compensationSummary,_that.approvalStatus,_that.approvedBy,_that.approvedAt,_that.exportedToPayroll,_that.exportedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeeklyAttendanceMetrics extends WeeklyAttendanceMetrics {
  const _WeeklyAttendanceMetrics({required this.id, required this.employeeId, required this.weekStartDate, required this.weekEndDate, required this.totalWorkMinutes, required this.overtimeMinutes, final  List<String> weekendDaysWorked = const [], final  List<String> holidaysWorked = const [], this.consecutiveDaysWithoutBreak = 0, this.hasBreakViolations = false, final  List<String> breakViolationDates = const [], required this.compensationSummary, required this.approvalStatus, this.approvedBy, this.approvedAt, this.exportedToPayroll = false, this.exportedAt}): _weekendDaysWorked = weekendDaysWorked,_holidaysWorked = holidaysWorked,_breakViolationDates = breakViolationDates,super._();
  factory _WeeklyAttendanceMetrics.fromJson(Map<String, dynamic> json) => _$WeeklyAttendanceMetricsFromJson(json);

@override final  String id;
@override final  String employeeId;
@override final  DateTime weekStartDate;
@override final  DateTime weekEndDate;
@override final  double totalWorkMinutes;
@override final  double overtimeMinutes;
 final  List<String> _weekendDaysWorked;
@override@JsonKey() List<String> get weekendDaysWorked {
  if (_weekendDaysWorked is EqualUnmodifiableListView) return _weekendDaysWorked;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_weekendDaysWorked);
}

 final  List<String> _holidaysWorked;
@override@JsonKey() List<String> get holidaysWorked {
  if (_holidaysWorked is EqualUnmodifiableListView) return _holidaysWorked;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_holidaysWorked);
}

@override@JsonKey() final  int consecutiveDaysWithoutBreak;
@override@JsonKey() final  bool hasBreakViolations;
 final  List<String> _breakViolationDates;
@override@JsonKey() List<String> get breakViolationDates {
  if (_breakViolationDates is EqualUnmodifiableListView) return _breakViolationDates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_breakViolationDates);
}

@override final  CompensationSummary compensationSummary;
@override final  ApprovalStatus approvalStatus;
@override final  String? approvedBy;
@override final  DateTime? approvedAt;
@override@JsonKey() final  bool exportedToPayroll;
@override final  DateTime? exportedAt;

/// Create a copy of WeeklyAttendanceMetrics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeeklyAttendanceMetricsCopyWith<_WeeklyAttendanceMetrics> get copyWith => __$WeeklyAttendanceMetricsCopyWithImpl<_WeeklyAttendanceMetrics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeeklyAttendanceMetricsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeeklyAttendanceMetrics&&(identical(other.id, id) || other.id == id)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.weekStartDate, weekStartDate) || other.weekStartDate == weekStartDate)&&(identical(other.weekEndDate, weekEndDate) || other.weekEndDate == weekEndDate)&&(identical(other.totalWorkMinutes, totalWorkMinutes) || other.totalWorkMinutes == totalWorkMinutes)&&(identical(other.overtimeMinutes, overtimeMinutes) || other.overtimeMinutes == overtimeMinutes)&&const DeepCollectionEquality().equals(other._weekendDaysWorked, _weekendDaysWorked)&&const DeepCollectionEquality().equals(other._holidaysWorked, _holidaysWorked)&&(identical(other.consecutiveDaysWithoutBreak, consecutiveDaysWithoutBreak) || other.consecutiveDaysWithoutBreak == consecutiveDaysWithoutBreak)&&(identical(other.hasBreakViolations, hasBreakViolations) || other.hasBreakViolations == hasBreakViolations)&&const DeepCollectionEquality().equals(other._breakViolationDates, _breakViolationDates)&&(identical(other.compensationSummary, compensationSummary) || other.compensationSummary == compensationSummary)&&(identical(other.approvalStatus, approvalStatus) || other.approvalStatus == approvalStatus)&&(identical(other.approvedBy, approvedBy) || other.approvedBy == approvedBy)&&(identical(other.approvedAt, approvedAt) || other.approvedAt == approvedAt)&&(identical(other.exportedToPayroll, exportedToPayroll) || other.exportedToPayroll == exportedToPayroll)&&(identical(other.exportedAt, exportedAt) || other.exportedAt == exportedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,employeeId,weekStartDate,weekEndDate,totalWorkMinutes,overtimeMinutes,const DeepCollectionEquality().hash(_weekendDaysWorked),const DeepCollectionEquality().hash(_holidaysWorked),consecutiveDaysWithoutBreak,hasBreakViolations,const DeepCollectionEquality().hash(_breakViolationDates),compensationSummary,approvalStatus,approvedBy,approvedAt,exportedToPayroll,exportedAt);

@override
String toString() {
  return 'WeeklyAttendanceMetrics(id: $id, employeeId: $employeeId, weekStartDate: $weekStartDate, weekEndDate: $weekEndDate, totalWorkMinutes: $totalWorkMinutes, overtimeMinutes: $overtimeMinutes, weekendDaysWorked: $weekendDaysWorked, holidaysWorked: $holidaysWorked, consecutiveDaysWithoutBreak: $consecutiveDaysWithoutBreak, hasBreakViolations: $hasBreakViolations, breakViolationDates: $breakViolationDates, compensationSummary: $compensationSummary, approvalStatus: $approvalStatus, approvedBy: $approvedBy, approvedAt: $approvedAt, exportedToPayroll: $exportedToPayroll, exportedAt: $exportedAt)';
}


}

/// @nodoc
abstract mixin class _$WeeklyAttendanceMetricsCopyWith<$Res> implements $WeeklyAttendanceMetricsCopyWith<$Res> {
  factory _$WeeklyAttendanceMetricsCopyWith(_WeeklyAttendanceMetrics value, $Res Function(_WeeklyAttendanceMetrics) _then) = __$WeeklyAttendanceMetricsCopyWithImpl;
@override @useResult
$Res call({
 String id, String employeeId, DateTime weekStartDate, DateTime weekEndDate, double totalWorkMinutes, double overtimeMinutes, List<String> weekendDaysWorked, List<String> holidaysWorked, int consecutiveDaysWithoutBreak, bool hasBreakViolations, List<String> breakViolationDates, CompensationSummary compensationSummary, ApprovalStatus approvalStatus, String? approvedBy, DateTime? approvedAt, bool exportedToPayroll, DateTime? exportedAt
});


@override $CompensationSummaryCopyWith<$Res> get compensationSummary;

}
/// @nodoc
class __$WeeklyAttendanceMetricsCopyWithImpl<$Res>
    implements _$WeeklyAttendanceMetricsCopyWith<$Res> {
  __$WeeklyAttendanceMetricsCopyWithImpl(this._self, this._then);

  final _WeeklyAttendanceMetrics _self;
  final $Res Function(_WeeklyAttendanceMetrics) _then;

/// Create a copy of WeeklyAttendanceMetrics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? employeeId = null,Object? weekStartDate = null,Object? weekEndDate = null,Object? totalWorkMinutes = null,Object? overtimeMinutes = null,Object? weekendDaysWorked = null,Object? holidaysWorked = null,Object? consecutiveDaysWithoutBreak = null,Object? hasBreakViolations = null,Object? breakViolationDates = null,Object? compensationSummary = null,Object? approvalStatus = null,Object? approvedBy = freezed,Object? approvedAt = freezed,Object? exportedToPayroll = null,Object? exportedAt = freezed,}) {
  return _then(_WeeklyAttendanceMetrics(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,weekStartDate: null == weekStartDate ? _self.weekStartDate : weekStartDate // ignore: cast_nullable_to_non_nullable
as DateTime,weekEndDate: null == weekEndDate ? _self.weekEndDate : weekEndDate // ignore: cast_nullable_to_non_nullable
as DateTime,totalWorkMinutes: null == totalWorkMinutes ? _self.totalWorkMinutes : totalWorkMinutes // ignore: cast_nullable_to_non_nullable
as double,overtimeMinutes: null == overtimeMinutes ? _self.overtimeMinutes : overtimeMinutes // ignore: cast_nullable_to_non_nullable
as double,weekendDaysWorked: null == weekendDaysWorked ? _self._weekendDaysWorked : weekendDaysWorked // ignore: cast_nullable_to_non_nullable
as List<String>,holidaysWorked: null == holidaysWorked ? _self._holidaysWorked : holidaysWorked // ignore: cast_nullable_to_non_nullable
as List<String>,consecutiveDaysWithoutBreak: null == consecutiveDaysWithoutBreak ? _self.consecutiveDaysWithoutBreak : consecutiveDaysWithoutBreak // ignore: cast_nullable_to_non_nullable
as int,hasBreakViolations: null == hasBreakViolations ? _self.hasBreakViolations : hasBreakViolations // ignore: cast_nullable_to_non_nullable
as bool,breakViolationDates: null == breakViolationDates ? _self._breakViolationDates : breakViolationDates // ignore: cast_nullable_to_non_nullable
as List<String>,compensationSummary: null == compensationSummary ? _self.compensationSummary : compensationSummary // ignore: cast_nullable_to_non_nullable
as CompensationSummary,approvalStatus: null == approvalStatus ? _self.approvalStatus : approvalStatus // ignore: cast_nullable_to_non_nullable
as ApprovalStatus,approvedBy: freezed == approvedBy ? _self.approvedBy : approvedBy // ignore: cast_nullable_to_non_nullable
as String?,approvedAt: freezed == approvedAt ? _self.approvedAt : approvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,exportedToPayroll: null == exportedToPayroll ? _self.exportedToPayroll : exportedToPayroll // ignore: cast_nullable_to_non_nullable
as bool,exportedAt: freezed == exportedAt ? _self.exportedAt : exportedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of WeeklyAttendanceMetrics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompensationSummaryCopyWith<$Res> get compensationSummary {
  
  return $CompensationSummaryCopyWith<$Res>(_self.compensationSummary, (value) {
    return _then(_self.copyWith(compensationSummary: value));
  });
}
}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'compensation_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CompensationReport {

 String get employeeId; DateTime get periodStart; DateTime get periodEnd; double get overtimeHours; double get overtimeAmount; int get weekendDays; double get weekendCompAmount; int get holidaysDays; double get holidayCompAmount; double get totalCompensationDue; DateTime get exportDate;
/// Create a copy of CompensationReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompensationReportCopyWith<CompensationReport> get copyWith => _$CompensationReportCopyWithImpl<CompensationReport>(this as CompensationReport, _$identity);

  /// Serializes this CompensationReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompensationReport&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd)&&(identical(other.overtimeHours, overtimeHours) || other.overtimeHours == overtimeHours)&&(identical(other.overtimeAmount, overtimeAmount) || other.overtimeAmount == overtimeAmount)&&(identical(other.weekendDays, weekendDays) || other.weekendDays == weekendDays)&&(identical(other.weekendCompAmount, weekendCompAmount) || other.weekendCompAmount == weekendCompAmount)&&(identical(other.holidaysDays, holidaysDays) || other.holidaysDays == holidaysDays)&&(identical(other.holidayCompAmount, holidayCompAmount) || other.holidayCompAmount == holidayCompAmount)&&(identical(other.totalCompensationDue, totalCompensationDue) || other.totalCompensationDue == totalCompensationDue)&&(identical(other.exportDate, exportDate) || other.exportDate == exportDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,employeeId,periodStart,periodEnd,overtimeHours,overtimeAmount,weekendDays,weekendCompAmount,holidaysDays,holidayCompAmount,totalCompensationDue,exportDate);

@override
String toString() {
  return 'CompensationReport(employeeId: $employeeId, periodStart: $periodStart, periodEnd: $periodEnd, overtimeHours: $overtimeHours, overtimeAmount: $overtimeAmount, weekendDays: $weekendDays, weekendCompAmount: $weekendCompAmount, holidaysDays: $holidaysDays, holidayCompAmount: $holidayCompAmount, totalCompensationDue: $totalCompensationDue, exportDate: $exportDate)';
}


}

/// @nodoc
abstract mixin class $CompensationReportCopyWith<$Res>  {
  factory $CompensationReportCopyWith(CompensationReport value, $Res Function(CompensationReport) _then) = _$CompensationReportCopyWithImpl;
@useResult
$Res call({
 String employeeId, DateTime periodStart, DateTime periodEnd, double overtimeHours, double overtimeAmount, int weekendDays, double weekendCompAmount, int holidaysDays, double holidayCompAmount, double totalCompensationDue, DateTime exportDate
});




}
/// @nodoc
class _$CompensationReportCopyWithImpl<$Res>
    implements $CompensationReportCopyWith<$Res> {
  _$CompensationReportCopyWithImpl(this._self, this._then);

  final CompensationReport _self;
  final $Res Function(CompensationReport) _then;

/// Create a copy of CompensationReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? employeeId = null,Object? periodStart = null,Object? periodEnd = null,Object? overtimeHours = null,Object? overtimeAmount = null,Object? weekendDays = null,Object? weekendCompAmount = null,Object? holidaysDays = null,Object? holidayCompAmount = null,Object? totalCompensationDue = null,Object? exportDate = null,}) {
  return _then(_self.copyWith(
employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as DateTime,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as DateTime,overtimeHours: null == overtimeHours ? _self.overtimeHours : overtimeHours // ignore: cast_nullable_to_non_nullable
as double,overtimeAmount: null == overtimeAmount ? _self.overtimeAmount : overtimeAmount // ignore: cast_nullable_to_non_nullable
as double,weekendDays: null == weekendDays ? _self.weekendDays : weekendDays // ignore: cast_nullable_to_non_nullable
as int,weekendCompAmount: null == weekendCompAmount ? _self.weekendCompAmount : weekendCompAmount // ignore: cast_nullable_to_non_nullable
as double,holidaysDays: null == holidaysDays ? _self.holidaysDays : holidaysDays // ignore: cast_nullable_to_non_nullable
as int,holidayCompAmount: null == holidayCompAmount ? _self.holidayCompAmount : holidayCompAmount // ignore: cast_nullable_to_non_nullable
as double,totalCompensationDue: null == totalCompensationDue ? _self.totalCompensationDue : totalCompensationDue // ignore: cast_nullable_to_non_nullable
as double,exportDate: null == exportDate ? _self.exportDate : exportDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [CompensationReport].
extension CompensationReportPatterns on CompensationReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompensationReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompensationReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompensationReport value)  $default,){
final _that = this;
switch (_that) {
case _CompensationReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompensationReport value)?  $default,){
final _that = this;
switch (_that) {
case _CompensationReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String employeeId,  DateTime periodStart,  DateTime periodEnd,  double overtimeHours,  double overtimeAmount,  int weekendDays,  double weekendCompAmount,  int holidaysDays,  double holidayCompAmount,  double totalCompensationDue,  DateTime exportDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompensationReport() when $default != null:
return $default(_that.employeeId,_that.periodStart,_that.periodEnd,_that.overtimeHours,_that.overtimeAmount,_that.weekendDays,_that.weekendCompAmount,_that.holidaysDays,_that.holidayCompAmount,_that.totalCompensationDue,_that.exportDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String employeeId,  DateTime periodStart,  DateTime periodEnd,  double overtimeHours,  double overtimeAmount,  int weekendDays,  double weekendCompAmount,  int holidaysDays,  double holidayCompAmount,  double totalCompensationDue,  DateTime exportDate)  $default,) {final _that = this;
switch (_that) {
case _CompensationReport():
return $default(_that.employeeId,_that.periodStart,_that.periodEnd,_that.overtimeHours,_that.overtimeAmount,_that.weekendDays,_that.weekendCompAmount,_that.holidaysDays,_that.holidayCompAmount,_that.totalCompensationDue,_that.exportDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String employeeId,  DateTime periodStart,  DateTime periodEnd,  double overtimeHours,  double overtimeAmount,  int weekendDays,  double weekendCompAmount,  int holidaysDays,  double holidayCompAmount,  double totalCompensationDue,  DateTime exportDate)?  $default,) {final _that = this;
switch (_that) {
case _CompensationReport() when $default != null:
return $default(_that.employeeId,_that.periodStart,_that.periodEnd,_that.overtimeHours,_that.overtimeAmount,_that.weekendDays,_that.weekendCompAmount,_that.holidaysDays,_that.holidayCompAmount,_that.totalCompensationDue,_that.exportDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CompensationReport implements CompensationReport {
  const _CompensationReport({required this.employeeId, required this.periodStart, required this.periodEnd, required this.overtimeHours, required this.overtimeAmount, required this.weekendDays, required this.weekendCompAmount, required this.holidaysDays, required this.holidayCompAmount, required this.totalCompensationDue, required this.exportDate});
  factory _CompensationReport.fromJson(Map<String, dynamic> json) => _$CompensationReportFromJson(json);

@override final  String employeeId;
@override final  DateTime periodStart;
@override final  DateTime periodEnd;
@override final  double overtimeHours;
@override final  double overtimeAmount;
@override final  int weekendDays;
@override final  double weekendCompAmount;
@override final  int holidaysDays;
@override final  double holidayCompAmount;
@override final  double totalCompensationDue;
@override final  DateTime exportDate;

/// Create a copy of CompensationReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompensationReportCopyWith<_CompensationReport> get copyWith => __$CompensationReportCopyWithImpl<_CompensationReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompensationReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompensationReport&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd)&&(identical(other.overtimeHours, overtimeHours) || other.overtimeHours == overtimeHours)&&(identical(other.overtimeAmount, overtimeAmount) || other.overtimeAmount == overtimeAmount)&&(identical(other.weekendDays, weekendDays) || other.weekendDays == weekendDays)&&(identical(other.weekendCompAmount, weekendCompAmount) || other.weekendCompAmount == weekendCompAmount)&&(identical(other.holidaysDays, holidaysDays) || other.holidaysDays == holidaysDays)&&(identical(other.holidayCompAmount, holidayCompAmount) || other.holidayCompAmount == holidayCompAmount)&&(identical(other.totalCompensationDue, totalCompensationDue) || other.totalCompensationDue == totalCompensationDue)&&(identical(other.exportDate, exportDate) || other.exportDate == exportDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,employeeId,periodStart,periodEnd,overtimeHours,overtimeAmount,weekendDays,weekendCompAmount,holidaysDays,holidayCompAmount,totalCompensationDue,exportDate);

@override
String toString() {
  return 'CompensationReport(employeeId: $employeeId, periodStart: $periodStart, periodEnd: $periodEnd, overtimeHours: $overtimeHours, overtimeAmount: $overtimeAmount, weekendDays: $weekendDays, weekendCompAmount: $weekendCompAmount, holidaysDays: $holidaysDays, holidayCompAmount: $holidayCompAmount, totalCompensationDue: $totalCompensationDue, exportDate: $exportDate)';
}


}

/// @nodoc
abstract mixin class _$CompensationReportCopyWith<$Res> implements $CompensationReportCopyWith<$Res> {
  factory _$CompensationReportCopyWith(_CompensationReport value, $Res Function(_CompensationReport) _then) = __$CompensationReportCopyWithImpl;
@override @useResult
$Res call({
 String employeeId, DateTime periodStart, DateTime periodEnd, double overtimeHours, double overtimeAmount, int weekendDays, double weekendCompAmount, int holidaysDays, double holidayCompAmount, double totalCompensationDue, DateTime exportDate
});




}
/// @nodoc
class __$CompensationReportCopyWithImpl<$Res>
    implements _$CompensationReportCopyWith<$Res> {
  __$CompensationReportCopyWithImpl(this._self, this._then);

  final _CompensationReport _self;
  final $Res Function(_CompensationReport) _then;

/// Create a copy of CompensationReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? employeeId = null,Object? periodStart = null,Object? periodEnd = null,Object? overtimeHours = null,Object? overtimeAmount = null,Object? weekendDays = null,Object? weekendCompAmount = null,Object? holidaysDays = null,Object? holidayCompAmount = null,Object? totalCompensationDue = null,Object? exportDate = null,}) {
  return _then(_CompensationReport(
employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as DateTime,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as DateTime,overtimeHours: null == overtimeHours ? _self.overtimeHours : overtimeHours // ignore: cast_nullable_to_non_nullable
as double,overtimeAmount: null == overtimeAmount ? _self.overtimeAmount : overtimeAmount // ignore: cast_nullable_to_non_nullable
as double,weekendDays: null == weekendDays ? _self.weekendDays : weekendDays // ignore: cast_nullable_to_non_nullable
as int,weekendCompAmount: null == weekendCompAmount ? _self.weekendCompAmount : weekendCompAmount // ignore: cast_nullable_to_non_nullable
as double,holidaysDays: null == holidaysDays ? _self.holidaysDays : holidaysDays // ignore: cast_nullable_to_non_nullable
as int,holidayCompAmount: null == holidayCompAmount ? _self.holidayCompAmount : holidayCompAmount // ignore: cast_nullable_to_non_nullable
as double,totalCompensationDue: null == totalCompensationDue ? _self.totalCompensationDue : totalCompensationDue // ignore: cast_nullable_to_non_nullable
as double,exportDate: null == exportDate ? _self.exportDate : exportDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on

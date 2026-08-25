// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shift.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Shift {

 String get id; String get employeeId; DateTime get date; DateTime get checkInTime; DateTime? get checkOutTime; int get shiftDurationMinutes; int get workMinutes; int get recordedBreakMinutes; int get policyBreakMinutes; ShiftStatus get status; String? get statusReason; String? get managerNotes; String? get managerApprovedBy; DateTime? get managerApprovedAt; bool get isHolidayWorked; String? get holidayId; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of Shift
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShiftCopyWith<Shift> get copyWith => _$ShiftCopyWithImpl<Shift>(this as Shift, _$identity);

  /// Serializes this Shift to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Shift&&(identical(other.id, id) || other.id == id)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.date, date) || other.date == date)&&(identical(other.checkInTime, checkInTime) || other.checkInTime == checkInTime)&&(identical(other.checkOutTime, checkOutTime) || other.checkOutTime == checkOutTime)&&(identical(other.shiftDurationMinutes, shiftDurationMinutes) || other.shiftDurationMinutes == shiftDurationMinutes)&&(identical(other.workMinutes, workMinutes) || other.workMinutes == workMinutes)&&(identical(other.recordedBreakMinutes, recordedBreakMinutes) || other.recordedBreakMinutes == recordedBreakMinutes)&&(identical(other.policyBreakMinutes, policyBreakMinutes) || other.policyBreakMinutes == policyBreakMinutes)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusReason, statusReason) || other.statusReason == statusReason)&&(identical(other.managerNotes, managerNotes) || other.managerNotes == managerNotes)&&(identical(other.managerApprovedBy, managerApprovedBy) || other.managerApprovedBy == managerApprovedBy)&&(identical(other.managerApprovedAt, managerApprovedAt) || other.managerApprovedAt == managerApprovedAt)&&(identical(other.isHolidayWorked, isHolidayWorked) || other.isHolidayWorked == isHolidayWorked)&&(identical(other.holidayId, holidayId) || other.holidayId == holidayId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,employeeId,date,checkInTime,checkOutTime,shiftDurationMinutes,workMinutes,recordedBreakMinutes,policyBreakMinutes,status,statusReason,managerNotes,managerApprovedBy,managerApprovedAt,isHolidayWorked,holidayId,createdAt,updatedAt);

@override
String toString() {
  return 'Shift(id: $id, employeeId: $employeeId, date: $date, checkInTime: $checkInTime, checkOutTime: $checkOutTime, shiftDurationMinutes: $shiftDurationMinutes, workMinutes: $workMinutes, recordedBreakMinutes: $recordedBreakMinutes, policyBreakMinutes: $policyBreakMinutes, status: $status, statusReason: $statusReason, managerNotes: $managerNotes, managerApprovedBy: $managerApprovedBy, managerApprovedAt: $managerApprovedAt, isHolidayWorked: $isHolidayWorked, holidayId: $holidayId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ShiftCopyWith<$Res>  {
  factory $ShiftCopyWith(Shift value, $Res Function(Shift) _then) = _$ShiftCopyWithImpl;
@useResult
$Res call({
 String id, String employeeId, DateTime date, DateTime checkInTime, DateTime? checkOutTime, int shiftDurationMinutes, int workMinutes, int recordedBreakMinutes, int policyBreakMinutes, ShiftStatus status, String? statusReason, String? managerNotes, String? managerApprovedBy, DateTime? managerApprovedAt, bool isHolidayWorked, String? holidayId, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$ShiftCopyWithImpl<$Res>
    implements $ShiftCopyWith<$Res> {
  _$ShiftCopyWithImpl(this._self, this._then);

  final Shift _self;
  final $Res Function(Shift) _then;

/// Create a copy of Shift
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? employeeId = null,Object? date = null,Object? checkInTime = null,Object? checkOutTime = freezed,Object? shiftDurationMinutes = null,Object? workMinutes = null,Object? recordedBreakMinutes = null,Object? policyBreakMinutes = null,Object? status = null,Object? statusReason = freezed,Object? managerNotes = freezed,Object? managerApprovedBy = freezed,Object? managerApprovedAt = freezed,Object? isHolidayWorked = null,Object? holidayId = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,checkInTime: null == checkInTime ? _self.checkInTime : checkInTime // ignore: cast_nullable_to_non_nullable
as DateTime,checkOutTime: freezed == checkOutTime ? _self.checkOutTime : checkOutTime // ignore: cast_nullable_to_non_nullable
as DateTime?,shiftDurationMinutes: null == shiftDurationMinutes ? _self.shiftDurationMinutes : shiftDurationMinutes // ignore: cast_nullable_to_non_nullable
as int,workMinutes: null == workMinutes ? _self.workMinutes : workMinutes // ignore: cast_nullable_to_non_nullable
as int,recordedBreakMinutes: null == recordedBreakMinutes ? _self.recordedBreakMinutes : recordedBreakMinutes // ignore: cast_nullable_to_non_nullable
as int,policyBreakMinutes: null == policyBreakMinutes ? _self.policyBreakMinutes : policyBreakMinutes // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ShiftStatus,statusReason: freezed == statusReason ? _self.statusReason : statusReason // ignore: cast_nullable_to_non_nullable
as String?,managerNotes: freezed == managerNotes ? _self.managerNotes : managerNotes // ignore: cast_nullable_to_non_nullable
as String?,managerApprovedBy: freezed == managerApprovedBy ? _self.managerApprovedBy : managerApprovedBy // ignore: cast_nullable_to_non_nullable
as String?,managerApprovedAt: freezed == managerApprovedAt ? _self.managerApprovedAt : managerApprovedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isHolidayWorked: null == isHolidayWorked ? _self.isHolidayWorked : isHolidayWorked // ignore: cast_nullable_to_non_nullable
as bool,holidayId: freezed == holidayId ? _self.holidayId : holidayId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Shift].
extension ShiftPatterns on Shift {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Shift value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Shift() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Shift value)  $default,){
final _that = this;
switch (_that) {
case _Shift():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Shift value)?  $default,){
final _that = this;
switch (_that) {
case _Shift() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String employeeId,  DateTime date,  DateTime checkInTime,  DateTime? checkOutTime,  int shiftDurationMinutes,  int workMinutes,  int recordedBreakMinutes,  int policyBreakMinutes,  ShiftStatus status,  String? statusReason,  String? managerNotes,  String? managerApprovedBy,  DateTime? managerApprovedAt,  bool isHolidayWorked,  String? holidayId,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Shift() when $default != null:
return $default(_that.id,_that.employeeId,_that.date,_that.checkInTime,_that.checkOutTime,_that.shiftDurationMinutes,_that.workMinutes,_that.recordedBreakMinutes,_that.policyBreakMinutes,_that.status,_that.statusReason,_that.managerNotes,_that.managerApprovedBy,_that.managerApprovedAt,_that.isHolidayWorked,_that.holidayId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String employeeId,  DateTime date,  DateTime checkInTime,  DateTime? checkOutTime,  int shiftDurationMinutes,  int workMinutes,  int recordedBreakMinutes,  int policyBreakMinutes,  ShiftStatus status,  String? statusReason,  String? managerNotes,  String? managerApprovedBy,  DateTime? managerApprovedAt,  bool isHolidayWorked,  String? holidayId,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Shift():
return $default(_that.id,_that.employeeId,_that.date,_that.checkInTime,_that.checkOutTime,_that.shiftDurationMinutes,_that.workMinutes,_that.recordedBreakMinutes,_that.policyBreakMinutes,_that.status,_that.statusReason,_that.managerNotes,_that.managerApprovedBy,_that.managerApprovedAt,_that.isHolidayWorked,_that.holidayId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String employeeId,  DateTime date,  DateTime checkInTime,  DateTime? checkOutTime,  int shiftDurationMinutes,  int workMinutes,  int recordedBreakMinutes,  int policyBreakMinutes,  ShiftStatus status,  String? statusReason,  String? managerNotes,  String? managerApprovedBy,  DateTime? managerApprovedAt,  bool isHolidayWorked,  String? holidayId,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Shift() when $default != null:
return $default(_that.id,_that.employeeId,_that.date,_that.checkInTime,_that.checkOutTime,_that.shiftDurationMinutes,_that.workMinutes,_that.recordedBreakMinutes,_that.policyBreakMinutes,_that.status,_that.statusReason,_that.managerNotes,_that.managerApprovedBy,_that.managerApprovedAt,_that.isHolidayWorked,_that.holidayId,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Shift extends Shift {
  const _Shift({required this.id, required this.employeeId, required this.date, required this.checkInTime, this.checkOutTime, required this.shiftDurationMinutes, required this.workMinutes, required this.recordedBreakMinutes, required this.policyBreakMinutes, required this.status, this.statusReason, this.managerNotes, this.managerApprovedBy, this.managerApprovedAt, this.isHolidayWorked = false, this.holidayId, required this.createdAt, required this.updatedAt}): super._();
  factory _Shift.fromJson(Map<String, dynamic> json) => _$ShiftFromJson(json);

@override final  String id;
@override final  String employeeId;
@override final  DateTime date;
@override final  DateTime checkInTime;
@override final  DateTime? checkOutTime;
@override final  int shiftDurationMinutes;
@override final  int workMinutes;
@override final  int recordedBreakMinutes;
@override final  int policyBreakMinutes;
@override final  ShiftStatus status;
@override final  String? statusReason;
@override final  String? managerNotes;
@override final  String? managerApprovedBy;
@override final  DateTime? managerApprovedAt;
@override@JsonKey() final  bool isHolidayWorked;
@override final  String? holidayId;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of Shift
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShiftCopyWith<_Shift> get copyWith => __$ShiftCopyWithImpl<_Shift>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShiftToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Shift&&(identical(other.id, id) || other.id == id)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.date, date) || other.date == date)&&(identical(other.checkInTime, checkInTime) || other.checkInTime == checkInTime)&&(identical(other.checkOutTime, checkOutTime) || other.checkOutTime == checkOutTime)&&(identical(other.shiftDurationMinutes, shiftDurationMinutes) || other.shiftDurationMinutes == shiftDurationMinutes)&&(identical(other.workMinutes, workMinutes) || other.workMinutes == workMinutes)&&(identical(other.recordedBreakMinutes, recordedBreakMinutes) || other.recordedBreakMinutes == recordedBreakMinutes)&&(identical(other.policyBreakMinutes, policyBreakMinutes) || other.policyBreakMinutes == policyBreakMinutes)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusReason, statusReason) || other.statusReason == statusReason)&&(identical(other.managerNotes, managerNotes) || other.managerNotes == managerNotes)&&(identical(other.managerApprovedBy, managerApprovedBy) || other.managerApprovedBy == managerApprovedBy)&&(identical(other.managerApprovedAt, managerApprovedAt) || other.managerApprovedAt == managerApprovedAt)&&(identical(other.isHolidayWorked, isHolidayWorked) || other.isHolidayWorked == isHolidayWorked)&&(identical(other.holidayId, holidayId) || other.holidayId == holidayId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,employeeId,date,checkInTime,checkOutTime,shiftDurationMinutes,workMinutes,recordedBreakMinutes,policyBreakMinutes,status,statusReason,managerNotes,managerApprovedBy,managerApprovedAt,isHolidayWorked,holidayId,createdAt,updatedAt);

@override
String toString() {
  return 'Shift(id: $id, employeeId: $employeeId, date: $date, checkInTime: $checkInTime, checkOutTime: $checkOutTime, shiftDurationMinutes: $shiftDurationMinutes, workMinutes: $workMinutes, recordedBreakMinutes: $recordedBreakMinutes, policyBreakMinutes: $policyBreakMinutes, status: $status, statusReason: $statusReason, managerNotes: $managerNotes, managerApprovedBy: $managerApprovedBy, managerApprovedAt: $managerApprovedAt, isHolidayWorked: $isHolidayWorked, holidayId: $holidayId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ShiftCopyWith<$Res> implements $ShiftCopyWith<$Res> {
  factory _$ShiftCopyWith(_Shift value, $Res Function(_Shift) _then) = __$ShiftCopyWithImpl;
@override @useResult
$Res call({
 String id, String employeeId, DateTime date, DateTime checkInTime, DateTime? checkOutTime, int shiftDurationMinutes, int workMinutes, int recordedBreakMinutes, int policyBreakMinutes, ShiftStatus status, String? statusReason, String? managerNotes, String? managerApprovedBy, DateTime? managerApprovedAt, bool isHolidayWorked, String? holidayId, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$ShiftCopyWithImpl<$Res>
    implements _$ShiftCopyWith<$Res> {
  __$ShiftCopyWithImpl(this._self, this._then);

  final _Shift _self;
  final $Res Function(_Shift) _then;

/// Create a copy of Shift
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? employeeId = null,Object? date = null,Object? checkInTime = null,Object? checkOutTime = freezed,Object? shiftDurationMinutes = null,Object? workMinutes = null,Object? recordedBreakMinutes = null,Object? policyBreakMinutes = null,Object? status = null,Object? statusReason = freezed,Object? managerNotes = freezed,Object? managerApprovedBy = freezed,Object? managerApprovedAt = freezed,Object? isHolidayWorked = null,Object? holidayId = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Shift(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,checkInTime: null == checkInTime ? _self.checkInTime : checkInTime // ignore: cast_nullable_to_non_nullable
as DateTime,checkOutTime: freezed == checkOutTime ? _self.checkOutTime : checkOutTime // ignore: cast_nullable_to_non_nullable
as DateTime?,shiftDurationMinutes: null == shiftDurationMinutes ? _self.shiftDurationMinutes : shiftDurationMinutes // ignore: cast_nullable_to_non_nullable
as int,workMinutes: null == workMinutes ? _self.workMinutes : workMinutes // ignore: cast_nullable_to_non_nullable
as int,recordedBreakMinutes: null == recordedBreakMinutes ? _self.recordedBreakMinutes : recordedBreakMinutes // ignore: cast_nullable_to_non_nullable
as int,policyBreakMinutes: null == policyBreakMinutes ? _self.policyBreakMinutes : policyBreakMinutes // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ShiftStatus,statusReason: freezed == statusReason ? _self.statusReason : statusReason // ignore: cast_nullable_to_non_nullable
as String?,managerNotes: freezed == managerNotes ? _self.managerNotes : managerNotes // ignore: cast_nullable_to_non_nullable
as String?,managerApprovedBy: freezed == managerApprovedBy ? _self.managerApprovedBy : managerApprovedBy // ignore: cast_nullable_to_non_nullable
as String?,managerApprovedAt: freezed == managerApprovedAt ? _self.managerApprovedAt : managerApprovedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isHolidayWorked: null == isHolidayWorked ? _self.isHolidayWorked : isHolidayWorked // ignore: cast_nullable_to_non_nullable
as bool,holidayId: freezed == holidayId ? _self.holidayId : holidayId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on

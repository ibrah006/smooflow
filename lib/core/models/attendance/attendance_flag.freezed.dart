// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attendance_flag.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AttendanceFlag {

 String get id; String get employeeId; DateTime get flagDate; FlagType get flagType; String get description; Map<String, dynamic>? get relatedData; bool get acknowledged; String? get acknowledgedBy; DateTime? get acknowledgedAt;
/// Create a copy of AttendanceFlag
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttendanceFlagCopyWith<AttendanceFlag> get copyWith => _$AttendanceFlagCopyWithImpl<AttendanceFlag>(this as AttendanceFlag, _$identity);

  /// Serializes this AttendanceFlag to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttendanceFlag&&(identical(other.id, id) || other.id == id)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.flagDate, flagDate) || other.flagDate == flagDate)&&(identical(other.flagType, flagType) || other.flagType == flagType)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.relatedData, relatedData)&&(identical(other.acknowledged, acknowledged) || other.acknowledged == acknowledged)&&(identical(other.acknowledgedBy, acknowledgedBy) || other.acknowledgedBy == acknowledgedBy)&&(identical(other.acknowledgedAt, acknowledgedAt) || other.acknowledgedAt == acknowledgedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,employeeId,flagDate,flagType,description,const DeepCollectionEquality().hash(relatedData),acknowledged,acknowledgedBy,acknowledgedAt);

@override
String toString() {
  return 'AttendanceFlag(id: $id, employeeId: $employeeId, flagDate: $flagDate, flagType: $flagType, description: $description, relatedData: $relatedData, acknowledged: $acknowledged, acknowledgedBy: $acknowledgedBy, acknowledgedAt: $acknowledgedAt)';
}


}

/// @nodoc
abstract mixin class $AttendanceFlagCopyWith<$Res>  {
  factory $AttendanceFlagCopyWith(AttendanceFlag value, $Res Function(AttendanceFlag) _then) = _$AttendanceFlagCopyWithImpl;
@useResult
$Res call({
 String id, String employeeId, DateTime flagDate, FlagType flagType, String description, Map<String, dynamic>? relatedData, bool acknowledged, String? acknowledgedBy, DateTime? acknowledgedAt
});




}
/// @nodoc
class _$AttendanceFlagCopyWithImpl<$Res>
    implements $AttendanceFlagCopyWith<$Res> {
  _$AttendanceFlagCopyWithImpl(this._self, this._then);

  final AttendanceFlag _self;
  final $Res Function(AttendanceFlag) _then;

/// Create a copy of AttendanceFlag
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? employeeId = null,Object? flagDate = null,Object? flagType = null,Object? description = null,Object? relatedData = freezed,Object? acknowledged = null,Object? acknowledgedBy = freezed,Object? acknowledgedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,flagDate: null == flagDate ? _self.flagDate : flagDate // ignore: cast_nullable_to_non_nullable
as DateTime,flagType: null == flagType ? _self.flagType : flagType // ignore: cast_nullable_to_non_nullable
as FlagType,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,relatedData: freezed == relatedData ? _self.relatedData : relatedData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,acknowledged: null == acknowledged ? _self.acknowledged : acknowledged // ignore: cast_nullable_to_non_nullable
as bool,acknowledgedBy: freezed == acknowledgedBy ? _self.acknowledgedBy : acknowledgedBy // ignore: cast_nullable_to_non_nullable
as String?,acknowledgedAt: freezed == acknowledgedAt ? _self.acknowledgedAt : acknowledgedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AttendanceFlag].
extension AttendanceFlagPatterns on AttendanceFlag {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttendanceFlag value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttendanceFlag() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttendanceFlag value)  $default,){
final _that = this;
switch (_that) {
case _AttendanceFlag():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttendanceFlag value)?  $default,){
final _that = this;
switch (_that) {
case _AttendanceFlag() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String employeeId,  DateTime flagDate,  FlagType flagType,  String description,  Map<String, dynamic>? relatedData,  bool acknowledged,  String? acknowledgedBy,  DateTime? acknowledgedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttendanceFlag() when $default != null:
return $default(_that.id,_that.employeeId,_that.flagDate,_that.flagType,_that.description,_that.relatedData,_that.acknowledged,_that.acknowledgedBy,_that.acknowledgedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String employeeId,  DateTime flagDate,  FlagType flagType,  String description,  Map<String, dynamic>? relatedData,  bool acknowledged,  String? acknowledgedBy,  DateTime? acknowledgedAt)  $default,) {final _that = this;
switch (_that) {
case _AttendanceFlag():
return $default(_that.id,_that.employeeId,_that.flagDate,_that.flagType,_that.description,_that.relatedData,_that.acknowledged,_that.acknowledgedBy,_that.acknowledgedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String employeeId,  DateTime flagDate,  FlagType flagType,  String description,  Map<String, dynamic>? relatedData,  bool acknowledged,  String? acknowledgedBy,  DateTime? acknowledgedAt)?  $default,) {final _that = this;
switch (_that) {
case _AttendanceFlag() when $default != null:
return $default(_that.id,_that.employeeId,_that.flagDate,_that.flagType,_that.description,_that.relatedData,_that.acknowledged,_that.acknowledgedBy,_that.acknowledgedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AttendanceFlag implements AttendanceFlag {
  const _AttendanceFlag({required this.id, required this.employeeId, required this.flagDate, required this.flagType, required this.description, final  Map<String, dynamic>? relatedData, this.acknowledged = false, this.acknowledgedBy, this.acknowledgedAt}): _relatedData = relatedData;
  factory _AttendanceFlag.fromJson(Map<String, dynamic> json) => _$AttendanceFlagFromJson(json);

@override final  String id;
@override final  String employeeId;
@override final  DateTime flagDate;
@override final  FlagType flagType;
@override final  String description;
 final  Map<String, dynamic>? _relatedData;
@override Map<String, dynamic>? get relatedData {
  final value = _relatedData;
  if (value == null) return null;
  if (_relatedData is EqualUnmodifiableMapView) return _relatedData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey() final  bool acknowledged;
@override final  String? acknowledgedBy;
@override final  DateTime? acknowledgedAt;

/// Create a copy of AttendanceFlag
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttendanceFlagCopyWith<_AttendanceFlag> get copyWith => __$AttendanceFlagCopyWithImpl<_AttendanceFlag>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AttendanceFlagToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttendanceFlag&&(identical(other.id, id) || other.id == id)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.flagDate, flagDate) || other.flagDate == flagDate)&&(identical(other.flagType, flagType) || other.flagType == flagType)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._relatedData, _relatedData)&&(identical(other.acknowledged, acknowledged) || other.acknowledged == acknowledged)&&(identical(other.acknowledgedBy, acknowledgedBy) || other.acknowledgedBy == acknowledgedBy)&&(identical(other.acknowledgedAt, acknowledgedAt) || other.acknowledgedAt == acknowledgedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,employeeId,flagDate,flagType,description,const DeepCollectionEquality().hash(_relatedData),acknowledged,acknowledgedBy,acknowledgedAt);

@override
String toString() {
  return 'AttendanceFlag(id: $id, employeeId: $employeeId, flagDate: $flagDate, flagType: $flagType, description: $description, relatedData: $relatedData, acknowledged: $acknowledged, acknowledgedBy: $acknowledgedBy, acknowledgedAt: $acknowledgedAt)';
}


}

/// @nodoc
abstract mixin class _$AttendanceFlagCopyWith<$Res> implements $AttendanceFlagCopyWith<$Res> {
  factory _$AttendanceFlagCopyWith(_AttendanceFlag value, $Res Function(_AttendanceFlag) _then) = __$AttendanceFlagCopyWithImpl;
@override @useResult
$Res call({
 String id, String employeeId, DateTime flagDate, FlagType flagType, String description, Map<String, dynamic>? relatedData, bool acknowledged, String? acknowledgedBy, DateTime? acknowledgedAt
});




}
/// @nodoc
class __$AttendanceFlagCopyWithImpl<$Res>
    implements _$AttendanceFlagCopyWith<$Res> {
  __$AttendanceFlagCopyWithImpl(this._self, this._then);

  final _AttendanceFlag _self;
  final $Res Function(_AttendanceFlag) _then;

/// Create a copy of AttendanceFlag
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? employeeId = null,Object? flagDate = null,Object? flagType = null,Object? description = null,Object? relatedData = freezed,Object? acknowledged = null,Object? acknowledgedBy = freezed,Object? acknowledgedAt = freezed,}) {
  return _then(_AttendanceFlag(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,flagDate: null == flagDate ? _self.flagDate : flagDate // ignore: cast_nullable_to_non_nullable
as DateTime,flagType: null == flagType ? _self.flagType : flagType // ignore: cast_nullable_to_non_nullable
as FlagType,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,relatedData: freezed == relatedData ? _self._relatedData : relatedData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,acknowledged: null == acknowledged ? _self.acknowledged : acknowledged // ignore: cast_nullable_to_non_nullable
as bool,acknowledgedBy: freezed == acknowledgedBy ? _self.acknowledgedBy : acknowledgedBy // ignore: cast_nullable_to_non_nullable
as String?,acknowledgedAt: freezed == acknowledgedAt ? _self.acknowledgedAt : acknowledgedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

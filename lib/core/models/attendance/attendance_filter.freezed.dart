// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attendance_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AttendanceFilter {

 String? get employeeId; DateTime? get startDate; DateTime? get endDate; List<ShiftStatus> get statuses; bool get onlyFlagged; bool get onlyPending;
/// Create a copy of AttendanceFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttendanceFilterCopyWith<AttendanceFilter> get copyWith => _$AttendanceFilterCopyWithImpl<AttendanceFilter>(this as AttendanceFilter, _$identity);

  /// Serializes this AttendanceFilter to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttendanceFilter&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&const DeepCollectionEquality().equals(other.statuses, statuses)&&(identical(other.onlyFlagged, onlyFlagged) || other.onlyFlagged == onlyFlagged)&&(identical(other.onlyPending, onlyPending) || other.onlyPending == onlyPending));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,employeeId,startDate,endDate,const DeepCollectionEquality().hash(statuses),onlyFlagged,onlyPending);

@override
String toString() {
  return 'AttendanceFilter(employeeId: $employeeId, startDate: $startDate, endDate: $endDate, statuses: $statuses, onlyFlagged: $onlyFlagged, onlyPending: $onlyPending)';
}


}

/// @nodoc
abstract mixin class $AttendanceFilterCopyWith<$Res>  {
  factory $AttendanceFilterCopyWith(AttendanceFilter value, $Res Function(AttendanceFilter) _then) = _$AttendanceFilterCopyWithImpl;
@useResult
$Res call({
 String? employeeId, DateTime? startDate, DateTime? endDate, List<ShiftStatus> statuses, bool onlyFlagged, bool onlyPending
});




}
/// @nodoc
class _$AttendanceFilterCopyWithImpl<$Res>
    implements $AttendanceFilterCopyWith<$Res> {
  _$AttendanceFilterCopyWithImpl(this._self, this._then);

  final AttendanceFilter _self;
  final $Res Function(AttendanceFilter) _then;

/// Create a copy of AttendanceFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? employeeId = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? statuses = null,Object? onlyFlagged = null,Object? onlyPending = null,}) {
  return _then(_self.copyWith(
employeeId: freezed == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,statuses: null == statuses ? _self.statuses : statuses // ignore: cast_nullable_to_non_nullable
as List<ShiftStatus>,onlyFlagged: null == onlyFlagged ? _self.onlyFlagged : onlyFlagged // ignore: cast_nullable_to_non_nullable
as bool,onlyPending: null == onlyPending ? _self.onlyPending : onlyPending // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AttendanceFilter].
extension AttendanceFilterPatterns on AttendanceFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttendanceFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttendanceFilter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttendanceFilter value)  $default,){
final _that = this;
switch (_that) {
case _AttendanceFilter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttendanceFilter value)?  $default,){
final _that = this;
switch (_that) {
case _AttendanceFilter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? employeeId,  DateTime? startDate,  DateTime? endDate,  List<ShiftStatus> statuses,  bool onlyFlagged,  bool onlyPending)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttendanceFilter() when $default != null:
return $default(_that.employeeId,_that.startDate,_that.endDate,_that.statuses,_that.onlyFlagged,_that.onlyPending);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? employeeId,  DateTime? startDate,  DateTime? endDate,  List<ShiftStatus> statuses,  bool onlyFlagged,  bool onlyPending)  $default,) {final _that = this;
switch (_that) {
case _AttendanceFilter():
return $default(_that.employeeId,_that.startDate,_that.endDate,_that.statuses,_that.onlyFlagged,_that.onlyPending);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? employeeId,  DateTime? startDate,  DateTime? endDate,  List<ShiftStatus> statuses,  bool onlyFlagged,  bool onlyPending)?  $default,) {final _that = this;
switch (_that) {
case _AttendanceFilter() when $default != null:
return $default(_that.employeeId,_that.startDate,_that.endDate,_that.statuses,_that.onlyFlagged,_that.onlyPending);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AttendanceFilter implements AttendanceFilter {
  const _AttendanceFilter({this.employeeId, this.startDate, this.endDate, final  List<ShiftStatus> statuses = const [], this.onlyFlagged = false, this.onlyPending = false}): _statuses = statuses;
  factory _AttendanceFilter.fromJson(Map<String, dynamic> json) => _$AttendanceFilterFromJson(json);

@override final  String? employeeId;
@override final  DateTime? startDate;
@override final  DateTime? endDate;
 final  List<ShiftStatus> _statuses;
@override@JsonKey() List<ShiftStatus> get statuses {
  if (_statuses is EqualUnmodifiableListView) return _statuses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_statuses);
}

@override@JsonKey() final  bool onlyFlagged;
@override@JsonKey() final  bool onlyPending;

/// Create a copy of AttendanceFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttendanceFilterCopyWith<_AttendanceFilter> get copyWith => __$AttendanceFilterCopyWithImpl<_AttendanceFilter>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AttendanceFilterToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttendanceFilter&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&const DeepCollectionEquality().equals(other._statuses, _statuses)&&(identical(other.onlyFlagged, onlyFlagged) || other.onlyFlagged == onlyFlagged)&&(identical(other.onlyPending, onlyPending) || other.onlyPending == onlyPending));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,employeeId,startDate,endDate,const DeepCollectionEquality().hash(_statuses),onlyFlagged,onlyPending);

@override
String toString() {
  return 'AttendanceFilter(employeeId: $employeeId, startDate: $startDate, endDate: $endDate, statuses: $statuses, onlyFlagged: $onlyFlagged, onlyPending: $onlyPending)';
}


}

/// @nodoc
abstract mixin class _$AttendanceFilterCopyWith<$Res> implements $AttendanceFilterCopyWith<$Res> {
  factory _$AttendanceFilterCopyWith(_AttendanceFilter value, $Res Function(_AttendanceFilter) _then) = __$AttendanceFilterCopyWithImpl;
@override @useResult
$Res call({
 String? employeeId, DateTime? startDate, DateTime? endDate, List<ShiftStatus> statuses, bool onlyFlagged, bool onlyPending
});




}
/// @nodoc
class __$AttendanceFilterCopyWithImpl<$Res>
    implements _$AttendanceFilterCopyWith<$Res> {
  __$AttendanceFilterCopyWithImpl(this._self, this._then);

  final _AttendanceFilter _self;
  final $Res Function(_AttendanceFilter) _then;

/// Create a copy of AttendanceFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? employeeId = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? statuses = null,Object? onlyFlagged = null,Object? onlyPending = null,}) {
  return _then(_AttendanceFilter(
employeeId: freezed == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,statuses: null == statuses ? _self._statuses : statuses // ignore: cast_nullable_to_non_nullable
as List<ShiftStatus>,onlyFlagged: null == onlyFlagged ? _self.onlyFlagged : onlyFlagged // ignore: cast_nullable_to_non_nullable
as bool,onlyPending: null == onlyPending ? _self.onlyPending : onlyPending // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

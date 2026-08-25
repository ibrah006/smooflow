// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'check_in_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CheckInRequest {

 String get employeeId; DateTime? get timestamp;
/// Create a copy of CheckInRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckInRequestCopyWith<CheckInRequest> get copyWith => _$CheckInRequestCopyWithImpl<CheckInRequest>(this as CheckInRequest, _$identity);

  /// Serializes this CheckInRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckInRequest&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,employeeId,timestamp);

@override
String toString() {
  return 'CheckInRequest(employeeId: $employeeId, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class $CheckInRequestCopyWith<$Res>  {
  factory $CheckInRequestCopyWith(CheckInRequest value, $Res Function(CheckInRequest) _then) = _$CheckInRequestCopyWithImpl;
@useResult
$Res call({
 String employeeId, DateTime? timestamp
});




}
/// @nodoc
class _$CheckInRequestCopyWithImpl<$Res>
    implements $CheckInRequestCopyWith<$Res> {
  _$CheckInRequestCopyWithImpl(this._self, this._then);

  final CheckInRequest _self;
  final $Res Function(CheckInRequest) _then;

/// Create a copy of CheckInRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? employeeId = null,Object? timestamp = freezed,}) {
  return _then(_self.copyWith(
employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CheckInRequest].
extension CheckInRequestPatterns on CheckInRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheckInRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckInRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheckInRequest value)  $default,){
final _that = this;
switch (_that) {
case _CheckInRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheckInRequest value)?  $default,){
final _that = this;
switch (_that) {
case _CheckInRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String employeeId,  DateTime? timestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckInRequest() when $default != null:
return $default(_that.employeeId,_that.timestamp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String employeeId,  DateTime? timestamp)  $default,) {final _that = this;
switch (_that) {
case _CheckInRequest():
return $default(_that.employeeId,_that.timestamp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String employeeId,  DateTime? timestamp)?  $default,) {final _that = this;
switch (_that) {
case _CheckInRequest() when $default != null:
return $default(_that.employeeId,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CheckInRequest implements CheckInRequest {
  const _CheckInRequest({required this.employeeId, this.timestamp});
  factory _CheckInRequest.fromJson(Map<String, dynamic> json) => _$CheckInRequestFromJson(json);

@override final  String employeeId;
@override final  DateTime? timestamp;

/// Create a copy of CheckInRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckInRequestCopyWith<_CheckInRequest> get copyWith => __$CheckInRequestCopyWithImpl<_CheckInRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CheckInRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckInRequest&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,employeeId,timestamp);

@override
String toString() {
  return 'CheckInRequest(employeeId: $employeeId, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class _$CheckInRequestCopyWith<$Res> implements $CheckInRequestCopyWith<$Res> {
  factory _$CheckInRequestCopyWith(_CheckInRequest value, $Res Function(_CheckInRequest) _then) = __$CheckInRequestCopyWithImpl;
@override @useResult
$Res call({
 String employeeId, DateTime? timestamp
});




}
/// @nodoc
class __$CheckInRequestCopyWithImpl<$Res>
    implements _$CheckInRequestCopyWith<$Res> {
  __$CheckInRequestCopyWithImpl(this._self, this._then);

  final _CheckInRequest _self;
  final $Res Function(_CheckInRequest) _then;

/// Create a copy of CheckInRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? employeeId = null,Object? timestamp = freezed,}) {
  return _then(_CheckInRequest(
employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attendance_api_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AttendanceApiResponse<T> {

 bool get success; T? get data; String? get error; List<String> get flags;
/// Create a copy of AttendanceApiResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttendanceApiResponseCopyWith<T, AttendanceApiResponse<T>> get copyWith => _$AttendanceApiResponseCopyWithImpl<T, AttendanceApiResponse<T>>(this as AttendanceApiResponse<T>, _$identity);

  /// Serializes this AttendanceApiResponse to a JSON map.
  Map<String, dynamic> toJson(Object? Function(T) toJsonT);


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttendanceApiResponse<T>&&(identical(other.success, success) || other.success == success)&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other.flags, flags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,success,const DeepCollectionEquality().hash(data),error,const DeepCollectionEquality().hash(flags));

@override
String toString() {
  return 'AttendanceApiResponse<$T>(success: $success, data: $data, error: $error, flags: $flags)';
}


}

/// @nodoc
abstract mixin class $AttendanceApiResponseCopyWith<T,$Res>  {
  factory $AttendanceApiResponseCopyWith(AttendanceApiResponse<T> value, $Res Function(AttendanceApiResponse<T>) _then) = _$AttendanceApiResponseCopyWithImpl;
@useResult
$Res call({
 bool success, T? data, String? error, List<String> flags
});




}
/// @nodoc
class _$AttendanceApiResponseCopyWithImpl<T,$Res>
    implements $AttendanceApiResponseCopyWith<T, $Res> {
  _$AttendanceApiResponseCopyWithImpl(this._self, this._then);

  final AttendanceApiResponse<T> _self;
  final $Res Function(AttendanceApiResponse<T>) _then;

/// Create a copy of AttendanceApiResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? success = null,Object? data = freezed,Object? error = freezed,Object? flags = null,}) {
  return _then(_self.copyWith(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as T?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,flags: null == flags ? _self.flags : flags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [AttendanceApiResponse].
extension AttendanceApiResponsePatterns<T> on AttendanceApiResponse<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttendanceApiResponse<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttendanceApiResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttendanceApiResponse<T> value)  $default,){
final _that = this;
switch (_that) {
case _AttendanceApiResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttendanceApiResponse<T> value)?  $default,){
final _that = this;
switch (_that) {
case _AttendanceApiResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool success,  T? data,  String? error,  List<String> flags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttendanceApiResponse() when $default != null:
return $default(_that.success,_that.data,_that.error,_that.flags);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool success,  T? data,  String? error,  List<String> flags)  $default,) {final _that = this;
switch (_that) {
case _AttendanceApiResponse():
return $default(_that.success,_that.data,_that.error,_that.flags);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool success,  T? data,  String? error,  List<String> flags)?  $default,) {final _that = this;
switch (_that) {
case _AttendanceApiResponse() when $default != null:
return $default(_that.success,_that.data,_that.error,_that.flags);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)

class _AttendanceApiResponse<T> implements AttendanceApiResponse<T> {
  const _AttendanceApiResponse({required this.success, this.data, this.error, final  List<String> flags = const []}): _flags = flags;
  factory _AttendanceApiResponse.fromJson(Map<String, dynamic> json,T Function(Object?) fromJsonT) => _$AttendanceApiResponseFromJson(json,fromJsonT);

@override final  bool success;
@override final  T? data;
@override final  String? error;
 final  List<String> _flags;
@override@JsonKey() List<String> get flags {
  if (_flags is EqualUnmodifiableListView) return _flags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_flags);
}


/// Create a copy of AttendanceApiResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttendanceApiResponseCopyWith<T, _AttendanceApiResponse<T>> get copyWith => __$AttendanceApiResponseCopyWithImpl<T, _AttendanceApiResponse<T>>(this, _$identity);

@override
Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
  return _$AttendanceApiResponseToJson<T>(this, toJsonT);
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttendanceApiResponse<T>&&(identical(other.success, success) || other.success == success)&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other._flags, _flags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,success,const DeepCollectionEquality().hash(data),error,const DeepCollectionEquality().hash(_flags));

@override
String toString() {
  return 'AttendanceApiResponse<$T>(success: $success, data: $data, error: $error, flags: $flags)';
}


}

/// @nodoc
abstract mixin class _$AttendanceApiResponseCopyWith<T,$Res> implements $AttendanceApiResponseCopyWith<T, $Res> {
  factory _$AttendanceApiResponseCopyWith(_AttendanceApiResponse<T> value, $Res Function(_AttendanceApiResponse<T>) _then) = __$AttendanceApiResponseCopyWithImpl;
@override @useResult
$Res call({
 bool success, T? data, String? error, List<String> flags
});




}
/// @nodoc
class __$AttendanceApiResponseCopyWithImpl<T,$Res>
    implements _$AttendanceApiResponseCopyWith<T, $Res> {
  __$AttendanceApiResponseCopyWithImpl(this._self, this._then);

  final _AttendanceApiResponse<T> _self;
  final $Res Function(_AttendanceApiResponse<T>) _then;

/// Create a copy of AttendanceApiResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? success = null,Object? data = freezed,Object? error = freezed,Object? flags = null,}) {
  return _then(_AttendanceApiResponse<T>(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as T?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,flags: null == flags ? _self._flags : flags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on

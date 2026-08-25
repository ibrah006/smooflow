// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'public_holiday.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PublicHoliday {

 String get id; String get name; DateTime get date; String? get region; bool get isCompensated; String? get description;
/// Create a copy of PublicHoliday
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PublicHolidayCopyWith<PublicHoliday> get copyWith => _$PublicHolidayCopyWithImpl<PublicHoliday>(this as PublicHoliday, _$identity);

  /// Serializes this PublicHoliday to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PublicHoliday&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.date, date) || other.date == date)&&(identical(other.region, region) || other.region == region)&&(identical(other.isCompensated, isCompensated) || other.isCompensated == isCompensated)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,date,region,isCompensated,description);

@override
String toString() {
  return 'PublicHoliday(id: $id, name: $name, date: $date, region: $region, isCompensated: $isCompensated, description: $description)';
}


}

/// @nodoc
abstract mixin class $PublicHolidayCopyWith<$Res>  {
  factory $PublicHolidayCopyWith(PublicHoliday value, $Res Function(PublicHoliday) _then) = _$PublicHolidayCopyWithImpl;
@useResult
$Res call({
 String id, String name, DateTime date, String? region, bool isCompensated, String? description
});




}
/// @nodoc
class _$PublicHolidayCopyWithImpl<$Res>
    implements $PublicHolidayCopyWith<$Res> {
  _$PublicHolidayCopyWithImpl(this._self, this._then);

  final PublicHoliday _self;
  final $Res Function(PublicHoliday) _then;

/// Create a copy of PublicHoliday
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? date = null,Object? region = freezed,Object? isCompensated = null,Object? description = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,region: freezed == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String?,isCompensated: null == isCompensated ? _self.isCompensated : isCompensated // ignore: cast_nullable_to_non_nullable
as bool,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PublicHoliday].
extension PublicHolidayPatterns on PublicHoliday {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PublicHoliday value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PublicHoliday() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PublicHoliday value)  $default,){
final _that = this;
switch (_that) {
case _PublicHoliday():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PublicHoliday value)?  $default,){
final _that = this;
switch (_that) {
case _PublicHoliday() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  DateTime date,  String? region,  bool isCompensated,  String? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PublicHoliday() when $default != null:
return $default(_that.id,_that.name,_that.date,_that.region,_that.isCompensated,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  DateTime date,  String? region,  bool isCompensated,  String? description)  $default,) {final _that = this;
switch (_that) {
case _PublicHoliday():
return $default(_that.id,_that.name,_that.date,_that.region,_that.isCompensated,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  DateTime date,  String? region,  bool isCompensated,  String? description)?  $default,) {final _that = this;
switch (_that) {
case _PublicHoliday() when $default != null:
return $default(_that.id,_that.name,_that.date,_that.region,_that.isCompensated,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PublicHoliday extends PublicHoliday {
  const _PublicHoliday({required this.id, required this.name, required this.date, this.region, this.isCompensated = true, this.description}): super._();
  factory _PublicHoliday.fromJson(Map<String, dynamic> json) => _$PublicHolidayFromJson(json);

@override final  String id;
@override final  String name;
@override final  DateTime date;
@override final  String? region;
@override@JsonKey() final  bool isCompensated;
@override final  String? description;

/// Create a copy of PublicHoliday
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PublicHolidayCopyWith<_PublicHoliday> get copyWith => __$PublicHolidayCopyWithImpl<_PublicHoliday>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PublicHolidayToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PublicHoliday&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.date, date) || other.date == date)&&(identical(other.region, region) || other.region == region)&&(identical(other.isCompensated, isCompensated) || other.isCompensated == isCompensated)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,date,region,isCompensated,description);

@override
String toString() {
  return 'PublicHoliday(id: $id, name: $name, date: $date, region: $region, isCompensated: $isCompensated, description: $description)';
}


}

/// @nodoc
abstract mixin class _$PublicHolidayCopyWith<$Res> implements $PublicHolidayCopyWith<$Res> {
  factory _$PublicHolidayCopyWith(_PublicHoliday value, $Res Function(_PublicHoliday) _then) = __$PublicHolidayCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, DateTime date, String? region, bool isCompensated, String? description
});




}
/// @nodoc
class __$PublicHolidayCopyWithImpl<$Res>
    implements _$PublicHolidayCopyWith<$Res> {
  __$PublicHolidayCopyWithImpl(this._self, this._then);

  final _PublicHoliday _self;
  final $Res Function(_PublicHoliday) _then;

/// Create a copy of PublicHoliday
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? date = null,Object? region = freezed,Object? isCompensated = null,Object? description = freezed,}) {
  return _then(_PublicHoliday(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,region: freezed == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String?,isCompensated: null == isCompensated ? _self.isCompensated : isCompensated // ignore: cast_nullable_to_non_nullable
as bool,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

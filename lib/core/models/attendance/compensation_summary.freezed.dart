// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'compensation_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CompensationSummary {

 double get overtimeHours; double get overtimeAmount; int get weekendDaysCount; double get weekendCompensationHours; double get weekendCompensationAmount; int get holidaysWorkedCount; double get holidayCompensationHours; double get holidayCompensationAmount; double get totalCompensationDue;
/// Create a copy of CompensationSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompensationSummaryCopyWith<CompensationSummary> get copyWith => _$CompensationSummaryCopyWithImpl<CompensationSummary>(this as CompensationSummary, _$identity);

  /// Serializes this CompensationSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompensationSummary&&(identical(other.overtimeHours, overtimeHours) || other.overtimeHours == overtimeHours)&&(identical(other.overtimeAmount, overtimeAmount) || other.overtimeAmount == overtimeAmount)&&(identical(other.weekendDaysCount, weekendDaysCount) || other.weekendDaysCount == weekendDaysCount)&&(identical(other.weekendCompensationHours, weekendCompensationHours) || other.weekendCompensationHours == weekendCompensationHours)&&(identical(other.weekendCompensationAmount, weekendCompensationAmount) || other.weekendCompensationAmount == weekendCompensationAmount)&&(identical(other.holidaysWorkedCount, holidaysWorkedCount) || other.holidaysWorkedCount == holidaysWorkedCount)&&(identical(other.holidayCompensationHours, holidayCompensationHours) || other.holidayCompensationHours == holidayCompensationHours)&&(identical(other.holidayCompensationAmount, holidayCompensationAmount) || other.holidayCompensationAmount == holidayCompensationAmount)&&(identical(other.totalCompensationDue, totalCompensationDue) || other.totalCompensationDue == totalCompensationDue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,overtimeHours,overtimeAmount,weekendDaysCount,weekendCompensationHours,weekendCompensationAmount,holidaysWorkedCount,holidayCompensationHours,holidayCompensationAmount,totalCompensationDue);

@override
String toString() {
  return 'CompensationSummary(overtimeHours: $overtimeHours, overtimeAmount: $overtimeAmount, weekendDaysCount: $weekendDaysCount, weekendCompensationHours: $weekendCompensationHours, weekendCompensationAmount: $weekendCompensationAmount, holidaysWorkedCount: $holidaysWorkedCount, holidayCompensationHours: $holidayCompensationHours, holidayCompensationAmount: $holidayCompensationAmount, totalCompensationDue: $totalCompensationDue)';
}


}

/// @nodoc
abstract mixin class $CompensationSummaryCopyWith<$Res>  {
  factory $CompensationSummaryCopyWith(CompensationSummary value, $Res Function(CompensationSummary) _then) = _$CompensationSummaryCopyWithImpl;
@useResult
$Res call({
 double overtimeHours, double overtimeAmount, int weekendDaysCount, double weekendCompensationHours, double weekendCompensationAmount, int holidaysWorkedCount, double holidayCompensationHours, double holidayCompensationAmount, double totalCompensationDue
});




}
/// @nodoc
class _$CompensationSummaryCopyWithImpl<$Res>
    implements $CompensationSummaryCopyWith<$Res> {
  _$CompensationSummaryCopyWithImpl(this._self, this._then);

  final CompensationSummary _self;
  final $Res Function(CompensationSummary) _then;

/// Create a copy of CompensationSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? overtimeHours = null,Object? overtimeAmount = null,Object? weekendDaysCount = null,Object? weekendCompensationHours = null,Object? weekendCompensationAmount = null,Object? holidaysWorkedCount = null,Object? holidayCompensationHours = null,Object? holidayCompensationAmount = null,Object? totalCompensationDue = null,}) {
  return _then(_self.copyWith(
overtimeHours: null == overtimeHours ? _self.overtimeHours : overtimeHours // ignore: cast_nullable_to_non_nullable
as double,overtimeAmount: null == overtimeAmount ? _self.overtimeAmount : overtimeAmount // ignore: cast_nullable_to_non_nullable
as double,weekendDaysCount: null == weekendDaysCount ? _self.weekendDaysCount : weekendDaysCount // ignore: cast_nullable_to_non_nullable
as int,weekendCompensationHours: null == weekendCompensationHours ? _self.weekendCompensationHours : weekendCompensationHours // ignore: cast_nullable_to_non_nullable
as double,weekendCompensationAmount: null == weekendCompensationAmount ? _self.weekendCompensationAmount : weekendCompensationAmount // ignore: cast_nullable_to_non_nullable
as double,holidaysWorkedCount: null == holidaysWorkedCount ? _self.holidaysWorkedCount : holidaysWorkedCount // ignore: cast_nullable_to_non_nullable
as int,holidayCompensationHours: null == holidayCompensationHours ? _self.holidayCompensationHours : holidayCompensationHours // ignore: cast_nullable_to_non_nullable
as double,holidayCompensationAmount: null == holidayCompensationAmount ? _self.holidayCompensationAmount : holidayCompensationAmount // ignore: cast_nullable_to_non_nullable
as double,totalCompensationDue: null == totalCompensationDue ? _self.totalCompensationDue : totalCompensationDue // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [CompensationSummary].
extension CompensationSummaryPatterns on CompensationSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompensationSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompensationSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompensationSummary value)  $default,){
final _that = this;
switch (_that) {
case _CompensationSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompensationSummary value)?  $default,){
final _that = this;
switch (_that) {
case _CompensationSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double overtimeHours,  double overtimeAmount,  int weekendDaysCount,  double weekendCompensationHours,  double weekendCompensationAmount,  int holidaysWorkedCount,  double holidayCompensationHours,  double holidayCompensationAmount,  double totalCompensationDue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompensationSummary() when $default != null:
return $default(_that.overtimeHours,_that.overtimeAmount,_that.weekendDaysCount,_that.weekendCompensationHours,_that.weekendCompensationAmount,_that.holidaysWorkedCount,_that.holidayCompensationHours,_that.holidayCompensationAmount,_that.totalCompensationDue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double overtimeHours,  double overtimeAmount,  int weekendDaysCount,  double weekendCompensationHours,  double weekendCompensationAmount,  int holidaysWorkedCount,  double holidayCompensationHours,  double holidayCompensationAmount,  double totalCompensationDue)  $default,) {final _that = this;
switch (_that) {
case _CompensationSummary():
return $default(_that.overtimeHours,_that.overtimeAmount,_that.weekendDaysCount,_that.weekendCompensationHours,_that.weekendCompensationAmount,_that.holidaysWorkedCount,_that.holidayCompensationHours,_that.holidayCompensationAmount,_that.totalCompensationDue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double overtimeHours,  double overtimeAmount,  int weekendDaysCount,  double weekendCompensationHours,  double weekendCompensationAmount,  int holidaysWorkedCount,  double holidayCompensationHours,  double holidayCompensationAmount,  double totalCompensationDue)?  $default,) {final _that = this;
switch (_that) {
case _CompensationSummary() when $default != null:
return $default(_that.overtimeHours,_that.overtimeAmount,_that.weekendDaysCount,_that.weekendCompensationHours,_that.weekendCompensationAmount,_that.holidaysWorkedCount,_that.holidayCompensationHours,_that.holidayCompensationAmount,_that.totalCompensationDue);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CompensationSummary implements CompensationSummary {
  const _CompensationSummary({required this.overtimeHours, required this.overtimeAmount, required this.weekendDaysCount, required this.weekendCompensationHours, required this.weekendCompensationAmount, required this.holidaysWorkedCount, required this.holidayCompensationHours, required this.holidayCompensationAmount, required this.totalCompensationDue});
  factory _CompensationSummary.fromJson(Map<String, dynamic> json) => _$CompensationSummaryFromJson(json);

@override final  double overtimeHours;
@override final  double overtimeAmount;
@override final  int weekendDaysCount;
@override final  double weekendCompensationHours;
@override final  double weekendCompensationAmount;
@override final  int holidaysWorkedCount;
@override final  double holidayCompensationHours;
@override final  double holidayCompensationAmount;
@override final  double totalCompensationDue;

/// Create a copy of CompensationSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompensationSummaryCopyWith<_CompensationSummary> get copyWith => __$CompensationSummaryCopyWithImpl<_CompensationSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompensationSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompensationSummary&&(identical(other.overtimeHours, overtimeHours) || other.overtimeHours == overtimeHours)&&(identical(other.overtimeAmount, overtimeAmount) || other.overtimeAmount == overtimeAmount)&&(identical(other.weekendDaysCount, weekendDaysCount) || other.weekendDaysCount == weekendDaysCount)&&(identical(other.weekendCompensationHours, weekendCompensationHours) || other.weekendCompensationHours == weekendCompensationHours)&&(identical(other.weekendCompensationAmount, weekendCompensationAmount) || other.weekendCompensationAmount == weekendCompensationAmount)&&(identical(other.holidaysWorkedCount, holidaysWorkedCount) || other.holidaysWorkedCount == holidaysWorkedCount)&&(identical(other.holidayCompensationHours, holidayCompensationHours) || other.holidayCompensationHours == holidayCompensationHours)&&(identical(other.holidayCompensationAmount, holidayCompensationAmount) || other.holidayCompensationAmount == holidayCompensationAmount)&&(identical(other.totalCompensationDue, totalCompensationDue) || other.totalCompensationDue == totalCompensationDue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,overtimeHours,overtimeAmount,weekendDaysCount,weekendCompensationHours,weekendCompensationAmount,holidaysWorkedCount,holidayCompensationHours,holidayCompensationAmount,totalCompensationDue);

@override
String toString() {
  return 'CompensationSummary(overtimeHours: $overtimeHours, overtimeAmount: $overtimeAmount, weekendDaysCount: $weekendDaysCount, weekendCompensationHours: $weekendCompensationHours, weekendCompensationAmount: $weekendCompensationAmount, holidaysWorkedCount: $holidaysWorkedCount, holidayCompensationHours: $holidayCompensationHours, holidayCompensationAmount: $holidayCompensationAmount, totalCompensationDue: $totalCompensationDue)';
}


}

/// @nodoc
abstract mixin class _$CompensationSummaryCopyWith<$Res> implements $CompensationSummaryCopyWith<$Res> {
  factory _$CompensationSummaryCopyWith(_CompensationSummary value, $Res Function(_CompensationSummary) _then) = __$CompensationSummaryCopyWithImpl;
@override @useResult
$Res call({
 double overtimeHours, double overtimeAmount, int weekendDaysCount, double weekendCompensationHours, double weekendCompensationAmount, int holidaysWorkedCount, double holidayCompensationHours, double holidayCompensationAmount, double totalCompensationDue
});




}
/// @nodoc
class __$CompensationSummaryCopyWithImpl<$Res>
    implements _$CompensationSummaryCopyWith<$Res> {
  __$CompensationSummaryCopyWithImpl(this._self, this._then);

  final _CompensationSummary _self;
  final $Res Function(_CompensationSummary) _then;

/// Create a copy of CompensationSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? overtimeHours = null,Object? overtimeAmount = null,Object? weekendDaysCount = null,Object? weekendCompensationHours = null,Object? weekendCompensationAmount = null,Object? holidaysWorkedCount = null,Object? holidayCompensationHours = null,Object? holidayCompensationAmount = null,Object? totalCompensationDue = null,}) {
  return _then(_CompensationSummary(
overtimeHours: null == overtimeHours ? _self.overtimeHours : overtimeHours // ignore: cast_nullable_to_non_nullable
as double,overtimeAmount: null == overtimeAmount ? _self.overtimeAmount : overtimeAmount // ignore: cast_nullable_to_non_nullable
as double,weekendDaysCount: null == weekendDaysCount ? _self.weekendDaysCount : weekendDaysCount // ignore: cast_nullable_to_non_nullable
as int,weekendCompensationHours: null == weekendCompensationHours ? _self.weekendCompensationHours : weekendCompensationHours // ignore: cast_nullable_to_non_nullable
as double,weekendCompensationAmount: null == weekendCompensationAmount ? _self.weekendCompensationAmount : weekendCompensationAmount // ignore: cast_nullable_to_non_nullable
as double,holidaysWorkedCount: null == holidaysWorkedCount ? _self.holidaysWorkedCount : holidaysWorkedCount // ignore: cast_nullable_to_non_nullable
as int,holidayCompensationHours: null == holidayCompensationHours ? _self.holidayCompensationHours : holidayCompensationHours // ignore: cast_nullable_to_non_nullable
as double,holidayCompensationAmount: null == holidayCompensationAmount ? _self.holidayCompensationAmount : holidayCompensationAmount // ignore: cast_nullable_to_non_nullable
as double,totalCompensationDue: null == totalCompensationDue ? _self.totalCompensationDue : totalCompensationDue // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on

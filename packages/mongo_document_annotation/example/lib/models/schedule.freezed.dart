// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Schedule {

 String? get name; String? get expression;@DateTimeConverter() DateTime? get oneOffDate;@DateTimeConverter() DateTime? get startDate;@DateTimeConverter() DateTime? get endDate;@DateTimeConverter() DateTime? get time; String get timezone; bool get userDefined; Map<int, bool> get weekDays; int? get dayOfMonth; int? get rateValue;@RateUnitConverter() RateUnit? get rateUnit; int get apiDestination; Map<String, dynamic>? get payload; bool get recurring;@EndConditionConverter() EndCondition get endCondition;@RecurrenceFrequencyConverter() RecurrenceFrequency? get frequency;
/// Create a copy of Schedule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduleCopyWith<Schedule> get copyWith => _$ScheduleCopyWithImpl<Schedule>(this as Schedule, _$identity);

  /// Serializes this Schedule to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Schedule&&(identical(other.name, name) || other.name == name)&&(identical(other.expression, expression) || other.expression == expression)&&(identical(other.oneOffDate, oneOffDate) || other.oneOffDate == oneOffDate)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.time, time) || other.time == time)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.userDefined, userDefined) || other.userDefined == userDefined)&&const DeepCollectionEquality().equals(other.weekDays, weekDays)&&(identical(other.dayOfMonth, dayOfMonth) || other.dayOfMonth == dayOfMonth)&&(identical(other.rateValue, rateValue) || other.rateValue == rateValue)&&(identical(other.rateUnit, rateUnit) || other.rateUnit == rateUnit)&&(identical(other.apiDestination, apiDestination) || other.apiDestination == apiDestination)&&const DeepCollectionEquality().equals(other.payload, payload)&&(identical(other.recurring, recurring) || other.recurring == recurring)&&(identical(other.endCondition, endCondition) || other.endCondition == endCondition)&&(identical(other.frequency, frequency) || other.frequency == frequency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,expression,oneOffDate,startDate,endDate,time,timezone,userDefined,const DeepCollectionEquality().hash(weekDays),dayOfMonth,rateValue,rateUnit,apiDestination,const DeepCollectionEquality().hash(payload),recurring,endCondition,frequency);

@override
String toString() {
  return 'Schedule(name: $name, expression: $expression, oneOffDate: $oneOffDate, startDate: $startDate, endDate: $endDate, time: $time, timezone: $timezone, userDefined: $userDefined, weekDays: $weekDays, dayOfMonth: $dayOfMonth, rateValue: $rateValue, rateUnit: $rateUnit, apiDestination: $apiDestination, payload: $payload, recurring: $recurring, endCondition: $endCondition, frequency: $frequency)';
}


}

/// @nodoc
abstract mixin class $ScheduleCopyWith<$Res>  {
  factory $ScheduleCopyWith(Schedule value, $Res Function(Schedule) _then) = _$ScheduleCopyWithImpl;
@useResult
$Res call({
 String? name, String? expression,@DateTimeConverter() DateTime? oneOffDate,@DateTimeConverter() DateTime? startDate,@DateTimeConverter() DateTime? endDate,@DateTimeConverter() DateTime? time, String timezone, bool userDefined, Map<int, bool> weekDays, int? dayOfMonth, int? rateValue,@RateUnitConverter() RateUnit? rateUnit, int apiDestination, Map<String, dynamic>? payload, bool recurring,@EndConditionConverter() EndCondition endCondition,@RecurrenceFrequencyConverter() RecurrenceFrequency? frequency
});




}
/// @nodoc
class _$ScheduleCopyWithImpl<$Res>
    implements $ScheduleCopyWith<$Res> {
  _$ScheduleCopyWithImpl(this._self, this._then);

  final Schedule _self;
  final $Res Function(Schedule) _then;

/// Create a copy of Schedule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? expression = freezed,Object? oneOffDate = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? time = freezed,Object? timezone = null,Object? userDefined = null,Object? weekDays = null,Object? dayOfMonth = freezed,Object? rateValue = freezed,Object? rateUnit = freezed,Object? apiDestination = null,Object? payload = freezed,Object? recurring = null,Object? endCondition = null,Object? frequency = freezed,}) {
  return _then(_self.copyWith(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,expression: freezed == expression ? _self.expression : expression // ignore: cast_nullable_to_non_nullable
as String?,oneOffDate: freezed == oneOffDate ? _self.oneOffDate : oneOffDate // ignore: cast_nullable_to_non_nullable
as DateTime?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,time: freezed == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime?,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,userDefined: null == userDefined ? _self.userDefined : userDefined // ignore: cast_nullable_to_non_nullable
as bool,weekDays: null == weekDays ? _self.weekDays : weekDays // ignore: cast_nullable_to_non_nullable
as Map<int, bool>,dayOfMonth: freezed == dayOfMonth ? _self.dayOfMonth : dayOfMonth // ignore: cast_nullable_to_non_nullable
as int?,rateValue: freezed == rateValue ? _self.rateValue : rateValue // ignore: cast_nullable_to_non_nullable
as int?,rateUnit: freezed == rateUnit ? _self.rateUnit : rateUnit // ignore: cast_nullable_to_non_nullable
as RateUnit?,apiDestination: null == apiDestination ? _self.apiDestination : apiDestination // ignore: cast_nullable_to_non_nullable
as int,payload: freezed == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,recurring: null == recurring ? _self.recurring : recurring // ignore: cast_nullable_to_non_nullable
as bool,endCondition: null == endCondition ? _self.endCondition : endCondition // ignore: cast_nullable_to_non_nullable
as EndCondition,frequency: freezed == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as RecurrenceFrequency?,
  ));
}

}


/// Adds pattern-matching-related methods to [Schedule].
extension SchedulePatterns on Schedule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Schedule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Schedule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Schedule value)  $default,){
final _that = this;
switch (_that) {
case _Schedule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Schedule value)?  $default,){
final _that = this;
switch (_that) {
case _Schedule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? name,  String? expression, @DateTimeConverter()  DateTime? oneOffDate, @DateTimeConverter()  DateTime? startDate, @DateTimeConverter()  DateTime? endDate, @DateTimeConverter()  DateTime? time,  String timezone,  bool userDefined,  Map<int, bool> weekDays,  int? dayOfMonth,  int? rateValue, @RateUnitConverter()  RateUnit? rateUnit,  int apiDestination,  Map<String, dynamic>? payload,  bool recurring, @EndConditionConverter()  EndCondition endCondition, @RecurrenceFrequencyConverter()  RecurrenceFrequency? frequency)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Schedule() when $default != null:
return $default(_that.name,_that.expression,_that.oneOffDate,_that.startDate,_that.endDate,_that.time,_that.timezone,_that.userDefined,_that.weekDays,_that.dayOfMonth,_that.rateValue,_that.rateUnit,_that.apiDestination,_that.payload,_that.recurring,_that.endCondition,_that.frequency);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? name,  String? expression, @DateTimeConverter()  DateTime? oneOffDate, @DateTimeConverter()  DateTime? startDate, @DateTimeConverter()  DateTime? endDate, @DateTimeConverter()  DateTime? time,  String timezone,  bool userDefined,  Map<int, bool> weekDays,  int? dayOfMonth,  int? rateValue, @RateUnitConverter()  RateUnit? rateUnit,  int apiDestination,  Map<String, dynamic>? payload,  bool recurring, @EndConditionConverter()  EndCondition endCondition, @RecurrenceFrequencyConverter()  RecurrenceFrequency? frequency)  $default,) {final _that = this;
switch (_that) {
case _Schedule():
return $default(_that.name,_that.expression,_that.oneOffDate,_that.startDate,_that.endDate,_that.time,_that.timezone,_that.userDefined,_that.weekDays,_that.dayOfMonth,_that.rateValue,_that.rateUnit,_that.apiDestination,_that.payload,_that.recurring,_that.endCondition,_that.frequency);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? name,  String? expression, @DateTimeConverter()  DateTime? oneOffDate, @DateTimeConverter()  DateTime? startDate, @DateTimeConverter()  DateTime? endDate, @DateTimeConverter()  DateTime? time,  String timezone,  bool userDefined,  Map<int, bool> weekDays,  int? dayOfMonth,  int? rateValue, @RateUnitConverter()  RateUnit? rateUnit,  int apiDestination,  Map<String, dynamic>? payload,  bool recurring, @EndConditionConverter()  EndCondition endCondition, @RecurrenceFrequencyConverter()  RecurrenceFrequency? frequency)?  $default,) {final _that = this;
switch (_that) {
case _Schedule() when $default != null:
return $default(_that.name,_that.expression,_that.oneOffDate,_that.startDate,_that.endDate,_that.time,_that.timezone,_that.userDefined,_that.weekDays,_that.dayOfMonth,_that.rateValue,_that.rateUnit,_that.apiDestination,_that.payload,_that.recurring,_that.endCondition,_that.frequency);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _Schedule implements Schedule {
  const _Schedule({this.name, this.expression, @DateTimeConverter() this.oneOffDate, @DateTimeConverter() this.startDate, @DateTimeConverter() this.endDate, @DateTimeConverter() this.time, this.timezone = "UTC", this.userDefined = false, final  Map<int, bool> weekDays = const {}, this.dayOfMonth, this.rateValue, @RateUnitConverter() this.rateUnit, this.apiDestination = 1, final  Map<String, dynamic>? payload, this.recurring = false, @EndConditionConverter() this.endCondition = EndCondition.never, @RecurrenceFrequencyConverter() this.frequency}): _weekDays = weekDays,_payload = payload;
  factory _Schedule.fromJson(Map<String, dynamic> json) => _$ScheduleFromJson(json);

@override final  String? name;
@override final  String? expression;
@override@DateTimeConverter() final  DateTime? oneOffDate;
@override@DateTimeConverter() final  DateTime? startDate;
@override@DateTimeConverter() final  DateTime? endDate;
@override@DateTimeConverter() final  DateTime? time;
@override@JsonKey() final  String timezone;
@override@JsonKey() final  bool userDefined;
 final  Map<int, bool> _weekDays;
@override@JsonKey() Map<int, bool> get weekDays {
  if (_weekDays is EqualUnmodifiableMapView) return _weekDays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_weekDays);
}

@override final  int? dayOfMonth;
@override final  int? rateValue;
@override@RateUnitConverter() final  RateUnit? rateUnit;
@override@JsonKey() final  int apiDestination;
 final  Map<String, dynamic>? _payload;
@override Map<String, dynamic>? get payload {
  final value = _payload;
  if (value == null) return null;
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey() final  bool recurring;
@override@JsonKey()@EndConditionConverter() final  EndCondition endCondition;
@override@RecurrenceFrequencyConverter() final  RecurrenceFrequency? frequency;

/// Create a copy of Schedule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduleCopyWith<_Schedule> get copyWith => __$ScheduleCopyWithImpl<_Schedule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScheduleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Schedule&&(identical(other.name, name) || other.name == name)&&(identical(other.expression, expression) || other.expression == expression)&&(identical(other.oneOffDate, oneOffDate) || other.oneOffDate == oneOffDate)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.time, time) || other.time == time)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.userDefined, userDefined) || other.userDefined == userDefined)&&const DeepCollectionEquality().equals(other._weekDays, _weekDays)&&(identical(other.dayOfMonth, dayOfMonth) || other.dayOfMonth == dayOfMonth)&&(identical(other.rateValue, rateValue) || other.rateValue == rateValue)&&(identical(other.rateUnit, rateUnit) || other.rateUnit == rateUnit)&&(identical(other.apiDestination, apiDestination) || other.apiDestination == apiDestination)&&const DeepCollectionEquality().equals(other._payload, _payload)&&(identical(other.recurring, recurring) || other.recurring == recurring)&&(identical(other.endCondition, endCondition) || other.endCondition == endCondition)&&(identical(other.frequency, frequency) || other.frequency == frequency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,expression,oneOffDate,startDate,endDate,time,timezone,userDefined,const DeepCollectionEquality().hash(_weekDays),dayOfMonth,rateValue,rateUnit,apiDestination,const DeepCollectionEquality().hash(_payload),recurring,endCondition,frequency);

@override
String toString() {
  return 'Schedule(name: $name, expression: $expression, oneOffDate: $oneOffDate, startDate: $startDate, endDate: $endDate, time: $time, timezone: $timezone, userDefined: $userDefined, weekDays: $weekDays, dayOfMonth: $dayOfMonth, rateValue: $rateValue, rateUnit: $rateUnit, apiDestination: $apiDestination, payload: $payload, recurring: $recurring, endCondition: $endCondition, frequency: $frequency)';
}


}

/// @nodoc
abstract mixin class _$ScheduleCopyWith<$Res> implements $ScheduleCopyWith<$Res> {
  factory _$ScheduleCopyWith(_Schedule value, $Res Function(_Schedule) _then) = __$ScheduleCopyWithImpl;
@override @useResult
$Res call({
 String? name, String? expression,@DateTimeConverter() DateTime? oneOffDate,@DateTimeConverter() DateTime? startDate,@DateTimeConverter() DateTime? endDate,@DateTimeConverter() DateTime? time, String timezone, bool userDefined, Map<int, bool> weekDays, int? dayOfMonth, int? rateValue,@RateUnitConverter() RateUnit? rateUnit, int apiDestination, Map<String, dynamic>? payload, bool recurring,@EndConditionConverter() EndCondition endCondition,@RecurrenceFrequencyConverter() RecurrenceFrequency? frequency
});




}
/// @nodoc
class __$ScheduleCopyWithImpl<$Res>
    implements _$ScheduleCopyWith<$Res> {
  __$ScheduleCopyWithImpl(this._self, this._then);

  final _Schedule _self;
  final $Res Function(_Schedule) _then;

/// Create a copy of Schedule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? expression = freezed,Object? oneOffDate = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? time = freezed,Object? timezone = null,Object? userDefined = null,Object? weekDays = null,Object? dayOfMonth = freezed,Object? rateValue = freezed,Object? rateUnit = freezed,Object? apiDestination = null,Object? payload = freezed,Object? recurring = null,Object? endCondition = null,Object? frequency = freezed,}) {
  return _then(_Schedule(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,expression: freezed == expression ? _self.expression : expression // ignore: cast_nullable_to_non_nullable
as String?,oneOffDate: freezed == oneOffDate ? _self.oneOffDate : oneOffDate // ignore: cast_nullable_to_non_nullable
as DateTime?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,time: freezed == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime?,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,userDefined: null == userDefined ? _self.userDefined : userDefined // ignore: cast_nullable_to_non_nullable
as bool,weekDays: null == weekDays ? _self._weekDays : weekDays // ignore: cast_nullable_to_non_nullable
as Map<int, bool>,dayOfMonth: freezed == dayOfMonth ? _self.dayOfMonth : dayOfMonth // ignore: cast_nullable_to_non_nullable
as int?,rateValue: freezed == rateValue ? _self.rateValue : rateValue // ignore: cast_nullable_to_non_nullable
as int?,rateUnit: freezed == rateUnit ? _self.rateUnit : rateUnit // ignore: cast_nullable_to_non_nullable
as RateUnit?,apiDestination: null == apiDestination ? _self.apiDestination : apiDestination // ignore: cast_nullable_to_non_nullable
as int,payload: freezed == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,recurring: null == recurring ? _self.recurring : recurring // ignore: cast_nullable_to_non_nullable
as bool,endCondition: null == endCondition ? _self.endCondition : endCondition // ignore: cast_nullable_to_non_nullable
as EndCondition,frequency: freezed == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as RecurrenceFrequency?,
  ));
}


}

// dart format on

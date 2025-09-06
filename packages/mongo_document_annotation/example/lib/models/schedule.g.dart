// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Schedule _$ScheduleFromJson(Map<String, dynamic> json) => _Schedule(
  name: json['name'] as String?,
  expression: json['expression'] as String?,
  oneOffDate: const DateTimeConverter().fromJson(json['one_off_date']),
  startDate: const DateTimeConverter().fromJson(json['start_date']),
  endDate: const DateTimeConverter().fromJson(json['end_date']),
  time: const DateTimeConverter().fromJson(json['time']),
  timezone: json['timezone'] as String? ?? "UTC",
  userDefined: json['user_defined'] as bool? ?? false,
  weekDays:
      (json['week_days'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(int.parse(k), e as bool),
      ) ??
      const {},
  dayOfMonth: (json['day_of_month'] as num?)?.toInt(),
  rateValue: (json['rate_value'] as num?)?.toInt(),
  rateUnit: const RateUnitConverter().fromJson(json['rate_unit']),
  apiDestination: (json['api_destination'] as num?)?.toInt() ?? 1,
  payload: json['payload'] as Map<String, dynamic>?,
  recurring: json['recurring'] as bool? ?? false,
  endCondition:
      json['end_condition'] == null
          ? EndCondition.never
          : const EndConditionConverter().fromJson(json['end_condition']),
  frequency: const RecurrenceFrequencyConverter().fromJson(json['frequency']),
);

Map<String, dynamic> _$ScheduleToJson(_Schedule instance) => <String, dynamic>{
  'name': instance.name,
  'expression': instance.expression,
  'one_off_date': const DateTimeConverter().toJson(instance.oneOffDate),
  'start_date': const DateTimeConverter().toJson(instance.startDate),
  'end_date': const DateTimeConverter().toJson(instance.endDate),
  'time': const DateTimeConverter().toJson(instance.time),
  'timezone': instance.timezone,
  'user_defined': instance.userDefined,
  'week_days': instance.weekDays.map((k, e) => MapEntry(k.toString(), e)),
  'day_of_month': instance.dayOfMonth,
  'rate_value': instance.rateValue,
  'rate_unit': _$JsonConverterToJson<dynamic, RateUnit>(
    instance.rateUnit,
    const RateUnitConverter().toJson,
  ),
  'api_destination': instance.apiDestination,
  'payload': instance.payload,
  'recurring': instance.recurring,
  'end_condition': const EndConditionConverter().toJson(instance.endCondition),
  'frequency': _$JsonConverterToJson<dynamic, RecurrenceFrequency>(
    instance.frequency,
    const RecurrenceFrequencyConverter().toJson,
  ),
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);

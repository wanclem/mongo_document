import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';

part 'schedule.freezed.dart';

part 'schedule.g.dart';

enum RecurrenceFrequency { daily, weekly, monthly, rate }

enum RateUnit { minute, hour }

enum EndCondition { never, specificDate }

@freezed
abstract class Schedule with _$Schedule {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory Schedule({
    String? name,
    String? expression,
    @DateTimeConverter() DateTime? oneOffDate,
    @DateTimeConverter() DateTime? startDate,
    @DateTimeConverter() DateTime? endDate,
    @DateTimeConverter() DateTime? time,
    @Default("UTC") String timezone,
    @Default(false) bool userDefined,
    @Default({}) Map<int, bool> weekDays,
    int? dayOfMonth,
    int? rateValue,
    @RateUnitConverter() RateUnit? rateUnit,
    @Default(1) int apiDestination,
    Map<String, dynamic>? payload,
    @Default(false) bool recurring,
    @Default(EndCondition.never)
    @EndConditionConverter()
    EndCondition endCondition,
    @RecurrenceFrequencyConverter() RecurrenceFrequency? frequency,
  }) = _Schedule;

  factory Schedule.fromJson(Map<String, dynamic> json) =>
      _$ScheduleFromJson(json);
}

class RecurrenceFrequencyConverter
    implements JsonConverter<RecurrenceFrequency, dynamic> {
  const RecurrenceFrequencyConverter();

  @override
  RecurrenceFrequency fromJson(dynamic json) {
    var raw = json.toString().toLowerCase();
    raw = raw.replaceFirst(RegExp(r'^recurrence[_.]?frequency\.'), '');
    raw = raw.replaceAll(RegExp(r'[_\s]'), '');
    switch (raw) {
      case 'daily':
        return RecurrenceFrequency.daily;
      case 'weekly':
        return RecurrenceFrequency.weekly;
      case 'monthly':
        return RecurrenceFrequency.monthly;
      case 'rate':
        return RecurrenceFrequency.rate;
      default:
        return RecurrenceFrequency.daily;
    }
  }

  @override
  String toJson(RecurrenceFrequency freq) => freq.name;
}

class RateUnitConverter implements JsonConverter<RateUnit, dynamic> {
  const RateUnitConverter();

  @override
  RateUnit fromJson(dynamic json) {
    var raw = json.toString().toLowerCase();
    raw = raw.replaceFirst(RegExp(r'^rate[_.]?unit\.'), '');
    raw = raw.replaceAll(RegExp(r'[_\s]'), '').replaceFirst(RegExp(r's$'), '');
    switch (raw) {
      case 'minute':
      case 'minutes':
        return RateUnit.minute;
      case 'hour':
      case 'hours':
        return RateUnit.hour;
      default:
        return RateUnit.hour;
    }
  }

  @override
  String toJson(RateUnit unit) => unit.name;
}

class EndConditionConverter implements JsonConverter<EndCondition, dynamic> {
  const EndConditionConverter();

  @override
  EndCondition fromJson(dynamic json) {
    var raw = json.toString().toLowerCase();
    raw = raw.replaceFirst(RegExp(r'^end[_.]?condition\.'), '');
    raw = raw.replaceAll(RegExp(r'[_\s]'), '');
    switch (raw) {
      case 'never':
        return EndCondition.never;
      case 'specificdate':
      case 'specific':
      case 'specific_date':
        return EndCondition.specificDate;
      default:
        return EndCondition.never;
    }
  }

  @override
  String toJson(EndCondition object) => object.name;
}

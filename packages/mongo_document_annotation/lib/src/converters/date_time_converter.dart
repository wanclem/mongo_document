import 'package:freezed_annotation/freezed_annotation.dart';

class DateTimeConverter implements JsonConverter<DateTime?, dynamic> {
  const DateTimeConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json is String) {
      try {
        return DateTime.parse(json);
      } catch (_) {
        return null;
      }
    } else if (json is DateTime) {
      return json;
    }
    return null;
  }

  @override
  String? toJson(DateTime? date) {
    if (date == null) return null;
    return date.toIso8601String();
  }
}

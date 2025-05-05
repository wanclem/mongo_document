import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mongo_dart/mongo_dart.dart';

class ObjectIdConverter implements JsonConverter<ObjectId?, dynamic> {
  const ObjectIdConverter();

  @override
  ObjectId? fromJson(dynamic json) {
    if (json == null) {
      return null;
    }
    if (json is String) {
      return ObjectId.fromHexString(json);
    }
    if (json is ObjectId) {
      return json;
    }
    if (json is Map<String, dynamic>) {
      return ObjectId.fromHexString(json['_id'] ?? json['id']);
    }
    throw ArgumentError('Invalid ObjectId format: $json');
  }

  @override
  ObjectId? toJson(ObjectId? object) {
    return object;
  }
}

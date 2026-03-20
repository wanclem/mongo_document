import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mongo_document_db_driver/mongo_document_db_driver.dart';

class ObjectIdConverter implements JsonConverter<ObjectId?, dynamic> {
  const ObjectIdConverter();

  @override
  ObjectId? fromJson(dynamic json) {
    final parsed = _extractObjectId(json);
    if (parsed != null || json == null) return parsed;
    throw ArgumentError('Invalid ObjectId format: $json');
  }

  @override
  ObjectId? toJson(ObjectId? objectId) {
    return objectId;
  }

  ObjectId? _extractObjectId(dynamic value) {
    if (value == null) return null;
    if (value is ObjectId) return value;
    if (value is String) return ObjectId.tryParse(value.trim());
    if (value is Map) {
      final map = value.cast<dynamic, dynamic>();
      final nestedId =
          map.containsKey('_id')
              ? _extractObjectId(map['_id'])
              : map.containsKey(r'$oid')
              ? _extractObjectId(map[r'$oid'])
              : map.containsKey('oid')
              ? _extractObjectId(map['oid'])
              : null;
      return nestedId;
    }
    return null;
  }
}

import 'package:mongo_document_annotation/mongo_document_annotation.dart';

extension QueryExtensions on Map<String, dynamic> {
  Map<String, dynamic> raw() {
    final cleaned = <String, dynamic>{};
    forEach((key, value) {
      if (key == r'$query' && value is Map<String, dynamic>) {
        value.forEach((innerKey, innerVal) {
          cleaned[innerKey] = _cleanNode(innerVal);
        });
      } else {
        cleaned[key] = _cleanNode(value);
      }
    });
    return cleaned;
  }

  Map<String, dynamic> cleaned() {
    final cleaned = <String, dynamic>{};
    forEach((rawKey, value) {
      final key = rawKey.replaceAll(RegExp(r'\._id$'), '');
      if (key == r'$query' && value is Map<String, dynamic>) {
        value.forEach((innerKey, innerVal) {
          final normalizedInnerKey = innerKey.replaceAll(RegExp(r'\._id$'), '');
          cleaned[normalizedInnerKey] = _cleanNode(innerVal);
        });
      } else {
        cleaned[key] = _cleanNode(value);
      }
    });
    return cleaned;
  }

  dynamic _cleanNode(dynamic node) {
    if (node is Map<String, dynamic>) {
      return node.cleaned();
    }
    if (node is List) {
      return node.map((e) => _cleanNode(e)).toList();
    }
    return node;
  }

  bool isValidMongoHex(String s) {
    try {
      ObjectId.parse(s);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Recursively wrap every ObjectId (except under '_id') in {'_id': …}.
  Map<String, dynamic> withRefs() {
    final result = <String, dynamic>{};
    forEach((key, value) {
      if (value is ObjectId && key != '_id') {
        result[key] = {'_id': value};
      } else if (value is Map<String, dynamic>) {
        result[key] = value.withRefs();
      } else if (value is List) {
        result[key] =
            value.map((item) {
              if (item is ObjectId) {
                return {'_id': item};
              } else if (item is Map<String, dynamic>) {
                return item.withRefs();
              }
              return item;
            }).toList();
      } else {
        if (value is String) {
          bool mongoId = isValidMongoHex(value);
          if (mongoId) {
            ObjectId? id = ObjectId.tryParse(value);
            if (id != null) {
              result[key] = {'_id': id};
            }
          } else {
            result[key] = value;
          }
        } else {
          result[key] = value;
        }
      }
    });
    return result;
  }

  Map<String, dynamic> withValidObjectReferences() {
    final result = <String, dynamic>{};
    forEach((key, value) {
      result[key] = _sniffValue(value);
    });
    return result;
  }

  dynamic _sniffValue(dynamic value) {
    if (value is String) {
      final objectIdCheck = ObjectId.tryParse(value);
      if (objectIdCheck != null) {
        return objectIdCheck;
      } else {
        return value;
      }
    } else if (value is Map) {
      if (value.containsKey('_id')) {
        final idVal = value['_id'];
        if (idVal is ObjectId) return idVal;
        if (idVal is String) {
          final parsed = ObjectId.tryParse(idVal);
          if (parsed != null) return parsed;
        }
      }
      return (value.cast<String, dynamic>()).withValidObjectReferences();
    } else if (value is Iterable) {
      return value.map((e) => _sniffValue(e)).toList();
    } else {
      return value;
    }
  }
}

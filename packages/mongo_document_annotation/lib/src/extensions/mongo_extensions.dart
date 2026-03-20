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

  /// Recursively wrap reference-like values in {'_id': …}.
  ///
  /// When [refFields] or [objectIdFields] are provided, conversion becomes
  /// schema-aware for the current map level:
  /// - keys in [refFields] hydrate as typed references
  /// - keys in [objectIdFields] hydrate as plain ObjectIds
  ///
  /// When no schema is provided, the legacy heuristic behavior is preserved for
  /// backward compatibility.
  Map<String, dynamic> withRefs({
    Set<String> refFields = const {},
    Set<String> objectIdFields = const {},
  }) {
    final usesSchema = refFields.isNotEmpty || objectIdFields.isNotEmpty;
    if (!usesSchema) {
      return _withRefsLegacy();
    }

    final result = <String, dynamic>{};
    forEach((key, value) {
      if (refFields.contains(key)) {
        result[key] = _wrapReferenceValue(value);
        return;
      }
      if (objectIdFields.contains(key)) {
        result[key] = _coerceObjectIdValue(value);
        return;
      }
      result[key] = _withRefsFallback(value);
    });
    return result;
  }

  Map<String, dynamic> _withRefsLegacy() {
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

  Map<String, dynamic> withValidObjectReferences({
    Set<String> refFields = const {},
    Set<String> objectIdFields = const {},
  }) {
    final usesSchema = refFields.isNotEmpty || objectIdFields.isNotEmpty;
    if (!usesSchema) {
      return _withValidObjectReferencesLegacy();
    }

    final result = <String, dynamic>{};
    forEach((key, value) {
      if (refFields.contains(key) || objectIdFields.contains(key)) {
        result[key] = _sniffObjectIdValue(value);
        return;
      }
      result[key] = _withValidObjectReferencesFallback(value);
    });
    return result;
  }

  Map<String, dynamic> _withValidObjectReferencesLegacy() {
    final result = <String, dynamic>{};
    forEach((key, value) {
      result[key] = _sniffValue(value);
    });
    return result;
  }

  dynamic _withRefsFallback(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value.withRefs();
    }
    if (value is List) {
      return value.map(_withRefsFallback).toList();
    }
    return value;
  }

  dynamic _withValidObjectReferencesFallback(dynamic value) {
    if (value is Map) {
      return (value.cast<String, dynamic>()).withValidObjectReferences();
    }
    if (value is Iterable) {
      return value.map(_withValidObjectReferencesFallback).toList();
    }
    return value;
  }

  dynamic _wrapReferenceValue(dynamic value) {
    if (value == null) return null;
    if (value is ObjectId) return {'_id': value};
    if (value is String) {
      final parsed = ObjectId.tryParse(value);
      return parsed == null ? value : {'_id': parsed};
    }
    if (value is Map) {
      final map = value.cast<String, dynamic>();
      final parsed = _extractObjectId(map);
      if (parsed != null) return {'_id': parsed};
      return map.withRefs();
    }
    if (value is Iterable) {
      return value.map(_wrapReferenceValue).toList();
    }
    return value;
  }

  dynamic _coerceObjectIdValue(dynamic value) {
    if (value == null) return null;
    final parsed = _extractObjectId(value);
    return parsed ?? value;
  }

  ObjectId? _extractObjectId(dynamic value) {
    if (value is ObjectId) return value;
    if (value is String) return ObjectId.tryParse(value.trim());
    if (value is Map) {
      if (value.containsKey('_id')) {
        return _extractObjectId(value['_id']);
      }
      if (value.containsKey(r'$oid')) {
        return _extractObjectId(value[r'$oid']);
      }
      if (value.containsKey('oid')) {
        return _extractObjectId(value['oid']);
      }
    }
    return null;
  }

  dynamic _sniffObjectIdValue(dynamic value) {
    if (value is Iterable) {
      return value.map(_sniffObjectIdValue).toList();
    }
    final parsed = _extractObjectId(value);
    return parsed ?? value;
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

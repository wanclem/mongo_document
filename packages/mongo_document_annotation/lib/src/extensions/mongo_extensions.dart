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

  Map<String, dynamic> withRefs() {
    final result = <String, dynamic>{...this};
    forEach((key, value) {
      if (value is ObjectId && key != '_id' && key != 'id') {
        result[key] = <String, dynamic>{
          '_id': value,
          'id': value,
        };
      }
    });
    return result;
  }
}

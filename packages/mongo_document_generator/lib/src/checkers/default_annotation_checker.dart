import 'package:analyzer/dart/element/element.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:source_gen/source_gen.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';

import 'annotation_checker.dart';

class DefaultAnnotationChecker implements AnnotationChecker {
  final _objectIdChecker = TypeChecker.fromRuntime(ObjectIdConverter);
  final _jsonKeyChecker = TypeChecker.fromRuntime(JsonKey);

  @override
  bool hasObjectIdConverter(ParameterElement element) =>
      _objectIdChecker.hasAnnotationOf(element);

  @override
  bool hasJsonKeyWithId(ParameterElement element) {
    final annotation = _jsonKeyChecker.firstAnnotationOf(element);
    if (annotation == null) return false;
    final nameField = annotation.getField('name');
    return nameField?.toStringValue() == '_id';
  }
}

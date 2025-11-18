import 'package:analyzer/dart/element/element.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:source_gen/source_gen.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';

import 'annotation_checker.dart';

class DefaultAnnotationChecker implements AnnotationChecker {
  final _objectIdChecker = TypeChecker.typeNamed(ObjectIdConverter);
  final _jsonKeyChecker = TypeChecker.typeNamed(JsonKey);

  @override
  bool hasObjectIdConverter(FormalParameterElement element) =>
      _objectIdChecker.hasAnnotationOf(element);

  @override
  bool hasJsonKeyWithId(FormalParameterElement element) {
    final annotation = _jsonKeyChecker.firstAnnotationOf(element);
    if (annotation == null) return false;
    final nameField = annotation.getField('name');
    return nameField?.toStringValue() == '_id';
  }
}

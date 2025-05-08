import 'package:analyzer/dart/element/element.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';
import 'package:source_gen/source_gen.dart';

FieldRename? getFieldRenamePolicy(
  TypeChecker typeChecker,
  ClassElement element,
) {
  var jsAnn = typeChecker.firstAnnotationOf(element);
  if (jsAnn == null && element.unnamedConstructor != null) {
    jsAnn = typeChecker.firstAnnotationOf(
      element.unnamedConstructor!,
    );
  }
  FieldRename? fieldRename;
  if (jsAnn != null) {
    final idx = jsAnn.getField('fieldRename')?.getField('index')?.toIntValue();
    if (idx != null) fieldRename = FieldRename.values[idx];
  }
  return fieldRename;
}

bool isNonNullable(ParameterElement param) =>
    !param.type.nullabilitySuffix.toString().contains('question');

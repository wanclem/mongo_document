import 'package:analyzer/dart/element/element.dart';
import 'package:mongo_document/mongo_document.dart';
import 'package:source_gen/source_gen.dart';

String _snakeCase(String input) => input.replaceAllMapped(
      RegExp(r'(?<=[a-z])[A-Z]'),
      (m) => '_${m.group(0)!.toLowerCase()}',
    );

String _kebabCase(String input) => input.replaceAllMapped(
      RegExp(r'(?<=[a-z])[A-Z]'),
      (m) => '-${m.group(0)!.toLowerCase()}',
    );

String getFieldKey(
  TypeChecker typeChecker,
  ParameterElement param,
  FieldRename? fieldRename,
) {
  final jsonKey = typeChecker.firstAnnotationOf(param);
  if (jsonKey != null) {
    return jsonKey.getField('name')?.toStringValue() ?? param.name;
  }
  final fieldName =
      param.name.startsWith('_') ? param.name.substring(1) : param.name;
  switch (fieldRename) {
    case FieldRename.snake:
      return _snakeCase(fieldName);
    case FieldRename.kebab:
      return _kebabCase(fieldName);
    default:
      return fieldName;
  }
}

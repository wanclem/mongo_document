import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:mongo_document/mongo_document.dart';
import 'package:source_gen/source_gen.dart';

const _jsonKeyChecker = TypeChecker.fromRuntime(JsonKey);
const _defaultChecker = TypeChecker.fromRuntime(Default);

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

String? getDefaultValue(ParameterElement param) {
  final DartObject? annValue = _jsonKeyChecker.firstAnnotationOf(param) ??
      _defaultChecker.firstAnnotationOf(param);
  if (annValue == null) return null;

  final astAnn = param.metadata.firstWhere(
      (m) => identical(m.computeConstantValue(), annValue),
      orElse: () => throw StateError('annotation not found'));

  final src = astAnn.toSource();
  String? literal;
  if (src.contains('defaultValue')) {
    final m = RegExp(r'defaultValue\s*:\s*([^,)]+)').firstMatch(src);
    literal = m?.group(1)?.trim();
  } else {
    final m = RegExp(r'Default\s*\(\s*([^)]*)\)').firstMatch(src);
    literal = m?.group(1)?.trim();
  }
  if (literal == null) return null;

  if (!literal.startsWith('const') &&
      (literal.startsWith('[') || literal.startsWith('{'))) {
    literal = 'const $literal';
  }
  return literal;
}

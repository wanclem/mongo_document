import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:json_annotation/json_annotation.dart';
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

String? getDefaultValue(ParameterElement param) {
  for (final annotation in param.metadata) {
    final value = annotation.computeConstantValue();
    if (value == null) continue;
    if (value.type?.getDisplayString(withNullability: false) == 'Default') {
      final defaultValue = value.getField('defaultValue');
      if (defaultValue == null || defaultValue.isNull) return null;

      final type = param.type;

      // Handle Map types with typed const {}
      if (type is InterfaceType && type.element.name == 'Map') {
        final keyType = type.typeArguments[0].getDisplayString(
          withNullability: false,
        );
        final valueType = type.typeArguments[1].getDisplayString(
          withNullability: false,
        );
        return 'const <$keyType, $valueType>{}';
      }

      // Handle List types with typed const []
      if (type is InterfaceType && type.element.name == 'List') {
        final itemType = type.typeArguments[0].getDisplayString(
          withNullability: false,
        );
        return 'const <$itemType>[]';
      }

      // Handle Set (represented as DartType "Set<T>")
      if (type is InterfaceType && type.element.name == 'Set') {
        final itemType = type.typeArguments[0].getDisplayString(
          withNullability: false,
        );
        return 'const <$itemType>{}';
      }

      // Handle other literal types
      final strVal = defaultValue.toStringValue();
      if (strVal != null) return "'$strVal'";
      final intVal = defaultValue.toIntValue();
      if (intVal != null) return '$intVal';
      final doubleVal = defaultValue.toDoubleValue();
      if (doubleVal != null) return '$doubleVal';
      final boolVal = defaultValue.toBoolValue();
      if (boolVal != null) return '$boolVal';

      // Handle enum constants
      if (defaultValue.type?.element is ClassElement &&
          (defaultValue.type!.element as ClassElement).kind ==
              ElementKind.ENUM) {
        return defaultValue.toString();
      }
      return null;
    }
  }
  return null;
}

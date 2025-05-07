import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:mongo_document/mongo_document.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

String getParameterKey(
  TypeChecker typeChecker,
  ParameterElement param,
  FieldRename? fieldRename,
) {
  final jsonKey = typeChecker.firstAnnotationOf(param);
  if (jsonKey != null) {
    return jsonKey.getField('name')?.toStringValue() ?? param.name;
  }
  final paramName =
      param.name.startsWith('_') ? param.name.substring(1) : param.name;
  final rc = ReCase(paramName);
  switch (fieldRename) {
    case FieldRename.snake:
      return rc.snakeCase;
    case FieldRename.kebab:
      return rc.paramCase;
    case FieldRename.pascal:
      return rc.pascalCase;
    case FieldRename.none:
    default:
      return paramName;
  }
}

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

Map<String, String> getNestedCollectionMap(List<ParameterElement> params) {
  final nestedCollectionMap = <String, String>{};
  for (final p in params) {
    final pType = p.type;
    if (pType is InterfaceType) {
      final nestedClassElem = pType.element;
      final mongoAnn = TypeChecker.fromRuntime(
        MongoDocument,
      ).firstAnnotationOf(nestedClassElem);
      if (mongoAnn != null) {
        final collName = mongoAnn.getField('collection')!.toStringValue()!;
        nestedCollectionMap[p.name] = collName;
      }
    }
  }
  return nestedCollectionMap;
}

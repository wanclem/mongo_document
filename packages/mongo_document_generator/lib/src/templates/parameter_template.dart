import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

class ParameterTemplates {
  static String buildNullableParams(
    List<ParameterElement> params,
    FieldRename? fieldRename,
  ) {
    return params.map((p) {
      final dartType = p.type.getDisplayString();
      final needsQuestion =
          p.type.nullabilitySuffix != NullabilitySuffix.question;
      final typeWithNull =
          needsQuestion && dartType != 'dynamic' ? '$dartType?' : dartType;
      return '    $typeWithNull ${p.name},';
    }).join('\n');
  }

  static String getParameterKey(
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

  static Map<String, String> getNestedCollectionMap(
      List<ParameterElement> params) {
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
}

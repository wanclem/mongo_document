import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

class ParameterTemplates {
  static String buildNullableParams(
    List<FormalParameterElement> params,
    FieldRename? fieldRename,
  ) {
    return params
        .map((p) {
          final dartType = p.type.getDisplayString();
          final needsQuestion =
              p.type.nullabilitySuffix != NullabilitySuffix.question;
          final typeWithNull =
              needsQuestion && dartType != 'dynamic' ? '$dartType?' : dartType;
          return '    $typeWithNull ${p.name},';
        })
        .join('\n');
  }

  static String getParameterKey(
    TypeChecker typeChecker,
    FormalParameterElement param,
    FieldRename? fieldRename,
  ) {
    final name = param.name ?? '';
    final jsonKey = typeChecker.firstAnnotationOf(param);
    if (jsonKey != null) {
      return jsonKey.getField('name')?.toStringValue() ?? name;
    }
    final paramName = name.startsWith('_') ? name.substring(1) : name;
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
    List<FormalParameterElement> params,
    TypeChecker typeChecker,
    FieldRename? fieldRename,
  ) {
    final nestedCollectionMap = <String, String>{};
    for (final p in params) {
      final pType = p.type;
      if (pType is InterfaceType) {
        final nestedClassElem = pType.element;
        final mongoAnn = TypeChecker.typeNamed(
          MongoDocument,
        ).firstAnnotationOf(nestedClassElem);
        if (mongoAnn != null) {
          final collName = mongoAnn.getField('collection')!.toStringValue()!;
          String paramName = getParameterKey(typeChecker, p, fieldRename);
          nestedCollectionMap[paramName] = collName;
        }
      }
    }
    return nestedCollectionMap;
  }
}

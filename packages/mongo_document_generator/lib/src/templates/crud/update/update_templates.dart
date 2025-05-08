import 'package:analyzer/dart/element/element.dart';
import 'package:mongo_document/mongo_document_generator.dart';
import 'package:mongo_document/src/templates/parameter_template.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';
import 'package:source_gen/source_gen.dart';

class UpdateTemplates {
  static String buildModifier() {
    return '''
  static ModifierBuilder _buildModifier(Map<String, dynamic> updateMap) {
    final now = DateTime.now().toUtc();
    var modifier = modify.set('updated_at', now);
    updateMap.forEach((k, v) => modifier = modifier.set(k, v));
    return modifier;
  }
  ''';
  }

  static String updateOne(
    String className,
    TypeChecker typeChecker,
    List<ParameterElement> params,
    FieldRename? fieldRename,
  ) {
    return '''
/// Type-safe updateOne
  static Future<bool> updateOne(
    Expression Function(Q$className ${className[0].toLowerCase()}) predicate, {
${ParameterTemplates.buildNullableParams(params, fieldRename)}
  }) async {
    final modifier = _buildModifier({
      ${params.map((p) {
      final key =
          ParameterTemplates.getParameterKey(typeChecker, p, fieldRename);
      final hasDefault =
          typeChecker.firstAnnotationOf(p)?.getField('defaultValue') != null;
      final name = p.name;
      if (isNonNullable(p) || hasDefault) {
        return "'$key': $name,";
      } else {
        return "if ($name != null) '$key': $name,";
      }
    }).join('\n    ')}
    });
    final expr = predicate(Q$className());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
      .collection(_collection)
      .updateOne(selector.map.flatQuery(), modifier);
    return result.isSuccess;
  }

''';
  }

  static String updateMany(
    String className,
    TypeChecker typeChecker,
    List<ParameterElement> params,
    FieldRename? fieldRename,
  ) {
    return '''
  /// Type-safe updateMany
  static Future<bool> updateMany(
    Expression Function(Q$className ${className[0].toLowerCase()}) predicate, {
${ParameterTemplates.buildNullableParams(params, fieldRename)}
  }) async {
    final modifier = _buildModifier({
      ${params.map((p) {
      final key =
          ParameterTemplates.getParameterKey(typeChecker, p, fieldRename);
      final hasDefault =
          typeChecker.firstAnnotationOf(p)?.getField('defaultValue') != null;
      final name = p.name;
      if (isNonNullable(p) || hasDefault) {
        return "'$key': $name,";
      } else {
        return "if ($name != null) '$key': $name,";
      }
    }).join('\n    ')}
    });
    final expr = predicate(Q$className());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
      .collection(_collection)
      .updateMany(selector.map.flatQuery(), modifier);
    return result.isSuccess;
  }
''';
  }

  static String updateOneFromMap(String className) {
    return '''
/// Use `updateOne` directly whenever possible for better performance and clarity.
  /// This method is a fallback for cases requiring additional logic or dynamic update maps.
  static Future<$className?> updateOneFromMap(
    ObjectId id, 
    Map<String, dynamic> updateMap,
  ) async {
    final conn = await MongoConnection.getDb();
    final coll = conn.collection(_collection);
    final result = await coll.updateOne({'_id':id},{'\\\$set':updateMap});
    if(!result.isSuccess) return null;
    final updatedDoc = await coll.findOne({
      '_id': id
    });
    return updatedDoc == null?null:$className.fromJson(updatedDoc);
  }''';
  }
}

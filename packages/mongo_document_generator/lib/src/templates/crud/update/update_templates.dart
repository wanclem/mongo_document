import 'package:analyzer/dart/element/element.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mongo_document/src/templates/parameter_template.dart';
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
    Map<String, dynamic> nestedCollectionMap,
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
      final name = p.name;
      if (nestedCollectionMap.containsKey(key)) {
        return "if ($name != null) '$key': $name.id,";
      } else {
        return "if ($name != null) '$key': $name,";
      }
    }).join('\n    ')}
    });
    final expr = predicate(Q$className());
    final selector = expr.toSelectorBuilder();
    final coll = await MongoDbConnection.getCollection(_collection);
    final result = await coll.updateOne(selector.map.cleaned(), modifier);
    return result.isSuccess;
  }

''';
  }

  static String updateMany(
    String className,
    Map<String, dynamic> nestedCollectionMap,
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
      final name = p.name;
      if (nestedCollectionMap.containsKey(key)) {
        return "if ($name != null) '$key': $name.id,";
      } else {
        return "if ($name != null) '$key': $name,";
      }
    }).join('\n    ')}
    });
    final expr = predicate(Q$className());
    final selector = expr.toSelectorBuilder();
    final coll = await MongoDbConnection.getCollection(_collection);
    final result = await coll.updateMany(selector.map.cleaned(), modifier);
    return result.isSuccess;
  }
''';
  }

  static String updateOneFromMap(String className) {
    return '''
   /// Prioritize `updateOne` whenever possible to avoid type mismatch.
  /// This method is a fallback for cases where you just had to use a map.
  static Future<$className?> updateOneFromMap(
    ObjectId id, 
    Map<String, dynamic> updateMap,
  ) async {
    final coll = await MongoDbConnection.getCollection(_collection);
    final result = await coll.updateOne({'_id':id},{'\\\$set':updateMap});
    if(!result.isSuccess) return null;
    final updatedDoc = await coll.findOne({
      '_id': id
    });
    return updatedDoc == null?null:$className.fromJson(updatedDoc);
  }''';
  }
}

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
  static Future<$className?> updateOne(
    Expression Function(Q$className ${className[0].toLowerCase()}) predicate, {
${ParameterTemplates.buildNullableParams(params, fieldRename)}Db?db
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
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final result = await coll.updateOne(selector.map.cleaned(), modifier);
    if (!result.isSuccess) return null;
    final updatedDoc = await coll.findOne({'_id': result.id});
    if (updatedDoc == null) return null;
    return $className.fromJson(updatedDoc.withRefs());
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
  static Future<List<$className>> updateMany(
    Expression Function(Q$className ${className[0].toLowerCase()}) predicate, {
${ParameterTemplates.buildNullableParams(params, fieldRename)}Db?db
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
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final result = await coll.updateMany(selector.map.cleaned(), modifier);
    if (!result.isSuccess) return [];
    final updatedDocs = await coll.find({'_id': result.id}).toList();
    if (updatedDocs.isEmpty) return [];
    return updatedDocs
        .map((doc) => $className.fromJson(doc.withRefs()))
        .toList();
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
    {Db?db}
  ) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final result = await coll.updateOne({'_id':id},{'\\\$set':updateMap});
    if(!result.isSuccess) return null;
    final updatedDoc = await coll.findOne({
      '_id': id
    });
    return updatedDoc == null?null:$className.fromJson(updatedDoc.withRefs());
  }''';
  }
}

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
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
    List<FormalParameterElement> params,
    FieldRename? fieldRename,
  ) {
    return '''
/// Type-safe updateOne
  static Future<$className?> updateOne(
    Expression Function(Q$className ${className[0].toLowerCase()}) predicate, {
${ParameterTemplates.buildNullableParams(params, fieldRename)}Db?db
  }) async {
    final modifier = _buildModifier(sanitizedDocument({
      ${params.map((p) {
      final key = ParameterTemplates.getParameterKey(typeChecker, p, fieldRename);
      final name = p.name;
      if (nestedCollectionMap.containsKey(key)) {
        return "if ($name != null) '$key': $name.id,";
      } else {
        var valueExpr = '$name';
        if (p.type is InterfaceType) {
          final interfaceType = p.type as InterfaceType;
          final hasToJson = interfaceType.lookUpMethod('toJson', interfaceType.element.library!) != null;
          if (hasToJson) {
            valueExpr = '$name.toJson()';
          }
        }
        return "if ($name != null) '$key': $valueExpr,";
      }
    }).join('\n    ')}
    }));
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final retrieved = await findOne(predicate);
    if (retrieved == null) return null;
    final result = await coll.updateOne(where.id(retrieved.id!), modifier);
    if (!result.isSuccess) return null;
    final updatedDoc = await coll.findOne({'_id': retrieved.id});
    if (updatedDoc == null) return null;
    return $className.fromJson(updatedDoc.withRefs());
  }

''';
  }

  static String updateMany(
    String className,
    Map<String, dynamic> nestedCollectionMap,
    TypeChecker typeChecker,
    List<FormalParameterElement> params,
    FieldRename? fieldRename,
  ) {
    return '''
  /// Type-safe updateMany
  static Future<List<$className>> updateMany(
    Expression Function(Q$className ${className[0].toLowerCase()}) predicate, {
${ParameterTemplates.buildNullableParams(params, fieldRename)}Db?db
  }) async {
    final modifier = _buildModifier(sanitizedDocument({
      ${params.map((p) {
      final key = ParameterTemplates.getParameterKey(typeChecker, p, fieldRename);
      final name = p.name;
      if (nestedCollectionMap.containsKey(key)) {
        return "if ($name != null) '$key': $name.id,";
      } else {
        var valueExpr = '$name';
        if (p.type is InterfaceType) {
          final interfaceType = p.type as InterfaceType;
          final hasToJson = interfaceType.lookUpMethod('toJson', interfaceType.element.library) != null;
          if (hasToJson) {
            valueExpr = '$name.toJson()';
          }
        }
        return "if ($name != null) '$key': $valueExpr,";
      }
    }).join('\n    ')}
    }));
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final retrieved = await findMany(predicate);
    if (retrieved.isEmpty) return [];
    final ids = retrieved.map((doc) => doc.id).toList();
    final result = await coll.updateMany(where.oneFrom('_id', ids), modifier);
    if (!result.isSuccess) return [];
    final updatedCursor = coll.find(where.oneFrom('_id', ids));
    final updatedDocs = await updatedCursor.toList();
    if (updatedDocs.isEmpty) return [];
    return updatedDocs.map((doc) => $className.fromJson(doc.withRefs())).toList();
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
    final mod = _buildModifier(sanitizedDocument(updateMap.withValidObjectReferences()));
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final result = await coll.updateOne(where.id(id),mod);
    if(!result.isSuccess) return null;
    final updatedDoc = await coll.findOne({
      '_id': id
    });
    return updatedDoc == null?null:$className.fromJson(updatedDoc.withRefs());
  }''';
  }
}

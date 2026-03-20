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
    final normalizedUpdateMap = Map<String, dynamic>.from(updateMap)
      ..remove('_id');
    var modifier = modify.set('updated_at', now);
    normalizedUpdateMap.forEach((k, v) => modifier = modifier.set(k, v));
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
      if (key == '_id') {
        return '';
      }
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
    final cleanedSelector =
        predicate(Q$className()).toSelectorBuilder().map.cleaned();
    final retrieved = await coll.modernFindOne(
      filter: cleanedSelector,
      projection: {'_id': 1},
    );
    if (retrieved == null) return null;
    final rawRetrievedId = retrieved['_id'];
    final retrievedId = rawRetrievedId is ObjectId
        ? rawRetrievedId
        : rawRetrievedId is String
        ? ObjectId.tryParse(rawRetrievedId)
        : null;
    if (retrievedId == null) return null;
    final result = await coll.updateOne({'_id': retrievedId}, modifier);
    if (!result.isSuccess) return null;
    final updatedDoc = await coll.modernFindOne(filter: {'_id': retrievedId});
    if (updatedDoc == null) return null;
    return _${className[0].toLowerCase()}${className.substring(1)}DeserializeDocument(updatedDoc);
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
      if (key == '_id') {
        return '';
      }
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
    final cleanedSelector =
        predicate(Q$className()).toSelectorBuilder().map.cleaned();
    final retrieved = await coll.modernFind(
      filter: cleanedSelector,
      projection: {'_id': 1},
    ).toList();
    if (retrieved.isEmpty) return [];
    final ids = <ObjectId>[];
    for (final doc in retrieved) {
      final rawId = doc['_id'];
      if (rawId is ObjectId) {
        ids.add(rawId);
      } else if (rawId is String) {
        final parsedId = ObjectId.tryParse(rawId);
        if (parsedId != null) {
          ids.add(parsedId);
        }
      }
    }
    if (ids.isEmpty) return [];
    final result = await coll.updateMany({'_id': {r'\$in': ids}}, modifier);
    if (!result.isSuccess) return [];
    final updatedDocs = await coll
        .modernFind(filter: {'_id': {r'\$in': ids}})
        .toList();
    if (updatedDocs.isEmpty) return [];
    final docsById = {
      for (final doc in updatedDocs) doc['_id']: doc,
    };
    return ids
        .map((id) => docsById[id])
        .whereType<Map<String, dynamic>>()
        .map(_${className[0].toLowerCase()}${className.substring(1)}DeserializeDocument)
        .toList();
  }
''';
  }

  static String updateOneFromMap(String className) {
    final classNameVar = className[0].toLowerCase() + className.substring(1);
    return '''
   /// Prioritize `updateOne` whenever possible to avoid type mismatch.
  /// This method is a fallback for cases where you just had to use a map.
  static Future<$className?> updateOneFromMap(
    ObjectId id, 
    Map<String, dynamic> updateMap,
    {Db?db}
  ) async {
    final mod = _buildModifier(
      sanitizedDocument(
        updateMap.withValidObjectReferences(
          refFields: _${classNameVar}RefFields,
          objectIdFields: _${classNameVar}ObjectIdFields,
        ),
      ),
    );
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final result = await coll.updateOne({'_id': id}, mod);
    if(!result.isSuccess) return null;
    final updatedDoc = await coll.modernFindOne(filter: {
      '_id': id
    });
    return updatedDoc == null
        ? null
        : _${classNameVar}DeserializeDocument(updatedDoc);
  }''';
  }
}

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mongo_document/mongo_document_generator.dart';
import 'package:mongo_document/src/templates/crud/create/create_template.dart';
import 'package:mongo_document/src/templates/crud/delete/delete_template.dart';
import 'package:mongo_document/src/templates/crud/read/query_templates.dart';
import 'package:mongo_document/src/templates/crud/read/read_templates.dart';
import 'package:mongo_document/src/templates/object_references/object_references.dart';
import 'package:mongo_document/src/templates/parameter_template.dart';
import 'package:mongo_document/src/utils/templates.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';
import 'package:source_gen/source_gen.dart';

const _jsonKeyChecker = TypeChecker.fromRuntime(JsonKey);
const _jsonSerializableChecker = TypeChecker.fromRuntime(JsonSerializable);

class MongoDocumentGenerator extends GeneratorForAnnotation<MongoDocument> {
  final _formatter = DartFormatter();

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) return '';
    FieldRename? fieldRename = getFieldRenamePolicy(
      _jsonSerializableChecker,
      element,
    );
    final className = element.name;
    final collection = annotation.peek('collection')!.stringValue;
    final params = element.unnamedConstructor?.parameters ?? [];
    final nestedCollectionMap =
        ParameterTemplates.getNestedCollectionMap(params);
    final nestedCollectionProjectionClasses =
        ObjectReferences.buildNestedCollectionProjectionClasses(
      _jsonSerializableChecker,
      _jsonKeyChecker,
      nestedCollectionMap,
      params,
    );
    final nestedCollectionMapLiteral =
        ObjectReferences.buildNestedCollectiontionsMapLiteral(
      nestedCollectionMap,
    );
    final queryClasses = QueryTemplates.buildQueryClasses(
      _jsonKeyChecker,
      className,
      fieldRename,
      params,
    );

    final template = '''
$nestedCollectionProjectionClasses
$nestedCollectionMapLiteral
$queryClasses

extension \$${className}Extension on $className {
  static String get _collection => '$collection';

  ${CreateTemplates.save(className)}
  ${DeleteTemplates.delete(className)}
  
}

class ${className}s {
  
  static String get _collection => '$collection';
  ${CreateTemplates.saveMany(className)}
  ${ReadTemplates.findById(className)}
  /// Type-safe findOne by predicate
  static Future<$className?> findOne(
  Expression Function(Q$className ${className[0].toLowerCase()})? predicate,
  {List<BaseProjections> projections=const [],}
  ) async {

    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);

    if (predicate == null) {
      final docs = await coll.modernFindOne(sort: {'created_at': -1});
      if (docs == null) return null;
      return $className.fromJson(docs.withRefs());
    }
    final selectorBuilder = predicate(Q$className()).toSelectorBuilder();
    final selectorMap = selectorBuilder.map.flatQuery().withLookupAwareness(_nestedCollections);

    if (projections.isNotEmpty) {
       ${buildProjectionFlowTemplate('''{
          r"\$match": selectorMap
        }''')}
      final docs = await coll.aggregateToStream(pipeline).toList();
      if (docs.isEmpty) return null;
      return $className.fromJson(docs.first.withRefs());
    }

    // fallback to simple findOne
    final doc = await coll.findOne(selectorMap);
    return doc == null ? null : $className.fromJson(doc);
  }

  /// Type-safe findOne by named arguments
  static Future<$className?> findOneByNamed({${ParameterTemplates.buildNullableParams(params, fieldRename)}List<BaseProjections> projections=const [],})async{
    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);

    final selector = <String, dynamic>{};
    ${params.map((p) {
      final paramName = p.name;
      final key =
          ParameterTemplates.getParameterKey(_jsonKeyChecker, p, fieldRename);
      return '''if ($paramName != null) selector['$key'] = $paramName;''';
    }).join('\n')}
    if (selector.isEmpty) {
      final doc = await coll.modernFindOne(sort: {'created_at': -1});
      if (doc == null) return null;
      return $className.fromJson(doc.withRefs());
    }
    if (projections.isNotEmpty) {
       ${buildProjectionFlowTemplate('''{
          r"\$match": selector
        }''')}
      final docs = await coll.aggregateToStream(pipeline).toList();
      if (docs.isEmpty) return null;
      return $className.fromJson(docs.first.withRefs());
    }
    final doc = await coll.findOne(selector);
    return doc == null ? null : $className.fromJson(doc.withRefs());
  }

  /// Type‑safe findMany by predicate
  static Future<List<$className>> findMany(
    Expression Function(Q$className ${className[0].toLowerCase()}) predicate, {
    int? skip, int? limit,
    List<BaseProjections> projections=const [],
  }) async {
    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);

    var selectorBuilder = predicate(Q$className()).toSelectorBuilder();
    if (skip != null) selectorBuilder = selectorBuilder.skip(skip);
    if (limit != null) selectorBuilder = selectorBuilder.limit(limit);
    final selectorMap = selectorBuilder.map.flatQuery().withLookupAwareness(_nestedCollections);

    if (projections.isNotEmpty) {
       ${buildProjectionFlowTemplate('''{
          r"\$match": selectorMap
        }''')}
      final docs = await coll.aggregateToStream(pipeline).toList();
      if (docs.isEmpty) return [];
      return docs.map((d)=>$className.fromJson(d.withRefs())).toList();
    }
    final docs = await (await MongoConnection.getDb())
      .collection(_collection)
      .find(selectorMap).toList();
    return docs.map((e) => $className.fromJson(e.withRefs())).toList();
 }

  /// Type-safe findMany by named arguments
  static Future<List<$className>> findManyByNamed({${ParameterTemplates.buildNullableParams(params, fieldRename)}    List<BaseProjections> projections=const [],Map<String,Object>sort=const{},int? skip,int limit=10,})async{
    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);

    final selector = <String, dynamic>{};
    ${params.map((p) {
      final paramName = p.name;
      final key =
          ParameterTemplates.getParameterKey(_jsonKeyChecker, p, fieldRename);
      return '''if ($paramName != null) selector['$key'] = $paramName;''';
    }).join('\n')}
    if (selector.isEmpty) {
      final docs = await coll.modernFind(sort: {'created_at': -1},limit:limit,skip:skip).toList();
      if (docs.isEmpty) return [];
     return docs.map((e) => $className.fromJson(e.withRefs())).toList();
    }
    if (projections.isNotEmpty) {
       ${buildProjectionFlowTemplate('''{
          r"\$match": selector
        }''')}
      final docs = await coll.aggregateToStream(pipeline).toList();
      if (docs.isEmpty) return [];
      return docs.map((d)=>$className.fromJson(d.withRefs())).toList();
    }
    final docs = await coll.modernFind(filter:selector,limit:limit,skip:skip,sort:sort).toList();
    return docs.map((e) => $className.fromJson(e.withRefs())).toList();
  }

  /// Type-safe deleteOne by predicate
  static Future<bool> deleteOne(
    Expression Function(Q$className ${className[0].toLowerCase()}) predicate
  ) async {
    final expr = predicate(Q$className());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
      .collection(_collection)
      .deleteOne(selector.map.flatQuery());
    return result.isSuccess;
  }

  /// Type-safe deleteOne by named arguments
  static Future<bool> deleteOneByNamed(
  {${ParameterTemplates.buildNullableParams(params, fieldRename)}}
  ) async {
  final selector = <String, dynamic>{};
  ${params.map((p) {
      final paramName = p.name;
      final key =
          ParameterTemplates.getParameterKey(_jsonKeyChecker, p, fieldRename);
      return '''if ($paramName != null) selector['$key'] = $paramName;''';
    }).join('\n')}
    if (selector.isEmpty) return false;
    final result = await (await MongoConnection.getDb())
      .collection(_collection)
      .deleteOne(selector);
    return result.isSuccess;
  }
  
  /// Type-safe deleteMany
  static Future<bool> deleteMany(
    Expression Function(Q$className ${className[0].toLowerCase()}) predicate
  ) async {
    final expr = predicate(Q$className());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
      .collection(_collection)
      .deleteMany(selector.map.flatQuery());
    return result.isSuccess;
  }

  /// Type-safe updateOne
  static Future<bool> updateOne(
    Expression Function(Q$className ${className[0].toLowerCase()}) predicate, {
${ParameterTemplates.buildNullableParams(params, fieldRename)}
  }) async {
    final modifier = _buildModifier({
      ${params.map((p) {
      final key =
          ParameterTemplates.getParameterKey(_jsonKeyChecker, p, fieldRename);
      final hasDefault =
          _jsonKeyChecker.firstAnnotationOf(p)?.getField('defaultValue') !=
              null;
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

  /// Type-safe updateMany
  static Future<bool> updateMany(
    Expression Function(Q$className ${className[0].toLowerCase()}) predicate, {
${ParameterTemplates.buildNullableParams(params, fieldRename)}
  }) async {
    final modifier = _buildModifier({
      ${params.map((p) {
      final key =
          ParameterTemplates.getParameterKey(_jsonKeyChecker, p, fieldRename);
      final hasDefault =
          _jsonKeyChecker.firstAnnotationOf(p)?.getField('defaultValue') !=
              null;
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

  static ModifierBuilder _buildModifier(Map<String, dynamic> updateMap) {
    final now = DateTime.now().toUtc();
    var modifier = modify.set('updated_at', now);
    updateMap.forEach((k, v) => modifier = modifier.set(k, v));
    return modifier;
  }
  
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
  }

  static Future<int> count(
    Expression Function(Q$className ${className[0].toLowerCase()})? predicate
  ) async {
    final selectorMap =predicate==null? {}: predicate(Q$className())
        .toSelectorBuilder()
        .map.flatQuery();
    return (await MongoConnection.getDb())
        .collection(_collection)
        .count(selectorMap);
  }

}
''';
    return _formatter.format(template);
  }
}

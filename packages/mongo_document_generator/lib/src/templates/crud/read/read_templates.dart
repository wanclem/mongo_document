import 'package:analyzer/dart/element/element.dart';
import 'package:mongo_document/src/templates/parameter_template.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';
import 'package:source_gen/source_gen.dart';

class ReadTemplates {
  static String findById(String className) {
    return '''
/// Type-safe findById with optional nested‑doc projections
  static Future<$className?> findById(
    dynamic id, {
    List<BaseProjections> projections=const [],
  }) async {
    if (id == null) return null;
    if (id is String) id = ObjectId.fromHexString(id);
    if (id is! ObjectId) {
      throw ArgumentError('Invalid id type: \${id.runtimeType}');
    }

    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);

    if (projections.isNotEmpty) {
       ${buildProjectionFlowTemplate('''{
          r"\$match": {'_id': id}
        }''')}
      final docs = await coll.aggregateToStream(pipeline).toList();
      if (docs.isEmpty) return null;
      return $className.fromJson(docs.first.withRefs());
    }

    // fallback: return entire document
    final doc = await coll.findOne(where.eq(r'_id', id));
    return doc == null ? null : $className.fromJson(doc.withRefs());
  }

''';
  }

  static String findOne(String className) {
    return '''
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
''';
  }

  static String findOneByNamed(
    TypeChecker typeChecker,
    FieldRename? fieldRename,
    List<ParameterElement> params,
    String className,
  ) {
    return '''
/// Type-safe findOne by named arguments
  static Future<$className?> findOneByNamed({${ParameterTemplates.buildNullableParams(params, fieldRename)}List<BaseProjections> projections=const [],})async{
    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);

    final selector = <String, dynamic>{};
    ${params.map((p) {
      final paramName = p.name;
      final key =
          ParameterTemplates.getParameterKey(typeChecker, p, fieldRename);
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
''';
  }

  static String findMany(String className) {
    return '''
  /// Type-safe findMany by predicate
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
''';
  }

  static String findManyByNamed(
    TypeChecker typeChecker,
    FieldRename? fieldRename,
    List<ParameterElement> params,
    String className,
  ) {
    return '''
/// Type-safe findMany by named arguments
  static Future<List<$className>> findManyByNamed({${ParameterTemplates.buildNullableParams(params, fieldRename)}    List<BaseProjections> projections=const [],Map<String,Object>sort=const{},int? skip,int limit=10,})async{
    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);

    final selector = <String, dynamic>{};
    ${params.map((p) {
      final paramName = p.name;
      final key =
          ParameterTemplates.getParameterKey(typeChecker, p, fieldRename);
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
''';
  }

  static String count(String className) {
    return '''
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
''';
  }
}

String buildProjectionFlowTemplate(String matchQuery) {
  return '''
final pipeline = <Map<String, Object>>[];
     final projDoc = <String, int>{};
     pipeline.add($matchQuery);
     for (var p in projections) {
        final projectedFields = p.fields;
        final allProjections = p.toProjection();
        final localField = allProjections.keys.first.split(".").first;
        final foreignColl = _nestedCollections[localField];
        if (projectedFields != null && projectedFields.isNotEmpty) {
          final selected = <String, int>{};
          for (var f in projectedFields) {
            final path = p.fieldMappings[(f as Enum).name]!;
            selected[path] = 1;
          }
          projDoc.addAll(selected);
        } else {
          projDoc.addAll(allProjections);
        }
        pipeline.add({
          r'\$lookup': {
            'from': foreignColl,
            'localField': localField,
            'foreignField': '_id',
            'as': localField,
          }
        });
        pipeline.add({r'\$unwind': localField});
      }
      pipeline.add({r'\$project': projDoc});
''';
}

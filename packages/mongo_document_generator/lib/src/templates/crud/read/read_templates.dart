import 'package:analyzer/dart/element/element.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mongo_document/src/templates/parameter_template.dart';
import 'package:source_gen/source_gen.dart';

class ReadTemplates {
  static String findById(String className) {
    String classNameVar = className.toLowerCase();
    return '''
/// Find a $className by its _id with optional nested-doc projections
  static Future<$className?> findById(
    dynamic ${classNameVar}Id, {
    List<BaseProjections> projections=const [],
  }) async {
    if (${classNameVar}Id == null) return null;
    if (${classNameVar}Id is String) ${classNameVar}Id = ObjectId.fromHexString(${classNameVar}Id);
    if (${classNameVar}Id is! ObjectId) {
      throw ArgumentError('Invalid ${classNameVar}Id type: \${${classNameVar}Id.runtimeType}');
    }

    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);

    if (projections.isNotEmpty) {
       ${buildAggregationPipeline('''{
          r"\$match": {'_id': ${classNameVar}Id}
        }''')}
      final ${classNameVar}s = await coll.aggregateToStream(pipeline).toList();
      if (${classNameVar}s.isEmpty) return null;
      return $className.fromJson(${classNameVar}s.first.withRefs());
    }

    // fallback: return entire $classNameVar
    final $classNameVar = await coll.findOne(where.eq(r'_id', ${classNameVar}Id));
    return $classNameVar == null ? null : $className.fromJson($classNameVar.withRefs());
  }

''';
  }

  static String findOne(String className) {
    String classNameVar = className.toLowerCase();
    return '''
/// Type-safe findOne by predicate
  static Future<$className?> findOne(
  Expression Function(Q$className ${className[0].toLowerCase()})? predicate,
  {List<BaseProjections> projections=const [],}
  ) async {

    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);

    if (predicate == null) {
      final $classNameVar = await coll.modernFindOne(sort: {'created_at': -1});
      if ($classNameVar == null) return null;
      return $className.fromJson($classNameVar.withRefs());
    }
    final selectorBuilder = predicate(Q$className()).toSelectorBuilder();
    final selectorMap = selectorBuilder.map.flatQuery();

    final projDoc =
        projections.isNotEmpty ? buildProjectionDoc(projections) : null;
    final (foundLookups, pipeline) = selectorMap.toAggregationPipelineWithMap(
      lookupRef: _nestedCollections,
      projections: projDoc,
    );

    if (foundLookups || projDoc != null) {
      final results = await coll.aggregateToStream(pipeline).toList();
      if (results.isEmpty) return null;
      return $className.fromJson(results.first.withRefs());
    }

    // fallback to simple findOne
    final ${classNameVar}Result = await coll.findOne(selectorMap);
    return ${classNameVar}Result == null ? null : $className.fromJson(${classNameVar}Result);
  }
''';
  }

  static String findOneByNamed(
    TypeChecker typeChecker,
    FieldRename? fieldRename,
    List<ParameterElement> params,
    String className,
    Map<String, dynamic> nestedCollectionMap,
  ) {
    String classNameVar = className.toLowerCase();
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
      return '''if ($paramName != null) selector['$key'] = ${nestedCollectionMap.containsKey(paramName) ? "$paramName.id" : paramName};''';
    }).join('\n')}
    if (selector.isEmpty) {
      final $classNameVar = await coll.modernFindOne(sort: {'created_at': -1});
      if ($classNameVar == null) return null;
      return $className.fromJson($classNameVar.withRefs());
    }
    if (projections.isNotEmpty) {
       ${buildAggregationPipeline('''{
          r"\$match": selector
        }''')}
      final ${classNameVar}s = await coll.aggregateToStream(pipeline).toList();
      if (${classNameVar}s.isEmpty) return null;
      return $className.fromJson(${classNameVar}s.first.withRefs());
    }
    final ${classNameVar}Result = await coll.findOne(selector);
    return ${classNameVar}Result == null ? null : $className.fromJson(${classNameVar}Result.withRefs());
  }
''';
  }

  static String findMany(String className) {
    String classNameVar = className.toLowerCase();
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
    final selectorMap = selectorBuilder.map.flatQuery();

    final projDoc =
        projections.isNotEmpty ? buildProjectionDoc(projections) : null;
    final (foundLookups, pipeline) = selectorMap.toAggregationPipelineWithMap(
      lookupRef: _nestedCollections,
      projections: projDoc,
    );

    if (foundLookups || projDoc != null) {
      final ${classNameVar}s = await coll.aggregateToStream(pipeline).toList();
      if (${classNameVar}s.isEmpty) return [];
      return ${classNameVar}s.map((d)=>$className.fromJson(d.withRefs())).toList();
    }

    final ${classNameVar}s = await (await MongoConnection.getDb())
      .collection(_collection)
      .find(selectorMap).toList();
    return ${classNameVar}s.map((e) => $className.fromJson(e.withRefs())).toList();
 }
''';
  }

  static String findManyByNamed(
    TypeChecker typeChecker,
    FieldRename? fieldRename,
    List<ParameterElement> params,
    String className,
    Map<String, dynamic> nestedCollectionMap,
  ) {
    String classNameVar = className.toLowerCase();
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
      return '''if ($paramName != null) selector['$key'] = ${nestedCollectionMap.containsKey(paramName) ? "$paramName.id" : paramName};''';
    }).join('\n')}
    if (selector.isEmpty) {
      final ${classNameVar}s = await coll.modernFind(sort: {'created_at': -1},limit:limit,skip:skip).toList();
      if (${classNameVar}s.isEmpty) return [];
     return ${classNameVar}s.map((e) => $className.fromJson(e.withRefs())).toList();
    }
    if (projections.isNotEmpty) {
       ${buildAggregationPipeline('''{
          r"\$match": selector
        }''')}
      final ${classNameVar}s = await coll.aggregateToStream(pipeline).toList();
      if (${classNameVar}s.isEmpty) return [];
      return ${classNameVar}s.map((d)=>$className.fromJson(d.withRefs())).toList();
    }
    final ${classNameVar}s = await coll.modernFind(filter:selector,limit:limit,skip:skip,sort:sort).toList();
    return ${classNameVar}s.map((e) => $className.fromJson(e.withRefs())).toList();
  }
''';
  }

  static String count(String className) {
    return '''
  static Future<int> count(
  Expression Function(Q$className ${className[0].toLowerCase()})? predicate
) async {
  final selectorMap = predicate == null
      ? <String, dynamic>{}
      : predicate(Q$className())
          .toSelectorBuilder()
          .map
          .flatQuery();

  final (foundLookups, pipelineWithoutCount) =
      selectorMap.toAggregationPipelineWithMap(
        lookupRef: _nestedCollections,
      );

  if (foundLookups) {
    final pipeline = [
      ...pipelineWithoutCount,
      { r'\$count': 'count' }                     
    ];

    final result = await (await MongoConnection.getDb())
        .collection(_collection)
        .aggregateToStream(pipeline)             
        .toList();

    if (result.isEmpty) return 0;
    return result.first['count'] as int;
  }

  return (await MongoConnection.getDb())
      .collection(_collection)
      .count(selectorMap);                       
}
''';
  }
}

String buildAggregationPipeline(String matchQuery) {
  return '''
final pipeline = <Map<String, Object>>[];
     final projDoc = <String, int>{};
     pipeline.add($matchQuery);
     final selected = <String, int>{};
     for (var p in projections) {
        final inclusions = p.inclusions??[];
        final exclusions = p.exclusions??[];
        final allProjections = p.toProjection();
        final localField = allProjections.keys.first.split(".").first;
        final foreignColl = _nestedCollections[localField];
        if(inclusions.isNotEmpty){
         for (var f in inclusions) {
            final path = p.fieldMappings[(f as Enum).name]!;
            selected[path] = 1;
          }
        }
        if(exclusions.isNotEmpty){
         for (var f in exclusions) {
            final path = p.fieldMappings[(f as Enum).name]!;
            selected[path] = 0;
          }
        }
        if(selected.isEmpty){
          selected.addAll(allProjections);
        }
        if(selected.isNotEmpty){
          projDoc.addAll(selected);
        }
        pipeline.add({
          r'\$lookup': {
            'from': foreignColl,
            'localField': localField,
            'foreignField': '_id',
            'as': localField,
          }
        });
        pipeline.add({r'\$unwind': {"path":"\\\$\${localField}","preserveNullAndEmptyArrays": true}});
      }
      pipeline.add({r'\$project': projDoc});
''';
}

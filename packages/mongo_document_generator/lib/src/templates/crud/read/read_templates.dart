import 'package:analyzer/dart/element/element.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mongo_document/src/templates/parameter_template.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

class ReadTemplates {
  static String findById(String className) {
    String classNameVar = ReCase(className).camelCase;
    return '''
  static Future<$className?> findById(
    dynamic id, {
    Db? db,
    List<BaseProjections> projections=const [],
  }) async {
    if (id == null) return null;
    if (id is String) id = ObjectId.fromHexString(id);
    if (id is! ObjectId) {
      throw ArgumentError('Invalid id type: \${id.runtimeType}');
    }
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

    if (projections.isNotEmpty) {
       ${buildAggregationPipeline("${className}Projections()", ['''{
          r"\$match": {'_id': id}
        }'''])}
      final ${classNameVar}s = await coll.aggregateToStream(pipeline).toList();
      if (${classNameVar}s.isEmpty) return null;
      return $className.fromJson(${classNameVar}s.first.withRefs());
    }

    // fallback: return entire $classNameVar
    final $classNameVar = await coll.findOne(where.eq(r'_id', id));
    return $classNameVar == null ? null : $className.fromJson($classNameVar.withRefs());
  }

''';
  }

  static String findOne(String className) {
    String classNameVar = ReCase(className).camelCase;
    return '''
/// Type-safe findOne by predicate
  static Future<$className?> findOne(
  Expression Function(Q$className ${className[0].toLowerCase()})? predicate,
  {Db?db,List<BaseProjections> projections=const [],}
  ) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

    if (predicate == null) {
      final $classNameVar = await coll.modernFindOne(sort: {'created_at': -1});
      if ($classNameVar == null) return null;
      return $className.fromJson($classNameVar.withRefs());
    }
    final selectorBuilder = predicate(Q$className()).toSelectorBuilder();
    final selectorMap = selectorBuilder.map;

    final projDoc =
        projections.isNotEmpty ? buildProjectionDoc(projections) : null;
    final (foundLookups, pipeline) = toAggregationPipelineWithMap(
      lookupRef: _nestedCollections,
      projections: projDoc,
      limit: 1,
      raw: selectorMap.raw(),
      cleaned: selectorMap.cleaned(),
    );

    if (foundLookups) {
      final results = await coll.aggregateToStream(pipeline).toList();
      if (results.isEmpty) return null;
      return $className.fromJson(results.first.withRefs());
    }

    // fallback to simple findOne
    final ${classNameVar}Result = await coll.findOne(selectorMap.cleaned());
    return ${classNameVar}Result == null ? null : $className.fromJson(${classNameVar}Result.withRefs());
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
    String classNameVar = ReCase(className).camelCase;
    return '''
/// Type-safe findOne by named arguments
  static Future<$className?> findOneByNamed({${ParameterTemplates.buildNullableParams(params, fieldRename)}Db?db,List<BaseProjections> projections=const [],})async{
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

    final selector = <String, dynamic>{};
    ${params.map((p) {
      final paramName = p.name;
      final key = ParameterTemplates.getParameterKey(typeChecker, p, fieldRename);
      return '''if ($paramName != null) selector['$key'] = ${nestedCollectionMap.containsKey(key) ? "$paramName.id" : paramName};''';
    }).join('\n')}
    if (selector.isEmpty) {
      final $classNameVar = await coll.modernFindOne(sort: {'created_at': -1});
      if ($classNameVar == null) return null;
      return $className.fromJson($classNameVar.withRefs());
    }
    if (projections.isNotEmpty) {
       ${buildAggregationPipeline("${className}Projections()", ['''{
          r"\$match": selector
        }'''])}
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
    String classNameVar = ReCase(className).camelCase;
    return '''
  /// Type-safe findMany by predicate
  static Future<List<$className>> findMany(
    Expression Function(Q$className ${className[0].toLowerCase()}) predicate, {
    int? skip, 
    int limit = 10,
    (String, int) sort = const("created_at", -1),
    List<BaseProjections> projections=const [],
    Db?db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

    var selectorBuilder = predicate(Q$className()).toSelectorBuilder();
    var selectorMap = selectorBuilder.map;

    final projDoc =
        projections.isNotEmpty ? buildProjectionDoc(projections) : null;
    final (foundLookups, pipeline) = toAggregationPipelineWithMap(
      lookupRef: _nestedCollections,
      projections: projDoc,
      raw: selectorMap.raw(),
      sort: sort,
      limit: limit,
      skip: skip,
      cleaned: selectorMap.cleaned(),
    );

    if (foundLookups) {
      final ${classNameVar}s = await coll.aggregateToStream(pipeline).toList();
      if (${classNameVar}s.isEmpty) return [];
      return ${classNameVar}s.map((d)=>$className.fromJson(d.withRefs())).toList();
    }

    if (skip != null) selectorBuilder = selectorBuilder.skip(skip);
    selectorBuilder = selectorBuilder.limit(limit);

    selectorMap=selectorBuilder.map;

    final ${classNameVar}s = await coll.find(selectorMap.cleaned()).toList();
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
    String classNameVar = ReCase(className).camelCase;
    return '''
/// Type-safe findMany by named arguments
  static Future<List<$className>> findManyByNamed({${ParameterTemplates.buildNullableParams(params, fieldRename)}Db?db,List<BaseProjections> projections=const [],Map<String,Object>sort=const{'created_at':-1},int? skip,int limit=10,
})async{
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

    final selector = <String, dynamic>{};
    ${params.map((p) {
      final paramName = p.name;
      final key = ParameterTemplates.getParameterKey(typeChecker, p, fieldRename);
      return '''if ($paramName != null) selector['$key'] = ${nestedCollectionMap.containsKey(key) ? "$paramName.id" : paramName};''';
    }).join('\n')}
    if (selector.isEmpty) {
      final ${classNameVar}s = await coll.modernFind(sort: sort ,limit:limit,skip:skip).toList();
      if (${classNameVar}s.isEmpty) return [];
     return ${classNameVar}s.map((e) => $className.fromJson(e.withRefs())).toList();
    }
    if (projections.isNotEmpty) {
       ${buildAggregationPipeline("${className}Projections()", ['''{
          r"\$match": selector
        }''', '''{
          r"\$sort": sort
        }''', '''{
          r"\$limit": limit
        }'''])}
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
  Expression Function(Q$className ${className[0].toLowerCase()})? predicate,
  {Db?db}
) async {
  final database = db ?? await MongoDbConnection.instance;
  final coll = await database.collection(_collection);

  final selectorMap = predicate == null
      ? <String, dynamic>{}
      : predicate(Q$className())
          .toSelectorBuilder()
          .map;

  final (foundLookups, pipelineWithoutCount) =
      toAggregationPipelineWithMap(
        lookupRef: _nestedCollections,
        raw: selectorMap.raw(),
        cleaned: selectorMap.cleaned()
      );

  if (foundLookups) {
    final pipeline = [
      ...pipelineWithoutCount,
      { r'\$count': 'count' }                     
    ];

    final result = await coll.aggregateToStream(pipeline).toList();
    if (result.isEmpty) return 0;
    return result.first['count'] as int;
  }

  return await coll.count(selectorMap.cleaned());                       
}
''';
  }
}

String addStages(List<dynamic> stages) {
  String stageString = "";
  for (var stage in stages) {
    stageString += "pipeline.add($stage);";
  }
  return stageString;
}

String buildAggregationPipeline(String baseProjection, List<dynamic> stages) {
  return '''
final pipeline = <Map<String, Object>>[];
     final projDoc = <String, int>{};
     ${addStages(stages)}
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
        projDoc.addAll($baseProjection.toProjection());
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

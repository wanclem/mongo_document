import 'package:analyzer/dart/element/element.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mongo_document/src/templates/parameter_template.dart';
import 'package:pluralize/pluralize.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

class ReadTemplates {
  static String findById(String className) {
    String classNameVar = ReCase(className).camelCase;
    return '''
  static Future<$className?> findById(
    dynamic id, {
    Db? db,
    List<Lookup>lookups=const [],
    List<BaseProjections> projections=const [],
  }) async {
    if (id == null) return null;
    if (id is String) {
      final parsedId = ObjectId.tryParse(id);
      if (parsedId == null) {
        throw ArgumentError('Invalid id value: \$id');
      }
      id = parsedId;
    }
    if (id is! ObjectId) {
      throw ArgumentError('Invalid id type: \${id.runtimeType}');
    }
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final normalizedLookups = remapLookups(lookups, _${classNameVar}FieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      ${className}Projections(),
    );
    final projDoc =
        projections.isNotEmpty ? buildProjectionDoc(normalizedProjections) : null;
    final canUseDirectProjection =
        projDoc != null && projectionDocSupportsDirectFind(projDoc);

    var (foundLookups, pipeline) = toAggregationPipelineWithMap(
      lookupRef: _nestedCollections,
      lookups: normalizedLookups,
      projections: projDoc,
      limit: 1,
      raw: {'_id': id},
      cleaned: {'_id': id},
    );
    if (normalizedLookups.isNotEmpty) {
      (foundLookups, pipeline) = mergeLookups(
        lookups: normalizedLookups,
        existingPipeline: foundLookups ? pipeline : null,
        queryMap: foundLookups ? null : {'_id': id},
        limit: foundLookups ? null : 1,
      );
    }
    if (foundLookups) {
      final collisionFreePipeline = withNoCollisions(pipeline);
      final results = await coll.aggregateToStream(collisionFreePipeline).toList();
      if (results.isEmpty) return null;
      return _${classNameVar}DeserializeDocument(results.first);
    }
    // fallback: return entire $classNameVar
    final $classNameVar = await coll.modernFindOne(
      filter: {'_id': id},
      projection: canUseDirectProjection ? projDoc.cast<String, Object>() : null,
    );
    return $classNameVar == null ? null : _${classNameVar}DeserializeDocument($classNameVar);
  }

''';
  }

  static String findOne(String className) {
    String classNameVar = ReCase(className).camelCase;
    return '''
/// Type-safe findOne by predicate
  static Future<$className?> findOne(
  Expression Function(Q$className ${className[0].toLowerCase()})? predicate,
  {Db?db,List<Lookup>lookups=const [],List<BaseProjections> projections=const [],}
  ) async {
  
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final normalizedLookups = remapLookups(lookups, _${classNameVar}FieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      ${className}Projections(),
    );

    if (predicate == null) {
      final $classNameVar = await coll.modernFindOne(sort: {'created_at': -1});
      if ($classNameVar == null) return null;
      return _${classNameVar}DeserializeDocument($classNameVar);
    }
    
    final selectorBuilder = predicate(Q$className()).toSelectorBuilder();
    final selectorMap = selectorBuilder.map;

    final projDoc =
        projections.isNotEmpty ? buildProjectionDoc(normalizedProjections) : null;
    final canUseDirectProjection =
        projDoc != null && projectionDocSupportsDirectFind(projDoc);
        
    var (foundLookups, pipeline) = toAggregationPipelineWithMap(
      lookupRef: _nestedCollections,
      lookups: normalizedLookups,
      projections: projDoc,
      limit: 1,
      raw: selectorMap.raw(),
      cleaned: selectorMap.cleaned(),
    );
    
    if (normalizedLookups.isNotEmpty) {
      (foundLookups, pipeline) = mergeLookups(
        lookups: normalizedLookups,
        existingPipeline: foundLookups ? pipeline : null,
        queryMap: foundLookups ? null : selectorMap.cleaned(),
        limit: 1,
      );
    }
    
    if (foundLookups) {
      final collisionFreePipeline = withNoCollisions(pipeline);
      final results = await coll.aggregateToStream(collisionFreePipeline).toList();
      if (results.isEmpty) return null;
      return _${classNameVar}DeserializeDocument(results.first);
    }

    // fallback to simple findOne
    final ${classNameVar}Result = await coll.modernFindOne(
      filter: selectorMap.cleaned(),
      projection: canUseDirectProjection ? projDoc.cast<String, Object>() : null,
    );
    return ${classNameVar}Result == null
        ? null
        : _${classNameVar}DeserializeDocument(${classNameVar}Result);
  }
''';
  }

  static String findOneByNamed(
    TypeChecker typeChecker,
    FieldRename? fieldRename,
    List<FormalParameterElement> params,
    String className,
    Map<String, dynamic> nestedCollectionMap,
  ) {
    String classNameVar = ReCase(className).camelCase;
    String classNamePlural = Pluralize().plural(classNameVar);
    return '''
/// Type-safe findOne by named arguments
  static Future<$className?> findOneByNamed({${ParameterTemplates.buildNullableParams(params, fieldRename)}Db?db,List<Lookup>lookups=const [],List<BaseProjections> projections=const [],})async{
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final normalizedLookups = remapLookups(lookups, _${classNameVar}FieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      ${className}Projections(),
    );

    final selector = <String, dynamic>{};
    
    ${params.map((p) {
      final paramName = p.name;
      final key = ParameterTemplates.getParameterKey(typeChecker, p, fieldRename);
      return '''if ($paramName != null) selector['$key'] = ${nestedCollectionMap.containsKey(key) ? "$paramName.id" : paramName};''';
    }).join('\n')}
    if (selector.isEmpty && projections.isEmpty && normalizedLookups.isEmpty) {
      final $classNameVar = await coll.modernFindOne(sort: {'created_at': -1});
      if ($classNameVar == null) return null;
      return _${classNameVar}DeserializeDocument($classNameVar);
    }

    final projDoc =
        projections.isNotEmpty ? buildProjectionDoc(normalizedProjections) : null;
    final canUseDirectProjection =
        projDoc != null && projectionDocSupportsDirectFind(projDoc);

    var (foundLookups, pipeline) = toAggregationPipelineWithMap(
      lookupRef: _nestedCollections,
      lookups: normalizedLookups,
      projections: projDoc,
      limit: 1,
      sort: selector.isEmpty ? ('created_at', -1) : null,
      raw: selector,
      cleaned: selector.cleaned(),
    );

    if (normalizedLookups.isNotEmpty) {
      (foundLookups, pipeline) = mergeLookups(
        lookups: normalizedLookups,
        existingPipeline: foundLookups ? pipeline : null,
        queryMap: foundLookups ? null : selector.cleaned(),
        sort: foundLookups || selector.isNotEmpty ? null : ('created_at', -1),
        limit: foundLookups ? null : 1,
      );
    }

    if (foundLookups) {
      final collisionFreePipeline = withNoCollisions(pipeline);
      final $classNamePlural = await coll.aggregateToStream(collisionFreePipeline).toList();
      if ($classNamePlural.isEmpty) return null;
      return _${classNameVar}DeserializeDocument($classNamePlural.first);
    }

    final ${classNameVar}Result = await coll.modernFindOne(
      filter: selector.cleaned(),
      sort: selector.isEmpty ? {'created_at': -1} : null,
      projection: canUseDirectProjection ? projDoc.cast<String, Object>() : null,
    );
    return ${classNameVar}Result == null
        ? null
        : _${classNameVar}DeserializeDocument(${classNameVar}Result);
  }
''';
  }

  static String findMany(String className) {
    String classNameVar = ReCase(className).camelCase;
    String classNamePlural = Pluralize().plural(classNameVar);
    return '''
  /// Type-safe findMany by predicate
  static Future<List<$className>> findMany(
    Expression Function(Q$className ${className[0].toLowerCase()}) predicate, {
    List<Lookup>lookups=const [],
    int? skip, 
    int limit = 10,
    (String, int) sort = const("created_at", -1),
    List<BaseProjections> projections=const [],
    Db?db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final normalizedLookups = remapLookups(lookups, _${classNameVar}FieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      ${className}Projections(),
    );

    var selectorBuilder = predicate(Q$className()).toSelectorBuilder();
    var selectorMap = selectorBuilder.map;

    final projDoc =
        projections.isNotEmpty ? buildProjectionDoc(normalizedProjections) : null;
    final canUseDirectProjection =
        projDoc != null && projectionDocSupportsDirectFind(projDoc);
        
    var (foundLookups, pipeline) = toAggregationPipelineWithMap(
      lookupRef: _nestedCollections,
      lookups: normalizedLookups,
      projections: projDoc,
      raw: selectorMap.raw(),
      sort: sort,
      limit: limit,
      skip: skip,
      cleaned: selectorMap.cleaned(),
    );
    
    if (normalizedLookups.isNotEmpty) {
      (foundLookups, pipeline) = mergeLookups(
        lookups: normalizedLookups,
        existingPipeline: foundLookups ? pipeline : null,
        queryMap: foundLookups ? null : selectorMap.cleaned(),
        sort: foundLookups ? null : sort,
        skip: foundLookups ? null : skip,
        limit: foundLookups ? null : limit,
      );
    }
  
    if (foundLookups) {
      final collisionFreePipeline = withNoCollisions(pipeline);
      final $classNamePlural = await coll.aggregateToStream(collisionFreePipeline).toList();
      if ($classNamePlural.isEmpty) return [];
      return _${classNameVar}DeserializeDocuments($classNamePlural);
    }

    final $classNamePlural = await coll
        .modernFind(
          filter: selectorMap.cleaned(),
          sort: {sort.\$1: sort.\$2},
          projection: canUseDirectProjection ? projDoc.cast<String, Object>() : null,
          skip: skip,
          limit: limit,
        )
        .toList();
    return _${classNameVar}DeserializeDocuments($classNamePlural);
 }
''';
  }

  static String findManyByNamed(
    TypeChecker typeChecker,
    FieldRename? fieldRename,
    List<FormalParameterElement> params,
    String className,
    Map<String, dynamic> nestedCollectionMap,
  ) {
    String classNameVar = ReCase(className).camelCase;
    String classNamePlural = Pluralize().plural(classNameVar);
    return '''
/// Type-safe findMany by named arguments
  static Future<List<$className>> findManyByNamed({${ParameterTemplates.buildNullableParams(params, fieldRename)}Db?db,List<Lookup>lookups=const [],List<BaseProjections> projections=const [],Map<String,Object>sort=const{'created_at':-1},int? skip,int limit=10,
})async{

    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final normalizedLookups = remapLookups(lookups, _${classNameVar}FieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      ${className}Projections(),
    );

    final selector = <String, dynamic>{};
    
    ${params.map((p) {
      final paramName = p.name;
      final key = ParameterTemplates.getParameterKey(typeChecker, p, fieldRename);
      return '''if ($paramName != null) selector['$key'] = ${nestedCollectionMap.containsKey(key) ? "$paramName.id" : paramName};''';
    }).join('\n')}
    
    if (selector.isEmpty && projections.isEmpty && normalizedLookups.isEmpty) {
      final $classNamePlural = await coll.modernFind(sort: sort ,limit:limit,skip:skip).toList();
      if ($classNamePlural.isEmpty) return [];
     return _${classNameVar}DeserializeDocuments($classNamePlural);
    }

    final projDoc =
        projections.isNotEmpty ? buildProjectionDoc(normalizedProjections) : null;
    final canUseDirectProjection =
        projDoc != null && projectionDocSupportsDirectFind(projDoc);

    var (foundLookups, pipeline) = toAggregationPipelineWithMap(
      lookupRef: _nestedCollections,
      lookups: normalizedLookups,
      projections: projDoc,
      sort: firstEntryToTuple(sort),
      skip: skip,
      limit: limit,
      raw: selector,
      cleaned: selector.cleaned(),
    );

    if (normalizedLookups.isNotEmpty) {
      (foundLookups, pipeline) = mergeLookups(
        lookups: normalizedLookups,
        existingPipeline: foundLookups ? pipeline : null,
        queryMap: foundLookups ? null : selector.cleaned(),
        sort: foundLookups ? null : firstEntryToTuple(sort),
        skip: foundLookups ? null : skip,
        limit: foundLookups ? null : limit,
      );
    }
    
    if(foundLookups){
      final collisionFreePipeline = withNoCollisions(pipeline);
      final $classNamePlural = await coll.aggregateToStream(collisionFreePipeline).toList();
      if ($classNamePlural.isEmpty) return [];
      return _${classNameVar}DeserializeDocuments($classNamePlural);
    }
    
    final $classNamePlural = await coll
        .modernFind(
          filter: selector.cleaned(),
          projection: canUseDirectProjection ? projDoc.cast<String, Object>() : null,
          limit: limit,
          skip: skip,
          sort: sort,
        )
        .toList();
    return _${classNameVar}DeserializeDocuments($classNamePlural);
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
  final coll = database.collection(_collection);

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

// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// Author: Wan Clem <wannclem@gmail.com>

part of 'token.dart';

// **************************************************************************
// MongoDocumentGenerator
// **************************************************************************

enum TokenFields {
  id,
  ownerEmail,
  token,
  data,
  reason,
  description,
  numberOfUpdates,
  expireAt,
  createdAt,
  updatedAt,
}

class TokenProjections implements BaseProjections {
  @override
  final List<TokenFields>? inclusions;
  final List<TokenFields>? exclusions;
  @override
  final Map<String, dynamic> fieldMappings = const {
    "id": "_id",
    "ownerEmail": "owner_email",
    "token": "token",
    "data": "data",
    "reason": "reason",
    "description": "description",
    "numberOfUpdates": "number_of_updates",
    "expireAt": "expire_at",
    "createdAt": "created_at",
    "updatedAt": "updated_at",
  };
  const TokenProjections({this.inclusions, this.exclusions});

  @override
  Map<String, int> toProjection() {
    return {
      '_id': 1,
      'owner_email': 1,
      'token': 1,
      'data': 1,
      'reason': 1,
      'description': 1,
      'number_of_updates': 1,
      'expire_at': 1,
      'created_at': 1,
      'updated_at': 1,
    };
  }
}

const _nestedCollections = <String, String>{};
const _tokenFieldMappings = <String, String>{
  'id': '_id',
  'ownerEmail': 'owner_email',
  'token': 'token',
  'data': 'data',
  'reason': 'reason',
  'description': 'description',
  'numberOfUpdates': 'number_of_updates',
  'expireAt': 'expire_at',
  'createdAt': 'created_at',
  'updatedAt': 'updated_at',
};
const _tokenCollection = 'tokens';
const _tokenTrackedPersistedKeys = <String>[
  'owner_email',
  'token',
  'data',
  'reason',
  'description',
  'number_of_updates',
  'expire_at',
  'created_at',
  'updated_at',
];

Map<String, dynamic> _tokenNormalizePersistedDocument(
  Map<String, dynamic> source,
) {
  final normalized = sanitizedDocument(Map<String, dynamic>.from(source));

  for (final entry in source.entries) {
    final root = entry.key;
    if (!_nestedCollections.containsKey(root)) continue;

    final value = entry.value;
    final rawNestedId =
        value is Map ? Map<String, dynamic>.from(value)['_id'] : value;
    final nestedId =
        rawNestedId is ObjectId
            ? rawNestedId
            : rawNestedId is String
            ? ObjectId.tryParse(rawNestedId)
            : null;

    if (nestedId == null) {
      normalized.remove(root);
    } else {
      normalized[root] = nestedId;
    }
  }

  return normalized;
}

void _rememberTokenSnapshot(Map<String, dynamic> document) {
  rememberMongoDocumentSnapshot(
    _tokenCollection,
    _tokenNormalizePersistedDocument(document),
  );
}

Token _tokenDeserializeDocument(Map<String, dynamic> document) {
  _rememberTokenSnapshot(document);
  return Token.fromJson(document.withRefs());
}

List<Token> _tokenDeserializeDocuments(
  Iterable<Map<String, dynamic>> documents,
) {
  return documents.map(_tokenDeserializeDocument).toList();
}

Map<String, dynamic>? _tokenSnapshotFor(ObjectId id) {
  return mongoDocumentSnapshot(_tokenCollection, id);
}

void _tokenForgetSnapshotFor(ObjectId id) {
  forgetMongoDocumentSnapshot(_tokenCollection, id);
}

class QToken {
  final String _prefix;
  QToken([this._prefix = '']);

  String _key(String field) => _prefix.isEmpty ? field : '$_prefix.$field';

  QueryField<ObjectId?> get id => QueryField<ObjectId?>(_key('_id'));

  QueryField<String?> get ownerEmail =>
      QueryField<String?>(_key('owner_email'));

  QueryField<String?> get token => QueryField<String?>(_key('token'));

  QMap<dynamic> get data => QMap<dynamic>(_key('data'));

  QueryField<String?> get reason => QueryField<String?>(_key('reason'));

  QueryField<String?> get description =>
      QueryField<String?>(_key('description'));

  QueryField<int?> get numberOfUpdates =>
      QueryField<int?>(_key('number_of_updates'));

  QueryField<DateTime?> get expireAt =>
      QueryField<DateTime?>(_key('expire_at'));

  QueryField<DateTime?> get createdAt =>
      QueryField<DateTime?>(_key('created_at'));

  QueryField<DateTime?> get updatedAt =>
      QueryField<DateTime?>(_key('updated_at'));
}

extension $TokenExtension on Token {
  static String get _collection => 'tokens';

  Future<Token?> save({Db? db}) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final now = DateTime.now().toUtc();
    final isInsert = id == null;

    final rawTokenMap = toJson()..remove('_id');
    final persistedTokenMap = _tokenNormalizePersistedDocument({
      ...rawTokenMap,
    });

    if (isInsert) {
      persistedTokenMap.update(
        'created_at',
        (value) => value ?? now,
        ifAbsent: () => now,
      );
      persistedTokenMap.update('updated_at', (_) => now, ifAbsent: () => now);

      final result = await coll.insertOne(persistedTokenMap);
      if (!result.isSuccess) return null;
      final savedDoc = await coll.modernFindOne(filter: {'_id': result.id});
      if (savedDoc == null) return null;
      return _tokenDeserializeDocument(savedDoc);
    }

    var snapshot = _tokenSnapshotFor(id!);
    snapshot ??= await coll.modernFindOne(filter: {'_id': id});
    if (snapshot == null) return null;
    snapshot = _tokenNormalizePersistedDocument(snapshot);

    final updateMap = buildMongoUpdateMapFromSnapshot(
      current: persistedTokenMap,
      snapshot: snapshot,
      trackedKeys: _tokenTrackedPersistedKeys,
    );

    if (updateMap.isEmpty) {
      final savedDoc = await coll.modernFindOne(filter: {'_id': id});
      if (savedDoc == null) return null;
      return _tokenDeserializeDocument(savedDoc);
    }

    var parentMod = modify.set('updated_at', now);
    updateMap.forEach((key, value) => parentMod = parentMod.set(key, value));
    final res = await coll.updateOne({'_id': id}, parentMod);
    if (!res.isSuccess) return null;
    final savedDoc = await coll.modernFindOne(filter: {'_id': id});
    if (savedDoc == null) return null;
    return _tokenDeserializeDocument(savedDoc);
  }

  Future<Token?> saveChanges({Db? db}) async {
    return save(db: db);
  }

  Future<bool> delete({Db? db}) async {
    if (id == null) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final res = await coll.deleteOne({'_id': id});
    if (res.isSuccess) {
      _tokenForgetSnapshotFor(id!);
    }
    return res.isSuccess;
  }
}

class Tokens {
  static String get _collection => 'tokens';
  static String get collection => _collection;

  static Future<List<Token?>> saveMany(List<Token> tokens, {Db? db}) async {
    if (tokens.isEmpty) return <Token>[];
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final now = DateTime.now().toUtc();
    final List<Map<String, dynamic>> toInsert = [];
    final List<Map<String, dynamic>> toSave = [];
    for (final t in tokens) {
      final json = _tokenNormalizePersistedDocument(t.toJson());
      final hasId = json.containsKey('_id') && json['_id'] != null;
      if (hasId) {
        json.update('updated_at', (_) => now, ifAbsent: () => now);
        toSave.add(json);
      } else {
        json
          ..remove('_id')
          ..update('created_at', (v) => v ?? now, ifAbsent: () => now)
          ..update('updated_at', (_) => now, ifAbsent: () => now);
        toInsert.add(json);
      }
    }
    final affectedIds = <dynamic>[];
    if (toInsert.isNotEmpty) {
      final insertResult = await coll.insertMany(toInsert);
      if (!insertResult.isSuccess || insertResult.ids == null) {
        return [];
      }
      affectedIds.addAll(insertResult.ids!);
    }
    for (final doc in toSave) {
      dynamic docId = doc['_id'];
      try {
        if (docId is String && docId.length == 24) {
          docId = ObjectId.fromHexString(docId);
        }
      } catch (_) {
        // ignore invalid conversion and let the driver handle it
      }
      if (docId == null) continue;
      final updateDoc = Map<String, dynamic>.from(doc)..remove('_id');
      var parentMod = modify.set('updated_at', now);
      updateDoc.forEach((k, v) => parentMod = parentMod.set(k, v));
      final updateResult = await coll.updateOne({'_id': docId}, parentMod);
      if (updateResult.isSuccess) {
        affectedIds.add(docId);
      }
    }
    final uniqueIds = <dynamic>[];
    for (final id in affectedIds) {
      if (id == null || uniqueIds.contains(id)) continue;
      uniqueIds.add(id);
    }
    if (uniqueIds.isEmpty) return <Token>[];
    final insertedDocs =
        await coll
            .modernFind(
              filter: {
                '_id': {r'$in': uniqueIds},
              },
            )
            .toList();
    final docsById = {for (final doc in insertedDocs) doc['_id']: doc};
    return uniqueIds
        .map((id) => docsById[id])
        .whereType<Map<String, dynamic>>()
        .map(_tokenDeserializeDocument)
        .toList();
  }

  static Future<Token?> findById(
    dynamic id, {
    Db? db,
    List<Lookup> lookups = const [],
    List<BaseProjections> projections = const [],
  }) async {
    if (id == null) return null;
    if (id is String) {
      final parsedId = ObjectId.tryParse(id);
      if (parsedId == null) {
        throw ArgumentError('Invalid id value: $id');
      }
      id = parsedId;
    }
    if (id is! ObjectId) {
      throw ArgumentError('Invalid id type: ${id.runtimeType}');
    }
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final normalizedLookups = remapLookups(lookups, _tokenFieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      TokenProjections(),
    );
    final projDoc =
        projections.isNotEmpty
            ? buildProjectionDoc(normalizedProjections)
            : null;

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
      final results =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (results.isEmpty) return null;
      return _tokenDeserializeDocument(results.first);
    }
    // fallback: return entire token
    final token = await coll.modernFindOne(filter: {'_id': id});
    return token == null ? null : _tokenDeserializeDocument(token);
  }

  /// Type-safe findOne by predicate
  static Future<Token?> findOne(
    Expression Function(QToken t)? predicate, {
    Db? db,
    List<Lookup> lookups = const [],
    List<BaseProjections> projections = const [],
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final normalizedLookups = remapLookups(lookups, _tokenFieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      TokenProjections(),
    );

    if (predicate == null) {
      final token = await coll.modernFindOne(sort: {'created_at': -1});
      if (token == null) return null;
      return _tokenDeserializeDocument(token);
    }

    final selectorBuilder = predicate(QToken()).toSelectorBuilder();
    final selectorMap = selectorBuilder.map;

    final projDoc =
        projections.isNotEmpty
            ? buildProjectionDoc(normalizedProjections)
            : null;

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
      final results =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (results.isEmpty) return null;
      return _tokenDeserializeDocument(results.first);
    }

    // fallback to simple findOne
    final tokenResult = await coll.modernFindOne(filter: selectorMap.cleaned());
    return tokenResult == null ? null : _tokenDeserializeDocument(tokenResult);
  }

  /// Type-safe findOne by named arguments
  static Future<Token?> findOneByNamed({
    ObjectId? id,
    String? ownerEmail,
    String? token,
    Map<String, dynamic>? data,
    String? reason,
    String? description,
    int? numberOfUpdates,
    DateTime? expireAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
    List<Lookup> lookups = const [],
    List<BaseProjections> projections = const [],
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final normalizedLookups = remapLookups(lookups, _tokenFieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      TokenProjections(),
    );

    final selector = <String, dynamic>{};

    if (id != null) selector['_id'] = id;
    if (ownerEmail != null) selector['owner_email'] = ownerEmail;
    if (token != null) selector['token'] = token;
    if (data != null) selector['data'] = data;
    if (reason != null) selector['reason'] = reason;
    if (description != null) selector['description'] = description;
    if (numberOfUpdates != null)
      selector['number_of_updates'] = numberOfUpdates;
    if (expireAt != null) selector['expire_at'] = expireAt;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty && projections.isEmpty && normalizedLookups.isEmpty) {
      final token = await coll.modernFindOne(sort: {'created_at': -1});
      if (token == null) return null;
      return _tokenDeserializeDocument(token);
    }

    final projDoc =
        projections.isNotEmpty
            ? buildProjectionDoc(normalizedProjections)
            : null;

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
      final tokens =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (tokens.isEmpty) return null;
      return _tokenDeserializeDocument(tokens.first);
    }

    final tokenResult = await coll.modernFindOne(
      filter: selector.cleaned(),
      sort: selector.isEmpty ? {'created_at': -1} : null,
    );
    return tokenResult == null ? null : _tokenDeserializeDocument(tokenResult);
  }

  /// Type-safe findMany by predicate
  static Future<List<Token>> findMany(
    Expression Function(QToken t) predicate, {
    List<Lookup> lookups = const [],
    int? skip,
    int limit = 10,
    (String, int) sort = const ("created_at", -1),
    List<BaseProjections> projections = const [],
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final normalizedLookups = remapLookups(lookups, _tokenFieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      TokenProjections(),
    );

    var selectorBuilder = predicate(QToken()).toSelectorBuilder();
    var selectorMap = selectorBuilder.map;

    final projDoc =
        projections.isNotEmpty
            ? buildProjectionDoc(normalizedProjections)
            : null;

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
      final tokens =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (tokens.isEmpty) return [];
      return _tokenDeserializeDocuments(tokens);
    }

    final tokens =
        await coll
            .modernFind(
              filter: selectorMap.cleaned(),
              sort: {sort.$1: sort.$2},
              skip: skip,
              limit: limit,
            )
            .toList();
    return _tokenDeserializeDocuments(tokens);
  }

  /// Type-safe findMany by named arguments
  static Future<List<Token>> findManyByNamed({
    ObjectId? id,
    String? ownerEmail,
    String? token,
    Map<String, dynamic>? data,
    String? reason,
    String? description,
    int? numberOfUpdates,
    DateTime? expireAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
    List<Lookup> lookups = const [],
    List<BaseProjections> projections = const [],
    Map<String, Object> sort = const {'created_at': -1},
    int? skip,
    int limit = 10,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final normalizedLookups = remapLookups(lookups, _tokenFieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      TokenProjections(),
    );

    final selector = <String, dynamic>{};

    if (id != null) selector['_id'] = id;
    if (ownerEmail != null) selector['owner_email'] = ownerEmail;
    if (token != null) selector['token'] = token;
    if (data != null) selector['data'] = data;
    if (reason != null) selector['reason'] = reason;
    if (description != null) selector['description'] = description;
    if (numberOfUpdates != null)
      selector['number_of_updates'] = numberOfUpdates;
    if (expireAt != null) selector['expire_at'] = expireAt;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;

    if (selector.isEmpty && projections.isEmpty && normalizedLookups.isEmpty) {
      final tokens =
          await coll.modernFind(sort: sort, limit: limit, skip: skip).toList();
      if (tokens.isEmpty) return [];
      return _tokenDeserializeDocuments(tokens);
    }

    final projDoc =
        projections.isNotEmpty
            ? buildProjectionDoc(normalizedProjections)
            : null;

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

    if (foundLookups) {
      final collisionFreePipeline = withNoCollisions(pipeline);
      final tokens =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (tokens.isEmpty) return [];
      return _tokenDeserializeDocuments(tokens);
    }

    final tokens =
        await coll
            .modernFind(filter: selector, limit: limit, skip: skip, sort: sort)
            .toList();
    return _tokenDeserializeDocuments(tokens);
  }

  static Future<bool> deleteOne(
    Expression Function(QToken t) predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final expr = predicate(QToken());
    final selector = expr.toSelectorBuilder();
    final coll = database.collection(_collection);
    final result = await coll.deleteOne(selector.map.cleaned());
    return result.isSuccess;
  }

  /// Type-safe deleteOne by named arguments
  static Future<bool> deleteOneByNamed({
    ObjectId? id,
    String? ownerEmail,
    String? token,
    Map<String, dynamic>? data,
    String? reason,
    String? description,
    int? numberOfUpdates,
    DateTime? expireAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (ownerEmail != null) selector['owner_email'] = ownerEmail;
    if (token != null) selector['token'] = token;
    if (data != null) selector['data'] = data;
    if (reason != null) selector['reason'] = reason;
    if (description != null) selector['description'] = description;
    if (numberOfUpdates != null)
      selector['number_of_updates'] = numberOfUpdates;
    if (expireAt != null) selector['expire_at'] = expireAt;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final result = await coll.deleteOne(selector);
    return result.isSuccess;
  }

  /// Type-safe deleteMany
  static Future<bool> deleteMany(
    Expression Function(QToken t) predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final expr = predicate(QToken());
    final selector = expr.toSelectorBuilder();
    final coll = database.collection(_collection);
    final result = await coll.deleteMany(selector.map.cleaned());
    return result.isSuccess;
  }

  /// Type-safe deleteMany by named arguments
  static Future<bool> deleteManyByNamed({
    ObjectId? id,
    String? ownerEmail,
    String? token,
    Map<String, dynamic>? data,
    String? reason,
    String? description,
    int? numberOfUpdates,
    DateTime? expireAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (ownerEmail != null) selector['owner_email'] = ownerEmail;
    if (token != null) selector['token'] = token;
    if (data != null) selector['data'] = data;
    if (reason != null) selector['reason'] = reason;
    if (description != null) selector['description'] = description;
    if (numberOfUpdates != null)
      selector['number_of_updates'] = numberOfUpdates;
    if (expireAt != null) selector['expire_at'] = expireAt;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final result = await coll.deleteMany(selector);
    return result.isSuccess;
  }

  /// Type-safe updateOne
  static Future<Token?> updateOne(
    Expression Function(QToken t) predicate, {
    ObjectId? id,
    String? ownerEmail,
    String? token,
    Map<String, dynamic>? data,
    String? reason,
    String? description,
    int? numberOfUpdates,
    DateTime? expireAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final modifier = _buildModifier(
      sanitizedDocument({
        if (ownerEmail != null) 'owner_email': ownerEmail,
        if (token != null) 'token': token,
        if (data != null) 'data': data,
        if (reason != null) 'reason': reason,
        if (description != null) 'description': description,
        if (numberOfUpdates != null) 'number_of_updates': numberOfUpdates,
        if (expireAt != null) 'expire_at': expireAt,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      }),
    );
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final selectorMap = predicate(QToken()).toSelectorBuilder().map.cleaned();
    final retrieved = await coll.modernFindOne(
      filter: selectorMap,
      projection: {'_id': 1},
    );
    if (retrieved == null) return null;
    final rawRetrievedId = retrieved['_id'];
    final retrievedId =
        rawRetrievedId is ObjectId
            ? rawRetrievedId
            : rawRetrievedId is String
            ? ObjectId.tryParse(rawRetrievedId)
            : null;
    if (retrievedId == null) return null;
    final result = await coll.updateOne({'_id': retrievedId}, modifier);
    if (!result.isSuccess) return null;
    final updatedDoc = await coll.modernFindOne(filter: {'_id': retrievedId});
    if (updatedDoc == null) return null;
    return _tokenDeserializeDocument(updatedDoc);
  }

  /// Type-safe updateMany
  static Future<List<Token>> updateMany(
    Expression Function(QToken t) predicate, {
    ObjectId? id,
    String? ownerEmail,
    String? token,
    Map<String, dynamic>? data,
    String? reason,
    String? description,
    int? numberOfUpdates,
    DateTime? expireAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final modifier = _buildModifier(
      sanitizedDocument({
        if (ownerEmail != null) 'owner_email': ownerEmail,
        if (token != null) 'token': token,
        if (data != null) 'data': data,
        if (reason != null) 'reason': reason,
        if (description != null) 'description': description,
        if (numberOfUpdates != null) 'number_of_updates': numberOfUpdates,
        if (expireAt != null) 'expire_at': expireAt,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      }),
    );
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final selectorMap = predicate(QToken()).toSelectorBuilder().map.cleaned();
    final retrieved =
        await coll
            .modernFind(filter: selectorMap, projection: {'_id': 1})
            .toList();
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
    final result = await coll.updateMany({
      '_id': {r'$in': ids},
    }, modifier);
    if (!result.isSuccess) return [];
    final updatedDocs =
        await coll
            .modernFind(
              filter: {
                '_id': {r'$in': ids},
              },
            )
            .toList();
    if (updatedDocs.isEmpty) return [];
    final docsById = {for (final doc in updatedDocs) doc['_id']: doc};
    return ids
        .map((id) => docsById[id])
        .whereType<Map<String, dynamic>>()
        .map(_tokenDeserializeDocument)
        .toList();
  }

  static ModifierBuilder _buildModifier(Map<String, dynamic> updateMap) {
    final now = DateTime.now().toUtc();
    final normalizedUpdateMap = Map<String, dynamic>.from(updateMap)
      ..remove('_id');
    var modifier = modify.set('updated_at', now);
    normalizedUpdateMap.forEach((k, v) => modifier = modifier.set(k, v));
    return modifier;
  }

  /// Prioritize `updateOne` whenever possible to avoid type mismatch.
  /// This method is a fallback for cases where you just had to use a map.
  static Future<Token?> updateOneFromMap(
    ObjectId id,
    Map<String, dynamic> updateMap, {
    Db? db,
  }) async {
    final mod = _buildModifier(
      sanitizedDocument(updateMap.withValidObjectReferences()),
    );
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final result = await coll.updateOne({'_id': id}, mod);
    if (!result.isSuccess) return null;
    final updatedDoc = await coll.modernFindOne(filter: {'_id': id});
    return updatedDoc == null ? null : _tokenDeserializeDocument(updatedDoc);
  }

  static Future<int> count(
    Expression Function(QToken t)? predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);

    final selectorMap =
        predicate == null
            ? <String, dynamic>{}
            : predicate(QToken()).toSelectorBuilder().map;

    final (foundLookups, pipelineWithoutCount) = toAggregationPipelineWithMap(
      lookupRef: _nestedCollections,
      raw: selectorMap.raw(),
      cleaned: selectorMap.cleaned(),
    );

    if (foundLookups) {
      final pipeline = [
        ...pipelineWithoutCount,
        {r'$count': 'count'},
      ];

      final result = await coll.aggregateToStream(pipeline).toList();
      if (result.isEmpty) return 0;
      return result.first['count'] as int;
    }

    return await coll.count(selectorMap.cleaned());
  }
}

// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// Author: Wan Clem <wannclem@gmail.com>

part of 'vanilla_user.dart';

// **************************************************************************
// MongoDocumentGenerator
// **************************************************************************

enum VanillaUserFields { id, firstName, lastName }

class VanillaUserProjections implements BaseProjections {
  @override
  final List<VanillaUserFields>? inclusions;
  final List<VanillaUserFields>? exclusions;
  @override
  final Map<String, dynamic> fieldMappings = const {
    "id": "_id",
    "firstName": "first_name",
    "lastName": "last_name",
  };
  const VanillaUserProjections({this.inclusions, this.exclusions});

  @override
  Map<String, int> toProjection() {
    return {'_id': 1, 'first_name': 1, 'last_name': 1};
  }
}

const _nestedCollections = <String, String>{};
const _vanillaUserFieldMappings = <String, String>{
  'id': '_id',
  'firstName': 'first_name',
  'lastName': 'last_name',
};
const _vanillaUserCollection = 'vanilla_users';
const _vanillaUserTrackedPersistedKeys = <String>['first_name', 'last_name'];

Map<String, dynamic> _vanillaUserNormalizePersistedDocument(
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

void _rememberVanillaUserSnapshot(Map<String, dynamic> document) {
  rememberMongoDocumentSnapshot(
    _vanillaUserCollection,
    _vanillaUserNormalizePersistedDocument(document),
  );
}

VanillaUser _vanillaUserDeserializeDocument(Map<String, dynamic> document) {
  _rememberVanillaUserSnapshot(document);
  return VanillaUser.fromJson(document.withRefs());
}

List<VanillaUser> _vanillaUserDeserializeDocuments(
  Iterable<Map<String, dynamic>> documents,
) {
  return documents.map(_vanillaUserDeserializeDocument).toList();
}

Map<String, dynamic>? _vanillaUserSnapshotFor(ObjectId id) {
  return mongoDocumentSnapshot(_vanillaUserCollection, id);
}

void _vanillaUserForgetSnapshotFor(ObjectId id) {
  forgetMongoDocumentSnapshot(_vanillaUserCollection, id);
}

class QVanillaUser {
  final String _prefix;
  QVanillaUser([this._prefix = '']);

  String _key(String field) => _prefix.isEmpty ? field : '$_prefix.$field';

  QueryField<ObjectId?> get id => QueryField<ObjectId?>(_key('_id'));

  QueryField<String?> get firstName => QueryField<String?>(_key('first_name'));

  QueryField<String?> get lastName => QueryField<String?>(_key('last_name'));
}

extension $VanillaUserExtension on VanillaUser {
  static String get _collection => 'vanilla_users';

  Future<VanillaUser?> save({Db? db}) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final now = DateTime.now().toUtc();
    final isInsert = id == null;

    final rawVanillaUserMap = toJson()..remove('_id');
    final persistedVanillaUserMap = _vanillaUserNormalizePersistedDocument({
      ...rawVanillaUserMap,
    });

    if (isInsert) {
      persistedVanillaUserMap.update(
        'created_at',
        (value) => value ?? now,
        ifAbsent: () => now,
      );
      persistedVanillaUserMap.update(
        'updated_at',
        (_) => now,
        ifAbsent: () => now,
      );

      final result = await coll.insertOne(persistedVanillaUserMap);
      if (!result.isSuccess) return null;
      final savedDoc = await coll.modernFindOne(filter: {'_id': result.id});
      if (savedDoc == null) return null;
      return _vanillaUserDeserializeDocument(savedDoc);
    }

    var snapshot = _vanillaUserSnapshotFor(id!);
    snapshot ??= await coll.modernFindOne(filter: {'_id': id});
    if (snapshot == null) return null;
    snapshot = _vanillaUserNormalizePersistedDocument(snapshot);

    final updateMap = buildMongoUpdateMapFromSnapshot(
      current: persistedVanillaUserMap,
      snapshot: snapshot,
      trackedKeys: _vanillaUserTrackedPersistedKeys,
    );

    if (updateMap.isEmpty) {
      final savedDoc = await coll.modernFindOne(filter: {'_id': id});
      if (savedDoc == null) return null;
      return _vanillaUserDeserializeDocument(savedDoc);
    }

    var parentMod = modify.set('updated_at', now);
    updateMap.forEach((key, value) => parentMod = parentMod.set(key, value));
    final res = await coll.updateOne({'_id': id}, parentMod);
    if (!res.isSuccess) return null;
    final savedDoc = await coll.modernFindOne(filter: {'_id': id});
    if (savedDoc == null) return null;
    return _vanillaUserDeserializeDocument(savedDoc);
  }

  Future<VanillaUser?> saveChanges({Db? db}) async {
    return save(db: db);
  }

  Future<bool> delete({Db? db}) async {
    if (id == null) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final res = await coll.deleteOne({'_id': id});
    if (res.isSuccess) {
      _vanillaUserForgetSnapshotFor(id!);
    }
    return res.isSuccess;
  }
}

class VanillaUsers {
  static String get _collection => 'vanilla_users';
  static String get collection => _collection;

  static Future<List<VanillaUser?>> saveMany(
    List<VanillaUser> vanillaUsers, {
    Db? db,
  }) async {
    if (vanillaUsers.isEmpty) return <VanillaUser>[];
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final now = DateTime.now().toUtc();
    final List<Map<String, dynamic>> toInsert = [];
    final List<Map<String, dynamic>> toSave = [];
    for (final v in vanillaUsers) {
      final json = _vanillaUserNormalizePersistedDocument(v.toJson());
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
    if (uniqueIds.isEmpty) return <VanillaUser>[];
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
        .map(_vanillaUserDeserializeDocument)
        .toList();
  }

  static Future<VanillaUser?> findById(
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
    final normalizedLookups = remapLookups(lookups, _vanillaUserFieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      VanillaUserProjections(),
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
      return _vanillaUserDeserializeDocument(results.first);
    }
    // fallback: return entire vanillaUser
    final vanillaUser = await coll.modernFindOne(filter: {'_id': id});
    return vanillaUser == null
        ? null
        : _vanillaUserDeserializeDocument(vanillaUser);
  }

  /// Type-safe findOne by predicate
  static Future<VanillaUser?> findOne(
    Expression Function(QVanillaUser v)? predicate, {
    Db? db,
    List<Lookup> lookups = const [],
    List<BaseProjections> projections = const [],
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final normalizedLookups = remapLookups(lookups, _vanillaUserFieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      VanillaUserProjections(),
    );

    if (predicate == null) {
      final vanillaUser = await coll.modernFindOne(sort: {'created_at': -1});
      if (vanillaUser == null) return null;
      return _vanillaUserDeserializeDocument(vanillaUser);
    }

    final selectorBuilder = predicate(QVanillaUser()).toSelectorBuilder();
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
      return _vanillaUserDeserializeDocument(results.first);
    }

    // fallback to simple findOne
    final vanillaUserResult = await coll.modernFindOne(
      filter: selectorMap.cleaned(),
    );
    return vanillaUserResult == null
        ? null
        : _vanillaUserDeserializeDocument(vanillaUserResult);
  }

  /// Type-safe findOne by named arguments
  static Future<VanillaUser?> findOneByNamed({
    ObjectId? id,
    String? firstName,
    String? lastName,
    Db? db,
    List<Lookup> lookups = const [],
    List<BaseProjections> projections = const [],
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final normalizedLookups = remapLookups(lookups, _vanillaUserFieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      VanillaUserProjections(),
    );

    final selector = <String, dynamic>{};

    if (id != null) selector['_id'] = id;
    if (firstName != null) selector['first_name'] = firstName;
    if (lastName != null) selector['last_name'] = lastName;
    if (selector.isEmpty && projections.isEmpty && normalizedLookups.isEmpty) {
      final vanillaUser = await coll.modernFindOne(sort: {'created_at': -1});
      if (vanillaUser == null) return null;
      return _vanillaUserDeserializeDocument(vanillaUser);
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
      final vanillaUsers =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (vanillaUsers.isEmpty) return null;
      return _vanillaUserDeserializeDocument(vanillaUsers.first);
    }

    final vanillaUserResult = await coll.modernFindOne(
      filter: selector.cleaned(),
      sort: selector.isEmpty ? {'created_at': -1} : null,
    );
    return vanillaUserResult == null
        ? null
        : _vanillaUserDeserializeDocument(vanillaUserResult);
  }

  /// Type-safe findMany by predicate
  static Future<List<VanillaUser>> findMany(
    Expression Function(QVanillaUser v) predicate, {
    List<Lookup> lookups = const [],
    int? skip,
    int limit = 10,
    (String, int) sort = const ("created_at", -1),
    List<BaseProjections> projections = const [],
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final normalizedLookups = remapLookups(lookups, _vanillaUserFieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      VanillaUserProjections(),
    );

    var selectorBuilder = predicate(QVanillaUser()).toSelectorBuilder();
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
      final vanillaUsers =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (vanillaUsers.isEmpty) return [];
      return _vanillaUserDeserializeDocuments(vanillaUsers);
    }

    final vanillaUsers =
        await coll
            .modernFind(
              filter: selectorMap.cleaned(),
              sort: {sort.$1: sort.$2},
              skip: skip,
              limit: limit,
            )
            .toList();
    return _vanillaUserDeserializeDocuments(vanillaUsers);
  }

  /// Type-safe findMany by named arguments
  static Future<List<VanillaUser>> findManyByNamed({
    ObjectId? id,
    String? firstName,
    String? lastName,
    Db? db,
    List<Lookup> lookups = const [],
    List<BaseProjections> projections = const [],
    Map<String, Object> sort = const {'created_at': -1},
    int? skip,
    int limit = 10,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final normalizedLookups = remapLookups(lookups, _vanillaUserFieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      VanillaUserProjections(),
    );

    final selector = <String, dynamic>{};

    if (id != null) selector['_id'] = id;
    if (firstName != null) selector['first_name'] = firstName;
    if (lastName != null) selector['last_name'] = lastName;

    if (selector.isEmpty && projections.isEmpty && normalizedLookups.isEmpty) {
      final vanillaUsers =
          await coll.modernFind(sort: sort, limit: limit, skip: skip).toList();
      if (vanillaUsers.isEmpty) return [];
      return _vanillaUserDeserializeDocuments(vanillaUsers);
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
      final vanillaUsers =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (vanillaUsers.isEmpty) return [];
      return _vanillaUserDeserializeDocuments(vanillaUsers);
    }

    final vanillaUsers =
        await coll
            .modernFind(filter: selector, limit: limit, skip: skip, sort: sort)
            .toList();
    return _vanillaUserDeserializeDocuments(vanillaUsers);
  }

  static Future<bool> deleteOne(
    Expression Function(QVanillaUser v) predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final expr = predicate(QVanillaUser());
    final selector = expr.toSelectorBuilder();
    final coll = database.collection(_collection);
    final result = await coll.deleteOne(selector.map.cleaned());
    return result.isSuccess;
  }

  /// Type-safe deleteOne by named arguments
  static Future<bool> deleteOneByNamed({
    ObjectId? id,
    String? firstName,
    String? lastName,
    Db? db,
  }) async {
    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (firstName != null) selector['first_name'] = firstName;
    if (lastName != null) selector['last_name'] = lastName;
    if (selector.isEmpty) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final result = await coll.deleteOne(selector);
    return result.isSuccess;
  }

  /// Type-safe deleteMany
  static Future<bool> deleteMany(
    Expression Function(QVanillaUser v) predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final expr = predicate(QVanillaUser());
    final selector = expr.toSelectorBuilder();
    final coll = database.collection(_collection);
    final result = await coll.deleteMany(selector.map.cleaned());
    return result.isSuccess;
  }

  /// Type-safe deleteMany by named arguments
  static Future<bool> deleteManyByNamed({
    ObjectId? id,
    String? firstName,
    String? lastName,
    Db? db,
  }) async {
    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (firstName != null) selector['first_name'] = firstName;
    if (lastName != null) selector['last_name'] = lastName;
    if (selector.isEmpty) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final result = await coll.deleteMany(selector);
    return result.isSuccess;
  }

  /// Type-safe updateOne
  static Future<VanillaUser?> updateOne(
    Expression Function(QVanillaUser v) predicate, {
    ObjectId? id,
    String? firstName,
    String? lastName,
    Db? db,
  }) async {
    final modifier = _buildModifier(
      sanitizedDocument({
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
      }),
    );
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final selectorMap =
        predicate(QVanillaUser()).toSelectorBuilder().map.cleaned();
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
    return _vanillaUserDeserializeDocument(updatedDoc);
  }

  /// Type-safe updateMany
  static Future<List<VanillaUser>> updateMany(
    Expression Function(QVanillaUser v) predicate, {
    ObjectId? id,
    String? firstName,
    String? lastName,
    Db? db,
  }) async {
    final modifier = _buildModifier(
      sanitizedDocument({
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
      }),
    );
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final selectorMap =
        predicate(QVanillaUser()).toSelectorBuilder().map.cleaned();
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
        .map(_vanillaUserDeserializeDocument)
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
  static Future<VanillaUser?> updateOneFromMap(
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
    return updatedDoc == null
        ? null
        : _vanillaUserDeserializeDocument(updatedDoc);
  }

  static Future<int> count(
    Expression Function(QVanillaUser v)? predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);

    final selectorMap =
        predicate == null
            ? <String, dynamic>{}
            : predicate(QVanillaUser()).toSelectorBuilder().map;

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

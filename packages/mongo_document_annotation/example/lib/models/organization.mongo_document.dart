// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// Author: Wan Clem <wannclem@gmail.com>

part of 'organization.dart';

// **************************************************************************
// MongoDocumentGenerator
// **************************************************************************

enum OrganizationFields {
  id,
  tempId,
  name,
  avatar,
  ephemeralData,
  active,
  createdAt,
  updatedAt,
}

class OrganizationProjections implements BaseProjections {
  @override
  final List<OrganizationFields>? inclusions;
  final List<OrganizationFields>? exclusions;
  @override
  final Map<String, dynamic> fieldMappings = const {
    "id": "_id",
    "tempId": "temp_id",
    "name": "name",
    "avatar": "avatar",
    "ephemeralData": "ephemeral_data",
    "active": "active",
    "createdAt": "created_at",
    "updatedAt": "updated_at",
  };
  const OrganizationProjections({this.inclusions, this.exclusions});

  @override
  Map<String, int> toProjection() {
    return {
      '_id': 1,
      'temp_id': 1,
      'name': 1,
      'avatar': 1,
      'ephemeral_data': 1,
      'active': 1,
      'created_at': 1,
      'updated_at': 1,
    };
  }
}

const _nestedCollections = <String, String>{'owner': 'accounts'};
const _organizationFieldMappings = <String, String>{
  'id': '_id',
  'tempId': 'temp_id',
  'owner': 'owner',
  'name': 'name',
  'avatar': 'avatar',
  'ephemeralData': 'ephemeral_data',
  'active': 'active',
  'createdAt': 'created_at',
  'updatedAt': 'updated_at',
};
const _organizationCollection = 'organizations';
const _organizationRefFields = <String>{'owner'};
const _organizationObjectIdFields = <String>{};
const _organizationTrackedPersistedKeys = <String>[
  'temp_id',
  'owner',
  'name',
  'avatar',
  'ephemeral_data',
  'active',
  'created_at',
  'updated_at',
];

Map<String, dynamic> _organizationNormalizePersistedDocument(
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

  for (final key in _organizationObjectIdFields) {
    if (!source.containsKey(key)) continue;

    final value = source[key];
    final rawId =
        value is Map ? Map<String, dynamic>.from(value)['_id'] : value;
    final objectId =
        rawId is ObjectId
            ? rawId
            : rawId is String
            ? ObjectId.tryParse(rawId)
            : null;

    if (objectId != null) {
      normalized[key] = objectId;
    } else {
      normalized[key] = value;
    }
  }

  return normalized;
}

void _rememberOrganizationSnapshot(Map<String, dynamic> document) {
  rememberMongoDocumentSnapshot(
    _organizationCollection,
    _organizationNormalizePersistedDocument(document),
  );
}

Organization _organizationDeserializeDocument(Map<String, dynamic> document) {
  _rememberOrganizationSnapshot(document);
  return Organization.fromJson(
    document.withRefs(
      refFields: _organizationRefFields,
      objectIdFields: _organizationObjectIdFields,
    ),
  );
}

List<Organization> _organizationDeserializeDocuments(
  Iterable<Map<String, dynamic>> documents,
) {
  return documents.map(_organizationDeserializeDocument).toList();
}

Map<String, dynamic>? _organizationSnapshotFor(ObjectId id) {
  return mongoDocumentSnapshot(_organizationCollection, id);
}

ObjectId? _organizationCoerceDocumentId(dynamic rawId) {
  if (rawId is ObjectId) return rawId;
  if (rawId is String) return ObjectId.tryParse(rawId);
  return null;
}

void _organizationForgetSnapshotFor(ObjectId id) {
  forgetMongoDocumentSnapshot(_organizationCollection, id);
}

enum OrganizationOwnerFields {
  id,
  firstName,
  lastName,
  email,
  password,
  createdAt,
  updatedAt,
}

class OrganizationOwnerProjections implements BaseProjections {
  @override
  final List<OrganizationOwnerFields>? inclusions;
  final List<OrganizationOwnerFields>? exclusions;
  @override
  final Map<String, dynamic> fieldMappings = const {
    "id": "owner._id",
    "firstName": "owner.first_name",
    "lastName": "owner.last_name",
    "email": "owner.email",
    "password": "owner.password",
    "createdAt": "owner.created_at",
    "updatedAt": "owner.updated_at",
  };
  const OrganizationOwnerProjections({this.inclusions, this.exclusions});

  @override
  Map<String, int> toProjection() {
    return {
      'owner._id': 1,
      'owner.first_name': 1,
      'owner.last_name': 1,
      'owner.email': 1,
      'owner.password': 1,
      'owner.created_at': 1,
      'owner.updated_at': 1,
    };
  }
}

class QOrganization {
  final String _prefix;
  QOrganization([this._prefix = '']);

  String _key(String field) => _prefix.isEmpty ? field : '$_prefix.$field';

  QueryField<ObjectId?> get id => QueryField<ObjectId?>(_key('_id'));

  QueryField<String?> get tempId => QueryField<String?>(_key('temp_id'));

  QUser get owner => QUser(_key('owner'));

  QueryField<String?> get name => QueryField<String?>(_key('name'));

  QueryField<dynamic> get avatar => QueryField<dynamic>(_key('avatar'));

  QMap<dynamic> get ephemeralData => QMap<dynamic>(_key('ephemeral_data'));

  QueryField<bool> get active => QueryField<bool>(_key('active'));

  QueryField<DateTime?> get createdAt =>
      QueryField<DateTime?>(_key('created_at'));

  QueryField<DateTime?> get updatedAt =>
      QueryField<DateTime?>(_key('updated_at'));
}

extension $OrganizationExtension on Organization {
  static String get _collection => 'organizations';

  Future<Organization?> save({Db? db}) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final now = DateTime.now().toUtc();
    final isInsert = id == null;

    final rawOrganizationMap = toJson()..remove('_id');
    final persistedOrganizationMap = _organizationNormalizePersistedDocument({
      ...rawOrganizationMap,
    });

    if (isInsert) {
      persistedOrganizationMap.update(
        'created_at',
        (value) => value ?? now,
        ifAbsent: () => now,
      );
      persistedOrganizationMap.update(
        'updated_at',
        (_) => now,
        ifAbsent: () => now,
      );

      final result = await coll.insertOne(persistedOrganizationMap);
      if (!result.isSuccess) return null;
      final savedDoc = await coll.modernFindOne(filter: {'_id': result.id});
      if (savedDoc == null) return null;
      return _organizationDeserializeDocument(savedDoc);
    }

    var snapshot = _organizationSnapshotFor(id!);
    snapshot ??= await coll.modernFindOne(filter: {'_id': id});
    if (snapshot == null) return null;
    snapshot = _organizationNormalizePersistedDocument(snapshot);

    final updateMap = buildMongoUpdateMapFromSnapshot(
      current: persistedOrganizationMap,
      snapshot: snapshot,
      trackedKeys: _organizationTrackedPersistedKeys,
    );

    if (updateMap.isEmpty) {
      final savedDoc = await coll.modernFindOne(filter: {'_id': id});
      if (savedDoc == null) return null;
      return _organizationDeserializeDocument(savedDoc);
    }

    var parentMod = modify.set('updated_at', now);
    updateMap.forEach((key, value) => parentMod = parentMod.set(key, value));
    final res = await coll.updateOne({'_id': id}, parentMod);
    if (!res.isSuccess) return null;
    final savedDoc = await coll.modernFindOne(filter: {'_id': id});
    if (savedDoc == null) return null;
    return _organizationDeserializeDocument(savedDoc);
  }

  Future<Organization?> saveChanges({Db? db}) async {
    return save(db: db);
  }

  Future<bool> delete({Db? db}) async {
    if (id == null) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final res = await coll.deleteOne({'_id': id});
    if (res.isSuccess) {
      _organizationForgetSnapshotFor(id!);
    }
    return res.isSuccess;
  }
}

class Organizations {
  static String get _collection => 'organizations';
  static String get collection => _collection;

  static Future<List<Organization?>> saveMany(
    List<Organization> organizations, {
    Db? db,
  }) async {
    if (organizations.isEmpty) return <Organization>[];
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final now = DateTime.now().toUtc();
    final List<Map<String, dynamic>> toInsert = [];
    final List<(int, Map<String, dynamic>)> toSave = [];
    final orderedIds = List<dynamic>.filled(organizations.length, null);
    final insertPositions = <int>[];
    for (int index = 0; index < organizations.length; index++) {
      final item = organizations[index];
      final json = _organizationNormalizePersistedDocument(item.toJson());
      final hasId = json.containsKey('_id') && json['_id'] != null;
      if (hasId) {
        json.update('updated_at', (_) => now, ifAbsent: () => now);
        toSave.add((index, json));
      } else {
        json
          ..remove('_id')
          ..update('created_at', (v) => v ?? now, ifAbsent: () => now)
          ..update('updated_at', (_) => now, ifAbsent: () => now);
        toInsert.add(json);
        insertPositions.add(index);
      }
    }
    if (toInsert.isNotEmpty) {
      final insertResult = await coll.insertMany(toInsert);
      if (!insertResult.isSuccess || insertResult.ids == null) {
        return [];
      }
      for (
        int insertIndex = 0;
        insertIndex < insertResult.ids!.length &&
            insertIndex < insertPositions.length;
        insertIndex++
      ) {
        orderedIds[insertPositions[insertIndex]] =
            insertResult.ids![insertIndex];
      }
    }
    final missingSnapshotIds = <ObjectId>[];
    for (final entry in toSave) {
      final docId = _organizationCoerceDocumentId(entry.$2['_id']);
      if (docId == null) continue;
      if (_organizationSnapshotFor(docId) == null) {
        missingSnapshotIds.add(docId);
      }
    }
    final uniqueMissingSnapshotIds = <ObjectId>[];
    for (final id in missingSnapshotIds) {
      if (!uniqueMissingSnapshotIds.contains(id)) {
        uniqueMissingSnapshotIds.add(id);
      }
    }
    final fetchedSnapshotsById = <ObjectId, Map<String, dynamic>>{};
    if (uniqueMissingSnapshotIds.isNotEmpty) {
      final fetchedSnapshots =
          await coll
              .modernFind(
                filter: {
                  '_id': {r'$in': uniqueMissingSnapshotIds},
                },
              )
              .toList();
      rememberMongoDocumentSnapshots(_organizationCollection, fetchedSnapshots);
      for (final snapshot in fetchedSnapshots) {
        final snapshotId = _organizationCoerceDocumentId(snapshot['_id']);
        if (snapshotId == null) continue;
        fetchedSnapshotsById[snapshotId] =
            _organizationNormalizePersistedDocument(snapshot);
      }
    }
    for (final entry in toSave) {
      final position = entry.$1;
      final doc = entry.$2;
      final docId = _organizationCoerceDocumentId(doc['_id']);
      if (docId == null) continue;
      final updateDoc = Map<String, dynamic>.from(doc)..remove('_id');
      var snapshot =
          _organizationSnapshotFor(docId) ?? fetchedSnapshotsById[docId];
      if (snapshot == null) continue;
      snapshot = _organizationNormalizePersistedDocument(snapshot);
      final updateMap = buildMongoUpdateMapFromSnapshot(
        current: updateDoc,
        snapshot: snapshot,
        trackedKeys: _organizationTrackedPersistedKeys,
      );
      if (updateMap.isEmpty) {
        orderedIds[position] = docId;
        continue;
      }
      var parentMod = modify.set('updated_at', now);
      updateMap.forEach((k, v) => parentMod = parentMod.set(k, v));
      final updateResult = await coll.updateOne({'_id': docId}, parentMod);
      if (updateResult.isSuccess) {
        orderedIds[position] = docId;
      }
    }
    final uniqueIds = <dynamic>[];
    for (final id in orderedIds) {
      if (id == null || uniqueIds.contains(id)) continue;
      uniqueIds.add(id);
    }
    if (uniqueIds.isEmpty) return <Organization>[];
    final insertedDocs =
        await coll
            .modernFind(
              filter: {
                '_id': {r'$in': uniqueIds},
              },
            )
            .toList();
    final docsById = {for (final doc in insertedDocs) doc['_id']: doc};
    return orderedIds
        .map((id) => id == null ? null : docsById[id])
        .map(
          (doc) => doc == null ? null : _organizationDeserializeDocument(doc),
        )
        .toList();
  }

  static Future<Organization?> findById(
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
    final normalizedLookups = remapLookups(lookups, _organizationFieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      OrganizationProjections(),
    );
    final projDoc =
        projections.isNotEmpty
            ? buildProjectionDoc(normalizedProjections)
            : null;
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
      final results =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (results.isEmpty) return null;
      return _organizationDeserializeDocument(results.first);
    }
    // fallback: return entire organization
    final organization = await coll.modernFindOne(
      filter: {'_id': id},
      projection:
          canUseDirectProjection ? projDoc.cast<String, Object>() : null,
    );
    return organization == null
        ? null
        : _organizationDeserializeDocument(organization);
  }

  /// Type-safe findOne by predicate
  static Future<Organization?> findOne(
    Expression Function(QOrganization o)? predicate, {
    Db? db,
    List<Lookup> lookups = const [],
    List<BaseProjections> projections = const [],
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final normalizedLookups = remapLookups(lookups, _organizationFieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      OrganizationProjections(),
    );

    if (predicate == null) {
      final organization = await coll.modernFindOne(sort: {'created_at': -1});
      if (organization == null) return null;
      return _organizationDeserializeDocument(organization);
    }

    final selectorBuilder = predicate(QOrganization()).toSelectorBuilder();
    final selectorMap = selectorBuilder.map;

    final projDoc =
        projections.isNotEmpty
            ? buildProjectionDoc(normalizedProjections)
            : null;
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
      final results =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (results.isEmpty) return null;
      return _organizationDeserializeDocument(results.first);
    }

    // fallback to simple findOne
    final organizationResult = await coll.modernFindOne(
      filter: selectorMap.cleaned(),
      projection:
          canUseDirectProjection ? projDoc.cast<String, Object>() : null,
    );
    return organizationResult == null
        ? null
        : _organizationDeserializeDocument(organizationResult);
  }

  /// Type-safe findOne by named arguments
  static Future<Organization?> findOneByNamed({
    ObjectId? id,
    String? tempId,
    User? owner,
    String? name,
    dynamic avatar,
    Map<String, dynamic>? ephemeralData,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
    List<Lookup> lookups = const [],
    List<BaseProjections> projections = const [],
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final normalizedLookups = remapLookups(lookups, _organizationFieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      OrganizationProjections(),
    );

    final selector = <String, dynamic>{};

    if (id != null) selector['_id'] = id;
    if (tempId != null) selector['temp_id'] = tempId;
    if (owner != null) selector['owner'] = owner.id;
    if (name != null) selector['name'] = name;
    if (avatar != null) selector['avatar'] = avatar;
    if (ephemeralData != null) selector['ephemeral_data'] = ephemeralData;
    if (active != null) selector['active'] = active;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty && projections.isEmpty && normalizedLookups.isEmpty) {
      final organization = await coll.modernFindOne(sort: {'created_at': -1});
      if (organization == null) return null;
      return _organizationDeserializeDocument(organization);
    }

    final projDoc =
        projections.isNotEmpty
            ? buildProjectionDoc(normalizedProjections)
            : null;
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
      final organizations =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (organizations.isEmpty) return null;
      return _organizationDeserializeDocument(organizations.first);
    }

    final organizationResult = await coll.modernFindOne(
      filter: selector.cleaned(),
      sort: selector.isEmpty ? {'created_at': -1} : null,
      projection:
          canUseDirectProjection ? projDoc.cast<String, Object>() : null,
    );
    return organizationResult == null
        ? null
        : _organizationDeserializeDocument(organizationResult);
  }

  /// Type-safe findMany by predicate
  static Future<List<Organization>> findMany(
    Expression Function(QOrganization o) predicate, {
    List<Lookup> lookups = const [],
    int? skip,
    int limit = 10,
    (String, int) sort = const ("created_at", -1),
    List<BaseProjections> projections = const [],
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final normalizedLookups = remapLookups(lookups, _organizationFieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      OrganizationProjections(),
    );

    var selectorBuilder = predicate(QOrganization()).toSelectorBuilder();
    var selectorMap = selectorBuilder.map;

    final projDoc =
        projections.isNotEmpty
            ? buildProjectionDoc(normalizedProjections)
            : null;
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
      final organizations =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (organizations.isEmpty) return [];
      return _organizationDeserializeDocuments(organizations);
    }

    final organizations =
        await coll
            .modernFind(
              filter: selectorMap.cleaned(),
              sort: {sort.$1: sort.$2},
              projection:
                  canUseDirectProjection
                      ? projDoc.cast<String, Object>()
                      : null,
              skip: skip,
              limit: limit,
            )
            .toList();
    return _organizationDeserializeDocuments(organizations);
  }

  /// Type-safe findMany by named arguments
  static Future<List<Organization>> findManyByNamed({
    ObjectId? id,
    String? tempId,
    User? owner,
    String? name,
    dynamic avatar,
    Map<String, dynamic>? ephemeralData,
    bool? active,
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
    final normalizedLookups = remapLookups(lookups, _organizationFieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      OrganizationProjections(),
    );

    final selector = <String, dynamic>{};

    if (id != null) selector['_id'] = id;
    if (tempId != null) selector['temp_id'] = tempId;
    if (owner != null) selector['owner'] = owner.id;
    if (name != null) selector['name'] = name;
    if (avatar != null) selector['avatar'] = avatar;
    if (ephemeralData != null) selector['ephemeral_data'] = ephemeralData;
    if (active != null) selector['active'] = active;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;

    if (selector.isEmpty && projections.isEmpty && normalizedLookups.isEmpty) {
      final organizations =
          await coll.modernFind(sort: sort, limit: limit, skip: skip).toList();
      if (organizations.isEmpty) return [];
      return _organizationDeserializeDocuments(organizations);
    }

    final projDoc =
        projections.isNotEmpty
            ? buildProjectionDoc(normalizedProjections)
            : null;
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

    if (foundLookups) {
      final collisionFreePipeline = withNoCollisions(pipeline);
      final organizations =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (organizations.isEmpty) return [];
      return _organizationDeserializeDocuments(organizations);
    }

    final organizations =
        await coll
            .modernFind(
              filter: selector.cleaned(),
              projection:
                  canUseDirectProjection
                      ? projDoc.cast<String, Object>()
                      : null,
              limit: limit,
              skip: skip,
              sort: sort,
            )
            .toList();
    return _organizationDeserializeDocuments(organizations);
  }

  static Future<bool> deleteOne(
    Expression Function(QOrganization o) predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final expr = predicate(QOrganization());
    final selector = expr.toSelectorBuilder();
    final coll = database.collection(_collection);
    final result = await coll.deleteOne(selector.map.cleaned());
    return result.isSuccess;
  }

  /// Type-safe deleteOne by named arguments
  static Future<bool> deleteOneByNamed({
    ObjectId? id,
    String? tempId,
    User? owner,
    String? name,
    dynamic avatar,
    Map<String, dynamic>? ephemeralData,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (tempId != null) selector['temp_id'] = tempId;
    if (owner != null) selector['owner'] = owner.id;
    if (name != null) selector['name'] = name;
    if (avatar != null) selector['avatar'] = avatar;
    if (ephemeralData != null) selector['ephemeral_data'] = ephemeralData;
    if (active != null) selector['active'] = active;
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
    Expression Function(QOrganization o) predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final expr = predicate(QOrganization());
    final selector = expr.toSelectorBuilder();
    final coll = database.collection(_collection);
    final result = await coll.deleteMany(selector.map.cleaned());
    return result.isSuccess;
  }

  /// Type-safe deleteMany by named arguments
  static Future<bool> deleteManyByNamed({
    ObjectId? id,
    String? tempId,
    User? owner,
    String? name,
    dynamic avatar,
    Map<String, dynamic>? ephemeralData,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (tempId != null) selector['temp_id'] = tempId;
    if (owner != null) selector['owner'] = owner.id;
    if (name != null) selector['name'] = name;
    if (avatar != null) selector['avatar'] = avatar;
    if (ephemeralData != null) selector['ephemeral_data'] = ephemeralData;
    if (active != null) selector['active'] = active;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final result = await coll.deleteMany(selector);
    return result.isSuccess;
  }

  /// Type-safe updateOne
  static Future<Organization?> updateOne(
    Expression Function(QOrganization o) predicate, {
    ObjectId? id,
    String? tempId,
    User? owner,
    String? name,
    dynamic avatar,
    Map<String, dynamic>? ephemeralData,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final modifier = _buildModifier(
      sanitizedDocument({
        if (tempId != null) 'temp_id': tempId,
        if (owner != null) 'owner': owner.id,
        if (name != null) 'name': name,
        if (avatar != null) 'avatar': avatar,
        if (ephemeralData != null) 'ephemeral_data': ephemeralData,
        if (active != null) 'active': active,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      }),
    );
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final cleanedSelector =
        predicate(QOrganization()).toSelectorBuilder().map.cleaned();
    final retrieved = await coll.modernFindOne(
      filter: cleanedSelector,
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
    return _organizationDeserializeDocument(updatedDoc);
  }

  /// Type-safe updateMany
  static Future<List<Organization>> updateMany(
    Expression Function(QOrganization o) predicate, {
    ObjectId? id,
    String? tempId,
    User? owner,
    String? name,
    dynamic avatar,
    Map<String, dynamic>? ephemeralData,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final modifier = _buildModifier(
      sanitizedDocument({
        if (tempId != null) 'temp_id': tempId,
        if (owner != null) 'owner': owner.id,
        if (name != null) 'name': name,
        if (avatar != null) 'avatar': avatar,
        if (ephemeralData != null) 'ephemeral_data': ephemeralData,
        if (active != null) 'active': active,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      }),
    );
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final cleanedSelector =
        predicate(QOrganization()).toSelectorBuilder().map.cleaned();
    final retrieved =
        await coll
            .modernFind(filter: cleanedSelector, projection: {'_id': 1})
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
        .map(_organizationDeserializeDocument)
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
  static Future<Organization?> updateOneFromMap(
    ObjectId id,
    Map<String, dynamic> updateMap, {
    Db? db,
  }) async {
    final mod = _buildModifier(
      sanitizedDocument(
        updateMap.withValidObjectReferences(
          refFields: _organizationRefFields,
          objectIdFields: _organizationObjectIdFields,
        ),
      ),
    );
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final result = await coll.updateOne({'_id': id}, mod);
    if (!result.isSuccess) return null;
    final updatedDoc = await coll.modernFindOne(filter: {'_id': id});
    return updatedDoc == null
        ? null
        : _organizationDeserializeDocument(updatedDoc);
  }

  static Future<int> count(
    Expression Function(QOrganization o)? predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);

    final selectorMap =
        predicate == null
            ? <String, dynamic>{}
            : predicate(QOrganization()).toSelectorBuilder().map;

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

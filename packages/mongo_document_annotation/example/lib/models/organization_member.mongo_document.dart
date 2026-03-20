// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// Author: Wan Clem <wannclem@gmail.com>

part of 'organization_member.dart';

// **************************************************************************
// MongoDocumentGenerator
// **************************************************************************

enum OrganizationMemberFields {
  id,
  occupation,
  role,
  title,
  createdAt,
  updatedAt,
}

class OrganizationMemberProjections implements BaseProjections {
  @override
  final List<OrganizationMemberFields>? inclusions;
  final List<OrganizationMemberFields>? exclusions;
  @override
  final Map<String, dynamic> fieldMappings = const {
    "id": "_id",
    "occupation": "occupation",
    "role": "role",
    "title": "title",
    "createdAt": "created_at",
    "updatedAt": "updated_at",
  };
  const OrganizationMemberProjections({this.inclusions, this.exclusions});

  @override
  Map<String, int> toProjection() {
    return {
      '_id': 1,
      'occupation': 1,
      'role': 1,
      'title': 1,
      'created_at': 1,
      'updated_at': 1,
    };
  }
}

const _nestedCollections = <String, String>{
  'user_id': 'accounts',
  'organization': 'organizations',
};
const _organizationMemberFieldMappings = <String, String>{
  'id': '_id',
  'user': 'user_id',
  'organization': 'organization',
  'occupation': 'occupation',
  'role': 'role',
  'title': 'title',
  'createdAt': 'created_at',
  'updatedAt': 'updated_at',
};
const _organizationMemberCollection = 'organizationmembers';
const _organizationMemberRefFields = <String>{'user_id', 'organization'};
const _organizationMemberObjectIdFields = <String>{};
const _organizationMemberTrackedPersistedKeys = <String>[
  'user_id',
  'organization',
  'occupation',
  'role',
  'title',
  'created_at',
  'updated_at',
];

Map<String, dynamic> _organizationMemberNormalizePersistedDocument(
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

  for (final key in _organizationMemberObjectIdFields) {
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

void _rememberOrganizationMemberSnapshot(Map<String, dynamic> document) {
  rememberMongoDocumentSnapshot(
    _organizationMemberCollection,
    _organizationMemberNormalizePersistedDocument(document),
  );
}

OrganizationMember _organizationMemberDeserializeDocument(
  Map<String, dynamic> document,
) {
  _rememberOrganizationMemberSnapshot(document);
  return OrganizationMember.fromJson(
    document.withRefs(
      refFields: _organizationMemberRefFields,
      objectIdFields: _organizationMemberObjectIdFields,
    ),
  );
}

List<OrganizationMember> _organizationMemberDeserializeDocuments(
  Iterable<Map<String, dynamic>> documents,
) {
  return documents.map(_organizationMemberDeserializeDocument).toList();
}

Map<String, dynamic>? _organizationMemberSnapshotFor(ObjectId id) {
  return mongoDocumentSnapshot(_organizationMemberCollection, id);
}

ObjectId? _organizationMemberCoerceDocumentId(dynamic rawId) {
  if (rawId is ObjectId) return rawId;
  if (rawId is String) return ObjectId.tryParse(rawId);
  return null;
}

void _organizationMemberForgetSnapshotFor(ObjectId id) {
  forgetMongoDocumentSnapshot(_organizationMemberCollection, id);
}

enum OrganizationMemberUserFields {
  id,
  firstName,
  lastName,
  email,
  password,
  createdAt,
  updatedAt,
}

class OrganizationMemberUserProjections implements BaseProjections {
  @override
  final List<OrganizationMemberUserFields>? inclusions;
  final List<OrganizationMemberUserFields>? exclusions;
  @override
  final Map<String, dynamic> fieldMappings = const {
    "id": "user_id._id",
    "firstName": "user_id.first_name",
    "lastName": "user_id.last_name",
    "email": "user_id.email",
    "password": "user_id.password",
    "createdAt": "user_id.created_at",
    "updatedAt": "user_id.updated_at",
  };
  const OrganizationMemberUserProjections({this.inclusions, this.exclusions});

  @override
  Map<String, int> toProjection() {
    return {
      'user_id._id': 1,
      'user_id.first_name': 1,
      'user_id.last_name': 1,
      'user_id.email': 1,
      'user_id.password': 1,
      'user_id.created_at': 1,
      'user_id.updated_at': 1,
    };
  }
}

enum OrganizationMemberOrganizationFields {
  id,
  tempId,
  owner,
  name,
  avatar,
  ephemeralData,
  active,
  createdAt,
  updatedAt,
}

class OrganizationMemberOrganizationProjections implements BaseProjections {
  @override
  final List<OrganizationMemberOrganizationFields>? inclusions;
  final List<OrganizationMemberOrganizationFields>? exclusions;
  @override
  final Map<String, dynamic> fieldMappings = const {
    "id": "organization._id",
    "tempId": "organization.temp_id",
    "owner": "organization.owner",
    "name": "organization.name",
    "avatar": "organization.avatar",
    "ephemeralData": "organization.ephemeral_data",
    "active": "organization.active",
    "createdAt": "organization.created_at",
    "updatedAt": "organization.updated_at",
  };
  const OrganizationMemberOrganizationProjections({
    this.inclusions,
    this.exclusions,
  });

  @override
  Map<String, int> toProjection() {
    return {
      'organization._id': 1,
      'organization.temp_id': 1,
      'organization.owner': 1,
      'organization.name': 1,
      'organization.avatar': 1,
      'organization.ephemeral_data': 1,
      'organization.active': 1,
      'organization.created_at': 1,
      'organization.updated_at': 1,
    };
  }
}

class QOrganizationMember {
  final String _prefix;
  QOrganizationMember([this._prefix = '']);

  String _key(String field) => _prefix.isEmpty ? field : '$_prefix.$field';

  QueryField<ObjectId?> get id => QueryField<ObjectId?>(_key('_id'));

  QUser get user => QUser(_key('user_id'));

  QOrganization get organization => QOrganization(_key('organization'));

  QueryField<String?> get occupation => QueryField<String?>(_key('occupation'));

  QueryField<String?> get role => QueryField<String?>(_key('role'));

  QueryField<String?> get title => QueryField<String?>(_key('title'));

  QueryField<DateTime?> get createdAt =>
      QueryField<DateTime?>(_key('created_at'));

  QueryField<DateTime?> get updatedAt =>
      QueryField<DateTime?>(_key('updated_at'));
}

extension $OrganizationMemberExtension on OrganizationMember {
  static String get _collection => 'organizationmembers';

  Future<OrganizationMember?> save({Db? db}) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final now = DateTime.now().toUtc();
    final isInsert = id == null;

    final rawOrganizationMemberMap = toJson()..remove('_id');
    final persistedOrganizationMemberMap =
        _organizationMemberNormalizePersistedDocument({
          ...rawOrganizationMemberMap,
        });

    if (isInsert) {
      persistedOrganizationMemberMap.update(
        'created_at',
        (value) => value ?? now,
        ifAbsent: () => now,
      );
      persistedOrganizationMemberMap.update(
        'updated_at',
        (_) => now,
        ifAbsent: () => now,
      );

      final result = await coll.insertOne(persistedOrganizationMemberMap);
      if (!result.isSuccess) return null;
      final savedDoc = await coll.modernFindOne(filter: {'_id': result.id});
      if (savedDoc == null) return null;
      return _organizationMemberDeserializeDocument(savedDoc);
    }

    var snapshot = _organizationMemberSnapshotFor(id!);
    snapshot ??= await coll.modernFindOne(filter: {'_id': id});
    if (snapshot == null) return null;
    snapshot = _organizationMemberNormalizePersistedDocument(snapshot);

    final updateMap = buildMongoUpdateMapFromSnapshot(
      current: persistedOrganizationMemberMap,
      snapshot: snapshot,
      trackedKeys: _organizationMemberTrackedPersistedKeys,
    );

    if (updateMap.isEmpty) {
      final savedDoc = await coll.modernFindOne(filter: {'_id': id});
      if (savedDoc == null) return null;
      return _organizationMemberDeserializeDocument(savedDoc);
    }

    var parentMod = modify.set('updated_at', now);
    updateMap.forEach((key, value) => parentMod = parentMod.set(key, value));
    final res = await coll.updateOne({'_id': id}, parentMod);
    if (!res.isSuccess) return null;
    final savedDoc = await coll.modernFindOne(filter: {'_id': id});
    if (savedDoc == null) return null;
    return _organizationMemberDeserializeDocument(savedDoc);
  }

  Future<OrganizationMember?> saveChanges({Db? db}) async {
    return save(db: db);
  }

  Future<bool> delete({Db? db}) async {
    if (id == null) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final res = await coll.deleteOne({'_id': id});
    if (res.isSuccess) {
      _organizationMemberForgetSnapshotFor(id!);
    }
    return res.isSuccess;
  }
}

class OrganizationMembers {
  static String get _collection => 'organizationmembers';
  static String get collection => _collection;

  static Future<List<OrganizationMember?>> saveMany(
    List<OrganizationMember> organizationMembers, {
    Db? db,
  }) async {
    if (organizationMembers.isEmpty) return <OrganizationMember>[];
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final now = DateTime.now().toUtc();
    final List<Map<String, dynamic>> toInsert = [];
    final List<(int, Map<String, dynamic>)> toSave = [];
    final orderedIds = List<dynamic>.filled(organizationMembers.length, null);
    final insertPositions = <int>[];
    for (int index = 0; index < organizationMembers.length; index++) {
      final item = organizationMembers[index];
      final json = _organizationMemberNormalizePersistedDocument(item.toJson());
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
      final docId = _organizationMemberCoerceDocumentId(entry.$2['_id']);
      if (docId == null) continue;
      if (_organizationMemberSnapshotFor(docId) == null) {
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
      rememberMongoDocumentSnapshots(
        _organizationMemberCollection,
        fetchedSnapshots,
      );
      for (final snapshot in fetchedSnapshots) {
        final snapshotId = _organizationMemberCoerceDocumentId(snapshot['_id']);
        if (snapshotId == null) continue;
        fetchedSnapshotsById[snapshotId] =
            _organizationMemberNormalizePersistedDocument(snapshot);
      }
    }
    for (final entry in toSave) {
      final position = entry.$1;
      final doc = entry.$2;
      final docId = _organizationMemberCoerceDocumentId(doc['_id']);
      if (docId == null) continue;
      final updateDoc = Map<String, dynamic>.from(doc)..remove('_id');
      var snapshot =
          _organizationMemberSnapshotFor(docId) ?? fetchedSnapshotsById[docId];
      if (snapshot == null) continue;
      snapshot = _organizationMemberNormalizePersistedDocument(snapshot);
      final updateMap = buildMongoUpdateMapFromSnapshot(
        current: updateDoc,
        snapshot: snapshot,
        trackedKeys: _organizationMemberTrackedPersistedKeys,
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
    if (uniqueIds.isEmpty) return <OrganizationMember>[];
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
          (doc) =>
              doc == null ? null : _organizationMemberDeserializeDocument(doc),
        )
        .toList();
  }

  static Future<OrganizationMember?> findById(
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
    final normalizedLookups = remapLookups(
      lookups,
      _organizationMemberFieldMappings,
    );
    final normalizedProjections = normalizeProjectionList(
      projections,
      OrganizationMemberProjections(),
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
      return _organizationMemberDeserializeDocument(results.first);
    }
    // fallback: return entire organizationMember
    final organizationMember = await coll.modernFindOne(
      filter: {'_id': id},
      projection:
          canUseDirectProjection ? projDoc.cast<String, Object>() : null,
    );
    return organizationMember == null
        ? null
        : _organizationMemberDeserializeDocument(organizationMember);
  }

  /// Type-safe findOne by predicate
  static Future<OrganizationMember?> findOne(
    Expression Function(QOrganizationMember o)? predicate, {
    Db? db,
    List<Lookup> lookups = const [],
    List<BaseProjections> projections = const [],
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final normalizedLookups = remapLookups(
      lookups,
      _organizationMemberFieldMappings,
    );
    final normalizedProjections = normalizeProjectionList(
      projections,
      OrganizationMemberProjections(),
    );

    if (predicate == null) {
      final organizationMember = await coll.modernFindOne(
        sort: {'created_at': -1},
      );
      if (organizationMember == null) return null;
      return _organizationMemberDeserializeDocument(organizationMember);
    }

    final selectorBuilder =
        predicate(QOrganizationMember()).toSelectorBuilder();
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
      return _organizationMemberDeserializeDocument(results.first);
    }

    // fallback to simple findOne
    final organizationMemberResult = await coll.modernFindOne(
      filter: selectorMap.cleaned(),
      projection:
          canUseDirectProjection ? projDoc.cast<String, Object>() : null,
    );
    return organizationMemberResult == null
        ? null
        : _organizationMemberDeserializeDocument(organizationMemberResult);
  }

  /// Type-safe findOne by named arguments
  static Future<OrganizationMember?> findOneByNamed({
    ObjectId? id,
    User? user,
    Organization? organization,
    String? occupation,
    String? role,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
    List<Lookup> lookups = const [],
    List<BaseProjections> projections = const [],
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final normalizedLookups = remapLookups(
      lookups,
      _organizationMemberFieldMappings,
    );
    final normalizedProjections = normalizeProjectionList(
      projections,
      OrganizationMemberProjections(),
    );

    final selector = <String, dynamic>{};

    if (id != null) selector['_id'] = id;
    if (user != null) selector['user_id'] = user.id;
    if (organization != null) selector['organization'] = organization.id;
    if (occupation != null) selector['occupation'] = occupation;
    if (role != null) selector['role'] = role;
    if (title != null) selector['title'] = title;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty && projections.isEmpty && normalizedLookups.isEmpty) {
      final organizationMember = await coll.modernFindOne(
        sort: {'created_at': -1},
      );
      if (organizationMember == null) return null;
      return _organizationMemberDeserializeDocument(organizationMember);
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
      final organizationMembers =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (organizationMembers.isEmpty) return null;
      return _organizationMemberDeserializeDocument(organizationMembers.first);
    }

    final organizationMemberResult = await coll.modernFindOne(
      filter: selector.cleaned(),
      sort: selector.isEmpty ? {'created_at': -1} : null,
      projection:
          canUseDirectProjection ? projDoc.cast<String, Object>() : null,
    );
    return organizationMemberResult == null
        ? null
        : _organizationMemberDeserializeDocument(organizationMemberResult);
  }

  /// Type-safe findMany by predicate
  static Future<List<OrganizationMember>> findMany(
    Expression Function(QOrganizationMember o) predicate, {
    List<Lookup> lookups = const [],
    int? skip,
    int limit = 10,
    (String, int) sort = const ("created_at", -1),
    List<BaseProjections> projections = const [],
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final normalizedLookups = remapLookups(
      lookups,
      _organizationMemberFieldMappings,
    );
    final normalizedProjections = normalizeProjectionList(
      projections,
      OrganizationMemberProjections(),
    );

    var selectorBuilder = predicate(QOrganizationMember()).toSelectorBuilder();
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
      final organizationMembers =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (organizationMembers.isEmpty) return [];
      return _organizationMemberDeserializeDocuments(organizationMembers);
    }

    final organizationMembers =
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
    return _organizationMemberDeserializeDocuments(organizationMembers);
  }

  /// Type-safe findMany by named arguments
  static Future<List<OrganizationMember>> findManyByNamed({
    ObjectId? id,
    User? user,
    Organization? organization,
    String? occupation,
    String? role,
    String? title,
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
    final normalizedLookups = remapLookups(
      lookups,
      _organizationMemberFieldMappings,
    );
    final normalizedProjections = normalizeProjectionList(
      projections,
      OrganizationMemberProjections(),
    );

    final selector = <String, dynamic>{};

    if (id != null) selector['_id'] = id;
    if (user != null) selector['user_id'] = user.id;
    if (organization != null) selector['organization'] = organization.id;
    if (occupation != null) selector['occupation'] = occupation;
    if (role != null) selector['role'] = role;
    if (title != null) selector['title'] = title;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;

    if (selector.isEmpty && projections.isEmpty && normalizedLookups.isEmpty) {
      final organizationMembers =
          await coll.modernFind(sort: sort, limit: limit, skip: skip).toList();
      if (organizationMembers.isEmpty) return [];
      return _organizationMemberDeserializeDocuments(organizationMembers);
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
      final organizationMembers =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (organizationMembers.isEmpty) return [];
      return _organizationMemberDeserializeDocuments(organizationMembers);
    }

    final organizationMembers =
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
    return _organizationMemberDeserializeDocuments(organizationMembers);
  }

  static Future<bool> deleteOne(
    Expression Function(QOrganizationMember o) predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final expr = predicate(QOrganizationMember());
    final selector = expr.toSelectorBuilder();
    final coll = database.collection(_collection);
    final result = await coll.deleteOne(selector.map.cleaned());
    return result.isSuccess;
  }

  /// Type-safe deleteOne by named arguments
  static Future<bool> deleteOneByNamed({
    ObjectId? id,
    User? user,
    Organization? organization,
    String? occupation,
    String? role,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (user != null) selector['user_id'] = user.id;
    if (organization != null) selector['organization'] = organization.id;
    if (occupation != null) selector['occupation'] = occupation;
    if (role != null) selector['role'] = role;
    if (title != null) selector['title'] = title;
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
    Expression Function(QOrganizationMember o) predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final expr = predicate(QOrganizationMember());
    final selector = expr.toSelectorBuilder();
    final coll = database.collection(_collection);
    final result = await coll.deleteMany(selector.map.cleaned());
    return result.isSuccess;
  }

  /// Type-safe deleteMany by named arguments
  static Future<bool> deleteManyByNamed({
    ObjectId? id,
    User? user,
    Organization? organization,
    String? occupation,
    String? role,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (user != null) selector['user_id'] = user.id;
    if (organization != null) selector['organization'] = organization.id;
    if (occupation != null) selector['occupation'] = occupation;
    if (role != null) selector['role'] = role;
    if (title != null) selector['title'] = title;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final result = await coll.deleteMany(selector);
    return result.isSuccess;
  }

  /// Type-safe updateOne
  static Future<OrganizationMember?> updateOne(
    Expression Function(QOrganizationMember o) predicate, {
    ObjectId? id,
    User? user,
    Organization? organization,
    String? occupation,
    String? role,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final modifier = _buildModifier(
      sanitizedDocument({
        if (user != null) 'user_id': user.id,
        if (organization != null) 'organization': organization.id,
        if (occupation != null) 'occupation': occupation,
        if (role != null) 'role': role,
        if (title != null) 'title': title,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      }),
    );
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final cleanedSelector =
        predicate(QOrganizationMember()).toSelectorBuilder().map.cleaned();
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
    return _organizationMemberDeserializeDocument(updatedDoc);
  }

  /// Type-safe updateMany
  static Future<List<OrganizationMember>> updateMany(
    Expression Function(QOrganizationMember o) predicate, {
    ObjectId? id,
    User? user,
    Organization? organization,
    String? occupation,
    String? role,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final modifier = _buildModifier(
      sanitizedDocument({
        if (user != null) 'user_id': user.id,
        if (organization != null) 'organization': organization.id,
        if (occupation != null) 'occupation': occupation,
        if (role != null) 'role': role,
        if (title != null) 'title': title,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      }),
    );
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final cleanedSelector =
        predicate(QOrganizationMember()).toSelectorBuilder().map.cleaned();
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
        .map(_organizationMemberDeserializeDocument)
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
  static Future<OrganizationMember?> updateOneFromMap(
    ObjectId id,
    Map<String, dynamic> updateMap, {
    Db? db,
  }) async {
    final mod = _buildModifier(
      sanitizedDocument(
        updateMap.withValidObjectReferences(
          refFields: _organizationMemberRefFields,
          objectIdFields: _organizationMemberObjectIdFields,
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
        : _organizationMemberDeserializeDocument(updatedDoc);
  }

  static Future<int> count(
    Expression Function(QOrganizationMember o)? predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);

    final selectorMap =
        predicate == null
            ? <String, dynamic>{}
            : predicate(QOrganizationMember()).toSelectorBuilder().map;

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

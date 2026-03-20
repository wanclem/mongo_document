// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// Author: Wan Clem <wannclem@gmail.com>

part of 'post.dart';

// **************************************************************************
// MongoDocumentGenerator
// **************************************************************************

enum PostFields {
  id,
  body,
  postNote,
  schedule,
  comments,
  authorFollowsYou,
  targetPlatforms,
  tags,
  createdAt,
  updatedAt,
}

class PostProjections implements BaseProjections {
  @override
  final List<PostFields>? inclusions;
  final List<PostFields>? exclusions;
  @override
  final Map<String, dynamic> fieldMappings = const {
    "id": "_id",
    "body": "body",
    "postNote": "post_note",
    "schedule": "schedule",
    "comments": "comments",
    "authorFollowsYou": "author_follows_you",
    "targetPlatforms": "target_platforms",
    "tags": "tags",
    "createdAt": "created_at",
    "updatedAt": "updated_at",
  };
  const PostProjections({this.inclusions, this.exclusions});

  @override
  Map<String, int> toProjection() {
    return {
      '_id': 1,
      'body': 1,
      'post_note': 1,
      'schedule': 1,
      'comments': 1,
      'author_follows_you': 1,
      'target_platforms': 1,
      'tags': 1,
      'created_at': 1,
      'updated_at': 1,
    };
  }
}

const _nestedCollections = <String, String>{'author': 'accounts'};
const _postFieldMappings = <String, String>{
  'id': '_id',
  'body': 'body',
  'postNote': 'post_note',
  'author': 'author',
  'schedule': 'schedule',
  'comments': 'comments',
  'authorFollowsYou': 'author_follows_you',
  'targetPlatforms': 'target_platforms',
  'tags': 'tags',
  'createdAt': 'created_at',
  'updatedAt': 'updated_at',
};
const _postCollection = 'posts';
const _postRefFields = <String>{'author'};
const _postObjectIdFields = <String>{};
const _postTrackedPersistedKeys = <String>[
  'body',
  'post_note',
  'author',
  'schedule',
  'comments',
  'author_follows_you',
  'target_platforms',
  'tags',
  'created_at',
  'updated_at',
];

Map<String, dynamic> _postNormalizePersistedDocument(
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

  for (final key in _postObjectIdFields) {
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

void _rememberPostSnapshot(Map<String, dynamic> document) {
  rememberMongoDocumentSnapshot(
    _postCollection,
    _postNormalizePersistedDocument(document),
  );
}

Post _postDeserializeDocument(Map<String, dynamic> document) {
  _rememberPostSnapshot(document);
  return Post.fromJson(
    document.withRefs(
      refFields: _postRefFields,
      objectIdFields: _postObjectIdFields,
    ),
  );
}

List<Post> _postDeserializeDocuments(Iterable<Map<String, dynamic>> documents) {
  return documents.map(_postDeserializeDocument).toList();
}

Map<String, dynamic>? _postSnapshotFor(ObjectId id) {
  return mongoDocumentSnapshot(_postCollection, id);
}

ObjectId? _postCoerceDocumentId(dynamic rawId) {
  if (rawId is ObjectId) return rawId;
  if (rawId is String) return ObjectId.tryParse(rawId);
  return null;
}

void _postForgetSnapshotFor(ObjectId id) {
  forgetMongoDocumentSnapshot(_postCollection, id);
}

enum PostAuthorFields {
  id,
  firstName,
  lastName,
  email,
  password,
  createdAt,
  updatedAt,
}

class PostAuthorProjections implements BaseProjections {
  @override
  final List<PostAuthorFields>? inclusions;
  final List<PostAuthorFields>? exclusions;
  @override
  final Map<String, dynamic> fieldMappings = const {
    "id": "author._id",
    "firstName": "author.first_name",
    "lastName": "author.last_name",
    "email": "author.email",
    "password": "author.password",
    "createdAt": "author.created_at",
    "updatedAt": "author.updated_at",
  };
  const PostAuthorProjections({this.inclusions, this.exclusions});

  @override
  Map<String, int> toProjection() {
    return {
      'author._id': 1,
      'author.first_name': 1,
      'author.last_name': 1,
      'author.email': 1,
      'author.password': 1,
      'author.created_at': 1,
      'author.updated_at': 1,
    };
  }
}

class QPost {
  final String _prefix;
  QPost([this._prefix = '']);

  String _key(String field) => _prefix.isEmpty ? field : '$_prefix.$field';

  QueryField<ObjectId?> get id => QueryField<ObjectId?>(_key('_id'));

  QueryField<String?> get body => QueryField<String?>(_key('body'));

  QueryField<String?> get postNote => QueryField<String?>(_key('post_note'));

  QUser get author => QUser(_key('author'));

  QueryField<Schedule?> get schedule => QueryField<Schedule?>(_key('schedule'));

  QList<Comment> get comments => QList<Comment>(_key('comments'));

  QueryField<bool> get authorFollowsYou =>
      QueryField<bool>(_key('author_follows_you'));

  QList<dynamic> get targetPlatforms =>
      QList<dynamic>(_key('target_platforms'));

  QList<String> get tags => QList<String>(_key('tags'));

  QueryField<DateTime?> get createdAt =>
      QueryField<DateTime?>(_key('created_at'));

  QueryField<DateTime?> get updatedAt =>
      QueryField<DateTime?>(_key('updated_at'));
}

extension $PostExtension on Post {
  static String get _collection => 'posts';

  Future<Post?> save({Db? db}) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final now = DateTime.now().toUtc();
    final isInsert = id == null;

    final rawPostMap = toJson()..remove('_id');
    final persistedPostMap = _postNormalizePersistedDocument({...rawPostMap});

    if (isInsert) {
      persistedPostMap.update(
        'created_at',
        (value) => value ?? now,
        ifAbsent: () => now,
      );
      persistedPostMap.update('updated_at', (_) => now, ifAbsent: () => now);

      final result = await coll.insertOne(persistedPostMap);
      if (!result.isSuccess) return null;
      final savedDoc = await coll.modernFindOne(filter: {'_id': result.id});
      if (savedDoc == null) return null;
      return _postDeserializeDocument(savedDoc);
    }

    var snapshot = _postSnapshotFor(id!);
    snapshot ??= await coll.modernFindOne(filter: {'_id': id});
    if (snapshot == null) return null;
    snapshot = _postNormalizePersistedDocument(snapshot);

    final updateMap = buildMongoUpdateMapFromSnapshot(
      current: persistedPostMap,
      snapshot: snapshot,
      trackedKeys: _postTrackedPersistedKeys,
    );

    if (updateMap.isEmpty) {
      final savedDoc = await coll.modernFindOne(filter: {'_id': id});
      if (savedDoc == null) return null;
      return _postDeserializeDocument(savedDoc);
    }

    var parentMod = modify.set('updated_at', now);
    updateMap.forEach((key, value) => parentMod = parentMod.set(key, value));
    final res = await coll.updateOne({'_id': id}, parentMod);
    if (!res.isSuccess) return null;
    final savedDoc = await coll.modernFindOne(filter: {'_id': id});
    if (savedDoc == null) return null;
    return _postDeserializeDocument(savedDoc);
  }

  Future<Post?> saveChanges({Db? db}) async {
    return save(db: db);
  }

  Future<bool> delete({Db? db}) async {
    if (id == null) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final res = await coll.deleteOne({'_id': id});
    if (res.isSuccess) {
      _postForgetSnapshotFor(id!);
    }
    return res.isSuccess;
  }
}

class Posts {
  static String get _collection => 'posts';
  static String get collection => _collection;

  static Future<List<Post?>> saveMany(List<Post> posts, {Db? db}) async {
    if (posts.isEmpty) return <Post>[];
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final now = DateTime.now().toUtc();
    final List<Map<String, dynamic>> toInsert = [];
    final List<(int, Map<String, dynamic>)> toSave = [];
    final orderedIds = List<dynamic>.filled(posts.length, null);
    final insertPositions = <int>[];
    for (int index = 0; index < posts.length; index++) {
      final item = posts[index];
      final json = _postNormalizePersistedDocument(item.toJson());
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
      final docId = _postCoerceDocumentId(entry.$2['_id']);
      if (docId == null) continue;
      if (_postSnapshotFor(docId) == null) {
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
      rememberMongoDocumentSnapshots(_postCollection, fetchedSnapshots);
      for (final snapshot in fetchedSnapshots) {
        final snapshotId = _postCoerceDocumentId(snapshot['_id']);
        if (snapshotId == null) continue;
        fetchedSnapshotsById[snapshotId] = _postNormalizePersistedDocument(
          snapshot,
        );
      }
    }
    for (final entry in toSave) {
      final position = entry.$1;
      final doc = entry.$2;
      final docId = _postCoerceDocumentId(doc['_id']);
      if (docId == null) continue;
      final updateDoc = Map<String, dynamic>.from(doc)..remove('_id');
      var snapshot = _postSnapshotFor(docId) ?? fetchedSnapshotsById[docId];
      if (snapshot == null) continue;
      snapshot = _postNormalizePersistedDocument(snapshot);
      final updateMap = buildMongoUpdateMapFromSnapshot(
        current: updateDoc,
        snapshot: snapshot,
        trackedKeys: _postTrackedPersistedKeys,
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
    if (uniqueIds.isEmpty) return <Post>[];
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
        .map((doc) => doc == null ? null : _postDeserializeDocument(doc))
        .toList();
  }

  static Future<Post?> findById(
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
    final normalizedLookups = remapLookups(lookups, _postFieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      PostProjections(),
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
      return _postDeserializeDocument(results.first);
    }
    // fallback: return entire post
    final post = await coll.modernFindOne(
      filter: {'_id': id},
      projection:
          canUseDirectProjection ? projDoc.cast<String, Object>() : null,
    );
    return post == null ? null : _postDeserializeDocument(post);
  }

  /// Type-safe findOne by predicate
  static Future<Post?> findOne(
    Expression Function(QPost p)? predicate, {
    Db? db,
    List<Lookup> lookups = const [],
    List<BaseProjections> projections = const [],
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final normalizedLookups = remapLookups(lookups, _postFieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      PostProjections(),
    );

    if (predicate == null) {
      final post = await coll.modernFindOne(sort: {'created_at': -1});
      if (post == null) return null;
      return _postDeserializeDocument(post);
    }

    final selectorBuilder = predicate(QPost()).toSelectorBuilder();
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
      return _postDeserializeDocument(results.first);
    }

    // fallback to simple findOne
    final postResult = await coll.modernFindOne(
      filter: selectorMap.cleaned(),
      projection:
          canUseDirectProjection ? projDoc.cast<String, Object>() : null,
    );
    return postResult == null ? null : _postDeserializeDocument(postResult);
  }

  /// Type-safe findOne by named arguments
  static Future<Post?> findOneByNamed({
    ObjectId? id,
    String? body,
    String? postNote,
    User? author,
    Schedule? schedule,
    List<Comment>? comments,
    bool? authorFollowsYou,
    List<dynamic>? targetPlatforms,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
    List<Lookup> lookups = const [],
    List<BaseProjections> projections = const [],
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final normalizedLookups = remapLookups(lookups, _postFieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      PostProjections(),
    );

    final selector = <String, dynamic>{};

    if (id != null) selector['_id'] = id;
    if (body != null) selector['body'] = body;
    if (postNote != null) selector['post_note'] = postNote;
    if (author != null) selector['author'] = author.id;
    if (schedule != null) selector['schedule'] = schedule;
    if (comments != null) selector['comments'] = comments;
    if (authorFollowsYou != null)
      selector['author_follows_you'] = authorFollowsYou;
    if (targetPlatforms != null) selector['target_platforms'] = targetPlatforms;
    if (tags != null) selector['tags'] = tags;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty && projections.isEmpty && normalizedLookups.isEmpty) {
      final post = await coll.modernFindOne(sort: {'created_at': -1});
      if (post == null) return null;
      return _postDeserializeDocument(post);
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
      final posts =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (posts.isEmpty) return null;
      return _postDeserializeDocument(posts.first);
    }

    final postResult = await coll.modernFindOne(
      filter: selector.cleaned(),
      sort: selector.isEmpty ? {'created_at': -1} : null,
      projection:
          canUseDirectProjection ? projDoc.cast<String, Object>() : null,
    );
    return postResult == null ? null : _postDeserializeDocument(postResult);
  }

  /// Type-safe findMany by predicate
  static Future<List<Post>> findMany(
    Expression Function(QPost p) predicate, {
    List<Lookup> lookups = const [],
    int? skip,
    int limit = 10,
    (String, int) sort = const ("created_at", -1),
    List<BaseProjections> projections = const [],
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final normalizedLookups = remapLookups(lookups, _postFieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      PostProjections(),
    );

    var selectorBuilder = predicate(QPost()).toSelectorBuilder();
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
      final posts =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (posts.isEmpty) return [];
      return _postDeserializeDocuments(posts);
    }

    final posts =
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
    return _postDeserializeDocuments(posts);
  }

  /// Type-safe findMany by named arguments
  static Future<List<Post>> findManyByNamed({
    ObjectId? id,
    String? body,
    String? postNote,
    User? author,
    Schedule? schedule,
    List<Comment>? comments,
    bool? authorFollowsYou,
    List<dynamic>? targetPlatforms,
    List<String>? tags,
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
    final normalizedLookups = remapLookups(lookups, _postFieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      PostProjections(),
    );

    final selector = <String, dynamic>{};

    if (id != null) selector['_id'] = id;
    if (body != null) selector['body'] = body;
    if (postNote != null) selector['post_note'] = postNote;
    if (author != null) selector['author'] = author.id;
    if (schedule != null) selector['schedule'] = schedule;
    if (comments != null) selector['comments'] = comments;
    if (authorFollowsYou != null)
      selector['author_follows_you'] = authorFollowsYou;
    if (targetPlatforms != null) selector['target_platforms'] = targetPlatforms;
    if (tags != null) selector['tags'] = tags;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;

    if (selector.isEmpty && projections.isEmpty && normalizedLookups.isEmpty) {
      final posts =
          await coll.modernFind(sort: sort, limit: limit, skip: skip).toList();
      if (posts.isEmpty) return [];
      return _postDeserializeDocuments(posts);
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
      final posts =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (posts.isEmpty) return [];
      return _postDeserializeDocuments(posts);
    }

    final posts =
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
    return _postDeserializeDocuments(posts);
  }

  static Future<bool> deleteOne(
    Expression Function(QPost p) predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final expr = predicate(QPost());
    final selector = expr.toSelectorBuilder();
    final coll = database.collection(_collection);
    final result = await coll.deleteOne(selector.map.cleaned());
    return result.isSuccess;
  }

  /// Type-safe deleteOne by named arguments
  static Future<bool> deleteOneByNamed({
    ObjectId? id,
    String? body,
    String? postNote,
    User? author,
    Schedule? schedule,
    List<Comment>? comments,
    bool? authorFollowsYou,
    List<dynamic>? targetPlatforms,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (body != null) selector['body'] = body;
    if (postNote != null) selector['post_note'] = postNote;
    if (author != null) selector['author'] = author.id;
    if (schedule != null) selector['schedule'] = schedule;
    if (comments != null) selector['comments'] = comments;
    if (authorFollowsYou != null)
      selector['author_follows_you'] = authorFollowsYou;
    if (targetPlatforms != null) selector['target_platforms'] = targetPlatforms;
    if (tags != null) selector['tags'] = tags;
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
    Expression Function(QPost p) predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final expr = predicate(QPost());
    final selector = expr.toSelectorBuilder();
    final coll = database.collection(_collection);
    final result = await coll.deleteMany(selector.map.cleaned());
    return result.isSuccess;
  }

  /// Type-safe deleteMany by named arguments
  static Future<bool> deleteManyByNamed({
    ObjectId? id,
    String? body,
    String? postNote,
    User? author,
    Schedule? schedule,
    List<Comment>? comments,
    bool? authorFollowsYou,
    List<dynamic>? targetPlatforms,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (body != null) selector['body'] = body;
    if (postNote != null) selector['post_note'] = postNote;
    if (author != null) selector['author'] = author.id;
    if (schedule != null) selector['schedule'] = schedule;
    if (comments != null) selector['comments'] = comments;
    if (authorFollowsYou != null)
      selector['author_follows_you'] = authorFollowsYou;
    if (targetPlatforms != null) selector['target_platforms'] = targetPlatforms;
    if (tags != null) selector['tags'] = tags;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final result = await coll.deleteMany(selector);
    return result.isSuccess;
  }

  /// Type-safe updateOne
  static Future<Post?> updateOne(
    Expression Function(QPost p) predicate, {
    ObjectId? id,
    String? body,
    String? postNote,
    User? author,
    Schedule? schedule,
    List<Comment>? comments,
    bool? authorFollowsYou,
    List<dynamic>? targetPlatforms,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final modifier = _buildModifier(
      sanitizedDocument({
        if (body != null) 'body': body,
        if (postNote != null) 'post_note': postNote,
        if (author != null) 'author': author.id,
        if (schedule != null) 'schedule': schedule.toJson(),
        if (comments != null) 'comments': comments,
        if (authorFollowsYou != null) 'author_follows_you': authorFollowsYou,
        if (targetPlatforms != null) 'target_platforms': targetPlatforms,
        if (tags != null) 'tags': tags,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      }),
    );
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final cleanedSelector =
        predicate(QPost()).toSelectorBuilder().map.cleaned();
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
    return _postDeserializeDocument(updatedDoc);
  }

  /// Type-safe updateMany
  static Future<List<Post>> updateMany(
    Expression Function(QPost p) predicate, {
    ObjectId? id,
    String? body,
    String? postNote,
    User? author,
    Schedule? schedule,
    List<Comment>? comments,
    bool? authorFollowsYou,
    List<dynamic>? targetPlatforms,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final modifier = _buildModifier(
      sanitizedDocument({
        if (body != null) 'body': body,
        if (postNote != null) 'post_note': postNote,
        if (author != null) 'author': author.id,
        if (schedule != null) 'schedule': schedule.toJson(),
        if (comments != null) 'comments': comments,
        if (authorFollowsYou != null) 'author_follows_you': authorFollowsYou,
        if (targetPlatforms != null) 'target_platforms': targetPlatforms,
        if (tags != null) 'tags': tags,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      }),
    );
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final cleanedSelector =
        predicate(QPost()).toSelectorBuilder().map.cleaned();
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
        .map(_postDeserializeDocument)
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
  static Future<Post?> updateOneFromMap(
    ObjectId id,
    Map<String, dynamic> updateMap, {
    Db? db,
  }) async {
    final mod = _buildModifier(
      sanitizedDocument(
        updateMap.withValidObjectReferences(
          refFields: _postRefFields,
          objectIdFields: _postObjectIdFields,
        ),
      ),
    );
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final result = await coll.updateOne({'_id': id}, mod);
    if (!result.isSuccess) return null;
    final updatedDoc = await coll.modernFindOne(filter: {'_id': id});
    return updatedDoc == null ? null : _postDeserializeDocument(updatedDoc);
  }

  static Future<int> count(
    Expression Function(QPost p)? predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);

    final selectorMap =
        predicate == null
            ? <String, dynamic>{}
            : predicate(QPost()).toSelectorBuilder().map;

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

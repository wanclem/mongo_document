// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// Author: Wan Clem <wannclem@gmail.com>

part of 'comment.dart';

// **************************************************************************
// MongoDocumentGenerator
// **************************************************************************

enum CommentFields { id, text, deleted, createdAt, updatedAt }

class CommentProjections implements BaseProjections {
  @override
  final List<CommentFields>? inclusions;
  final List<CommentFields>? exclusions;
  @override
  final Map<String, dynamic> fieldMappings = const {
    "id": "_id",
    "text": "text",
    "deleted": "deleted",
    "createdAt": "created_at",
    "updatedAt": "updated_at",
  };
  const CommentProjections({this.inclusions, this.exclusions});

  @override
  Map<String, int> toProjection() {
    return {
      '_id': 1,
      'text': 1,
      'deleted': 1,
      'created_at': 1,
      'updated_at': 1,
    };
  }
}

const _nestedCollections = <String, String>{
  'author': 'accounts',
  'post': 'posts',
};
const _commentFieldMappings = <String, String>{
  'id': '_id',
  'author': 'author',
  'post': 'post',
  'text': 'text',
  'deleted': 'deleted',
  'createdAt': 'created_at',
  'updatedAt': 'updated_at',
};
const _commentCollection = 'comments';
const _commentRefFields = <String>{'author', 'post'};
const _commentObjectIdFields = <String>{};
const _commentTrackedPersistedKeys = <String>[
  'author',
  'post',
  'text',
  'deleted',
  'created_at',
  'updated_at',
];

Map<String, dynamic> _commentNormalizePersistedDocument(
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

  for (final key in _commentObjectIdFields) {
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

void _rememberCommentSnapshot(Map<String, dynamic> document) {
  rememberMongoDocumentSnapshot(
    _commentCollection,
    _commentNormalizePersistedDocument(document),
  );
}

Comment _commentDeserializeDocument(Map<String, dynamic> document) {
  _rememberCommentSnapshot(document);
  return Comment.fromJson(
    document.withRefs(
      refFields: _commentRefFields,
      objectIdFields: _commentObjectIdFields,
    ),
  );
}

List<Comment> _commentDeserializeDocuments(
  Iterable<Map<String, dynamic>> documents,
) {
  return documents.map(_commentDeserializeDocument).toList();
}

Map<String, dynamic>? _commentSnapshotFor(ObjectId id) {
  return mongoDocumentSnapshot(_commentCollection, id);
}

ObjectId? _commentCoerceDocumentId(dynamic rawId) {
  if (rawId is ObjectId) return rawId;
  if (rawId is String) return ObjectId.tryParse(rawId);
  return null;
}

void _commentForgetSnapshotFor(ObjectId id) {
  forgetMongoDocumentSnapshot(_commentCollection, id);
}

enum CommentAuthorFields {
  id,
  firstName,
  lastName,
  email,
  password,
  createdAt,
  updatedAt,
}

class CommentAuthorProjections implements BaseProjections {
  @override
  final List<CommentAuthorFields>? inclusions;
  final List<CommentAuthorFields>? exclusions;
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
  const CommentAuthorProjections({this.inclusions, this.exclusions});

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

enum CommentPostFields {
  id,
  body,
  postNote,
  author,
  schedule,
  comments,
  authorFollowsYou,
  targetPlatforms,
  tags,
  createdAt,
  updatedAt,
}

class CommentPostProjections implements BaseProjections {
  @override
  final List<CommentPostFields>? inclusions;
  final List<CommentPostFields>? exclusions;
  @override
  final Map<String, dynamic> fieldMappings = const {
    "id": "post._id",
    "body": "post.body",
    "postNote": "post.post_note",
    "author": "post.author",
    "schedule": "post.schedule",
    "comments": "post.comments",
    "authorFollowsYou": "post.author_follows_you",
    "targetPlatforms": "post.target_platforms",
    "tags": "post.tags",
    "createdAt": "post.created_at",
    "updatedAt": "post.updated_at",
  };
  const CommentPostProjections({this.inclusions, this.exclusions});

  @override
  Map<String, int> toProjection() {
    return {
      'post._id': 1,
      'post.body': 1,
      'post.post_note': 1,
      'post.author': 1,
      'post.schedule': 1,
      'post.comments': 1,
      'post.author_follows_you': 1,
      'post.target_platforms': 1,
      'post.tags': 1,
      'post.created_at': 1,
      'post.updated_at': 1,
    };
  }
}

class QComment {
  final String _prefix;
  QComment([this._prefix = '']);

  String _key(String field) => _prefix.isEmpty ? field : '$_prefix.$field';

  QueryField<ObjectId?> get id => QueryField<ObjectId?>(_key('_id'));

  QUser get author => QUser(_key('author'));

  QPost get post => QPost(_key('post'));

  QueryField<String?> get text => QueryField<String?>(_key('text'));

  QueryField<bool> get deleted => QueryField<bool>(_key('deleted'));

  QueryField<DateTime?> get createdAt =>
      QueryField<DateTime?>(_key('created_at'));

  QueryField<DateTime?> get updatedAt =>
      QueryField<DateTime?>(_key('updated_at'));
}

extension $CommentExtension on Comment {
  static String get _collection => 'comments';

  Future<Comment?> save({Db? db}) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final now = DateTime.now().toUtc();
    final isInsert = id == null;

    final rawCommentMap = toJson()..remove('_id');
    final persistedCommentMap = _commentNormalizePersistedDocument({
      ...rawCommentMap,
    });

    if (isInsert) {
      persistedCommentMap.update(
        'created_at',
        (value) => value ?? now,
        ifAbsent: () => now,
      );
      persistedCommentMap.update('updated_at', (_) => now, ifAbsent: () => now);

      final result = await coll.insertOne(persistedCommentMap);
      if (!result.isSuccess) return null;
      final savedDoc = await coll.modernFindOne(filter: {'_id': result.id});
      if (savedDoc == null) return null;
      return _commentDeserializeDocument(savedDoc);
    }

    var snapshot = _commentSnapshotFor(id!);
    snapshot ??= await coll.modernFindOne(filter: {'_id': id});
    if (snapshot == null) return null;
    snapshot = _commentNormalizePersistedDocument(snapshot);

    final updateMap = buildMongoUpdateMapFromSnapshot(
      current: persistedCommentMap,
      snapshot: snapshot,
      trackedKeys: _commentTrackedPersistedKeys,
    );

    if (updateMap.isEmpty) {
      final savedDoc = await coll.modernFindOne(filter: {'_id': id});
      if (savedDoc == null) return null;
      return _commentDeserializeDocument(savedDoc);
    }

    var parentMod = modify.set('updated_at', now);
    updateMap.forEach((key, value) => parentMod = parentMod.set(key, value));
    final res = await coll.updateOne({'_id': id}, parentMod);
    if (!res.isSuccess) return null;
    final savedDoc = await coll.modernFindOne(filter: {'_id': id});
    if (savedDoc == null) return null;
    return _commentDeserializeDocument(savedDoc);
  }

  Future<Comment?> saveChanges({Db? db}) async {
    return save(db: db);
  }

  Future<bool> delete({Db? db}) async {
    if (id == null) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final res = await coll.deleteOne({'_id': id});
    if (res.isSuccess) {
      _commentForgetSnapshotFor(id!);
    }
    return res.isSuccess;
  }
}

class Comments {
  static String get _collection => 'comments';
  static String get collection => _collection;

  static Future<List<Comment?>> saveMany(
    List<Comment> comments, {
    Db? db,
  }) async {
    if (comments.isEmpty) return <Comment>[];
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final now = DateTime.now().toUtc();
    final List<Map<String, dynamic>> toInsert = [];
    final List<(int, Map<String, dynamic>)> toSave = [];
    final orderedIds = List<dynamic>.filled(comments.length, null);
    final insertPositions = <int>[];
    for (int index = 0; index < comments.length; index++) {
      final item = comments[index];
      final json = _commentNormalizePersistedDocument(item.toJson());
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
      final docId = _commentCoerceDocumentId(entry.$2['_id']);
      if (docId == null) continue;
      if (_commentSnapshotFor(docId) == null) {
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
      rememberMongoDocumentSnapshots(_commentCollection, fetchedSnapshots);
      for (final snapshot in fetchedSnapshots) {
        final snapshotId = _commentCoerceDocumentId(snapshot['_id']);
        if (snapshotId == null) continue;
        fetchedSnapshotsById[snapshotId] = _commentNormalizePersistedDocument(
          snapshot,
        );
      }
    }
    for (final entry in toSave) {
      final position = entry.$1;
      final doc = entry.$2;
      final docId = _commentCoerceDocumentId(doc['_id']);
      if (docId == null) continue;
      final updateDoc = Map<String, dynamic>.from(doc)..remove('_id');
      var snapshot = _commentSnapshotFor(docId) ?? fetchedSnapshotsById[docId];
      if (snapshot == null) continue;
      snapshot = _commentNormalizePersistedDocument(snapshot);
      final updateMap = buildMongoUpdateMapFromSnapshot(
        current: updateDoc,
        snapshot: snapshot,
        trackedKeys: _commentTrackedPersistedKeys,
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
    if (uniqueIds.isEmpty) return <Comment>[];
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
        .map((doc) => doc == null ? null : _commentDeserializeDocument(doc))
        .toList();
  }

  static Future<Comment?> findById(
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
    final normalizedLookups = remapLookups(lookups, _commentFieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      CommentProjections(),
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
      return _commentDeserializeDocument(results.first);
    }
    // fallback: return entire comment
    final comment = await coll.modernFindOne(
      filter: {'_id': id},
      projection:
          canUseDirectProjection ? projDoc.cast<String, Object>() : null,
    );
    return comment == null ? null : _commentDeserializeDocument(comment);
  }

  /// Type-safe findOne by predicate
  static Future<Comment?> findOne(
    Expression Function(QComment c)? predicate, {
    Db? db,
    List<Lookup> lookups = const [],
    List<BaseProjections> projections = const [],
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final normalizedLookups = remapLookups(lookups, _commentFieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      CommentProjections(),
    );

    if (predicate == null) {
      final comment = await coll.modernFindOne(sort: {'created_at': -1});
      if (comment == null) return null;
      return _commentDeserializeDocument(comment);
    }

    final selectorBuilder = predicate(QComment()).toSelectorBuilder();
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
      return _commentDeserializeDocument(results.first);
    }

    // fallback to simple findOne
    final commentResult = await coll.modernFindOne(
      filter: selectorMap.cleaned(),
      projection:
          canUseDirectProjection ? projDoc.cast<String, Object>() : null,
    );
    return commentResult == null
        ? null
        : _commentDeserializeDocument(commentResult);
  }

  /// Type-safe findOne by named arguments
  static Future<Comment?> findOneByNamed({
    ObjectId? id,
    User? author,
    Post? post,
    String? text,
    bool? deleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
    List<Lookup> lookups = const [],
    List<BaseProjections> projections = const [],
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final normalizedLookups = remapLookups(lookups, _commentFieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      CommentProjections(),
    );

    final selector = <String, dynamic>{};

    if (id != null) selector['_id'] = id;
    if (author != null) selector['author'] = author.id;
    if (post != null) selector['post'] = post.id;
    if (text != null) selector['text'] = text;
    if (deleted != null) selector['deleted'] = deleted;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty && projections.isEmpty && normalizedLookups.isEmpty) {
      final comment = await coll.modernFindOne(sort: {'created_at': -1});
      if (comment == null) return null;
      return _commentDeserializeDocument(comment);
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
      final comments =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (comments.isEmpty) return null;
      return _commentDeserializeDocument(comments.first);
    }

    final commentResult = await coll.modernFindOne(
      filter: selector.cleaned(),
      sort: selector.isEmpty ? {'created_at': -1} : null,
      projection:
          canUseDirectProjection ? projDoc.cast<String, Object>() : null,
    );
    return commentResult == null
        ? null
        : _commentDeserializeDocument(commentResult);
  }

  /// Type-safe findMany by predicate
  static Future<List<Comment>> findMany(
    Expression Function(QComment c) predicate, {
    List<Lookup> lookups = const [],
    int? skip,
    int limit = 10,
    (String, int) sort = const ("created_at", -1),
    List<BaseProjections> projections = const [],
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final normalizedLookups = remapLookups(lookups, _commentFieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      CommentProjections(),
    );

    var selectorBuilder = predicate(QComment()).toSelectorBuilder();
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
      final comments =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (comments.isEmpty) return [];
      return _commentDeserializeDocuments(comments);
    }

    final comments =
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
    return _commentDeserializeDocuments(comments);
  }

  /// Type-safe findMany by named arguments
  static Future<List<Comment>> findManyByNamed({
    ObjectId? id,
    User? author,
    Post? post,
    String? text,
    bool? deleted,
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
    final normalizedLookups = remapLookups(lookups, _commentFieldMappings);
    final normalizedProjections = normalizeProjectionList(
      projections,
      CommentProjections(),
    );

    final selector = <String, dynamic>{};

    if (id != null) selector['_id'] = id;
    if (author != null) selector['author'] = author.id;
    if (post != null) selector['post'] = post.id;
    if (text != null) selector['text'] = text;
    if (deleted != null) selector['deleted'] = deleted;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;

    if (selector.isEmpty && projections.isEmpty && normalizedLookups.isEmpty) {
      final comments =
          await coll.modernFind(sort: sort, limit: limit, skip: skip).toList();
      if (comments.isEmpty) return [];
      return _commentDeserializeDocuments(comments);
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
      final comments =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (comments.isEmpty) return [];
      return _commentDeserializeDocuments(comments);
    }

    final comments =
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
    return _commentDeserializeDocuments(comments);
  }

  static Future<bool> deleteOne(
    Expression Function(QComment c) predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final expr = predicate(QComment());
    final selector = expr.toSelectorBuilder();
    final coll = database.collection(_collection);
    final result = await coll.deleteOne(selector.map.cleaned());
    return result.isSuccess;
  }

  /// Type-safe deleteOne by named arguments
  static Future<bool> deleteOneByNamed({
    ObjectId? id,
    User? author,
    Post? post,
    String? text,
    bool? deleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (author != null) selector['author'] = author.id;
    if (post != null) selector['post'] = post.id;
    if (text != null) selector['text'] = text;
    if (deleted != null) selector['deleted'] = deleted;
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
    Expression Function(QComment c) predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final expr = predicate(QComment());
    final selector = expr.toSelectorBuilder();
    final coll = database.collection(_collection);
    final result = await coll.deleteMany(selector.map.cleaned());
    return result.isSuccess;
  }

  /// Type-safe deleteMany by named arguments
  static Future<bool> deleteManyByNamed({
    ObjectId? id,
    User? author,
    Post? post,
    String? text,
    bool? deleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (author != null) selector['author'] = author.id;
    if (post != null) selector['post'] = post.id;
    if (text != null) selector['text'] = text;
    if (deleted != null) selector['deleted'] = deleted;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final result = await coll.deleteMany(selector);
    return result.isSuccess;
  }

  /// Type-safe updateOne
  static Future<Comment?> updateOne(
    Expression Function(QComment c) predicate, {
    ObjectId? id,
    User? author,
    Post? post,
    String? text,
    bool? deleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final modifier = _buildModifier(
      sanitizedDocument({
        if (author != null) 'author': author.id,
        if (post != null) 'post': post.id,
        if (text != null) 'text': text,
        if (deleted != null) 'deleted': deleted,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      }),
    );
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final cleanedSelector =
        predicate(QComment()).toSelectorBuilder().map.cleaned();
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
    return _commentDeserializeDocument(updatedDoc);
  }

  /// Type-safe updateMany
  static Future<List<Comment>> updateMany(
    Expression Function(QComment c) predicate, {
    ObjectId? id,
    User? author,
    Post? post,
    String? text,
    bool? deleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final modifier = _buildModifier(
      sanitizedDocument({
        if (author != null) 'author': author.id,
        if (post != null) 'post': post.id,
        if (text != null) 'text': text,
        if (deleted != null) 'deleted': deleted,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      }),
    );
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final cleanedSelector =
        predicate(QComment()).toSelectorBuilder().map.cleaned();
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
        .map(_commentDeserializeDocument)
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
  static Future<Comment?> updateOneFromMap(
    ObjectId id,
    Map<String, dynamic> updateMap, {
    Db? db,
  }) async {
    final mod = _buildModifier(
      sanitizedDocument(
        updateMap.withValidObjectReferences(
          refFields: _commentRefFields,
          objectIdFields: _commentObjectIdFields,
        ),
      ),
    );
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final result = await coll.updateOne({'_id': id}, mod);
    if (!result.isSuccess) return null;
    final updatedDoc = await coll.modernFindOne(filter: {'_id': id});
    return updatedDoc == null ? null : _commentDeserializeDocument(updatedDoc);
  }

  static Future<int> count(
    Expression Function(QComment c)? predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);

    final selectorMap =
        predicate == null
            ? <String, dynamic>{}
            : predicate(QComment()).toSelectorBuilder().map;

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

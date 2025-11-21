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
    final coll = await database.collection(_collection);
    final now = DateTime.now().toUtc();
    final isInsert = id == null;

    final commentMap = toJson()..remove('_id');
    commentMap.update('created_at', (v) => v ?? now, ifAbsent: () => now);
    commentMap.update('updated_at', (v) => now, ifAbsent: () => now);

    var comment = sanitizedDocument({...commentMap});
    for (var entry in commentMap.entries) {
      final root = entry.key;
      if (_nestedCollections.containsKey(root)) {
        final Map<String, dynamic> value =
            entry.value is Map
                ? Map<String, dynamic>.from(entry.value as Map)
                : <String, dynamic>{};
        if (value.isEmpty) continue;
        final nestedId = value['_id'] as ObjectId?;
        if (nestedId == null) {
          comment.remove(root);
        } else {
          comment[root] = nestedId;
        }
      }
    }

    if (isInsert) {
      final result = await coll.insertOne(comment);
      if (!result.isSuccess) return null;
      final savedDoc = await coll.findOne(where.id(result.id));
      return Comment.fromJson(savedDoc!.withRefs());
    }

    var parentMod = modify.set('updated_at', now);
    comment.forEach((k, v) => parentMod = parentMod.set(k, v));
    final res = await coll.updateOne(where.eq(r'_id', id), parentMod);
    if (!res.isSuccess) return null;
    final savedDoc = await coll.findOne(where.id(id!));
    return Comment.fromJson(savedDoc!.withRefs());
  }

  Future<bool> delete({Db? db}) async {
    if (id == null) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final res = await coll.deleteOne(where.eq(r'_id', id));
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
    final coll = await database.collection(_collection);
    final now = DateTime.now().toUtc();
    final List<Map<String, dynamic>> toInsert = [];
    final List<Map<String, dynamic>> toSave = [];
    for (final c in comments) {
      final json = sanitizedDocument(c.toJson());
      json.update('created_at', (v) => v ?? now, ifAbsent: () => now);
      json.update('updated_at', (v) => now, ifAbsent: () => now);
      final processed = json.map((key, value) {
        if (_nestedCollections.containsKey(key) && value is Map) {
          return MapEntry<String, dynamic>(key, value['_id'] as ObjectId?);
        }
        return MapEntry<String, dynamic>(key, value);
      });
      if (processed.containsKey('_id') && processed['_id'] != null) {
        toSave.add(processed);
      } else {
        processed.remove('_id');
        toInsert.add(processed);
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
      try {
        final rawId = doc['_id'];
        if (rawId is String && rawId.length == 24) {
          doc['_id'] = ObjectId.fromHexString(rawId);
        }
      } catch (_) {
        // ignore invalid conversion and let the driver handle it
      }
      var parentMod = modify.set('updated_at', now);
      doc.forEach((k, v) => parentMod = parentMod.set(k, v));
      await coll.updateOne(where.eq(r'_id', doc['_id']), parentMod);
      affectedIds.add(doc['_id']);
    }
    final uniqueIds = affectedIds.where((e) => e != null).toSet().toList();
    if (uniqueIds.isEmpty) return <Comment>[];
    final insertedDocs =
        await coll.find(where.oneFrom('_id', uniqueIds)).toList();
    return insertedDocs.map((doc) => Comment.fromJson(doc.withRefs())).toList();
  }

  static Future<Comment?> findById(
    dynamic id, {
    Db? db,
    List<Lookup> lookups = const [],
    List<BaseProjections> projections = const [],
  }) async {
    if (id == null) return null;
    if (id is String) id = ObjectId.fromHexString(id);
    if (id is! ObjectId) {
      throw ArgumentError('Invalid id type: ${id.runtimeType}');
    }
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    bool foundLookups = false;
    List<Map<String, Object>> pipeline = [];
    if (projections.isNotEmpty) {
      foundLookups = true;
      final projDoc = <String, int>{};
      pipeline.add({
        r"$match": {'_id': id},
      });
      for (var p in projections) {
        final selected = <String, int>{};
        final inclusions = p.inclusions ?? [];
        final exclusions = p.exclusions ?? [];
        final allProjections = p.toProjection();
        final localField = allProjections.keys.first.split(".").first;
        final foreignColl = _nestedCollections[localField];
        if (inclusions.isNotEmpty) {
          for (var f in inclusions) {
            final path = p.fieldMappings[(f as Enum).name]!;
            selected[path] = 1;
          }
        }
        if (exclusions.isNotEmpty) {
          for (var f in exclusions) {
            final path = p.fieldMappings[(f as Enum).name]!;
            selected[path] = 0;
          }
        }
        if (selected.isEmpty) {
          projDoc.addAll(allProjections);
        } else {
          projDoc.addAll(selected);
        }
        if (foreignColl != null) {
          pipeline.add({
            r'$lookup': {
              'from': foreignColl,
              'localField': localField,
              'foreignField': '_id',
              'as': localField,
            },
          });
          pipeline.add({
            r'$unwind': {
              "path": "\$${localField}",
              "preserveNullAndEmptyArrays": true,
            },
          });
        }
      }
      final _hasBaseType = projections.any((p) => p is CommentProjections);
      if (!_hasBaseType) {
        projDoc.addAll(CommentProjections().toProjection());
      }
      pipeline.add({r'$project': projDoc});
    }
    if (lookups.isNotEmpty) {
      bool hasMatch = pipeline.any((stage) => stage.containsKey(r"\$match"));
      if (!hasMatch) {
        pipeline.add({
          r"\$match": {'_id': id},
        });
      }
      (foundLookups, pipeline) = mergeLookups(
        lookups: lookups,
        existingPipeline: foundLookups ? pipeline : null,
        limit: 1,
      );
    }
    if (foundLookups) {
      final collisionFreePipeline = withNoCollisions(pipeline);
      final results =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (results.isEmpty) return null;
      return Comment.fromJson(results.first.withRefs());
    }
    // fallback: return entire comment
    final comment = await coll.findOne(where.eq(r'_id', id));
    return comment == null ? null : Comment.fromJson(comment.withRefs());
  }

  /// Type-safe findOne by predicate
  static Future<Comment?> findOne(
    Expression Function(QComment c)? predicate, {
    Db? db,
    List<Lookup> lookups = const [],
    List<BaseProjections> projections = const [],
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

    if (predicate == null) {
      final comment = await coll.modernFindOne(sort: {'created_at': -1});
      if (comment == null) return null;
      return Comment.fromJson(comment.withRefs());
    }

    final selectorBuilder = predicate(QComment()).toSelectorBuilder();
    final selectorMap = selectorBuilder.map;

    final projDoc =
        projections.isNotEmpty ? buildProjectionDoc(projections) : null;

    var (foundLookups, pipeline) = toAggregationPipelineWithMap(
      lookupRef: _nestedCollections,
      projections: projDoc,
      limit: 1,
      raw: selectorMap.raw(),
      cleaned: selectorMap.cleaned(),
    );

    if (lookups.isNotEmpty) {
      (foundLookups, pipeline) = mergeLookups(
        lookups: lookups,
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
      return Comment.fromJson(results.first.withRefs());
    }

    // fallback to simple findOne
    final commentResult = await coll.findOne(selectorMap.cleaned());
    return commentResult == null
        ? null
        : Comment.fromJson(commentResult.withRefs());
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
    final coll = await database.collection(_collection);

    final selector = <String, dynamic>{};

    if (id != null) selector['_id'] = id;
    if (author != null) selector['author'] = author.id;
    if (post != null) selector['post'] = post.id;
    if (text != null) selector['text'] = text;
    if (deleted != null) selector['deleted'] = deleted;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) {
      final comment = await coll.modernFindOne(sort: {'created_at': -1});
      if (comment == null) return null;
      return Comment.fromJson(comment.withRefs());
    }

    bool foundLookups = false;
    List<Map<String, Object>> pipeline = [];

    if (projections.isNotEmpty) {
      foundLookups = true;
      final projDoc = <String, int>{};
      pipeline.add({r"$match": selector});
      for (var p in projections) {
        final selected = <String, int>{};
        final inclusions = p.inclusions ?? [];
        final exclusions = p.exclusions ?? [];
        final allProjections = p.toProjection();
        final localField = allProjections.keys.first.split(".").first;
        final foreignColl = _nestedCollections[localField];
        if (inclusions.isNotEmpty) {
          for (var f in inclusions) {
            final path = p.fieldMappings[(f as Enum).name]!;
            selected[path] = 1;
          }
        }
        if (exclusions.isNotEmpty) {
          for (var f in exclusions) {
            final path = p.fieldMappings[(f as Enum).name]!;
            selected[path] = 0;
          }
        }
        if (selected.isEmpty) {
          projDoc.addAll(allProjections);
        } else {
          projDoc.addAll(selected);
        }
        if (foreignColl != null) {
          pipeline.add({
            r'$lookup': {
              'from': foreignColl,
              'localField': localField,
              'foreignField': '_id',
              'as': localField,
            },
          });
          pipeline.add({
            r'$unwind': {
              "path": "\$${localField}",
              "preserveNullAndEmptyArrays": true,
            },
          });
        }
      }
      final _hasBaseType = projections.any((p) => p is CommentProjections);
      if (!_hasBaseType) {
        projDoc.addAll(CommentProjections().toProjection());
      }
      pipeline.add({r'$project': projDoc});
    }

    if (lookups.isNotEmpty) {
      (foundLookups, pipeline) = mergeLookups(
        lookups: lookups,
        existingPipeline: foundLookups ? pipeline : null,
        queryMap: foundLookups ? null : selector,
        limit: 1,
      );
    }

    if (foundLookups) {
      final collisionFreePipeline = withNoCollisions(pipeline);
      final comments =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (comments.isEmpty) return null;
      return comments.map((d) => Comment.fromJson(d.withRefs())).toList().first;
    }

    final commentResult = await coll.findOne(selector);
    return commentResult == null
        ? null
        : Comment.fromJson(commentResult.withRefs());
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
    final coll = await database.collection(_collection);

    var selectorBuilder = predicate(QComment()).toSelectorBuilder();
    var selectorMap = selectorBuilder.map;

    final projDoc =
        projections.isNotEmpty ? buildProjectionDoc(projections) : null;

    var (foundLookups, pipeline) = toAggregationPipelineWithMap(
      lookupRef: _nestedCollections,
      projections: projDoc,
      raw: selectorMap.raw(),
      sort: sort,
      limit: limit,
      skip: skip,
      cleaned: selectorMap.cleaned(),
    );

    if (lookups.isNotEmpty) {
      (foundLookups, pipeline) = mergeLookups(
        lookups: lookups,
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
      return comments.map((d) => Comment.fromJson(d.withRefs())).toList();
    }

    if (skip != null) selectorBuilder = selectorBuilder.skip(skip);
    selectorBuilder = selectorBuilder.limit(limit);

    selectorMap = selectorBuilder.map;

    final comments = await coll.find(selectorMap.cleaned()).toList();
    return comments.map((e) => Comment.fromJson(e.withRefs())).toList();
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
    final coll = await database.collection(_collection);

    final selector = <String, dynamic>{};

    if (id != null) selector['_id'] = id;
    if (author != null) selector['author'] = author.id;
    if (post != null) selector['post'] = post.id;
    if (text != null) selector['text'] = text;
    if (deleted != null) selector['deleted'] = deleted;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;

    if (selector.isEmpty) {
      final comments =
          await coll.modernFind(sort: sort, limit: limit, skip: skip).toList();
      if (comments.isEmpty) return [];
      return comments.map((e) => Comment.fromJson(e.withRefs())).toList();
    }

    bool foundLookups = false;
    List<Map<String, Object>> pipeline = [];

    if (projections.isNotEmpty) {
      foundLookups = true;
      final projDoc = <String, int>{};
      pipeline.add({r"$match": selector});
      pipeline.add({r"$sort": sort});
      pipeline.add({r"$limit": limit});
      for (var p in projections) {
        final selected = <String, int>{};
        final inclusions = p.inclusions ?? [];
        final exclusions = p.exclusions ?? [];
        final allProjections = p.toProjection();
        final localField = allProjections.keys.first.split(".").first;
        final foreignColl = _nestedCollections[localField];
        if (inclusions.isNotEmpty) {
          for (var f in inclusions) {
            final path = p.fieldMappings[(f as Enum).name]!;
            selected[path] = 1;
          }
        }
        if (exclusions.isNotEmpty) {
          for (var f in exclusions) {
            final path = p.fieldMappings[(f as Enum).name]!;
            selected[path] = 0;
          }
        }
        if (selected.isEmpty) {
          projDoc.addAll(allProjections);
        } else {
          projDoc.addAll(selected);
        }
        if (foreignColl != null) {
          pipeline.add({
            r'$lookup': {
              'from': foreignColl,
              'localField': localField,
              'foreignField': '_id',
              'as': localField,
            },
          });
          pipeline.add({
            r'$unwind': {
              "path": "\$${localField}",
              "preserveNullAndEmptyArrays": true,
            },
          });
        }
      }
      final _hasBaseType = projections.any((p) => p is CommentProjections);
      if (!_hasBaseType) {
        projDoc.addAll(CommentProjections().toProjection());
      }
      pipeline.add({r'$project': projDoc});
    }

    if (lookups.isNotEmpty) {
      (foundLookups, pipeline) = mergeLookups(
        lookups: lookups,
        existingPipeline: foundLookups ? pipeline : null,
        queryMap: foundLookups ? null : selector.cleaned(),
        sort: foundLookups ? null : firstEntryToTuple(sort),
        skip: foundLookups ? null : skip,
        limit: foundLookups ? null : limit,
      );
    }

    if (foundLookups && pipeline.isNotEmpty) {
      final collisionFreePipeline = withNoCollisions(pipeline);
      final comments =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (comments.isEmpty) return [];
      return comments.map((d) => Comment.fromJson(d.withRefs())).toList();
    }

    final comments =
        await coll
            .modernFind(filter: selector, limit: limit, skip: skip, sort: sort)
            .toList();
    return comments.map((e) => Comment.fromJson(e.withRefs())).toList();
  }

  static Future<bool> deleteOne(
    Expression Function(QComment c) predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final expr = predicate(QComment());
    final selector = expr.toSelectorBuilder();
    final coll = await database.collection(_collection);
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
    final coll = await database.collection(_collection);
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
    final coll = await database.collection(_collection);
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
    final coll = await database.collection(_collection);
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
        if (id != null) '_id': id,
        if (author != null) 'author': author.id,
        if (post != null) 'post': post.id,
        if (text != null) 'text': text,
        if (deleted != null) 'deleted': deleted,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      }),
    );
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final retrieved = await findOne(predicate);
    if (retrieved == null) return null;
    final result = await coll.updateOne(where.id(retrieved.id!), modifier);
    if (!result.isSuccess) return null;
    final updatedDoc = await coll.findOne({'_id': retrieved.id});
    if (updatedDoc == null) return null;
    return Comment.fromJson(updatedDoc.withRefs());
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
        if (id != null) '_id': id,
        if (author != null) 'author': author.id,
        if (post != null) 'post': post.id,
        if (text != null) 'text': text,
        if (deleted != null) 'deleted': deleted,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      }),
    );
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final retrieved = await findMany(predicate);
    if (retrieved.isEmpty) return [];
    final ids = retrieved.map((doc) => doc.id).toList();
    final result = await coll.updateMany(where.oneFrom('_id', ids), modifier);
    if (!result.isSuccess) return [];
    final updatedCursor = coll.find(where.oneFrom('_id', ids));
    final updatedDocs = await updatedCursor.toList();
    if (updatedDocs.isEmpty) return [];
    return updatedDocs.map((doc) => Comment.fromJson(doc.withRefs())).toList();
  }

  static ModifierBuilder _buildModifier(Map<String, dynamic> updateMap) {
    final now = DateTime.now().toUtc();
    var modifier = modify.set('updated_at', now);
    updateMap.forEach((k, v) => modifier = modifier.set(k, v));
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
      sanitizedDocument(updateMap.withValidObjectReferences()),
    );
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final result = await coll.updateOne(where.id(id), mod);
    if (!result.isSuccess) return null;
    final updatedDoc = await coll.findOne({'_id': id});
    return updatedDoc == null ? null : Comment.fromJson(updatedDoc.withRefs());
  }

  static Future<int> count(
    Expression Function(QComment c)? predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

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

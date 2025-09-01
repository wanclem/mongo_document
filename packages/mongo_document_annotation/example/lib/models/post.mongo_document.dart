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

enum PostFields { id, body, postNote, tags, createdAt, updatedAt }

class PostProjections implements BaseProjections {
  @override
  final List<PostFields>? inclusions;
  final List<PostFields>? exclusions;
  @override
  final Map<String, dynamic> fieldMappings = const {
    "id": "_id",
    "body": "body",
    "postNote": "post_note",
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
      'tags': 1,
      'created_at': 1,
      'updated_at': 1,
    };
  }
}

const _nestedCollections = <String, String>{'author': 'accounts'};

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
    final coll = await database.collection(_collection);
    final now = DateTime.now().toUtc();
    final isInsert = id == null;

    final postMap = toJson()..remove('_id');
    postMap.update('created_at', (v) => v ?? now, ifAbsent: () => now);
    postMap.update('updated_at', (v) => now, ifAbsent: () => now);

    var post = {...postMap};
    for (var entry in postMap.entries) {
      final root = entry.key;
      if (_nestedCollections.containsKey(root)) {
        final Map<String, dynamic> value =
            entry.value is Map
                ? Map<String, dynamic>.from(entry.value as Map)
                : <String, dynamic>{};
        if (value.isEmpty) continue;
        final nestedId = value['_id'] as ObjectId?;
        if (nestedId == null) {
          post.remove(root);
        } else {
          post[root] = nestedId;
        }
      }
    }

    if (isInsert) {
      final result = await coll.insertOne(post);
      if (!result.isSuccess) return null;
      final savedDoc = await coll.findOne(where.id(result.id));
      return Post.fromJson(savedDoc!.withRefs());
    }

    var parentMod = modify.set('updated_at', now);
    post.forEach((k, v) => parentMod = parentMod.set(k, v));
    final res = await coll.updateOne(where.eq(r'_id', id), parentMod);
    if (!res.isSuccess) return null;
    final savedDoc = await coll.findOne(where.id(id!));
    return Post.fromJson(savedDoc!.withRefs());
  }

  Future<bool> delete({Db? db}) async {
    if (id == null) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final res = await coll.deleteOne(where.eq(r'_id', id));
    return res.isSuccess;
  }
}

class Posts {
  static String get _collection => 'posts';
  static Future<List<Post?>> saveMany(List<Post> posts, {Db? db}) async {
    if (posts.isEmpty) return <Post>[];
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final now = DateTime.now().toUtc();
    final List<Map<String, dynamic>> toInsert = [];
    final List<Map<String, dynamic>> toSave = [];
    for (final p in posts) {
      final json = p.toJson();
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
      await coll.save(doc);
      affectedIds.add(doc['_id']);
    }
    final uniqueIds = affectedIds.where((e) => e != null).toSet().toList();
    if (uniqueIds.isEmpty) return <Post>[];
    final insertedDocs =
        await coll.find(where.oneFrom('_id', uniqueIds)).toList();
    return insertedDocs.map((doc) => Post.fromJson(doc.withRefs())).toList();
  }

  static Future<Post?> findById(
    dynamic id, {
    Db? db,
    List<BaseProjections> projections = const [],
  }) async {
    if (id == null) return null;
    if (id is String) id = ObjectId.fromHexString(id);
    if (id is! ObjectId) {
      throw ArgumentError('Invalid id type: ${id.runtimeType}');
    }
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

    if (projections.isNotEmpty) {
      final pipeline = <Map<String, Object>>[];
      final projDoc = <String, int>{};
      pipeline.add({
        r"$match": {'_id': id},
      });
      final selected = <String, int>{};
      for (var p in projections) {
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
          selected.addAll(allProjections);
        }
        if (selected.isNotEmpty) {
          projDoc.addAll(selected);
        }
        projDoc.addAll(PostProjections().toProjection());
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
      pipeline.add({r'$project': projDoc});

      final posts = await coll.aggregateToStream(pipeline).toList();
      if (posts.isEmpty) return null;
      return Post.fromJson(posts.first.withRefs());
    }

    // fallback: return entire post
    final post = await coll.findOne(where.eq(r'_id', id));
    return post == null ? null : Post.fromJson(post.withRefs());
  }

  /// Type-safe findOne by predicate
  static Future<Post?> findOne(
    Expression Function(QPost p)? predicate, {
    Db? db,
    List<BaseProjections> projections = const [],
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

    if (predicate == null) {
      final post = await coll.modernFindOne(sort: {'created_at': -1});
      if (post == null) return null;
      return Post.fromJson(post.withRefs());
    }
    final selectorBuilder = predicate(QPost()).toSelectorBuilder();
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
      return Post.fromJson(results.first.withRefs());
    }

    // fallback to simple findOne
    final postResult = await coll.findOne(selectorMap.cleaned());
    return postResult == null ? null : Post.fromJson(postResult.withRefs());
  }

  /// Type-safe findOne by named arguments
  static Future<Post?> findOneByNamed({
    ObjectId? id,
    String? body,
    String? postNote,
    User? author,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
    List<BaseProjections> projections = const [],
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (body != null) selector['body'] = body;
    if (postNote != null) selector['post_note'] = postNote;
    if (author != null) selector['author'] = author.id;
    if (tags != null) selector['tags'] = tags;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) {
      final post = await coll.modernFindOne(sort: {'created_at': -1});
      if (post == null) return null;
      return Post.fromJson(post.withRefs());
    }
    if (projections.isNotEmpty) {
      final pipeline = <Map<String, Object>>[];
      final projDoc = <String, int>{};
      pipeline.add({r"$match": selector});
      final selected = <String, int>{};
      for (var p in projections) {
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
          selected.addAll(allProjections);
        }
        if (selected.isNotEmpty) {
          projDoc.addAll(selected);
        }
        projDoc.addAll(PostProjections().toProjection());
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
      pipeline.add({r'$project': projDoc});

      final posts = await coll.aggregateToStream(pipeline).toList();
      if (posts.isEmpty) return null;
      return Post.fromJson(posts.first.withRefs());
    }
    final postResult = await coll.findOne(selector);
    return postResult == null ? null : Post.fromJson(postResult.withRefs());
  }

  /// Type-safe findMany by predicate
  static Future<List<Post>> findMany(
    Expression Function(QPost p) predicate, {
    int? skip,
    int limit = 10,
    (String, int) sort = const ("created_at", -1),
    List<BaseProjections> projections = const [],
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

    var selectorBuilder = predicate(QPost()).toSelectorBuilder();
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
      final posts = await coll.aggregateToStream(pipeline).toList();
      if (posts.isEmpty) return [];
      return posts.map((d) => Post.fromJson(d.withRefs())).toList();
    }

    if (skip != null) selectorBuilder = selectorBuilder.skip(skip);
    selectorBuilder = selectorBuilder.limit(limit);

    selectorMap = selectorBuilder.map;

    final posts = await coll.find(selectorMap.cleaned()).toList();
    return posts.map((e) => Post.fromJson(e.withRefs())).toList();
  }

  /// Type-safe findMany by named arguments
  static Future<List<Post>> findManyByNamed({
    ObjectId? id,
    String? body,
    String? postNote,
    User? author,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
    List<BaseProjections> projections = const [],
    Map<String, Object> sort = const {'created_at': -1},
    int? skip,
    int limit = 10,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (body != null) selector['body'] = body;
    if (postNote != null) selector['post_note'] = postNote;
    if (author != null) selector['author'] = author.id;
    if (tags != null) selector['tags'] = tags;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) {
      final posts =
          await coll.modernFind(sort: sort, limit: limit, skip: skip).toList();
      if (posts.isEmpty) return [];
      return posts.map((e) => Post.fromJson(e.withRefs())).toList();
    }
    if (projections.isNotEmpty) {
      final pipeline = <Map<String, Object>>[];
      final projDoc = <String, int>{};
      pipeline.add({r"$match": selector});
      pipeline.add({r"$sort": sort});
      pipeline.add({r"$limit": limit});
      final selected = <String, int>{};
      for (var p in projections) {
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
          selected.addAll(allProjections);
        }
        if (selected.isNotEmpty) {
          projDoc.addAll(selected);
        }
        projDoc.addAll(PostProjections().toProjection());
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
      pipeline.add({r'$project': projDoc});

      final posts = await coll.aggregateToStream(pipeline).toList();
      if (posts.isEmpty) return [];
      return posts.map((d) => Post.fromJson(d.withRefs())).toList();
    }
    final posts =
        await coll
            .modernFind(filter: selector, limit: limit, skip: skip, sort: sort)
            .toList();
    return posts.map((e) => Post.fromJson(e.withRefs())).toList();
  }

  static Future<bool> deleteOne(
    Expression Function(QPost p) predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final expr = predicate(QPost());
    final selector = expr.toSelectorBuilder();
    final coll = await database.collection(_collection);
    final result = await coll.deleteOne(selector.map.cleaned());
    return result.isSuccess;
  }

  /// Type-safe deleteOne by named arguments
  static Future<bool> deleteOneByNamed({
    ObjectId? id,
    String? body,
    String? postNote,
    User? author,
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
    if (tags != null) selector['tags'] = tags;
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
    Expression Function(QPost p) predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final expr = predicate(QPost());
    final selector = expr.toSelectorBuilder();
    final coll = await database.collection(_collection);
    final result = await coll.deleteMany(selector.map.cleaned());
    return result.isSuccess;
  }

  /// Type-safe deleteMany by named arguments
  static Future<bool> deleteManyByNamed({
    ObjectId? id,
    String? body,
    String? postNote,
    User? author,
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
    if (tags != null) selector['tags'] = tags;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
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
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final modifier = _buildModifier({
      if (id != null) '_id': id,
      if (body != null) 'body': body,
      if (postNote != null) 'post_note': postNote,
      if (author != null) 'author': author.id,
      if (tags != null) 'tags': tags,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final retrieved = await findOne(predicate);
    if (retrieved == null) return null;
    final result = await coll.updateOne(where.id(retrieved.id!), modifier);
    if (!result.isSuccess) return null;
    final updatedDoc = await coll.findOne({'_id': retrieved.id});
    if (updatedDoc == null) return null;
    return Post.fromJson(updatedDoc.withRefs());
  }

  /// Type-safe updateMany
  static Future<List<Post>> updateMany(
    Expression Function(QPost p) predicate, {
    ObjectId? id,
    String? body,
    String? postNote,
    User? author,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final modifier = _buildModifier({
      if (id != null) '_id': id,
      if (body != null) 'body': body,
      if (postNote != null) 'post_note': postNote,
      if (author != null) 'author': author.id,
      if (tags != null) 'tags': tags,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
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
    return updatedDocs.map((doc) => Post.fromJson(doc.withRefs())).toList();
  }

  static ModifierBuilder _buildModifier(Map<String, dynamic> updateMap) {
    final now = DateTime.now().toUtc();
    var modifier = modify.set('updated_at', now);
    updateMap.forEach((k, v) => modifier = modifier.set(k, v));
    return modifier;
  }

  /// Prioritize `updateOne` whenever possible to avoid type mismatch.
  /// This method is a fallback for cases where you just had to use a map.
  static Future<Post?> updateOneFromMap(
    ObjectId id,
    Map<String, dynamic> updateMap, {
    Db? db,
  }) async {
    final mod = _buildModifier(updateMap);
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final result = await coll.updateOne(where.id(id), mod);
    if (!result.isSuccess) return null;
    final updatedDoc = await coll.findOne({'_id': id});
    return updatedDoc == null ? null : Post.fromJson(updatedDoc.withRefs());
  }

  static Future<int> count(
    Expression Function(QPost p)? predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

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

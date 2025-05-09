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

const _nestedCollections = <String, String>{
  'author': 'users',
  'lastComment': 'comments',
};

enum AuthorFields { id, firstName, lastName, email, age, createdAt, updatedAt }

class AuthorProjections implements BaseProjections {
  @override
  final List<AuthorFields>? inclusions;
  final List<AuthorFields>? exclusions;
  @override
  final Map<String, dynamic> fieldMappings = const {
    "id": "author._id",
    "firstName": "author.first_name",
    "lastName": "author.last_name",
    "email": "author.email",
    "age": "author.age",
    "createdAt": "author.created_at",
    "updatedAt": "author.updated_at",
  };
  const AuthorProjections({this.inclusions, this.exclusions});

  @override
  Map<String, int> toProjection() {
    return {
      'author._id': 1,
      'author.first_name': 1,
      'author.last_name': 1,
      'author.email': 1,
      'author.age': 1,
      'author.created_at': 1,
      'author.updated_at': 1,
    };
  }
}

enum LastCommentFields { id, post, text, age, createdAt, updatedAt }

class LastCommentProjections implements BaseProjections {
  @override
  final List<LastCommentFields>? inclusions;
  final List<LastCommentFields>? exclusions;
  @override
  final Map<String, dynamic> fieldMappings = const {
    "id": "lastComment._id",
    "post": "lastComment.post",
    "text": "lastComment.text",
    "age": "lastComment.age",
    "createdAt": "lastComment.created_at",
    "updatedAt": "lastComment.updated_at",
  };
  const LastCommentProjections({this.inclusions, this.exclusions});

  @override
  Map<String, int> toProjection() {
    return {
      'lastComment._id': 1,
      'lastComment.post': 1,
      'lastComment.text': 1,
      'lastComment.age': 1,
      'lastComment.created_at': 1,
      'lastComment.updated_at': 1,
    };
  }
}

class QPost {
  final String _prefix;
  QPost([this._prefix = '']);

  String _key(String field) => _prefix.isEmpty ? field : '$_prefix.$field';

  QueryField<ObjectId?> get id => QueryField<ObjectId?>(_key('_id'));

  QUser get author => QUser(_key('author'));

  QComment get lastComment => QComment(_key('last_comment'));

  QList<String> get tags => QList<String>(_key('tags'));

  QueryField<String?> get body => QueryField<String?>(_key('body'));

  QueryField<dynamic> get name => QueryField<dynamic>(_key('name'));

  QueryField<DateTime?> get createdAt =>
      QueryField<DateTime?>(_key('created_at'));

  QueryField<DateTime?> get updatedAt =>
      QueryField<DateTime?>(_key('updated_at'));
}

extension $PostExtension on Post {
  static String get _collection => 'posts';

  Future<Post?> save() async {
    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);
    final now = DateTime.now().toUtc();
    final isInsert = id == null;

    final postMap =
        toJson()
          ..remove('_id')
          ..removeWhere((key, value) => value == null);
    postMap.update('created_at', (v) => v ?? now, ifAbsent: () => now);
    postMap.update('updated_at', (v) => now, ifAbsent: () => now);

    var post = {...postMap};
    final nestedUpdates = <Future>[];
    for (var entry in postMap.entries) {
      final root = entry.key;
      if (_nestedCollections.containsKey(root)) {
        final collectionName = _nestedCollections[root]!;
        var nestedColl = db.collection(collectionName);
        var value = entry.value as Map<String, dynamic>?;
        if (value == null) continue;
        value.removeWhere((key, value) => value == null);
        final nestedId = value['_id'] as ObjectId?;
        if (nestedId == null) {
          post.remove(root);
        } else {
          post[root] = nestedId;
          final nestedMap = value..remove('_id');
          if (nestedMap.isNotEmpty) {
            var mod = modify.set('updated_at', now);
            nestedMap.forEach((k, v) => mod = mod.set(k, v));
            nestedUpdates.add(
              nestedColl.updateOne(where.eq(r'_id', nestedId), mod),
            );
          }
        }
      }
    }

    if (isInsert) {
      final result = await coll.insertOne(post);
      if (!result.isSuccess) return null;
      await Future.wait(nestedUpdates);
      return copyWith(id: result.id);
    }

    var parentMod = modify.set('updated_at', now);
    post.forEach((k, v) => parentMod = parentMod.set(k, v));
    final res = await coll.updateOne(where.eq(r'_id', id), parentMod);
    if (!res.isSuccess) return null;
    await Future.wait(nestedUpdates);
    return this;
  }

  Future<bool> delete() async {
    if (id == null) return false;
    final res = await (await MongoConnection.getDb())
        .collection(_collection)
        .deleteOne(where.eq(r'_id', id));
    return res.isSuccess;
  }
}

class Posts {
  static String get _collection => 'posts';

  /// Type-safe saveMany
  static Future<List<Post?>> saveMany(List<Post> posts) async {
    if (posts.isEmpty) return <Post>[];
    final List<Map<String, dynamic>> postsMap =
        posts.map((p) {
          final json = p.toJson()..remove('_id');
          return json.map((key, value) {
            if (_nestedCollections.containsKey(key)) {
              return MapEntry<String, dynamic>(key, value['_id'] as ObjectId?);
            }
            return MapEntry<String, dynamic>(key, value);
          });
        }).toList();
    final coll = (await MongoConnection.getDb()).collection(_collection);
    final result = await coll.insertMany(postsMap);
    return posts.asMap().entries.map((e) {
      final idx = e.key;
      final post = e.value;
      final id = result.isSuccess ? result.ids![idx] : null;
      return post.copyWith(id: id);
    }).toList();
  }

  /// Find a Post by its _id with optional nested-doc projections
  static Future<Post?> findById(
    dynamic postId, {
    List<BaseProjections> projections = const [],
  }) async {
    if (postId == null) return null;
    if (postId is String) postId = ObjectId.fromHexString(postId);
    if (postId is! ObjectId) {
      throw ArgumentError('Invalid postId type: ${postId.runtimeType}');
    }

    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);

    if (projections.isNotEmpty) {
      final pipeline = <Map<String, Object>>[];
      final projDoc = <String, int>{};
      pipeline.add({
        r"$match": {'_id': postId},
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
    final post = await coll.findOne(where.eq(r'_id', postId));
    return post == null ? null : Post.fromJson(post.withRefs());
  }

  /// Type-safe findOne by predicate
  static Future<Post?> findOne(
    Expression Function(QPost p)? predicate, {
    List<BaseProjections> projections = const [],
  }) async {
    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);

    if (predicate == null) {
      final post = await coll.modernFindOne(sort: {'created_at': -1});
      if (post == null) return null;
      return Post.fromJson(post.withRefs());
    }
    final selectorBuilder = predicate(QPost()).toSelectorBuilder();
    final selectorMap = selectorBuilder.map.flatQuery();

    final projDoc =
        projections.isNotEmpty ? buildProjectionDoc(projections) : null;
    final (foundLookups, pipeline) = selectorMap.toAggregationPipelineWithMap(
      lookupRef: _nestedCollections,
      projections: projDoc,
    );

    if (foundLookups || projDoc != null) {
      final results = await coll.aggregateToStream(pipeline).toList();
      if (results.isEmpty) return null;
      return Post.fromJson(results.first.withRefs());
    }

    // fallback to simple findOne
    final postResult = await coll.findOne(selectorMap);
    return postResult == null ? null : Post.fromJson(postResult);
  }

  /// Type-safe findOne by named arguments
  static Future<Post?> findOneByNamed({
    ObjectId? id,
    User? author,
    Comment? lastComment,
    List<String>? tags,
    String? body,
    dynamic name,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<BaseProjections> projections = const [],
  }) async {
    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);

    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (author != null) selector['author'] = author;
    if (lastComment != null) selector['last_comment'] = lastComment;
    if (tags != null) selector['tags'] = tags;
    if (body != null) selector['body'] = body;
    if (name != null) selector['name'] = name;
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
    int? limit,
    List<BaseProjections> projections = const [],
  }) async {
    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);

    var selectorBuilder = predicate(QPost()).toSelectorBuilder();
    if (skip != null) selectorBuilder = selectorBuilder.skip(skip);
    if (limit != null) selectorBuilder = selectorBuilder.limit(limit);
    final selectorMap = selectorBuilder.map.flatQuery();

    final projDoc =
        projections.isNotEmpty ? buildProjectionDoc(projections) : null;
    final (foundLookups, pipeline) = selectorMap.toAggregationPipelineWithMap(
      lookupRef: _nestedCollections,
      projections: projDoc,
    );

    if (foundLookups || projDoc != null) {
      final posts = await coll.aggregateToStream(pipeline).toList();
      if (posts.isEmpty) return [];
      return posts.map((d) => Post.fromJson(d.withRefs())).toList();
    }

    final posts =
        await (await MongoConnection.getDb())
            .collection(_collection)
            .find(selectorMap)
            .toList();
    return posts.map((e) => Post.fromJson(e.withRefs())).toList();
  }

  /// Type-safe findMany by named arguments
  static Future<List<Post>> findManyByNamed({
    ObjectId? id,
    User? author,
    Comment? lastComment,
    List<String>? tags,
    String? body,
    dynamic name,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<BaseProjections> projections = const [],
    Map<String, Object> sort = const {},
    int? skip,
    int limit = 10,
  }) async {
    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);

    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (author != null) selector['author'] = author;
    if (lastComment != null) selector['last_comment'] = lastComment;
    if (tags != null) selector['tags'] = tags;
    if (body != null) selector['body'] = body;
    if (name != null) selector['name'] = name;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) {
      final posts =
          await coll
              .modernFind(sort: {'created_at': -1}, limit: limit, skip: skip)
              .toList();
      if (posts.isEmpty) return [];
      return posts.map((e) => Post.fromJson(e.withRefs())).toList();
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

  /// Type-safe deleteOne by predicate
  static Future<bool> deleteOne(Expression Function(QPost p) predicate) async {
    final expr = predicate(QPost());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
        .collection(_collection)
        .deleteOne(selector.map.flatQuery());
    return result.isSuccess;
  }

  /// Type-safe deleteOne by named arguments
  static Future<bool> deleteOneByNamed({
    ObjectId? id,
    User? author,
    Comment? lastComment,
    List<String>? tags,
    String? body,
    dynamic name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (author != null) selector['author'] = author;
    if (lastComment != null) selector['last_comment'] = lastComment;
    if (tags != null) selector['tags'] = tags;
    if (body != null) selector['body'] = body;
    if (name != null) selector['name'] = name;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) return false;
    final result = await (await MongoConnection.getDb())
        .collection(_collection)
        .deleteOne(selector);
    return result.isSuccess;
  }

  /// Type-safe deleteMany
  static Future<bool> deleteMany(Expression Function(QPost p) predicate) async {
    final expr = predicate(QPost());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
        .collection(_collection)
        .deleteMany(selector.map.flatQuery());
    return result.isSuccess;
  }

  /// Type-safe deleteMany by named arguments
  static Future<bool> deleteManyByNamed({
    ObjectId? id,
    User? author,
    Comment? lastComment,
    List<String>? tags,
    String? body,
    dynamic name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (author != null) selector['author'] = author;
    if (lastComment != null) selector['last_comment'] = lastComment;
    if (tags != null) selector['tags'] = tags;
    if (body != null) selector['body'] = body;
    if (name != null) selector['name'] = name;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) return false;
    final result = await (await MongoConnection.getDb())
        .collection(_collection)
        .deleteMany(selector);
    return result.isSuccess;
  }

  /// Type-safe updateOne
  static Future<bool> updateOne(
    Expression Function(QPost p) predicate, {
    ObjectId? id,
    User? author,
    Comment? lastComment,
    List<String>? tags,
    String? body,
    dynamic name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final modifier = _buildModifier({
      if (id != null) '_id': id,
      if (author != null) 'author': author.id,
      if (lastComment != null) 'last_comment': lastComment.id,
      if (tags != null) 'tags': tags,
      if (body != null) 'body': body,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
    final expr = predicate(QPost());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
        .collection(_collection)
        .updateOne(selector.map.flatQuery(), modifier);
    return result.isSuccess;
  }

  /// Type-safe updateMany
  static Future<bool> updateMany(
    Expression Function(QPost p) predicate, {
    ObjectId? id,
    User? author,
    Comment? lastComment,
    List<String>? tags,
    String? body,
    dynamic name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final modifier = _buildModifier({
      if (id != null) '_id': id,
      if (author != null) 'author': author.id,
      if (lastComment != null) 'last_comment': lastComment.id,
      if (tags != null) 'tags': tags,
      if (body != null) 'body': body,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
    final expr = predicate(QPost());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
        .collection(_collection)
        .updateMany(selector.map.flatQuery(), modifier);
    return result.isSuccess;
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
    Map<String, dynamic> updateMap,
  ) async {
    final conn = await MongoConnection.getDb();
    final coll = conn.collection(_collection);
    final result = await coll.updateOne({'_id': id}, {'\$set': updateMap});
    if (!result.isSuccess) return null;
    final updatedDoc = await coll.findOne({'_id': id});
    return updatedDoc == null ? null : Post.fromJson(updatedDoc);
  }

  static Future<int> count(Expression Function(QPost p)? predicate) async {
    final selectorMap =
        predicate == null
            ? <String, dynamic>{}
            : predicate(QPost()).toSelectorBuilder().map.flatQuery();

    final (foundLookups, pipelineWithoutCount) = selectorMap
        .toAggregationPipelineWithMap(lookupRef: _nestedCollections);

    if (foundLookups) {
      final pipeline = [
        ...pipelineWithoutCount,
        {r'$count': 'count'},
      ];

      final result =
          await (await MongoConnection.getDb())
              .collection(_collection)
              .aggregateToStream(pipeline)
              .toList();

      if (result.isEmpty) return 0;
      return result.first['count'] as int;
    }

    return (await MongoConnection.getDb())
        .collection(_collection)
        .count(selectorMap);
  }
}

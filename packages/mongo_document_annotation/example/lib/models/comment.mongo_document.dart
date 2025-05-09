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

const _nestedCollections = <String, String>{'post': 'posts'};

enum PostFields {
  id,
  author,
  lastComment,
  tags,
  body,
  name,
  createdAt,
  updatedAt,
}

class PostProjections implements BaseProjections {
  @override
  final List<PostFields>? inclusions;
  final List<PostFields>? exclusions;
  @override
  final Map<String, dynamic> fieldMappings = const {
    "id": "post._id",
    "author": "post.author",
    "lastComment": "post.last_comment",
    "tags": "post.tags",
    "body": "post.body",
    "name": "post.name",
    "createdAt": "post.created_at",
    "updatedAt": "post.updated_at",
  };
  const PostProjections({this.inclusions, this.exclusions});

  @override
  Map<String, int> toProjection() {
    return {
      'post._id': 1,
      'post.author': 1,
      'post.last_comment': 1,
      'post.tags': 1,
      'post.body': 1,
      'post.name': 1,
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

  QPost get post => QPost(_key('post'));

  QueryField<String?> get text => QueryField<String?>(_key('text'));

  QueryField<int> get age => QueryField<int>(_key('age'));

  QueryField<DateTime?> get createdAt =>
      QueryField<DateTime?>(_key('created_at'));

  QueryField<DateTime?> get updatedAt =>
      QueryField<DateTime?>(_key('updated_at'));
}

extension $CommentExtension on Comment {
  static String get _collection => 'comments';

  Future<Comment?> save() async {
    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);
    final now = DateTime.now().toUtc();
    final isInsert = id == null;

    final commentMap =
        toJson()
          ..remove('_id')
          ..removeWhere((key, value) => value == null);
    commentMap.update('created_at', (v) => v ?? now, ifAbsent: () => now);
    commentMap.update('updated_at', (v) => now, ifAbsent: () => now);

    var comment = {...commentMap};
    final nestedUpdates = <Future>[];
    for (var entry in commentMap.entries) {
      final root = entry.key;
      if (_nestedCollections.containsKey(root)) {
        final collectionName = _nestedCollections[root]!;
        var nestedColl = db.collection(collectionName);
        var value = entry.value as Map<String, dynamic>?;
        if (value == null) continue;
        value.removeWhere((key, value) => value == null);
        final nestedId = value['_id'] as ObjectId?;
        if (nestedId == null) {
          comment.remove(root);
        } else {
          comment[root] = nestedId;
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
      final result = await coll.insertOne(comment);
      if (!result.isSuccess) return null;
      await Future.wait(nestedUpdates);
      return copyWith(id: result.id);
    }

    var parentMod = modify.set('updated_at', now);
    comment.forEach((k, v) => parentMod = parentMod.set(k, v));
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

class Comments {
  static String get _collection => 'comments';

  /// Type-safe saveMany
  static Future<List<Comment?>> saveMany(List<Comment> comments) async {
    if (comments.isEmpty) return <Comment>[];
    final List<Map<String, dynamic>> commentsMap =
        comments.map((c) {
          final json = c.toJson()..remove('_id');
          return json.map((key, value) {
            if (_nestedCollections.containsKey(key)) {
              return MapEntry<String, dynamic>(key, value['_id'] as ObjectId?);
            }
            return MapEntry<String, dynamic>(key, value);
          });
        }).toList();
    final coll = (await MongoConnection.getDb()).collection(_collection);
    final result = await coll.insertMany(commentsMap);
    return comments.asMap().entries.map((e) {
      final idx = e.key;
      final comment = e.value;
      final id = result.isSuccess ? result.ids![idx] : null;
      return comment.copyWith(id: id);
    }).toList();
  }

  /// Find a Comment by its _id with optional nested-doc projections
  static Future<Comment?> findById(
    dynamic commentId, {
    List<BaseProjections> projections = const [],
  }) async {
    if (commentId == null) return null;
    if (commentId is String) commentId = ObjectId.fromHexString(commentId);
    if (commentId is! ObjectId) {
      throw ArgumentError('Invalid commentId type: ${commentId.runtimeType}');
    }

    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);

    if (projections.isNotEmpty) {
      final pipeline = <Map<String, Object>>[];
      final projDoc = <String, int>{};
      pipeline.add({
        r"$match": {'_id': commentId},
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

      final comments = await coll.aggregateToStream(pipeline).toList();
      if (comments.isEmpty) return null;
      return Comment.fromJson(comments.first.withRefs());
    }

    // fallback: return entire comment
    final comment = await coll.findOne(where.eq(r'_id', commentId));
    return comment == null ? null : Comment.fromJson(comment.withRefs());
  }

  /// Type-safe findOne by predicate
  static Future<Comment?> findOne(
    Expression Function(QComment c)? predicate, {
    List<BaseProjections> projections = const [],
  }) async {
    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);

    if (predicate == null) {
      final comment = await coll.modernFindOne(sort: {'created_at': -1});
      if (comment == null) return null;
      return Comment.fromJson(comment.withRefs());
    }
    final selectorBuilder = predicate(QComment()).toSelectorBuilder();
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
      return Comment.fromJson(results.first.withRefs());
    }

    // fallback to simple findOne
    final commentResult = await coll.findOne(selectorMap);
    return commentResult == null ? null : Comment.fromJson(commentResult);
  }

  /// Type-safe findOne by named arguments
  static Future<Comment?> findOneByNamed({
    ObjectId? id,
    Post? post,
    String? text,
    int? age,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<BaseProjections> projections = const [],
  }) async {
    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);

    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (post != null) selector['post'] = post.id;
    if (text != null) selector['text'] = text;
    if (age != null) selector['age'] = age;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) {
      final comment = await coll.modernFindOne(sort: {'created_at': -1});
      if (comment == null) return null;
      return Comment.fromJson(comment.withRefs());
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

      final comments = await coll.aggregateToStream(pipeline).toList();
      if (comments.isEmpty) return null;
      return Comment.fromJson(comments.first.withRefs());
    }
    final commentResult = await coll.findOne(selector);
    return commentResult == null
        ? null
        : Comment.fromJson(commentResult.withRefs());
  }

  /// Type-safe findMany by predicate
  static Future<List<Comment>> findMany(
    Expression Function(QComment c) predicate, {
    int? skip,
    int? limit,
    List<BaseProjections> projections = const [],
  }) async {
    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);

    var selectorBuilder = predicate(QComment()).toSelectorBuilder();
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
      final comments = await coll.aggregateToStream(pipeline).toList();
      if (comments.isEmpty) return [];
      return comments.map((d) => Comment.fromJson(d.withRefs())).toList();
    }

    final comments =
        await (await MongoConnection.getDb())
            .collection(_collection)
            .find(selectorMap)
            .toList();
    return comments.map((e) => Comment.fromJson(e.withRefs())).toList();
  }

  /// Type-safe findMany by named arguments
  static Future<List<Comment>> findManyByNamed({
    ObjectId? id,
    Post? post,
    String? text,
    int? age,
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
    if (post != null) selector['post'] = post.id;
    if (text != null) selector['text'] = text;
    if (age != null) selector['age'] = age;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) {
      final comments =
          await coll
              .modernFind(sort: {'created_at': -1}, limit: limit, skip: skip)
              .toList();
      if (comments.isEmpty) return [];
      return comments.map((e) => Comment.fromJson(e.withRefs())).toList();
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

      final comments = await coll.aggregateToStream(pipeline).toList();
      if (comments.isEmpty) return [];
      return comments.map((d) => Comment.fromJson(d.withRefs())).toList();
    }
    final comments =
        await coll
            .modernFind(filter: selector, limit: limit, skip: skip, sort: sort)
            .toList();
    return comments.map((e) => Comment.fromJson(e.withRefs())).toList();
  }

  /// Type-safe deleteOne by predicate
  static Future<bool> deleteOne(
    Expression Function(QComment c) predicate,
  ) async {
    final expr = predicate(QComment());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
        .collection(_collection)
        .deleteOne(selector.map.flatQuery());
    return result.isSuccess;
  }

  /// Type-safe deleteOne by named arguments
  static Future<bool> deleteOneByNamed({
    ObjectId? id,
    Post? post,
    String? text,
    int? age,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (post != null) selector['post'] = post;
    if (text != null) selector['text'] = text;
    if (age != null) selector['age'] = age;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) return false;
    final result = await (await MongoConnection.getDb())
        .collection(_collection)
        .deleteOne(selector);
    return result.isSuccess;
  }

  /// Type-safe deleteMany
  static Future<bool> deleteMany(
    Expression Function(QComment c) predicate,
  ) async {
    final expr = predicate(QComment());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
        .collection(_collection)
        .deleteMany(selector.map.flatQuery());
    return result.isSuccess;
  }

  /// Type-safe deleteMany by named arguments
  static Future<bool> deleteManyByNamed({
    ObjectId? id,
    Post? post,
    String? text,
    int? age,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (post != null) selector['post'] = post;
    if (text != null) selector['text'] = text;
    if (age != null) selector['age'] = age;
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
    Expression Function(QComment c) predicate, {
    ObjectId? id,
    Post? post,
    String? text,
    int? age,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final modifier = _buildModifier({
      if (id != null) '_id': id,
      if (post != null) 'post': post.id,
      if (text != null) 'text': text,
      if (age != null) 'age': age,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
    final expr = predicate(QComment());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
        .collection(_collection)
        .updateOne(selector.map.flatQuery(), modifier);
    return result.isSuccess;
  }

  /// Type-safe updateMany
  static Future<bool> updateMany(
    Expression Function(QComment c) predicate, {
    ObjectId? id,
    Post? post,
    String? text,
    int? age,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final modifier = _buildModifier({
      if (id != null) '_id': id,
      if (post != null) 'post': post.id,
      if (text != null) 'text': text,
      if (age != null) 'age': age,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
    final expr = predicate(QComment());
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
  static Future<Comment?> updateOneFromMap(
    ObjectId id,
    Map<String, dynamic> updateMap,
  ) async {
    final conn = await MongoConnection.getDb();
    final coll = conn.collection(_collection);
    final result = await coll.updateOne({'_id': id}, {'\$set': updateMap});
    if (!result.isSuccess) return null;
    final updatedDoc = await coll.findOne({'_id': id});
    return updatedDoc == null ? null : Comment.fromJson(updatedDoc);
  }

  static Future<int> count(Expression Function(QComment c)? predicate) async {
    final selectorMap =
        predicate == null
            ? <String, dynamic>{}
            : predicate(QComment()).toSelectorBuilder().map.flatQuery();

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

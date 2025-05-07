// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// Author: Wan Clem <wannclem@gmail.com>

part of 'comment.dart';

// **************************************************************************
// MongoDocumentGenerator
// **************************************************************************

enum PostFields { id, author, lastComment, tags, body, createdAt, updatedAt }

class PostProjections implements BaseProjections {
  @override
  final List<PostFields>? fields;
  @override
  final Map<String, dynamic> fieldMappings = const {
    "id": "post._id",
    "author": "post.author",
    "lastComment": "post.last_comment",
    "tags": "post.tags",
    "body": "post.body",
    "createdAt": "post.created_at",
    "updatedAt": "post.updated_at"
  };
  const PostProjections([this.fields]);

  @override
  Map<String, int> toProjection() {
    return {
      'post._id': 1,
      'post.author': 1,
      'post.last_comment': 1,
      'post.tags': 1,
      'post.body': 1,
      'post.created_at': 1,
      'post.updated_at': 1
    };
  }
}

const _nestedCollections = <String, String>{'post': 'posts'};

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

    final parentMap = toJson()
      ..remove('_id')
      ..removeWhere((key, value) => value == null);
    parentMap.update('created_at', (v) => v ?? now, ifAbsent: () => now);
    parentMap.update('updated_at', (v) => now, ifAbsent: () => now);

    var doc = {...parentMap};
    final nestedUpdates = <Future>[];
    for (var entry in parentMap.entries) {
      final root = entry.key;
      if (_nestedCollections.containsKey(root)) {
        final collectionName = _nestedCollections[root]!;
        var nestedColl = db.collection(collectionName);
        var value = entry.value as Map<String, dynamic>?;
        if (value == null) continue;
        value.removeWhere((key, value) => value == null);
        final nestedId = (value['_id'] ?? value['id']) as ObjectId?;
        if (nestedId == null) {
          doc.remove(root);
        } else {
          doc[root] = nestedId;
          final nestedMap = value..remove('_id');
          if (nestedMap.isNotEmpty) {
            var mod = modify.set('updated_at', now);
            nestedMap.forEach((k, v) => mod = mod.set(k, v));
            nestedUpdates
                .add(nestedColl.updateOne(where.eq(r'_id', nestedId), mod));
          }
        }
      }
    }

    if (isInsert) {
      final result = await coll.insertOne(doc);
      if (!result.isSuccess) return null;
      await Future.wait(nestedUpdates);
      return copyWith(id: result.id);
    }

    var parentMod = modify.set('updated_at', now);
    doc.forEach((k, v) => parentMod = parentMod.set(k, v));
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

  /// Type‑safe insertMany
  static Future<List<Comment?>> insertMany(
    List<Comment> docs,
  ) async {
    if (docs.isEmpty) return <Comment>[];
    final raw = docs.map((d) => d.toJson()..remove('_id')).toList();
    final coll = (await MongoConnection.getDb()).collection(_collection);
    final result = await coll.insertMany(raw);
    return docs.asMap().entries.map((e) {
      final idx = e.key;
      final doc = e.value;
      final id = result.isSuccess ? result.ids![idx] : null;
      return doc.copyWith(id: id);
    }).toList();
  }

  /// Type‑safe findById with optional nested‑doc projections
  static Future<Comment?> findById(
    dynamic id, {
    List<BaseProjections> projections = const [],
  }) async {
    if (id == null) return null;
    if (id is String) id = ObjectId.fromHexString(id);
    if (id is! ObjectId) {
      throw ArgumentError('Invalid id type: ${id.runtimeType}');
    }

    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);

    if (projections.isNotEmpty) {
      final pipeline = <Map<String, Object>>[];
      final projDoc = <String, int>{};
      pipeline.add({
        r"$match": {'_id': id}
      });
      for (var p in projections) {
        final projectedFields = p.fields;
        final allProjections = p.toProjection();
        final localField = allProjections.keys.first.split(".").first;
        final foreignColl = _nestedCollections[localField];
        if (projectedFields != null && projectedFields.isNotEmpty) {
          final selected = <String, int>{};
          for (var f in projectedFields) {
            final path = p.fieldMappings[(f as Enum).name]!;
            selected[path] = 1;
          }
          projDoc.addAll(selected);
        } else {
          projDoc.addAll(allProjections);
        }
        pipeline.add({
          r'$lookup': {
            'from': foreignColl,
            'localField': localField,
            'foreignField': '_id',
            'as': localField,
          }
        });
        pipeline.add({r'$unwind': localField});
      }
      pipeline.add({r'$project': projDoc});

      final docs = await coll.aggregateToStream(pipeline).toList();
      if (docs.isEmpty) return null;
      return Comment.fromJson(docs.first.withRefs());
    }

    // fallback: return entire document
    final doc = await coll.findOne(where.eq(r'_id', id));
    return doc == null ? null : Comment.fromJson(doc.withRefs());
  }

  /// Type-safe findOne by predicate
  static Future<Comment?> findOne(
    Expression Function(QComment c)? predicate, {
    List<BaseProjections> projections = const [],
  }) async {
    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);

    if (predicate == null) {
      final docs = await coll.modernFindOne(sort: {'created_at': -1});
      if (docs == null) return null;
      return Comment.fromJson(docs.withRefs());
    }
    final selectorBuilder = predicate(QComment()).toSelectorBuilder();
    final selectorMap = selectorBuilder.map.flatQuery();

    if (projections.isNotEmpty) {
      final pipeline = <Map<String, Object>>[];
      final projDoc = <String, int>{};
      pipeline.add({r"$match": selectorMap});
      for (var p in projections) {
        final projectedFields = p.fields;
        final allProjections = p.toProjection();
        final localField = allProjections.keys.first.split(".").first;
        final foreignColl = _nestedCollections[localField];
        if (projectedFields != null && projectedFields.isNotEmpty) {
          final selected = <String, int>{};
          for (var f in projectedFields) {
            final path = p.fieldMappings[(f as Enum).name]!;
            selected[path] = 1;
          }
          projDoc.addAll(selected);
        } else {
          projDoc.addAll(allProjections);
        }
        pipeline.add({
          r'$lookup': {
            'from': foreignColl,
            'localField': localField,
            'foreignField': '_id',
            'as': localField,
          }
        });
        pipeline.add({r'$unwind': localField});
      }
      pipeline.add({r'$project': projDoc});

      final docs = await coll.aggregateToStream(pipeline).toList();
      if (docs.isEmpty) return null;
      return Comment.fromJson(docs.first.withRefs());
    }

    // fallback to simple findOne
    final doc = await coll.findOne(selectorMap);
    return doc == null ? null : Comment.fromJson(doc);
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
    if (post != null) selector['post'] = post;
    if (text != null) selector['text'] = text;
    if (age != null) selector['age'] = age;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) {
      final doc = await coll.modernFindOne(sort: {'created_at': -1});
      if (doc == null) return null;
      return Comment.fromJson(doc.withRefs());
    }
    if (projections.isNotEmpty) {
      final pipeline = <Map<String, Object>>[];
      final projDoc = <String, int>{};
      pipeline.add({r"$match": selector});
      for (var p in projections) {
        final projectedFields = p.fields;
        final allProjections = p.toProjection();
        final localField = allProjections.keys.first.split(".").first;
        final foreignColl = _nestedCollections[localField];
        if (projectedFields != null && projectedFields.isNotEmpty) {
          final selected = <String, int>{};
          for (var f in projectedFields) {
            final path = p.fieldMappings[(f as Enum).name]!;
            selected[path] = 1;
          }
          projDoc.addAll(selected);
        } else {
          projDoc.addAll(allProjections);
        }
        pipeline.add({
          r'$lookup': {
            'from': foreignColl,
            'localField': localField,
            'foreignField': '_id',
            'as': localField,
          }
        });
        pipeline.add({r'$unwind': localField});
      }
      pipeline.add({r'$project': projDoc});

      final docs = await coll.aggregateToStream(pipeline).toList();
      if (docs.isEmpty) return null;
      return Comment.fromJson(docs.first.withRefs());
    }
    final doc = await coll.findOne(selector);
    return doc == null ? null : Comment.fromJson(doc.withRefs());
  }

  /// Type‑safe findMany by predicate
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

    if (projections.isNotEmpty) {
      final pipeline = <Map<String, Object>>[];
      final projDoc = <String, int>{};
      pipeline.add({r"$match": selectorMap});
      for (var p in projections) {
        final projectedFields = p.fields;
        final allProjections = p.toProjection();
        final localField = allProjections.keys.first.split(".").first;
        final foreignColl = _nestedCollections[localField];
        if (projectedFields != null && projectedFields.isNotEmpty) {
          final selected = <String, int>{};
          for (var f in projectedFields) {
            final path = p.fieldMappings[(f as Enum).name]!;
            selected[path] = 1;
          }
          projDoc.addAll(selected);
        } else {
          projDoc.addAll(allProjections);
        }
        pipeline.add({
          r'$lookup': {
            'from': foreignColl,
            'localField': localField,
            'foreignField': '_id',
            'as': localField,
          }
        });
        pipeline.add({r'$unwind': localField});
      }
      pipeline.add({r'$project': projDoc});

      final docs = await coll.aggregateToStream(pipeline).toList();
      if (docs.isEmpty) return [];
      return docs.map((d) => Comment.fromJson(d.withRefs())).toList();
    }
    final docs = await (await MongoConnection.getDb())
        .collection(_collection)
        .find(selectorMap)
        .toList();
    return docs.map((e) => Comment.fromJson(e.withRefs())).toList();
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
    if (post != null) selector['post'] = post;
    if (text != null) selector['text'] = text;
    if (age != null) selector['age'] = age;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) {
      final docs = await coll.modernFind(
          sort: {'created_at': -1}, limit: limit, skip: skip).toList();
      if (docs.isEmpty) return [];
      return docs.map((e) => Comment.fromJson(e.withRefs())).toList();
    }
    if (projections.isNotEmpty) {
      final pipeline = <Map<String, Object>>[];
      final projDoc = <String, int>{};
      pipeline.add({r"$match": selector});
      for (var p in projections) {
        final projectedFields = p.fields;
        final allProjections = p.toProjection();
        final localField = allProjections.keys.first.split(".").first;
        final foreignColl = _nestedCollections[localField];
        if (projectedFields != null && projectedFields.isNotEmpty) {
          final selected = <String, int>{};
          for (var f in projectedFields) {
            final path = p.fieldMappings[(f as Enum).name]!;
            selected[path] = 1;
          }
          projDoc.addAll(selected);
        } else {
          projDoc.addAll(allProjections);
        }
        pipeline.add({
          r'$lookup': {
            'from': foreignColl,
            'localField': localField,
            'foreignField': '_id',
            'as': localField,
          }
        });
        pipeline.add({r'$unwind': localField});
      }
      pipeline.add({r'$project': projDoc});

      final docs = await coll.aggregateToStream(pipeline).toList();
      if (docs.isEmpty) return [];
      return docs.map((d) => Comment.fromJson(d.withRefs())).toList();
    }
    final docs = await coll
        .modernFind(filter: selector, limit: limit, skip: skip, sort: sort)
        .toList();
    return docs.map((e) => Comment.fromJson(e.withRefs())).toList();
  }

  /// Type-safe deleteOne by predicate
  static Future<bool> deleteOne(
      Expression Function(QComment c) predicate) async {
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
      Expression Function(QComment c) predicate) async {
    final expr = predicate(QComment());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
        .collection(_collection)
        .deleteMany(selector.map.flatQuery());
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
      '_id': id,
      if (post != null) 'post': post,
      if (text != null) 'text': text,
      'age': age,
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
      '_id': id,
      if (post != null) 'post': post,
      if (text != null) 'text': text,
      'age': age,
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

  /// Use `updateOne` directly whenever possible for better performance and clarity.
  /// This method is a fallback for cases requiring additional logic or dynamic update maps.
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
    final selectorMap = predicate == null
        ? {}
        : predicate(QComment()).toSelectorBuilder().map.flatQuery();
    return (await MongoConnection.getDb())
        .collection(_collection)
        .count(selectorMap);
  }
}

// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// Author: Wan Clem <wannclem@gmail.com>

part of 'post.dart';

// **************************************************************************
// MongoDocumentGenerator
// **************************************************************************

enum UserFields { id, firstName, lastName, email, age, createdAt, updatedAt }

class UserProjections implements BaseProjections {
  final List<UserFields>? fields;
  const UserProjections([this.fields]);

  @override
  Map<String, int>? toProjection() {
    if (fields == null || fields!.isEmpty) return null;
    return {
      'author._id': 1,
      'author.first_name': 1,
      'author.last_name': 1,
      'author.email': 1,
      'author.age': 1,
      'author.created_at': 1,
      'author.updated_at': 1
    };
  }
}

const _nestedCollections = <String, String>{'author': 'users'};

class QPost {
  final String _prefix;
  QPost([this._prefix = '']);

  String _key(String field) => _prefix.isEmpty ? field : '$_prefix.$field';

  QueryField<ObjectId?> get id => QueryField<ObjectId?>(_key('_id'));

  QUser get author => QUser(_key('author'));

  QList<String> get tags => QList<String>(_key('tags'));

  QueryField<String?> get body => QueryField<String?>(_key('body'));

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

class Posts {
  static String get _collection => 'posts';

  /// Type‑safe insertMany
  static Future<List<Post?>> insertMany(
    List<Post> docs,
  ) async {
    if (docs.isEmpty) return <Post>[];
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

  /// Type-safe findById
  static Future<Post?> findById(dynamic id) async {
    if (id == null) return null;
    if (id is String) {
      id = ObjectId.fromHexString(id);
    }
    if (id is! ObjectId) {
      throw ArgumentError('Invalid id type: ${id.runtimeType}');
    }
    final doc = await (await MongoConnection.getDb())
        .collection(_collection)
        .findOne(where.eq(r'_id', id));
    return doc == null ? null : Post.fromJson(doc.withRefs());
  }

  /// Type-safe findOne
  static Future<Post?> findOne(
      [Expression Function(QPost p)? predicate]) async {
    if (predicate == null) {
      final docs = await (await MongoConnection.getDb())
          .collection(_collection)
          .modernFindOne(sort: {'created_at': -1});
      if (docs == null) return null;
      return Post.fromJson(docs.withRefs());
    }
    final selectorBuilder = predicate(QPost()).toSelectorBuilder();
    final selectorMap = selectorBuilder.map.flatQuery();

    final allKeys = <String>{};
    collectKeys(selectorMap, allKeys);
    final roots = allKeys
        .where((k) => k.contains('.'))
        .map((k) => k.split('.').first)
        .toSet();

    if (roots.isNotEmpty) {
      var builder = AggregationPipelineBuilder();
      for (final root in roots) {
        if (!_nestedCollections.containsKey(root)) {
          continue;
        }
        final foreignColl = _nestedCollections[root]!;
        builder = builder
            .addStage(Lookup(
                from: foreignColl,
                localField: root,
                foreignField: '_id',
                as: root))
            .addStage(Unwind(Field(root)));
      }
      builder = builder.addStage(Match(selectorMap));
      final stream = (await MongoConnection.getDb())
          .collection(_collection)
          .modernAggregate(builder.build());
      final doc = await stream.first;
      return Post.fromJson(doc.withRefs());
    }

    // fallback to simple findOne
    final doc = await (await MongoConnection.getDb())
        .collection(_collection)
        .findOne(selectorMap);
    return doc == null ? null : Post.fromJson(doc);
  }

  /// Type‑safe findMany
  static Future<List<Post>> findMany(
    Expression Function(QPost p) predicate, {
    int? skip,
    int? limit,
    List<BaseProjections>? project,
  }) async {
    var selectorBuilder = predicate(QPost()).toSelectorBuilder();
    if (skip != null) selectorBuilder = selectorBuilder.skip(skip);
    if (limit != null) selectorBuilder = selectorBuilder.limit(limit);
    final selectorMap = selectorBuilder.map.flatQuery();

    final allKeys = <String>{};
    collectKeys(selectorMap, allKeys);
    final roots = allKeys
        .where((k) => k.contains('.'))
        .map((k) => k.split('.').first)
        .toSet();

    if (roots.isNotEmpty) {
      var builder = AggregationPipelineBuilder();
      for (final root in roots) {
        if (!_nestedCollections.containsKey(root)) continue;
        builder = builder
            .addStage(Lookup(
              from: _nestedCollections[root]!,
              localField: root,
              foreignField: '_id',
              as: root,
            ))
            .addStage(Unwind(Field(root)));
      }
      builder = builder.addStage(Match(selectorMap));

      if (skip != null) builder = builder.addStage(Skip(skip));
      if (limit != null) builder = builder.addStage(Limit(limit));

      final docs = await (await MongoConnection.getDb())
          .collection(_collection)
          .modernAggregate(builder.build())
          .toList();
      return docs.map((e) => Post.fromJson(e)).toList();
    }

    final docs = await (await MongoConnection.getDb())
        .collection(_collection)
        .find(selectorMap)
        .toList();
    return docs.map((e) => Post.fromJson(e)).toList();
  }

  /// Type-safe deleteOne
  static Future<bool> deleteOne(Expression Function(QPost p) predicate) async {
    final expr = predicate(QPost());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
        .collection(_collection)
        .deleteOne(selector.map.flatQuery());
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

  /// Type-safe updateOne
  static Future<bool> updateOne(
    Expression Function(QPost p) predicate, {
    ObjectId? id,
    User? author,
    List<String>? tags,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final modifier = _buildModifier({
      '_id': id,
      if (author != null) 'author': author,
      'tags': tags,
      if (body != null) 'body': body,
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
    List<String>? tags,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final modifier = _buildModifier({
      '_id': id,
      if (author != null) 'author': author,
      'tags': tags,
      if (body != null) 'body': body,
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

  /// Use `updateOne` directly whenever possible for better performance and clarity.
  /// This method is a fallback for cases requiring additional logic or dynamic update maps.
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
    final selectorMap = predicate == null
        ? {}
        : predicate(QPost()).toSelectorBuilder().map.flatQuery();
    return (await MongoConnection.getDb())
        .collection(_collection)
        .count(selectorMap);
  }
}

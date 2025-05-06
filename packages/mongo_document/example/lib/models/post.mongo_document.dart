// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// Author: Wan Clem <wannclem@gmail.com>

part of 'post.dart';

// **************************************************************************
// MongoDocumentGenerator
// **************************************************************************

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
    final coll = (await MongoConnection.getDb()).collection(_collection);
    final now = DateTime.now().toUtc();
    if (id == null) {
      final doc = toJson()..remove('_id');
      doc.update('created_at', (v) => v ?? now, ifAbsent: () => now);
      doc.update('updated_at', (v) => v ?? now, ifAbsent: () => now);
      final result = await coll.insertOne(doc);
      if (result.isSuccess) return copyWith(id: result.id);
      return null;
    }
    final updateMap = toJson()..remove('_id');
    updateMap.update('created_at', (v) => v ?? now, ifAbsent: () => now);
    updateMap.update('updated_at', (v) => v ?? now, ifAbsent: () => now);
    var modifier = modify;
    updateMap.forEach((k, v) => modifier = modifier.set(k, v));
    final res = await coll.updateOne(where.eq(r'_id', id), modifier);
    return res.isSuccess ? this : null;
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
  static Future<List<Post>> insertMany(
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
      return doc.copyWith(id: id as ObjectId?);
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
    return doc == null ? null : Post.fromJson(doc);
  }

  /// Type-safe findOne
  static Future<Post?> findOne(Expression Function(QPost q) predicate) async {
    final selectorBuilder = predicate(QPost()).toSelectorBuilder();
    final selectorMap = selectorBuilder.map;

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
      return Post.fromJson(doc);
    }

    // fallback to simple findOne
    final doc = await (await MongoConnection.getDb())
        .collection(_collection)
        .findOne(selectorBuilder);
    return doc == null ? null : Post.fromJson(doc);
  }

  /// Type‑safe findMany
  static Future<List<Post>> findMany(Expression Function(QPost q) predicate,
      {int? skip, int? limit}) async {
    var selectorBuilder = predicate(QPost()).toSelectorBuilder();
    if (skip != null) selectorBuilder = selectorBuilder.skip(skip);
    if (limit != null) selectorBuilder = selectorBuilder.limit(limit);
    final selectorMap = selectorBuilder.map;

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
        .find(selectorBuilder)
        .toList();
    return docs.map((e) => Post.fromJson(e)).toList();
  }

  /// Type-safe deleteOne
  static Future<bool> deleteOne(Expression Function(QPost q) predicate) async {
    final expr = predicate(QPost());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
        .collection(_collection)
        .deleteOne(selector);
    return result.isSuccess;
  }

  /// Type-safe deleteMany
  static Future<bool> deleteMany(Expression Function(QPost q) predicate) async {
    final expr = predicate(QPost());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
        .collection(_collection)
        .deleteMany(selector);
    return result.isSuccess;
  }

  /// Type-safe updateOne
  static Future<bool> updateOne(
    Expression Function(QPost q) predicate, {
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
        .updateOne(selector, modifier);
    return result.isSuccess;
  }

  /// Type-safe updateMany
  static Future<bool> updateMany(
    Expression Function(QPost q) predicate, {
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
        .updateMany(selector, modifier);
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

  static Future<int> count(Expression Function(QPost q) predicate) async {
    final selectorMap = predicate(QPost()).toSelectorBuilder().map;
    return (await MongoConnection.getDb())
        .collection(_collection)
        .count(selectorMap);
  }
}

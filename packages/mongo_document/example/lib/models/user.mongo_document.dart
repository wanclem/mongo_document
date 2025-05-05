// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// Author: Wan Clem <wannclem@gmail.com>

part of 'user.dart';

// **************************************************************************
// MongoDocumentGenerator
// **************************************************************************

const _nestedCollections = <String, String>{};

class QUser {
  final String _prefix;
  QUser([this._prefix = '']);

  String _key(String field) => _prefix.isEmpty ? field : '$_prefix.$field';

  QueryField<ObjectId?> get id => QueryField<ObjectId?>(_key('id'));

  QueryField<String?> get firstName => QueryField<String?>(_key('first_name'));

  QueryField<String?> get lastName => QueryField<String?>(_key('last_name'));

  QueryField<String?> get email => QueryField<String?>(_key('email'));

  QueryField<int> get age => QueryField<int>(_key('age'));

  QueryField<DateTime?> get createdAt =>
      QueryField<DateTime?>(_key('created_at'));

  QueryField<DateTime?> get updatedAt =>
      QueryField<DateTime?>(_key('updated_at'));
}

extension $UserExtension on User {
  static String get _collection => 'users';

  Future<User?> save() async {
    final coll = (await MongoConnection.getDb()).collection(_collection);
    final now = DateTime.now().toUtc();
    if (id == null) {
      final doc = toJson()
        ..remove('_id')
        ..putIfAbsent('created_at', () => now)
        ..['updatedAt'] = now;
      final result = await coll.insertOne(doc);
      if (result.isSuccess) return copyWith(id: result.id);
      return null;
    }
    final updateMap = toJson()
      ..remove('_id')
      ..putIfAbsent('created_at', () => now);
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

class Users {
  static String get _collection => 'users';

  /// Type‑safe DSL insertMany
  static Future<List<User>> insertMany(
    List<User> docs,
  ) async {
    if (docs.isEmpty) return <User>[];
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

  /// Type-safe DSL findOne
  static Future<User?> findOne(Expression Function(QUser q) predicate) async {
    final selectorBuilder = predicate(QUser()).toSelectorBuilder();
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
      return User.fromJson(doc);
    }

    // fallback to simple findOne
    final doc = await (await MongoConnection.getDb())
        .collection(_collection)
        .findOne(selectorBuilder);
    return doc == null ? null : User.fromJson(doc);
  }

  /// Type‑safe DSL findMany
  static Future<List<User>> findMany(Expression Function(QUser q) predicate,
      {int? skip, int? limit}) async {
    var selectorBuilder = predicate(QUser()).toSelectorBuilder();
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
      return docs.map((e) => User.fromJson(e)).toList();
    }

    final docs = await (await MongoConnection.getDb())
        .collection(_collection)
        .find(selectorBuilder)
        .toList();
    return docs.map((e) => User.fromJson(e)).toList();
  }

  /// Type-safe DSL deleteOne
  static Future<bool> deleteOne(Expression Function(QUser q) predicate) async {
    final expr = predicate(QUser());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
        .collection(_collection)
        .deleteOne(selector);
    return result.isSuccess;
  }

  /// Type-safe DSL deleteMany
  static Future<bool> deleteMany(Expression Function(QUser q) predicate) async {
    final expr = predicate(QUser());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
        .collection(_collection)
        .deleteMany(selector);
    return result.isSuccess;
  }

  static Future<bool> updateOne(
    Expression Function(QUser q) predicate, {
    ObjectId? id,
    String? firstName,
    String? lastName,
    String? email,
    int age = 18,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final modifier = _buildModifier({
      if (id != null) 'id': id,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (email != null) 'email': email,
      'age': age,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
    final expr = predicate(QUser());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
        .collection(_collection)
        .updateOne(selector, modifier);
    return result.isSuccess;
  }

  /// Type-safe DSL updateMany
  static Future<bool> updateMany(
    Expression Function(QUser q) predicate, {
    ObjectId? id,
    String? firstName,
    String? lastName,
    String? email,
    int age = 18,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final modifier = _buildModifier({
      if (id != null) 'id': id,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (email != null) 'email': email,
      'age': age,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
    final expr = predicate(QUser());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
        .collection(_collection)
        .updateMany(selector, modifier);
    return result.isSuccess;
  }

  static ModifierBuilder _buildModifier(Map<String, dynamic> updateMap) {
    final now = DateTime.now().toUtc();
    var modifier = modify.set('updatedAt', now);
    updateMap.forEach((k, v) => modifier = modifier.set(k, v));
    return modifier;
  }

  static Future<int> count(Expression Function(QUser q) predicate) async {
    final selectorMap = predicate(QUser()).toSelectorBuilder().map;
    return (await MongoConnection.getDb())
        .collection(_collection)
        .count(selectorMap);
  }
}

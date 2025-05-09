// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
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

  QueryField<ObjectId?> get id => QueryField<ObjectId?>(_key('_id'));

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
    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);
    final now = DateTime.now().toUtc();
    final isInsert = id == null;

    final userMap = toJson()
      ..remove('_id')
      ..removeWhere((key, value) => value == null);
    userMap.update('created_at', (v) => v ?? now, ifAbsent: () => now);
    userMap.update('updated_at', (v) => now, ifAbsent: () => now);

    var user = {...userMap};
    final nestedUpdates = <Future>[];
    for (var entry in userMap.entries) {
      final root = entry.key;
      if (_nestedCollections.containsKey(root)) {
        final collectionName = _nestedCollections[root]!;
        var nestedColl = db.collection(collectionName);
        var value = entry.value as Map<String, dynamic>?;
        if (value == null) continue;
        value.removeWhere((key, value) => value == null);
        final nestedId = value['_id'] as ObjectId?;
        if (nestedId == null) {
          user.remove(root);
        } else {
          user[root] = nestedId;
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
      final result = await coll.insertOne(user);
      if (!result.isSuccess) return null;
      await Future.wait(nestedUpdates);
      return copyWith(id: result.id);
    }

    var parentMod = modify.set('updated_at', now);
    user.forEach((k, v) => parentMod = parentMod.set(k, v));
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

class Users {
  static String get _collection => 'users';

  /// Type-safe saveMany
  static Future<List<User?>> saveMany(
    List<User> users,
  ) async {
    if (users.isEmpty) return <User>[];
    final List<Map<String, dynamic>> usersMap = users.map((u) {
      final json = u.toJson()..remove('_id');
      return json.map((key, value) {
        if (_nestedCollections.containsKey(key)) {
          return MapEntry<String, dynamic>(
            key,
            value['_id'] as ObjectId?,
          );
        }
        return MapEntry<String, dynamic>(key, value);
      });
    }).toList();
    final coll = (await MongoConnection.getDb()).collection(_collection);
    final result = await coll.insertMany(usersMap);
    return users.asMap().entries.map((e) {
      final idx = e.key;
      final user = e.value;
      final id = result.isSuccess ? result.ids![idx] : null;
      return user.copyWith(id: id);
    }).toList();
  }

  /// Find a User by its _id with optional nested-doc projections
  static Future<User?> findById(
    dynamic userId, {
    List<BaseProjections> projections = const [],
  }) async {
    if (userId == null) return null;
    if (userId is String) userId = ObjectId.fromHexString(userId);
    if (userId is! ObjectId) {
      throw ArgumentError('Invalid userId type: ${userId.runtimeType}');
    }

    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);

    if (projections.isNotEmpty) {
      final pipeline = <Map<String, Object>>[];
      final projDoc = <String, int>{};
      pipeline.add({
        r"$match": {'_id': userId}
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
          }
        });
        pipeline.add({
          r'$unwind': {
            "path": "\$${localField}",
            "preserveNullAndEmptyArrays": true
          }
        });
      }
      pipeline.add({r'$project': projDoc});

      final users = await coll.aggregateToStream(pipeline).toList();
      if (users.isEmpty) return null;
      return User.fromJson(users.first.withRefs());
    }

    // fallback: return entire user
    final user = await coll.findOne(where.eq(r'_id', userId));
    return user == null ? null : User.fromJson(user.withRefs());
  }

  /// Type-safe findOne by predicate
  static Future<User?> findOne(
    Expression Function(QUser u)? predicate, {
    List<BaseProjections> projections = const [],
  }) async {
    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);

    if (predicate == null) {
      final user = await coll.modernFindOne(sort: {'created_at': -1});
      if (user == null) return null;
      return User.fromJson(user.withRefs());
    }
    final selectorBuilder = predicate(QUser()).toSelectorBuilder();
    final selectorMap = selectorBuilder.map.flatQuery();

    if (projections.isNotEmpty) {
      final pipeline = <Map<String, Object>>[];
      final projDoc = <String, int>{};
      pipeline.add({r"$match": selectorMap});
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
          }
        });
        pipeline.add({
          r'$unwind': {
            "path": "\$${localField}",
            "preserveNullAndEmptyArrays": true
          }
        });
      }
      pipeline.add({r'$project': projDoc});

      final users = await coll.aggregateToStream(pipeline).toList();
      if (users.isEmpty) return null;
      return User.fromJson(users.first.withRefs());
    }

    // fallback to simple findOne
    final user = await coll.findOne(selectorMap);
    return user == null ? null : User.fromJson(user);
  }

  /// Type-safe findOne by named arguments
  static Future<User?> findOneByNamed({
    ObjectId? id,
    String? firstName,
    String? lastName,
    String? email,
    int? age,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<BaseProjections> projections = const [],
  }) async {
    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);

    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (firstName != null) selector['first_name'] = firstName;
    if (lastName != null) selector['last_name'] = lastName;
    if (email != null) selector['email'] = email;
    if (age != null) selector['age'] = age;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) {
      final user = await coll.modernFindOne(sort: {'created_at': -1});
      if (user == null) return null;
      return User.fromJson(user.withRefs());
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
          }
        });
        pipeline.add({
          r'$unwind': {
            "path": "\$${localField}",
            "preserveNullAndEmptyArrays": true
          }
        });
      }
      pipeline.add({r'$project': projDoc});

      final users = await coll.aggregateToStream(pipeline).toList();
      if (users.isEmpty) return null;
      return User.fromJson(users.first.withRefs());
    }
    final user = await coll.findOne(selector);
    return user == null ? null : User.fromJson(user.withRefs());
  }

  /// Type-safe findMany by predicate
  static Future<List<User>> findMany(
    Expression Function(QUser u) predicate, {
    int? skip,
    int? limit,
    List<BaseProjections> projections = const [],
  }) async {
    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);

    var selectorBuilder = predicate(QUser()).toSelectorBuilder();
    if (skip != null) selectorBuilder = selectorBuilder.skip(skip);
    if (limit != null) selectorBuilder = selectorBuilder.limit(limit);
    final selectorMap = selectorBuilder.map.flatQuery();

    if (projections.isNotEmpty) {
      final pipeline = <Map<String, Object>>[];
      final projDoc = <String, int>{};
      pipeline.add({r"$match": selectorMap});
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
          }
        });
        pipeline.add({
          r'$unwind': {
            "path": "\$${localField}",
            "preserveNullAndEmptyArrays": true
          }
        });
      }
      pipeline.add({r'$project': projDoc});

      final users = await coll.aggregateToStream(pipeline).toList();
      if (users.isEmpty) return [];
      return users.map((d) => User.fromJson(d.withRefs())).toList();
    }
    final users = await (await MongoConnection.getDb())
        .collection(_collection)
        .find(selectorMap)
        .toList();
    return users.map((e) => User.fromJson(e.withRefs())).toList();
  }

  /// Type-safe findMany by named arguments
  static Future<List<User>> findManyByNamed({
    ObjectId? id,
    String? firstName,
    String? lastName,
    String? email,
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
    if (firstName != null) selector['first_name'] = firstName;
    if (lastName != null) selector['last_name'] = lastName;
    if (email != null) selector['email'] = email;
    if (age != null) selector['age'] = age;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) {
      final users = await coll.modernFind(
          sort: {'created_at': -1}, limit: limit, skip: skip).toList();
      if (users.isEmpty) return [];
      return users.map((e) => User.fromJson(e.withRefs())).toList();
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
          }
        });
        pipeline.add({
          r'$unwind': {
            "path": "\$${localField}",
            "preserveNullAndEmptyArrays": true
          }
        });
      }
      pipeline.add({r'$project': projDoc});

      final users = await coll.aggregateToStream(pipeline).toList();
      if (users.isEmpty) return [];
      return users.map((d) => User.fromJson(d.withRefs())).toList();
    }
    final users = await coll
        .modernFind(filter: selector, limit: limit, skip: skip, sort: sort)
        .toList();
    return users.map((e) => User.fromJson(e.withRefs())).toList();
  }

  /// Type-safe deleteOne by predicate
  static Future<bool> deleteOne(Expression Function(QUser u) predicate) async {
    final expr = predicate(QUser());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
        .collection(_collection)
        .deleteOne(selector.map.flatQuery());
    return result.isSuccess;
  }

  /// Type-safe deleteOne by named arguments
  static Future<bool> deleteOneByNamed({
    ObjectId? id,
    String? firstName,
    String? lastName,
    String? email,
    int? age,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (firstName != null) selector['first_name'] = firstName;
    if (lastName != null) selector['last_name'] = lastName;
    if (email != null) selector['email'] = email;
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
  static Future<bool> deleteMany(Expression Function(QUser u) predicate) async {
    final expr = predicate(QUser());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
        .collection(_collection)
        .deleteMany(selector.map.flatQuery());
    return result.isSuccess;
  }

  /// Type-safe deleteMany by named arguments
  static Future<bool> deleteManyByNamed({
    ObjectId? id,
    String? firstName,
    String? lastName,
    String? email,
    int? age,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (firstName != null) selector['first_name'] = firstName;
    if (lastName != null) selector['last_name'] = lastName;
    if (email != null) selector['email'] = email;
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
    Expression Function(QUser u) predicate, {
    ObjectId? id,
    String? firstName,
    String? lastName,
    String? email,
    int? age,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final modifier = _buildModifier({
      if (id != null) '_id': id,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (email != null) 'email': email,
      if (age != null) 'age': age,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
    final expr = predicate(QUser());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
        .collection(_collection)
        .updateOne(selector.map.flatQuery(), modifier);
    return result.isSuccess;
  }

  /// Type-safe updateMany
  static Future<bool> updateMany(
    Expression Function(QUser u) predicate, {
    ObjectId? id,
    String? firstName,
    String? lastName,
    String? email,
    int? age,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final modifier = _buildModifier({
      if (id != null) '_id': id,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (email != null) 'email': email,
      if (age != null) 'age': age,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
    final expr = predicate(QUser());
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
  static Future<User?> updateOneFromMap(
    ObjectId id,
    Map<String, dynamic> updateMap,
  ) async {
    final conn = await MongoConnection.getDb();
    final coll = conn.collection(_collection);
    final result = await coll.updateOne({'_id': id}, {'\$set': updateMap});
    if (!result.isSuccess) return null;
    final updatedDoc = await coll.findOne({'_id': id});
    return updatedDoc == null ? null : User.fromJson(updatedDoc);
  }

  static Future<int> count(Expression Function(QUser u)? predicate) async {
    final selectorMap = predicate == null
        ? {}
        : predicate(QUser()).toSelectorBuilder().map.flatQuery();
    return (await MongoConnection.getDb())
        .collection(_collection)
        .count(selectorMap);
  }
}

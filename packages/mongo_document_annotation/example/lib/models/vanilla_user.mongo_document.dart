// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// Author: Wan Clem <wannclem@gmail.com>

part of 'vanilla_user.dart';

// **************************************************************************
// MongoDocumentGenerator
// **************************************************************************

enum VanillaUserFields { id, firstName, lastName }

class VanillaUserProjections implements BaseProjections {
  @override
  final List<VanillaUserFields>? inclusions;
  final List<VanillaUserFields>? exclusions;
  @override
  final Map<String, dynamic> fieldMappings = const {
    "id": "_id",
    "firstName": "first_name",
    "lastName": "last_name",
  };
  const VanillaUserProjections({this.inclusions, this.exclusions});

  @override
  Map<String, int> toProjection() {
    return {'_id': 1, 'first_name': 1, 'last_name': 1};
  }
}

const _nestedCollections = <String, String>{};

class QVanillaUser {
  final String _prefix;
  QVanillaUser([this._prefix = '']);

  String _key(String field) => _prefix.isEmpty ? field : '$_prefix.$field';

  QueryField<ObjectId?> get id => QueryField<ObjectId?>(_key('_id'));

  QueryField<String?> get firstName => QueryField<String?>(_key('first_name'));

  QueryField<String?> get lastName => QueryField<String?>(_key('last_name'));
}

extension $VanillaUserExtension on VanillaUser {
  static String get _collection => 'vanilla_users';

  Future<VanillaUser?> save({Db? db}) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final now = DateTime.now().toUtc();
    final isInsert = id == null;

    final vanillaUserMap = toJson()..remove('_id');
    vanillaUserMap.update('created_at', (v) => v ?? now, ifAbsent: () => now);
    vanillaUserMap.update('updated_at', (v) => now, ifAbsent: () => now);

    var vanillaUser = sanitizedDocument({...vanillaUserMap});
    for (var entry in vanillaUserMap.entries) {
      final root = entry.key;
      if (_nestedCollections.containsKey(root)) {
        final Map<String, dynamic> value =
            entry.value is Map
                ? Map<String, dynamic>.from(entry.value as Map)
                : <String, dynamic>{};
        if (value.isEmpty) continue;
        final nestedId = value['_id'] as ObjectId?;
        if (nestedId == null) {
          vanillaUser.remove(root);
        } else {
          vanillaUser[root] = nestedId;
        }
      }
    }

    if (isInsert) {
      final result = await coll.insertOne(vanillaUser);
      if (!result.isSuccess) return null;
      final savedDoc = await coll.findOne(where.id(result.id));
      return VanillaUser.fromJson(savedDoc!.withRefs());
    }

    var parentMod = modify.set('updated_at', now);
    vanillaUser.forEach((k, v) => parentMod = parentMod.set(k, v));
    final res = await coll.updateOne(where.eq(r'_id', id), parentMod);
    if (!res.isSuccess) return null;
    final savedDoc = await coll.findOne(where.id(id!));
    return VanillaUser.fromJson(savedDoc!.withRefs());
  }

  Future<bool> delete({Db? db}) async {
    if (id == null) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final res = await coll.deleteOne(where.eq(r'_id', id));
    return res.isSuccess;
  }
}

class VanillaUsers {
  static String get _collection => 'vanilla_users';
  static String get collection => _collection;

  static Future<List<VanillaUser?>> saveMany(
    List<VanillaUser> vanillaUsers, {
    Db? db,
  }) async {
    if (vanillaUsers.isEmpty) return <VanillaUser>[];
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final now = DateTime.now().toUtc();
    final List<Map<String, dynamic>> toInsert = [];
    final List<Map<String, dynamic>> toSave = [];
    for (final v in vanillaUsers) {
      final json = sanitizedDocument(v.toJson());
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
    if (uniqueIds.isEmpty) return <VanillaUser>[];
    final insertedDocs =
        await coll.find(where.oneFrom('_id', uniqueIds)).toList();
    return insertedDocs
        .map((doc) => VanillaUser.fromJson(doc.withRefs()))
        .toList();
  }

  static Future<VanillaUser?> findById(
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
      final _hasBaseType = projections.any((p) => p is VanillaUserProjections);
      if (!_hasBaseType) {
        projDoc.addAll(VanillaUserProjections().toProjection());
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
      return VanillaUser.fromJson(results.first.withRefs());
    }
    // fallback: return entire vanillaUser
    final vanillaUser = await coll.findOne(where.eq(r'_id', id));
    return vanillaUser == null
        ? null
        : VanillaUser.fromJson(vanillaUser.withRefs());
  }

  /// Type-safe findOne by predicate
  static Future<VanillaUser?> findOne(
    Expression Function(QVanillaUser v)? predicate, {
    Db? db,
    List<Lookup> lookups = const [],
    List<BaseProjections> projections = const [],
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

    if (predicate == null) {
      final vanillaUser = await coll.modernFindOne(sort: {'created_at': -1});
      if (vanillaUser == null) return null;
      return VanillaUser.fromJson(vanillaUser.withRefs());
    }

    final selectorBuilder = predicate(QVanillaUser()).toSelectorBuilder();
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
      return VanillaUser.fromJson(results.first.withRefs());
    }

    // fallback to simple findOne
    final vanillaUserResult = await coll.findOne(selectorMap.cleaned());
    return vanillaUserResult == null
        ? null
        : VanillaUser.fromJson(vanillaUserResult.withRefs());
  }

  /// Type-safe findOne by named arguments
  static Future<VanillaUser?> findOneByNamed({
    ObjectId? id,
    String? firstName,
    String? lastName,
    Db? db,
    List<Lookup> lookups = const [],
    List<BaseProjections> projections = const [],
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

    final selector = <String, dynamic>{};

    if (id != null) selector['_id'] = id;
    if (firstName != null) selector['first_name'] = firstName;
    if (lastName != null) selector['last_name'] = lastName;
    if (selector.isEmpty) {
      final vanillaUser = await coll.modernFindOne(sort: {'created_at': -1});
      if (vanillaUser == null) return null;
      return VanillaUser.fromJson(vanillaUser.withRefs());
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
      final _hasBaseType = projections.any((p) => p is VanillaUserProjections);
      if (!_hasBaseType) {
        projDoc.addAll(VanillaUserProjections().toProjection());
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
      final vanillaUsers =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (vanillaUsers.isEmpty) return null;
      return vanillaUsers
          .map((d) => VanillaUser.fromJson(d.withRefs()))
          .toList()
          .first;
    }

    final vanillaUserResult = await coll.findOne(selector);
    return vanillaUserResult == null
        ? null
        : VanillaUser.fromJson(vanillaUserResult.withRefs());
  }

  /// Type-safe findMany by predicate
  static Future<List<VanillaUser>> findMany(
    Expression Function(QVanillaUser v) predicate, {
    List<Lookup> lookups = const [],
    int? skip,
    int limit = 10,
    (String, int) sort = const ("created_at", -1),
    List<BaseProjections> projections = const [],
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

    var selectorBuilder = predicate(QVanillaUser()).toSelectorBuilder();
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
      final vanillaUsers =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (vanillaUsers.isEmpty) return [];
      return vanillaUsers
          .map((d) => VanillaUser.fromJson(d.withRefs()))
          .toList();
    }

    if (skip != null) selectorBuilder = selectorBuilder.skip(skip);
    selectorBuilder = selectorBuilder.limit(limit);

    selectorMap = selectorBuilder.map;

    final vanillaUsers = await coll.find(selectorMap.cleaned()).toList();
    return vanillaUsers.map((e) => VanillaUser.fromJson(e.withRefs())).toList();
  }

  /// Type-safe findMany by named arguments
  static Future<List<VanillaUser>> findManyByNamed({
    ObjectId? id,
    String? firstName,
    String? lastName,
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
    if (firstName != null) selector['first_name'] = firstName;
    if (lastName != null) selector['last_name'] = lastName;

    if (selector.isEmpty) {
      final vanillaUsers =
          await coll.modernFind(sort: sort, limit: limit, skip: skip).toList();
      if (vanillaUsers.isEmpty) return [];
      return vanillaUsers
          .map((e) => VanillaUser.fromJson(e.withRefs()))
          .toList();
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
      final _hasBaseType = projections.any((p) => p is VanillaUserProjections);
      if (!_hasBaseType) {
        projDoc.addAll(VanillaUserProjections().toProjection());
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
      final vanillaUsers =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (vanillaUsers.isEmpty) return [];
      return vanillaUsers
          .map((d) => VanillaUser.fromJson(d.withRefs()))
          .toList();
    }

    final vanillaUsers =
        await coll
            .modernFind(filter: selector, limit: limit, skip: skip, sort: sort)
            .toList();
    return vanillaUsers.map((e) => VanillaUser.fromJson(e.withRefs())).toList();
  }

  static Future<bool> deleteOne(
    Expression Function(QVanillaUser v) predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final expr = predicate(QVanillaUser());
    final selector = expr.toSelectorBuilder();
    final coll = await database.collection(_collection);
    final result = await coll.deleteOne(selector.map.cleaned());
    return result.isSuccess;
  }

  /// Type-safe deleteOne by named arguments
  static Future<bool> deleteOneByNamed({
    ObjectId? id,
    String? firstName,
    String? lastName,
    Db? db,
  }) async {
    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (firstName != null) selector['first_name'] = firstName;
    if (lastName != null) selector['last_name'] = lastName;
    if (selector.isEmpty) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final result = await coll.deleteOne(selector);
    return result.isSuccess;
  }

  /// Type-safe deleteMany
  static Future<bool> deleteMany(
    Expression Function(QVanillaUser v) predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final expr = predicate(QVanillaUser());
    final selector = expr.toSelectorBuilder();
    final coll = await database.collection(_collection);
    final result = await coll.deleteMany(selector.map.cleaned());
    return result.isSuccess;
  }

  /// Type-safe deleteMany by named arguments
  static Future<bool> deleteManyByNamed({
    ObjectId? id,
    String? firstName,
    String? lastName,
    Db? db,
  }) async {
    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (firstName != null) selector['first_name'] = firstName;
    if (lastName != null) selector['last_name'] = lastName;
    if (selector.isEmpty) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final result = await coll.deleteMany(selector);
    return result.isSuccess;
  }

  /// Type-safe updateOne
  static Future<VanillaUser?> updateOne(
    Expression Function(QVanillaUser v) predicate, {
    ObjectId? id,
    String? firstName,
    String? lastName,
    Db? db,
  }) async {
    final modifier = _buildModifier(
      sanitizedDocument({
        if (id != null) '_id': id,
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
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
    return VanillaUser.fromJson(updatedDoc.withRefs());
  }

  /// Type-safe updateMany
  static Future<List<VanillaUser>> updateMany(
    Expression Function(QVanillaUser v) predicate, {
    ObjectId? id,
    String? firstName,
    String? lastName,
    Db? db,
  }) async {
    final modifier = _buildModifier(
      sanitizedDocument({
        if (id != null) '_id': id,
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
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
    return updatedDocs
        .map((doc) => VanillaUser.fromJson(doc.withRefs()))
        .toList();
  }

  static ModifierBuilder _buildModifier(Map<String, dynamic> updateMap) {
    final now = DateTime.now().toUtc();
    var modifier = modify.set('updated_at', now);
    updateMap.forEach((k, v) => modifier = modifier.set(k, v));
    return modifier;
  }

  /// Prioritize `updateOne` whenever possible to avoid type mismatch.
  /// This method is a fallback for cases where you just had to use a map.
  static Future<VanillaUser?> updateOneFromMap(
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
    return updatedDoc == null
        ? null
        : VanillaUser.fromJson(updatedDoc.withRefs());
  }

  static Future<int> count(
    Expression Function(QVanillaUser v)? predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

    final selectorMap =
        predicate == null
            ? <String, dynamic>{}
            : predicate(QVanillaUser()).toSelectorBuilder().map;

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

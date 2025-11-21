// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// Author: Wan Clem <wannclem@gmail.com>

part of 'token.dart';

// **************************************************************************
// MongoDocumentGenerator
// **************************************************************************

enum TokenFields {
  id,
  ownerEmail,
  token,
  data,
  reason,
  description,
  numberOfUpdates,
  expireAt,
  createdAt,
  updatedAt,
}

class TokenProjections implements BaseProjections {
  @override
  final List<TokenFields>? inclusions;
  final List<TokenFields>? exclusions;
  @override
  final Map<String, dynamic> fieldMappings = const {
    "id": "_id",
    "ownerEmail": "owner_email",
    "token": "token",
    "data": "data",
    "reason": "reason",
    "description": "description",
    "numberOfUpdates": "number_of_updates",
    "expireAt": "expire_at",
    "createdAt": "created_at",
    "updatedAt": "updated_at",
  };
  const TokenProjections({this.inclusions, this.exclusions});

  @override
  Map<String, int> toProjection() {
    return {
      '_id': 1,
      'owner_email': 1,
      'token': 1,
      'data': 1,
      'reason': 1,
      'description': 1,
      'number_of_updates': 1,
      'expire_at': 1,
      'created_at': 1,
      'updated_at': 1,
    };
  }
}

const _nestedCollections = <String, String>{};

class QToken {
  final String _prefix;
  QToken([this._prefix = '']);

  String _key(String field) => _prefix.isEmpty ? field : '$_prefix.$field';

  QueryField<ObjectId?> get id => QueryField<ObjectId?>(_key('_id'));

  QueryField<String?> get ownerEmail =>
      QueryField<String?>(_key('owner_email'));

  QueryField<String?> get token => QueryField<String?>(_key('token'));

  QMap<dynamic> get data => QMap<dynamic>(_key('data'));

  QueryField<String?> get reason => QueryField<String?>(_key('reason'));

  QueryField<String?> get description =>
      QueryField<String?>(_key('description'));

  QueryField<int?> get numberOfUpdates =>
      QueryField<int?>(_key('number_of_updates'));

  QueryField<DateTime?> get expireAt =>
      QueryField<DateTime?>(_key('expire_at'));

  QueryField<DateTime?> get createdAt =>
      QueryField<DateTime?>(_key('created_at'));

  QueryField<DateTime?> get updatedAt =>
      QueryField<DateTime?>(_key('updated_at'));
}

extension $TokenExtension on Token {
  static String get _collection => 'tokens';

  Future<Token?> save({Db? db}) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final now = DateTime.now().toUtc();
    final isInsert = id == null;

    final tokenMap = toJson()..remove('_id');
    tokenMap.update('created_at', (v) => v ?? now, ifAbsent: () => now);
    tokenMap.update('updated_at', (v) => now, ifAbsent: () => now);

    var token = sanitizedDocument({...tokenMap});
    for (var entry in tokenMap.entries) {
      final root = entry.key;
      if (_nestedCollections.containsKey(root)) {
        final Map<String, dynamic> value =
            entry.value is Map
                ? Map<String, dynamic>.from(entry.value as Map)
                : <String, dynamic>{};
        if (value.isEmpty) continue;
        final nestedId = value['_id'] as ObjectId?;
        if (nestedId == null) {
          token.remove(root);
        } else {
          token[root] = nestedId;
        }
      }
    }

    if (isInsert) {
      final result = await coll.insertOne(token);
      if (!result.isSuccess) return null;
      final savedDoc = await coll.findOne(where.id(result.id));
      return Token.fromJson(savedDoc!.withRefs());
    }

    var parentMod = modify.set('updated_at', now);
    token.forEach((k, v) => parentMod = parentMod.set(k, v));
    final res = await coll.updateOne(where.eq(r'_id', id), parentMod);
    if (!res.isSuccess) return null;
    final savedDoc = await coll.findOne(where.id(id!));
    return Token.fromJson(savedDoc!.withRefs());
  }

  Future<bool> delete({Db? db}) async {
    if (id == null) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final res = await coll.deleteOne(where.eq(r'_id', id));
    return res.isSuccess;
  }
}

class Tokens {
  static String get _collection => 'tokens';
  static String get collection => _collection;

  static Future<List<Token?>> saveMany(List<Token> tokens, {Db? db}) async {
    if (tokens.isEmpty) return <Token>[];
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final now = DateTime.now().toUtc();
    final List<Map<String, dynamic>> toInsert = [];
    final List<Map<String, dynamic>> toSave = [];
    for (final t in tokens) {
      final json = sanitizedDocument(t.toJson());
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
    if (uniqueIds.isEmpty) return <Token>[];
    final insertedDocs =
        await coll.find(where.oneFrom('_id', uniqueIds)).toList();
    return insertedDocs.map((doc) => Token.fromJson(doc.withRefs())).toList();
  }

  static Future<Token?> findById(
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
      final _hasBaseType = projections.any((p) => p is TokenProjections);
      if (!_hasBaseType) {
        projDoc.addAll(TokenProjections().toProjection());
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
      return Token.fromJson(results.first.withRefs());
    }
    // fallback: return entire token
    final token = await coll.findOne(where.eq(r'_id', id));
    return token == null ? null : Token.fromJson(token.withRefs());
  }

  /// Type-safe findOne by predicate
  static Future<Token?> findOne(
    Expression Function(QToken t)? predicate, {
    Db? db,
    List<Lookup> lookups = const [],
    List<BaseProjections> projections = const [],
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

    if (predicate == null) {
      final token = await coll.modernFindOne(sort: {'created_at': -1});
      if (token == null) return null;
      return Token.fromJson(token.withRefs());
    }

    final selectorBuilder = predicate(QToken()).toSelectorBuilder();
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
      return Token.fromJson(results.first.withRefs());
    }

    // fallback to simple findOne
    final tokenResult = await coll.findOne(selectorMap.cleaned());
    return tokenResult == null ? null : Token.fromJson(tokenResult.withRefs());
  }

  /// Type-safe findOne by named arguments
  static Future<Token?> findOneByNamed({
    ObjectId? id,
    String? ownerEmail,
    String? token,
    Map<String, dynamic>? data,
    String? reason,
    String? description,
    int? numberOfUpdates,
    DateTime? expireAt,
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
    if (ownerEmail != null) selector['owner_email'] = ownerEmail;
    if (token != null) selector['token'] = token;
    if (data != null) selector['data'] = data;
    if (reason != null) selector['reason'] = reason;
    if (description != null) selector['description'] = description;
    if (numberOfUpdates != null)
      selector['number_of_updates'] = numberOfUpdates;
    if (expireAt != null) selector['expire_at'] = expireAt;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) {
      final token = await coll.modernFindOne(sort: {'created_at': -1});
      if (token == null) return null;
      return Token.fromJson(token.withRefs());
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
      final _hasBaseType = projections.any((p) => p is TokenProjections);
      if (!_hasBaseType) {
        projDoc.addAll(TokenProjections().toProjection());
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
      final tokens =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (tokens.isEmpty) return null;
      return tokens.map((d) => Token.fromJson(d.withRefs())).toList().first;
    }

    final tokenResult = await coll.findOne(selector);
    return tokenResult == null ? null : Token.fromJson(tokenResult.withRefs());
  }

  /// Type-safe findMany by predicate
  static Future<List<Token>> findMany(
    Expression Function(QToken t) predicate, {
    List<Lookup> lookups = const [],
    int? skip,
    int limit = 10,
    (String, int) sort = const ("created_at", -1),
    List<BaseProjections> projections = const [],
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

    var selectorBuilder = predicate(QToken()).toSelectorBuilder();
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
      final tokens =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (tokens.isEmpty) return [];
      return tokens.map((d) => Token.fromJson(d.withRefs())).toList();
    }

    if (skip != null) selectorBuilder = selectorBuilder.skip(skip);
    selectorBuilder = selectorBuilder.limit(limit);

    selectorMap = selectorBuilder.map;

    final tokens = await coll.find(selectorMap.cleaned()).toList();
    return tokens.map((e) => Token.fromJson(e.withRefs())).toList();
  }

  /// Type-safe findMany by named arguments
  static Future<List<Token>> findManyByNamed({
    ObjectId? id,
    String? ownerEmail,
    String? token,
    Map<String, dynamic>? data,
    String? reason,
    String? description,
    int? numberOfUpdates,
    DateTime? expireAt,
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
    if (ownerEmail != null) selector['owner_email'] = ownerEmail;
    if (token != null) selector['token'] = token;
    if (data != null) selector['data'] = data;
    if (reason != null) selector['reason'] = reason;
    if (description != null) selector['description'] = description;
    if (numberOfUpdates != null)
      selector['number_of_updates'] = numberOfUpdates;
    if (expireAt != null) selector['expire_at'] = expireAt;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;

    if (selector.isEmpty) {
      final tokens =
          await coll.modernFind(sort: sort, limit: limit, skip: skip).toList();
      if (tokens.isEmpty) return [];
      return tokens.map((e) => Token.fromJson(e.withRefs())).toList();
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
      final _hasBaseType = projections.any((p) => p is TokenProjections);
      if (!_hasBaseType) {
        projDoc.addAll(TokenProjections().toProjection());
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
      final tokens =
          await coll.aggregateToStream(collisionFreePipeline).toList();
      if (tokens.isEmpty) return [];
      return tokens.map((d) => Token.fromJson(d.withRefs())).toList();
    }

    final tokens =
        await coll
            .modernFind(filter: selector, limit: limit, skip: skip, sort: sort)
            .toList();
    return tokens.map((e) => Token.fromJson(e.withRefs())).toList();
  }

  static Future<bool> deleteOne(
    Expression Function(QToken t) predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final expr = predicate(QToken());
    final selector = expr.toSelectorBuilder();
    final coll = await database.collection(_collection);
    final result = await coll.deleteOne(selector.map.cleaned());
    return result.isSuccess;
  }

  /// Type-safe deleteOne by named arguments
  static Future<bool> deleteOneByNamed({
    ObjectId? id,
    String? ownerEmail,
    String? token,
    Map<String, dynamic>? data,
    String? reason,
    String? description,
    int? numberOfUpdates,
    DateTime? expireAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (ownerEmail != null) selector['owner_email'] = ownerEmail;
    if (token != null) selector['token'] = token;
    if (data != null) selector['data'] = data;
    if (reason != null) selector['reason'] = reason;
    if (description != null) selector['description'] = description;
    if (numberOfUpdates != null)
      selector['number_of_updates'] = numberOfUpdates;
    if (expireAt != null) selector['expire_at'] = expireAt;
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
    Expression Function(QToken t) predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final expr = predicate(QToken());
    final selector = expr.toSelectorBuilder();
    final coll = await database.collection(_collection);
    final result = await coll.deleteMany(selector.map.cleaned());
    return result.isSuccess;
  }

  /// Type-safe deleteMany by named arguments
  static Future<bool> deleteManyByNamed({
    ObjectId? id,
    String? ownerEmail,
    String? token,
    Map<String, dynamic>? data,
    String? reason,
    String? description,
    int? numberOfUpdates,
    DateTime? expireAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (ownerEmail != null) selector['owner_email'] = ownerEmail;
    if (token != null) selector['token'] = token;
    if (data != null) selector['data'] = data;
    if (reason != null) selector['reason'] = reason;
    if (description != null) selector['description'] = description;
    if (numberOfUpdates != null)
      selector['number_of_updates'] = numberOfUpdates;
    if (expireAt != null) selector['expire_at'] = expireAt;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final result = await coll.deleteMany(selector);
    return result.isSuccess;
  }

  /// Type-safe updateOne
  static Future<Token?> updateOne(
    Expression Function(QToken t) predicate, {
    ObjectId? id,
    String? ownerEmail,
    String? token,
    Map<String, dynamic>? data,
    String? reason,
    String? description,
    int? numberOfUpdates,
    DateTime? expireAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final modifier = _buildModifier(
      sanitizedDocument({
        if (id != null) '_id': id,
        if (ownerEmail != null) 'owner_email': ownerEmail,
        if (token != null) 'token': token,
        if (data != null) 'data': data,
        if (reason != null) 'reason': reason,
        if (description != null) 'description': description,
        if (numberOfUpdates != null) 'number_of_updates': numberOfUpdates,
        if (expireAt != null) 'expire_at': expireAt,
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
    return Token.fromJson(updatedDoc.withRefs());
  }

  /// Type-safe updateMany
  static Future<List<Token>> updateMany(
    Expression Function(QToken t) predicate, {
    ObjectId? id,
    String? ownerEmail,
    String? token,
    Map<String, dynamic>? data,
    String? reason,
    String? description,
    int? numberOfUpdates,
    DateTime? expireAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final modifier = _buildModifier(
      sanitizedDocument({
        if (id != null) '_id': id,
        if (ownerEmail != null) 'owner_email': ownerEmail,
        if (token != null) 'token': token,
        if (data != null) 'data': data,
        if (reason != null) 'reason': reason,
        if (description != null) 'description': description,
        if (numberOfUpdates != null) 'number_of_updates': numberOfUpdates,
        if (expireAt != null) 'expire_at': expireAt,
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
    return updatedDocs.map((doc) => Token.fromJson(doc.withRefs())).toList();
  }

  static ModifierBuilder _buildModifier(Map<String, dynamic> updateMap) {
    final now = DateTime.now().toUtc();
    var modifier = modify.set('updated_at', now);
    updateMap.forEach((k, v) => modifier = modifier.set(k, v));
    return modifier;
  }

  /// Prioritize `updateOne` whenever possible to avoid type mismatch.
  /// This method is a fallback for cases where you just had to use a map.
  static Future<Token?> updateOneFromMap(
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
    return updatedDoc == null ? null : Token.fromJson(updatedDoc.withRefs());
  }

  static Future<int> count(
    Expression Function(QToken t)? predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

    final selectorMap =
        predicate == null
            ? <String, dynamic>{}
            : predicate(QToken()).toSelectorBuilder().map;

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

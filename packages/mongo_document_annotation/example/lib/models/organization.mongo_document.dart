// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// Author: Wan Clem <wannclem@gmail.com>

part of 'organization.dart';

// **************************************************************************
// MongoDocumentGenerator
// **************************************************************************

enum OrganizationFields {
  id,
  tempId,
  name,
  avatar,
  ephemeralData,
  active,
  createdAt,
  updatedAt,
}

class OrganizationProjections implements BaseProjections {
  @override
  final List<OrganizationFields>? inclusions;
  final List<OrganizationFields>? exclusions;
  @override
  final Map<String, dynamic> fieldMappings = const {
    "id": "_id",
    "tempId": "temp_id",
    "name": "name",
    "avatar": "avatar",
    "ephemeralData": "ephemeral_data",
    "active": "active",
    "createdAt": "created_at",
    "updatedAt": "updated_at",
  };
  const OrganizationProjections({this.inclusions, this.exclusions});

  @override
  Map<String, int> toProjection() {
    return {
      '_id': 1,
      'temp_id': 1,
      'name': 1,
      'avatar': 1,
      'ephemeral_data': 1,
      'active': 1,
      'created_at': 1,
      'updated_at': 1,
    };
  }
}

const _nestedCollections = <String, String>{'owner': 'accounts'};

enum OrganizationOwnerFields {
  id,
  firstName,
  lastName,
  email,
  password,
  createdAt,
  updatedAt,
}

class OrganizationOwnerProjections implements BaseProjections {
  @override
  final List<OrganizationOwnerFields>? inclusions;
  final List<OrganizationOwnerFields>? exclusions;
  @override
  final Map<String, dynamic> fieldMappings = const {
    "id": "owner._id",
    "firstName": "owner.first_name",
    "lastName": "owner.last_name",
    "email": "owner.email",
    "password": "owner.password",
    "createdAt": "owner.created_at",
    "updatedAt": "owner.updated_at",
  };
  const OrganizationOwnerProjections({this.inclusions, this.exclusions});

  @override
  Map<String, int> toProjection() {
    return {
      'owner._id': 1,
      'owner.first_name': 1,
      'owner.last_name': 1,
      'owner.email': 1,
      'owner.password': 1,
      'owner.created_at': 1,
      'owner.updated_at': 1,
    };
  }
}

class QOrganization {
  final String _prefix;
  QOrganization([this._prefix = '']);

  String _key(String field) => _prefix.isEmpty ? field : '$_prefix.$field';

  QueryField<ObjectId?> get id => QueryField<ObjectId?>(_key('_id'));

  QueryField<String?> get tempId => QueryField<String?>(_key('temp_id'));

  QUser get owner => QUser(_key('owner'));

  QueryField<String?> get name => QueryField<String?>(_key('name'));

  QueryField<dynamic> get avatar => QueryField<dynamic>(_key('avatar'));

  QMap<dynamic> get ephemeralData => QMap<dynamic>(_key('ephemeral_data'));

  QueryField<bool> get active => QueryField<bool>(_key('active'));

  QueryField<DateTime?> get createdAt =>
      QueryField<DateTime?>(_key('created_at'));

  QueryField<DateTime?> get updatedAt =>
      QueryField<DateTime?>(_key('updated_at'));
}

extension $OrganizationExtension on Organization {
  static String get _collection => 'organizations';

  Future<Organization?> save({Db? db}) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final now = DateTime.now().toUtc();
    final isInsert = id == null;

    final organizationMap = toJson()..remove('_id');
    organizationMap.update('created_at', (v) => v ?? now, ifAbsent: () => now);
    organizationMap.update('updated_at', (v) => now, ifAbsent: () => now);

    var organization = {...organizationMap};
    for (var entry in organizationMap.entries) {
      final root = entry.key;
      if (_nestedCollections.containsKey(root)) {
        final Map<String, dynamic> value =
            entry.value is Map
                ? Map<String, dynamic>.from(entry.value as Map)
                : <String, dynamic>{};
        if (value.isEmpty) continue;
        final nestedId = value['_id'] as ObjectId?;
        if (nestedId == null) {
          organization.remove(root);
        } else {
          organization[root] = nestedId;
        }
      }
    }

    if (isInsert) {
      final result = await coll.insertOne(organization);
      if (!result.isSuccess) return null;
      final savedDoc = await coll.findOne(where.id(result.id));
      return Organization.fromJson(savedDoc!.withRefs());
    }

    var parentMod = modify.set('updated_at', now);
    organization.forEach((k, v) => parentMod = parentMod.set(k, v));
    final res = await coll.updateOne(where.eq(r'_id', id), parentMod);
    if (!res.isSuccess) return null;
    final savedDoc = await coll.findOne(where.id(id!));
    return Organization.fromJson(savedDoc!.withRefs());
  }

  Future<bool> delete({Db? db}) async {
    if (id == null) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final res = await coll.deleteOne(where.eq(r'_id', id));
    return res.isSuccess;
  }
}

class Organizations {
  static String get _collection => 'organizations';
  static Future<List<Organization?>> saveMany(
    List<Organization> organizations, {
    Db? db,
  }) async {
    if (organizations.isEmpty) return <Organization>[];
    final List<Map<String, dynamic>> organizationsMap =
        organizations.map((o) {
          final json = o.toJson()..remove('_id');
          final now = DateTime.now().toUtc();
          json.update('created_at', (v) => v ?? now, ifAbsent: () => now);
          json.update('updated_at', (v) => now, ifAbsent: () => now);
          return json.map((key, value) {
            if (_nestedCollections.containsKey(key) && value is Map) {
              return MapEntry<String, dynamic>(key, value['_id'] as ObjectId?);
            }
            return MapEntry<String, dynamic>(key, value);
          });
        }).toList();
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final result = await coll.insertMany(organizationsMap);
    if (!result.isSuccess || result.ids == null) {
      return [];
    }
    final insertedIds = result.ids!;
    final insertedDocs =
        await coll.find(where.oneFrom('_id', insertedIds)).toList();
    return insertedDocs
        .map((doc) => Organization.fromJson(doc.withRefs()))
        .toList();
  }

  static Future<Organization?> findById(
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
        projDoc.addAll(OrganizationProjections().toProjection());
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

      final organizations = await coll.aggregateToStream(pipeline).toList();
      if (organizations.isEmpty) return null;
      return Organization.fromJson(organizations.first.withRefs());
    }

    // fallback: return entire organization
    final organization = await coll.findOne(where.eq(r'_id', id));
    return organization == null
        ? null
        : Organization.fromJson(organization.withRefs());
  }

  /// Type-safe findOne by predicate
  static Future<Organization?> findOne(
    Expression Function(QOrganization o)? predicate, {
    Db? db,
    List<BaseProjections> projections = const [],
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

    if (predicate == null) {
      final organization = await coll.modernFindOne(sort: {'created_at': -1});
      if (organization == null) return null;
      return Organization.fromJson(organization.withRefs());
    }
    final selectorBuilder = predicate(QOrganization()).toSelectorBuilder();
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
      return Organization.fromJson(results.first.withRefs());
    }

    // fallback to simple findOne
    final organizationResult = await coll.findOne(selectorMap.cleaned());
    return organizationResult == null
        ? null
        : Organization.fromJson(organizationResult.withRefs());
  }

  /// Type-safe findOne by named arguments
  static Future<Organization?> findOneByNamed({
    ObjectId? id,
    String? tempId,
    User? owner,
    String? name,
    dynamic avatar,
    Map<String, dynamic>? ephemeralData,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
    List<BaseProjections> projections = const [],
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (tempId != null) selector['temp_id'] = tempId;
    if (owner != null) selector['owner'] = owner.id;
    if (name != null) selector['name'] = name;
    if (avatar != null) selector['avatar'] = avatar;
    if (ephemeralData != null) selector['ephemeral_data'] = ephemeralData;
    if (active != null) selector['active'] = active;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) {
      final organization = await coll.modernFindOne(sort: {'created_at': -1});
      if (organization == null) return null;
      return Organization.fromJson(organization.withRefs());
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
        projDoc.addAll(OrganizationProjections().toProjection());
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

      final organizations = await coll.aggregateToStream(pipeline).toList();
      if (organizations.isEmpty) return null;
      return Organization.fromJson(organizations.first.withRefs());
    }
    final organizationResult = await coll.findOne(selector);
    return organizationResult == null
        ? null
        : Organization.fromJson(organizationResult.withRefs());
  }

  /// Type-safe findMany by predicate
  static Future<List<Organization>> findMany(
    Expression Function(QOrganization o) predicate, {
    int? skip,
    int limit = 10,
    (String, int) sort = const ("created_at", -1),
    List<BaseProjections> projections = const [],
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

    var selectorBuilder = predicate(QOrganization()).toSelectorBuilder();
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
      final organizations = await coll.aggregateToStream(pipeline).toList();
      if (organizations.isEmpty) return [];
      return organizations
          .map((d) => Organization.fromJson(d.withRefs()))
          .toList();
    }

    if (skip != null) selectorBuilder = selectorBuilder.skip(skip);
    selectorBuilder = selectorBuilder.limit(limit);

    selectorMap = selectorBuilder.map;

    final organizations = await coll.find(selectorMap.cleaned()).toList();
    return organizations
        .map((e) => Organization.fromJson(e.withRefs()))
        .toList();
  }

  /// Type-safe findMany by named arguments
  static Future<List<Organization>> findManyByNamed({
    ObjectId? id,
    String? tempId,
    User? owner,
    String? name,
    dynamic avatar,
    Map<String, dynamic>? ephemeralData,
    bool? active,
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
    if (tempId != null) selector['temp_id'] = tempId;
    if (owner != null) selector['owner'] = owner.id;
    if (name != null) selector['name'] = name;
    if (avatar != null) selector['avatar'] = avatar;
    if (ephemeralData != null) selector['ephemeral_data'] = ephemeralData;
    if (active != null) selector['active'] = active;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) {
      final organizations =
          await coll.modernFind(sort: sort, limit: limit, skip: skip).toList();
      if (organizations.isEmpty) return [];
      return organizations
          .map((e) => Organization.fromJson(e.withRefs()))
          .toList();
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
        projDoc.addAll(OrganizationProjections().toProjection());
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

      final organizations = await coll.aggregateToStream(pipeline).toList();
      if (organizations.isEmpty) return [];
      return organizations
          .map((d) => Organization.fromJson(d.withRefs()))
          .toList();
    }
    final organizations =
        await coll
            .modernFind(filter: selector, limit: limit, skip: skip, sort: sort)
            .toList();
    return organizations
        .map((e) => Organization.fromJson(e.withRefs()))
        .toList();
  }

  static Future<bool> deleteOne(
    Expression Function(QOrganization o) predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final expr = predicate(QOrganization());
    final selector = expr.toSelectorBuilder();
    final coll = await database.collection(_collection);
    final result = await coll.deleteOne(selector.map.cleaned());
    return result.isSuccess;
  }

  /// Type-safe deleteOne by named arguments
  static Future<bool> deleteOneByNamed({
    ObjectId? id,
    String? tempId,
    User? owner,
    String? name,
    dynamic avatar,
    Map<String, dynamic>? ephemeralData,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (tempId != null) selector['temp_id'] = tempId;
    if (owner != null) selector['owner'] = owner.id;
    if (name != null) selector['name'] = name;
    if (avatar != null) selector['avatar'] = avatar;
    if (ephemeralData != null) selector['ephemeral_data'] = ephemeralData;
    if (active != null) selector['active'] = active;
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
    Expression Function(QOrganization o) predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final expr = predicate(QOrganization());
    final selector = expr.toSelectorBuilder();
    final coll = await database.collection(_collection);
    final result = await coll.deleteMany(selector.map.cleaned());
    return result.isSuccess;
  }

  /// Type-safe deleteMany by named arguments
  static Future<bool> deleteManyByNamed({
    ObjectId? id,
    String? tempId,
    User? owner,
    String? name,
    dynamic avatar,
    Map<String, dynamic>? ephemeralData,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (tempId != null) selector['temp_id'] = tempId;
    if (owner != null) selector['owner'] = owner.id;
    if (name != null) selector['name'] = name;
    if (avatar != null) selector['avatar'] = avatar;
    if (ephemeralData != null) selector['ephemeral_data'] = ephemeralData;
    if (active != null) selector['active'] = active;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final result = await coll.deleteMany(selector);
    return result.isSuccess;
  }

  /// Type-safe updateOne
  static Future<Organization?> updateOne(
    Expression Function(QOrganization o) predicate, {
    ObjectId? id,
    String? tempId,
    User? owner,
    String? name,
    dynamic avatar,
    Map<String, dynamic>? ephemeralData,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final modifier = _buildModifier({
      if (id != null) '_id': id,
      if (tempId != null) 'temp_id': tempId,
      if (owner != null) 'owner': owner.id,
      if (name != null) 'name': name,
      if (avatar != null) 'avatar': avatar,
      if (ephemeralData != null) 'ephemeral_data': ephemeralData,
      if (active != null) 'active': active,
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
    return Organization.fromJson(updatedDoc.withRefs());
  }

  /// Type-safe updateMany
  static Future<List<Organization>> updateMany(
    Expression Function(QOrganization o) predicate, {
    ObjectId? id,
    String? tempId,
    User? owner,
    String? name,
    dynamic avatar,
    Map<String, dynamic>? ephemeralData,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final modifier = _buildModifier({
      if (id != null) '_id': id,
      if (tempId != null) 'temp_id': tempId,
      if (owner != null) 'owner': owner.id,
      if (name != null) 'name': name,
      if (avatar != null) 'avatar': avatar,
      if (ephemeralData != null) 'ephemeral_data': ephemeralData,
      if (active != null) 'active': active,
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
    return updatedDocs
        .map((doc) => Organization.fromJson(doc.withRefs()))
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
  static Future<Organization?> updateOneFromMap(
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
    return updatedDoc == null
        ? null
        : Organization.fromJson(updatedDoc.withRefs());
  }

  static Future<int> count(
    Expression Function(QOrganization o)? predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

    final selectorMap =
        predicate == null
            ? <String, dynamic>{}
            : predicate(QOrganization()).toSelectorBuilder().map;

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

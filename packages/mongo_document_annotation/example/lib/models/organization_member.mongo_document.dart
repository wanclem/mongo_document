// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// Author: Wan Clem <wannclem@gmail.com>

part of 'organization_member.dart';

// **************************************************************************
// MongoDocumentGenerator
// **************************************************************************

enum OrganizationMemberFields {
  id,
  occupation,
  role,
  title,
  createdAt,
  updatedAt,
}

class OrganizationMemberProjections implements BaseProjections {
  @override
  final List<OrganizationMemberFields>? inclusions;
  final List<OrganizationMemberFields>? exclusions;
  @override
  final Map<String, dynamic> fieldMappings = const {
    "id": "_id",
    "occupation": "occupation",
    "role": "role",
    "title": "title",
    "createdAt": "created_at",
    "updatedAt": "updated_at",
  };
  const OrganizationMemberProjections({this.inclusions, this.exclusions});

  @override
  Map<String, int> toProjection() {
    return {
      '_id': 1,
      'occupation': 1,
      'role': 1,
      'title': 1,
      'created_at': 1,
      'updated_at': 1,
    };
  }
}

const _nestedCollections = <String, String>{
  'user_id': 'accounts',
  'organization': 'organizations',
};

enum OrganizationMemberUserFields {
  id,
  firstName,
  lastName,
  email,
  password,
  createdAt,
  updatedAt,
}

class OrganizationMemberUserProjections implements BaseProjections {
  @override
  final List<OrganizationMemberUserFields>? inclusions;
  final List<OrganizationMemberUserFields>? exclusions;
  @override
  final Map<String, dynamic> fieldMappings = const {
    "id": "user_id._id",
    "firstName": "user_id.first_name",
    "lastName": "user_id.last_name",
    "email": "user_id.email",
    "password": "user_id.password",
    "createdAt": "user_id.created_at",
    "updatedAt": "user_id.updated_at",
  };
  const OrganizationMemberUserProjections({this.inclusions, this.exclusions});

  @override
  Map<String, int> toProjection() {
    return {
      'user_id._id': 1,
      'user_id.first_name': 1,
      'user_id.last_name': 1,
      'user_id.email': 1,
      'user_id.password': 1,
      'user_id.created_at': 1,
      'user_id.updated_at': 1,
    };
  }
}

enum OrganizationMemberOrganizationFields {
  id,
  tempId,
  owner,
  name,
  avatar,
  ephemeralData,
  active,
  createdAt,
  updatedAt,
}

class OrganizationMemberOrganizationProjections implements BaseProjections {
  @override
  final List<OrganizationMemberOrganizationFields>? inclusions;
  final List<OrganizationMemberOrganizationFields>? exclusions;
  @override
  final Map<String, dynamic> fieldMappings = const {
    "id": "organization._id",
    "tempId": "organization.temp_id",
    "owner": "organization.owner",
    "name": "organization.name",
    "avatar": "organization.avatar",
    "ephemeralData": "organization.ephemeral_data",
    "active": "organization.active",
    "createdAt": "organization.created_at",
    "updatedAt": "organization.updated_at",
  };
  const OrganizationMemberOrganizationProjections({
    this.inclusions,
    this.exclusions,
  });

  @override
  Map<String, int> toProjection() {
    return {
      'organization._id': 1,
      'organization.temp_id': 1,
      'organization.owner': 1,
      'organization.name': 1,
      'organization.avatar': 1,
      'organization.ephemeral_data': 1,
      'organization.active': 1,
      'organization.created_at': 1,
      'organization.updated_at': 1,
    };
  }
}

class QOrganizationMember {
  final String _prefix;
  QOrganizationMember([this._prefix = '']);

  String _key(String field) => _prefix.isEmpty ? field : '$_prefix.$field';

  QueryField<ObjectId?> get id => QueryField<ObjectId?>(_key('_id'));

  QUser get user => QUser(_key('user_id'));

  QOrganization get organization => QOrganization(_key('organization'));

  QueryField<String?> get occupation => QueryField<String?>(_key('occupation'));

  QueryField<String?> get role => QueryField<String?>(_key('role'));

  QueryField<String?> get title => QueryField<String?>(_key('title'));

  QueryField<DateTime?> get createdAt =>
      QueryField<DateTime?>(_key('created_at'));

  QueryField<DateTime?> get updatedAt =>
      QueryField<DateTime?>(_key('updated_at'));
}

extension $OrganizationMemberExtension on OrganizationMember {
  static String get _collection => 'organizationmembers';

  Future<OrganizationMember?> save({Db? db}) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final now = DateTime.now().toUtc();
    final isInsert = id == null;

    final organizationMemberMap = toJson()..remove('_id');
    organizationMemberMap.update(
      'created_at',
      (v) => v ?? now,
      ifAbsent: () => now,
    );
    organizationMemberMap.update('updated_at', (v) => now, ifAbsent: () => now);

    var organizationMember = {...organizationMemberMap};
    for (var entry in organizationMemberMap.entries) {
      final root = entry.key;
      if (_nestedCollections.containsKey(root)) {
        final Map<String, dynamic> value =
            entry.value is Map
                ? Map<String, dynamic>.from(entry.value as Map)
                : <String, dynamic>{};
        if (value.isEmpty) continue;
        final nestedId = value['_id'] as ObjectId?;
        if (nestedId == null) {
          organizationMember.remove(root);
        } else {
          organizationMember[root] = nestedId;
        }
      }
    }

    if (isInsert) {
      final result = await coll.insertOne(organizationMember);
      if (!result.isSuccess) return null;
      final savedDoc = await coll.findOne(where.id(result.id));
      return OrganizationMember.fromJson(savedDoc!.withRefs());
    }

    var parentMod = modify.set('updated_at', now);
    organizationMember.forEach((k, v) => parentMod = parentMod.set(k, v));
    final res = await coll.updateOne(where.eq(r'_id', id), parentMod);
    if (!res.isSuccess) return null;
    final savedDoc = await coll.findOne(where.id(id!));
    return OrganizationMember.fromJson(savedDoc!.withRefs());
  }

  Future<bool> delete({Db? db}) async {
    if (id == null) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final res = await coll.deleteOne(where.eq(r'_id', id));
    return res.isSuccess;
  }
}

class OrganizationMembers {
  static String get _collection => 'organizationmembers';
  static Future<List<OrganizationMember?>> saveMany(
    List<OrganizationMember> organizationMembers, {
    Db? db,
  }) async {
    if (organizationMembers.isEmpty) return <OrganizationMember>[];
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final now = DateTime.now().toUtc();
    final List<Map<String, dynamic>> toInsert = [];
    final List<Map<String, dynamic>> toSave = [];
    for (final o in organizationMembers) {
      final json = o.toJson();
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
      await coll.save(doc);
      affectedIds.add(doc['_id']);
    }
    final uniqueIds = affectedIds.where((e) => e != null).toSet().toList();
    if (uniqueIds.isEmpty) return <OrganizationMember>[];
    final insertedDocs =
        await coll.find(where.oneFrom('_id', uniqueIds)).toList();
    return insertedDocs
        .map((doc) => OrganizationMember.fromJson(doc.withRefs()))
        .toList();
  }

  static Future<OrganizationMember?> findById(
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
        projDoc.addAll(OrganizationMemberProjections().toProjection());
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

      final organizationMembers =
          await coll.aggregateToStream(pipeline).toList();
      if (organizationMembers.isEmpty) return null;
      return OrganizationMember.fromJson(organizationMembers.first.withRefs());
    }

    // fallback: return entire organizationMember
    final organizationMember = await coll.findOne(where.eq(r'_id', id));
    return organizationMember == null
        ? null
        : OrganizationMember.fromJson(organizationMember.withRefs());
  }

  /// Type-safe findOne by predicate
  static Future<OrganizationMember?> findOne(
    Expression Function(QOrganizationMember o)? predicate, {
    Db? db,
    List<BaseProjections> projections = const [],
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

    if (predicate == null) {
      final organizationMember = await coll.modernFindOne(
        sort: {'created_at': -1},
      );
      if (organizationMember == null) return null;
      return OrganizationMember.fromJson(organizationMember.withRefs());
    }
    final selectorBuilder =
        predicate(QOrganizationMember()).toSelectorBuilder();
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
      return OrganizationMember.fromJson(results.first.withRefs());
    }

    // fallback to simple findOne
    final organizationMemberResult = await coll.findOne(selectorMap.cleaned());
    return organizationMemberResult == null
        ? null
        : OrganizationMember.fromJson(organizationMemberResult.withRefs());
  }

  /// Type-safe findOne by named arguments
  static Future<OrganizationMember?> findOneByNamed({
    ObjectId? id,
    User? user,
    Organization? organization,
    String? occupation,
    String? role,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
    List<BaseProjections> projections = const [],
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (user != null) selector['user_id'] = user.id;
    if (organization != null) selector['organization'] = organization.id;
    if (occupation != null) selector['occupation'] = occupation;
    if (role != null) selector['role'] = role;
    if (title != null) selector['title'] = title;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) {
      final organizationMember = await coll.modernFindOne(
        sort: {'created_at': -1},
      );
      if (organizationMember == null) return null;
      return OrganizationMember.fromJson(organizationMember.withRefs());
    }
    if (projections.isNotEmpty) {
      final pipeline = <Map<String, Object>>[];
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
        projDoc.addAll(OrganizationMemberProjections().toProjection());
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

      final organizationMembers =
          await coll.aggregateToStream(pipeline).toList();
      if (organizationMembers.isEmpty) return null;
      return OrganizationMember.fromJson(organizationMembers.first.withRefs());
    }
    final organizationMemberResult = await coll.findOne(selector);
    return organizationMemberResult == null
        ? null
        : OrganizationMember.fromJson(organizationMemberResult.withRefs());
  }

  /// Type-safe findMany by predicate
  static Future<List<OrganizationMember>> findMany(
    Expression Function(QOrganizationMember o) predicate, {
    int? skip,
    int limit = 10,
    (String, int) sort = const ("created_at", -1),
    List<BaseProjections> projections = const [],
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

    var selectorBuilder = predicate(QOrganizationMember()).toSelectorBuilder();
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
      final organizationMembers =
          await coll.aggregateToStream(pipeline).toList();
      if (organizationMembers.isEmpty) return [];
      return organizationMembers
          .map((d) => OrganizationMember.fromJson(d.withRefs()))
          .toList();
    }

    if (skip != null) selectorBuilder = selectorBuilder.skip(skip);
    selectorBuilder = selectorBuilder.limit(limit);

    selectorMap = selectorBuilder.map;

    final organizationMembers = await coll.find(selectorMap.cleaned()).toList();
    return organizationMembers
        .map((e) => OrganizationMember.fromJson(e.withRefs()))
        .toList();
  }

  /// Type-safe findMany by named arguments
  static Future<List<OrganizationMember>> findManyByNamed({
    ObjectId? id,
    User? user,
    Organization? organization,
    String? occupation,
    String? role,
    String? title,
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
    if (user != null) selector['user_id'] = user.id;
    if (organization != null) selector['organization'] = organization.id;
    if (occupation != null) selector['occupation'] = occupation;
    if (role != null) selector['role'] = role;
    if (title != null) selector['title'] = title;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) {
      final organizationMembers =
          await coll.modernFind(sort: sort, limit: limit, skip: skip).toList();
      if (organizationMembers.isEmpty) return [];
      return organizationMembers
          .map((e) => OrganizationMember.fromJson(e.withRefs()))
          .toList();
    }
    if (projections.isNotEmpty) {
      final pipeline = <Map<String, Object>>[];
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
        projDoc.addAll(OrganizationMemberProjections().toProjection());
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

      final organizationMembers =
          await coll.aggregateToStream(pipeline).toList();
      if (organizationMembers.isEmpty) return [];
      return organizationMembers
          .map((d) => OrganizationMember.fromJson(d.withRefs()))
          .toList();
    }
    final organizationMembers =
        await coll
            .modernFind(filter: selector, limit: limit, skip: skip, sort: sort)
            .toList();
    return organizationMembers
        .map((e) => OrganizationMember.fromJson(e.withRefs()))
        .toList();
  }

  static Future<bool> deleteOne(
    Expression Function(QOrganizationMember o) predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final expr = predicate(QOrganizationMember());
    final selector = expr.toSelectorBuilder();
    final coll = await database.collection(_collection);
    final result = await coll.deleteOne(selector.map.cleaned());
    return result.isSuccess;
  }

  /// Type-safe deleteOne by named arguments
  static Future<bool> deleteOneByNamed({
    ObjectId? id,
    User? user,
    Organization? organization,
    String? occupation,
    String? role,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (user != null) selector['user_id'] = user.id;
    if (organization != null) selector['organization'] = organization.id;
    if (occupation != null) selector['occupation'] = occupation;
    if (role != null) selector['role'] = role;
    if (title != null) selector['title'] = title;
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
    Expression Function(QOrganizationMember o) predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final expr = predicate(QOrganizationMember());
    final selector = expr.toSelectorBuilder();
    final coll = await database.collection(_collection);
    final result = await coll.deleteMany(selector.map.cleaned());
    return result.isSuccess;
  }

  /// Type-safe deleteMany by named arguments
  static Future<bool> deleteManyByNamed({
    ObjectId? id,
    User? user,
    Organization? organization,
    String? occupation,
    String? role,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final selector = <String, dynamic>{};
    if (id != null) selector['_id'] = id;
    if (user != null) selector['user_id'] = user.id;
    if (organization != null) selector['organization'] = organization.id;
    if (occupation != null) selector['occupation'] = occupation;
    if (role != null) selector['role'] = role;
    if (title != null) selector['title'] = title;
    if (createdAt != null) selector['created_at'] = createdAt;
    if (updatedAt != null) selector['updated_at'] = updatedAt;
    if (selector.isEmpty) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final result = await coll.deleteMany(selector);
    return result.isSuccess;
  }

  /// Type-safe updateOne
  static Future<OrganizationMember?> updateOne(
    Expression Function(QOrganizationMember o) predicate, {
    ObjectId? id,
    User? user,
    Organization? organization,
    String? occupation,
    String? role,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final modifier = _buildModifier({
      if (id != null) '_id': id,
      if (user != null) 'user_id': user.id,
      if (organization != null) 'organization': organization.id,
      if (occupation != null) 'occupation': occupation,
      if (role != null) 'role': role,
      if (title != null) 'title': title,
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
    return OrganizationMember.fromJson(updatedDoc.withRefs());
  }

  /// Type-safe updateMany
  static Future<List<OrganizationMember>> updateMany(
    Expression Function(QOrganizationMember o) predicate, {
    ObjectId? id,
    User? user,
    Organization? organization,
    String? occupation,
    String? role,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    Db? db,
  }) async {
    final modifier = _buildModifier({
      if (id != null) '_id': id,
      if (user != null) 'user_id': user.id,
      if (organization != null) 'organization': organization.id,
      if (occupation != null) 'occupation': occupation,
      if (role != null) 'role': role,
      if (title != null) 'title': title,
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
        .map((doc) => OrganizationMember.fromJson(doc.withRefs()))
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
  static Future<OrganizationMember?> updateOneFromMap(
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
        : OrganizationMember.fromJson(updatedDoc.withRefs());
  }

  static Future<int> count(
    Expression Function(QOrganizationMember o)? predicate, {
    Db? db,
  }) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);

    final selectorMap =
        predicate == null
            ? <String, dynamic>{}
            : predicate(QOrganizationMember()).toSelectorBuilder().map;

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

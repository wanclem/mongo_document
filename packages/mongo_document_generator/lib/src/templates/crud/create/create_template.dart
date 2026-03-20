import 'package:analyzer/dart/element/element.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mongo_document/src/templates/parameter_template.dart';
import 'package:pluralize/pluralize.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

class CreateTemplates {
  static String buildPersistenceHelpers(
    String className,
    String collection,
    TypeChecker typeChecker,
    List<FormalParameterElement> params,
    FieldRename? fieldRename,
  ) {
    final classNameVar = ReCase(className).camelCase;
    final nestedCollectionMap = ParameterTemplates.getNestedCollectionMap(
      params,
      typeChecker,
      fieldRename,
    );
    final refFieldKeys = ParameterTemplates.buildStringSetLiteral(
      nestedCollectionMap.keys,
    );
    final objectIdFieldKeys = ParameterTemplates.buildObjectIdFieldKeysLiteral(
      params,
      typeChecker,
      fieldRename,
      excludedKeys: nestedCollectionMap.keys.toSet(),
    );
    final trackedKeys =
        params
            .where((param) => param.name != 'id')
            .map(
              (param) =>
                  "'${ParameterTemplates.getParameterKey(typeChecker, param, fieldRename)}'",
            )
            .join(', ');

    return '''
const _${classNameVar}Collection = '$collection';
const _${classNameVar}RefFields = $refFieldKeys;
const _${classNameVar}ObjectIdFields = $objectIdFieldKeys;
const _${classNameVar}TrackedPersistedKeys = <String>[$trackedKeys];

Map<String, dynamic> _${classNameVar}NormalizePersistedDocument(
  Map<String, dynamic> source,
) {
  final normalized = sanitizedDocument(Map<String, dynamic>.from(source));

  for (final entry in source.entries) {
    final root = entry.key;
    if (!_nestedCollections.containsKey(root)) continue;

    final value = entry.value;
    final rawNestedId =
        value is Map ? Map<String, dynamic>.from(value)['_id'] : value;
    final nestedId =
        rawNestedId is ObjectId
            ? rawNestedId
            : rawNestedId is String
            ? ObjectId.tryParse(rawNestedId)
            : null;

    if (nestedId == null) {
      normalized.remove(root);
    } else {
      normalized[root] = nestedId;
    }
  }

  for (final key in _${classNameVar}ObjectIdFields) {
    if (!source.containsKey(key)) continue;

    final value = source[key];
    final rawId = value is Map ? Map<String, dynamic>.from(value)['_id'] : value;
    final objectId =
        rawId is ObjectId
            ? rawId
            : rawId is String
            ? ObjectId.tryParse(rawId)
            : null;

    if (objectId != null) {
      normalized[key] = objectId;
    } else {
      normalized[key] = value;
    }
  }

  return normalized;
}

void _remember${className}Snapshot(Map<String, dynamic> document) {
  rememberMongoDocumentSnapshot(
    _${classNameVar}Collection,
    _${classNameVar}NormalizePersistedDocument(document),
  );
}

$className _${classNameVar}DeserializeDocument(Map<String, dynamic> document) {
  _remember${className}Snapshot(document);
  return $className.fromJson(
    document.withRefs(
      refFields: _${classNameVar}RefFields,
      objectIdFields: _${classNameVar}ObjectIdFields,
    ),
  );
}

List<$className> _${classNameVar}DeserializeDocuments(
  Iterable<Map<String, dynamic>> documents,
) {
  return documents.map(_${classNameVar}DeserializeDocument).toList();
}

Map<String, dynamic>? _${classNameVar}SnapshotFor(ObjectId id) {
  return mongoDocumentSnapshot(_${classNameVar}Collection, id);
}

ObjectId? _${classNameVar}CoerceDocumentId(dynamic rawId) {
  if (rawId is ObjectId) return rawId;
  if (rawId is String) return ObjectId.tryParse(rawId);
  return null;
}

void _${classNameVar}ForgetSnapshotFor(ObjectId id) {
  forgetMongoDocumentSnapshot(_${classNameVar}Collection, id);
}
''';
  }

  static String save(String className) {
    final classNameVar = ReCase(className).camelCase;
    return '''
  Future<$className?> save({Db? db}) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final now = DateTime.now().toUtc();
    final isInsert = id == null;

    final raw${className}Map = toJson()..remove('_id');
    final persisted${className}Map = _${classNameVar}NormalizePersistedDocument(
      {...raw${className}Map},
    );

    if (isInsert) {
      persisted${className}Map.update(
        'created_at',
        (value) => value ?? now,
        ifAbsent: () => now,
      );
      persisted${className}Map.update(
        'updated_at',
        (_) => now,
        ifAbsent: () => now,
      );

      final result = await coll.insertOne(persisted${className}Map);
      if (!result.isSuccess) return null;
      final savedDoc = await coll.modernFindOne(filter: {'_id': result.id});
      if (savedDoc == null) return null;
      return _${classNameVar}DeserializeDocument(savedDoc);
    }

    var snapshot = _${classNameVar}SnapshotFor(id!);
    snapshot ??= await coll.modernFindOne(filter: {'_id': id});
    if (snapshot == null) return null;
    snapshot = _${classNameVar}NormalizePersistedDocument(snapshot);

    final updateMap = buildMongoUpdateMapFromSnapshot(
      current: persisted${className}Map,
      snapshot: snapshot,
      trackedKeys: _${classNameVar}TrackedPersistedKeys,
    );

    if (updateMap.isEmpty) {
      final savedDoc = await coll.modernFindOne(filter: {'_id': id});
      if (savedDoc == null) return null;
      return _${classNameVar}DeserializeDocument(savedDoc);
    }

    var parentMod = modify.set('updated_at', now);
    updateMap.forEach((key, value) => parentMod = parentMod.set(key, value));
    final res = await coll.updateOne({'_id': id}, parentMod);
    if (!res.isSuccess) return null;
    final savedDoc = await coll.modernFindOne(filter: {'_id': id});
    if (savedDoc == null) return null;
    return _${classNameVar}DeserializeDocument(savedDoc);
  }

  Future<$className?> saveChanges({Db? db}) async {
    return save(db: db);
  }

''';
  }

  static String saveMany(String className) {
    final classNameVar = ReCase(className).camelCase;
    final classNamePlural = Pluralize().plural(classNameVar);
    return '''
  static Future<List<$className?>> saveMany(
    List<$className> $classNamePlural,{Db? db}
  ) async {
    if ($classNamePlural.isEmpty) return <$className>[];
    final database = db ?? await MongoDbConnection.instance;
    final coll = database.collection(_collection);
    final now = DateTime.now().toUtc();
    final List<Map<String, dynamic>> toInsert = [];
    final List<(int, Map<String, dynamic>)> toSave = [];
    final orderedIds = List<dynamic>.filled($classNamePlural.length, null);
    final insertPositions = <int>[];
    for (int index = 0; index < $classNamePlural.length; index++) {
      final item = $classNamePlural[index];
      final json = _${classNameVar}NormalizePersistedDocument(
        item.toJson(),
      );
      final hasId = json.containsKey('_id') && json['_id'] != null;
      if (hasId) {
        json.update('updated_at', (_) => now, ifAbsent: () => now);
        toSave.add((index, json));
      } else {
        json
          ..remove('_id')
          ..update('created_at', (v) => v ?? now, ifAbsent: () => now)
          ..update('updated_at', (_) => now, ifAbsent: () => now);
        toInsert.add(json);
        insertPositions.add(index);
      }
    }
    if (toInsert.isNotEmpty) {
      final insertResult = await coll.insertMany(toInsert);
      if (!insertResult.isSuccess || insertResult.ids == null) {
        return [];
      }
      for (int insertIndex = 0;
          insertIndex < insertResult.ids!.length &&
              insertIndex < insertPositions.length;
          insertIndex++) {
        orderedIds[insertPositions[insertIndex]] =
            insertResult.ids![insertIndex];
      }
    }
    final missingSnapshotIds = <ObjectId>[];
    for (final entry in toSave) {
      final docId = _${classNameVar}CoerceDocumentId(entry.\$2['_id']);
      if (docId == null) continue;
      if (_${classNameVar}SnapshotFor(docId) == null) {
        missingSnapshotIds.add(docId);
      }
    }
    final uniqueMissingSnapshotIds = <ObjectId>[];
    for (final id in missingSnapshotIds) {
      if (!uniqueMissingSnapshotIds.contains(id)) {
        uniqueMissingSnapshotIds.add(id);
      }
    }
    final fetchedSnapshotsById = <ObjectId, Map<String, dynamic>>{};
    if (uniqueMissingSnapshotIds.isNotEmpty) {
      final fetchedSnapshots = await coll
          .modernFind(filter: {'_id': {r'\$in': uniqueMissingSnapshotIds}})
          .toList();
      rememberMongoDocumentSnapshots(_${classNameVar}Collection, fetchedSnapshots);
      for (final snapshot in fetchedSnapshots) {
        final snapshotId = _${classNameVar}CoerceDocumentId(snapshot['_id']);
        if (snapshotId == null) continue;
        fetchedSnapshotsById[snapshotId] = _${classNameVar}NormalizePersistedDocument(snapshot);
      }
    }
    for (final entry in toSave) {
      final position = entry.\$1;
      final doc = entry.\$2;
      final docId = _${classNameVar}CoerceDocumentId(doc['_id']);
      if (docId == null) continue;
      final updateDoc = Map<String, dynamic>.from(doc)..remove('_id');
      var snapshot = _${classNameVar}SnapshotFor(docId) ?? fetchedSnapshotsById[docId];
      if (snapshot == null) continue;
      snapshot = _${classNameVar}NormalizePersistedDocument(snapshot);
      final updateMap = buildMongoUpdateMapFromSnapshot(
        current: updateDoc,
        snapshot: snapshot,
        trackedKeys: _${classNameVar}TrackedPersistedKeys,
      );
      if (updateMap.isEmpty) {
        orderedIds[position] = docId;
        continue;
      }
      var parentMod = modify.set('updated_at', now);
      updateMap.forEach((k, v) => parentMod = parentMod.set(k, v));
      final updateResult = await coll.updateOne({'_id': docId}, parentMod);
      if (updateResult.isSuccess) {
        orderedIds[position] = docId;
      }
    }
    final uniqueIds = <dynamic>[];
    for (final id in orderedIds) {
      if (id == null || uniqueIds.contains(id)) continue;
      uniqueIds.add(id);
    }
    if (uniqueIds.isEmpty) return <$className>[];
    final insertedDocs = await coll
        .modernFind(filter: {'_id': {r'\$in': uniqueIds}})
        .toList();
    final docsById = {
      for (final doc in insertedDocs) doc['_id']: doc,
    };
    return orderedIds
        .map((id) => id == null ? null : docsById[id])
        .map(
          (doc) =>
              doc == null ? null : _${classNameVar}DeserializeDocument(doc),
        )
        .toList();
  }
''';
  }
}

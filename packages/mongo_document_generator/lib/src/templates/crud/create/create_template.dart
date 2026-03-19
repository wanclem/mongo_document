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
  return $className.fromJson(document.withRefs());
}

List<$className> _${classNameVar}DeserializeDocuments(
  Iterable<Map<String, dynamic>> documents,
) {
  return documents.map(_${classNameVar}DeserializeDocument).toList();
}

Map<String, dynamic>? _${classNameVar}SnapshotFor(ObjectId id) {
  return mongoDocumentSnapshot(_${classNameVar}Collection, id);
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
    final List<Map<String, dynamic>> toSave = [];
    for (final ${classNameVar[0]} in $classNamePlural) {
      final json = _${classNameVar}NormalizePersistedDocument(
        ${classNameVar[0]}.toJson(),
      );
      final hasId = json.containsKey('_id') && json['_id'] != null;
      if (hasId) {
        json.update('updated_at', (_) => now, ifAbsent: () => now);
        toSave.add(json);
      } else {
        json
          ..remove('_id')
          ..update('created_at', (v) => v ?? now, ifAbsent: () => now)
          ..update('updated_at', (_) => now, ifAbsent: () => now);
        toInsert.add(json);
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
      dynamic docId = doc['_id'];
      try {
        if (docId is String && docId.length == 24) {
          docId = ObjectId.fromHexString(docId);
        }
      } catch (_) {
        // ignore invalid conversion and let the driver handle it
      }
      if (docId == null) continue;
      final updateDoc = Map<String, dynamic>.from(doc)..remove('_id');
      var parentMod = modify.set('updated_at', now);
      updateDoc.forEach((k, v) => parentMod = parentMod.set(k, v));
      final updateResult = await coll.updateOne({'_id': docId}, parentMod);
      if (updateResult.isSuccess) {
        affectedIds.add(docId);
      }
    }
    final uniqueIds = <dynamic>[];
    for (final id in affectedIds) {
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
    return uniqueIds
        .map((id) => docsById[id])
        .whereType<Map<String, dynamic>>()
        .map(_${classNameVar}DeserializeDocument)
        .toList();
  }
''';
  }
}

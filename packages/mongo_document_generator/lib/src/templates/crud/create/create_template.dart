import 'package:recase/recase.dart';

class CreateTemplates {
  static save(String className) {
    String classNameVar = ReCase(className).camelCase;
    return '''
  Future<$className?> save({Db? db}) async {
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final now = DateTime.now().toUtc();
    final isInsert = id == null;

    final ${classNameVar}Map = toJson()..remove('_id');
    ${classNameVar}Map.update('created_at', (v) => v ?? now, ifAbsent: () => now);
    ${classNameVar}Map.update('updated_at', (v) => now,    ifAbsent: () => now);

    var $classNameVar = {...${classNameVar}Map};
    for (var entry in ${classNameVar}Map.entries) {
      final root = entry.key;
      if (_nestedCollections.containsKey(root)) {
        final Map<String, dynamic> value = entry.value is Map ? Map<String, dynamic>.from(entry.value as Map) : <String, dynamic>{};
        if (value.isEmpty) continue;
        final nestedId = value['_id'] as ObjectId?;
        if (nestedId == null) {
           $classNameVar.remove(root);
        }else{
           $classNameVar[root] = nestedId;
        }
      }
    }

    if (isInsert) {
      final result = await coll.insertOne($classNameVar);
      if (!result.isSuccess) return null;
      final savedDoc = await coll.findOne(where.id(result.id));
      return $className.fromJson(savedDoc!.withRefs());
    }

    var parentMod = modify.set('updated_at', now);
    $classNameVar.forEach((k, v) => parentMod = parentMod.set(k, v));
    final res = await coll.updateOne(where.eq(r'_id', id), parentMod);
    if (!res.isSuccess) return null;
    final savedDoc = await coll.findOne(where.id(id!));
    return $className.fromJson(savedDoc!.withRefs());
  }

''';
  }

  static saveMany(String className) {
    String classNameVar = ReCase(className).camelCase;
    return '''
  static Future<List<$className?>> saveMany(
    List<$className> ${classNameVar}s,{Db? db}
  ) async {
    if (${classNameVar}s.isEmpty) return <$className>[];
    final List<Map<String, dynamic>> ${classNameVar}sMap = ${classNameVar}s.map((${classNameVar[0]}) {
      final json = ${classNameVar[0]}.toJson()..remove('_id');
      final now = DateTime.now().toUtc();
      json.update('created_at', (v) => v ?? now, ifAbsent: () => now);
      json.update('updated_at', (v) => now, ifAbsent: () => now);
      return json.map((key, value) {
        if (_nestedCollections.containsKey(key) && value is Map) {
          return MapEntry<String, dynamic>(
            key, value['_id'] as ObjectId?,
          );
        }
        return MapEntry<String, dynamic>(key, value);
      });
    }).toList();
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final result = await coll.insertMany(${classNameVar}sMap);
    if (!result.isSuccess || result.ids == null) {
      return [];
    }
    final insertedIds = result.ids!;
    final insertedDocs =
        await coll.find(where.oneFrom('_id', insertedIds)).toList();
    return insertedDocs
        .map((doc) => $className.fromJson(doc.withRefs()))
        .toList();
  }
''';
  }
}

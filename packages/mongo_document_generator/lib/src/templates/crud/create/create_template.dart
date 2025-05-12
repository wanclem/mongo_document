class CreateTemplates {
  static save(String className) {
    String classNameVar = className.toLowerCase();
    return '''
  Future<$className?> save() async {
    final coll = await MongoDbConnection.getCollection(_collection);
    final now = DateTime.now().toUtc();
    final isInsert = id == null;

    final ${classNameVar}Map = toJson()..remove('_id')..removeWhere((key, value) => value == null);
    ${classNameVar}Map.update('created_at', (v) => v ?? now, ifAbsent: () => now);
    ${classNameVar}Map.update('updated_at', (v) => now,    ifAbsent: () => now);

    var $classNameVar = {...${classNameVar}Map};
    final nestedUpdates = <Future>[];
    for (var entry in ${classNameVar}Map.entries) {
      final root = entry.key;
      if (_nestedCollections.containsKey(root)) {
        final collectionName = _nestedCollections[root]!;
        var nestedColl = await MongoDbConnection.getCollection(collectionName);
        var value = entry.value as Map<String, dynamic>?;
        if (value == null) continue;
        value.removeWhere((key, value) => value == null);
        final nestedId = value['_id'] as ObjectId?;
        if (nestedId == null) {
           $classNameVar.remove(root);
        }else{
           $classNameVar[root] = nestedId;
           final nestedMap = value..remove('_id');
           if (nestedMap.isNotEmpty) {
            var mod = modify.set('updated_at', now);
            nestedMap.forEach((k, v) => mod = mod.set(k, v));
            nestedUpdates.add(
              nestedColl.updateOne(where.eq(r'_id', nestedId), mod)
            );
          }
        }
      }
    }

    if (isInsert) {
      final result = await coll.insertOne($classNameVar);
      if (!result.isSuccess) return null;
      await Future.wait(nestedUpdates);
      final savedDoc = await coll.findOne({'_id': result.id});
      return $className.fromJson(savedDoc!.withRefs());
    }

    var parentMod = modify.set('updated_at', now);
    $classNameVar.forEach((k, v) => parentMod = parentMod.set(k, v));
    final res = await coll.updateOne(where.eq(r'_id', id), parentMod);
    if (!res.isSuccess) return null;
    await Future.wait(nestedUpdates);
    final savedDoc = await coll.findOne({'_id': res.id});
    return $className.fromJson(savedDoc!.withRefs());
  }

''';
  }

  static saveMany(String className) {
    String classNameVar = className.toLowerCase();
    return '''
   /// Type-safe saveMany
  static Future<List<$className?>> saveMany(
    List<$className> ${classNameVar}s,
  ) async {
    if (${classNameVar}s.isEmpty) return <$className>[];
    final List<Map<String, dynamic>> ${classNameVar}sMap = ${classNameVar}s.map((${classNameVar[0]}) {
      final json = ${classNameVar[0]}.toJson()..remove('_id');
      return json.map((key, value) {
        if (_nestedCollections.containsKey(key) && value is Map) {
          return MapEntry<String, dynamic>(
            key, value['_id'] as ObjectId?,
          );
        }
        return MapEntry<String, dynamic>(key, value);
      });
    }).toList();
    final coll = await MongoDbConnection.getCollection(_collection);
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

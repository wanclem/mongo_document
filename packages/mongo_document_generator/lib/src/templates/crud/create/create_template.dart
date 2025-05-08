class CreateTemplates {
  static save(String className) {
    return '''
  Future<$className?> save() async {
    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);
    final now = DateTime.now().toUtc();
    final isInsert = id == null;

    final parentMap = toJson()..remove('_id')..removeWhere((key, value) => value == null);
    parentMap.update('created_at', (v) => v ?? now, ifAbsent: () => now);
    parentMap.update('updated_at', (v) => now,    ifAbsent: () => now);

    var doc = {...parentMap};
    final nestedUpdates = <Future>[];
    for (var entry in parentMap.entries) {
      final root = entry.key;
      if (_nestedCollections.containsKey(root)) {
        final collectionName = _nestedCollections[root]!;
        var nestedColl =db.collection(collectionName);
        var value = entry.value as Map<String, dynamic>?;
        if (value == null) continue;
        value.removeWhere((key, value) => value == null);
        final nestedId = (value['_id'] ?? value['id']) as ObjectId?;
        if (nestedId == null) {
           doc.remove(root);
        }else{
           doc[root] = nestedId;
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
      final result = await coll.insertOne(doc);
      if (!result.isSuccess) return null;
      await Future.wait(nestedUpdates);
      return copyWith(id: result.id);
    }

    var parentMod = modify.set('updated_at', now);
    doc.forEach((k, v) => parentMod = parentMod.set(k, v));
    final res = await coll.updateOne(where.eq(r'_id', id), parentMod);
    if (!res.isSuccess) return null;
    await Future.wait(nestedUpdates);
    return this;
  }

''';
  }

  static saveMany(String className) {
    return '''
   /// Type‑safe saveMany
  static Future<List<$className?>> saveMany(
    List<$className> docs,
  ) async {
    if (docs.isEmpty) return <$className>[];
    final List<Map<String, dynamic>> raw = docs.map((d) {
      final json = d.toJson()..remove('_id');
      return json.map((key, value) {
        if (_nestedCollections.containsKey(key)) {
          return MapEntry<String, dynamic>(
            key,
            (value['_id'] ?? value['id']) as ObjectId?,
          );
        }
        return MapEntry<String, dynamic>(key, value);
      });
    }).toList();
    final coll = (await MongoConnection.getDb()).collection(_collection);
    final result = await coll.insertMany(raw);
    return docs
        .asMap()
        .entries
        .map((e) {
          final idx = e.key;
          final doc = e.value;
          final id = result.isSuccess ? result.ids![idx] : null;
          return doc.copyWith(id: id);
        })
        .toList();
  }
''';
  }
}

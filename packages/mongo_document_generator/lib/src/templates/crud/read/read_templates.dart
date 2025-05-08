import 'package:mongo_document/src/utils/templates.dart';

class ReadTemplates {
  static String findById(String className) {
    return '''
/// Type‑safe findById with optional nested‑doc projections
  static Future<$className?> findById(
    dynamic id, {
    List<BaseProjections> projections=const [],
  }) async {
    if (id == null) return null;
    if (id is String) id = ObjectId.fromHexString(id);
    if (id is! ObjectId) {
      throw ArgumentError('Invalid id type: \${id.runtimeType}');
    }

    final db = await MongoConnection.getDb();
    final coll = db.collection(_collection);

    if (projections.isNotEmpty) {
       ${buildProjectionFlowTemplate('''{
          r"\$match": {'_id': id}
        }''')}
      final docs = await coll.aggregateToStream(pipeline).toList();
      if (docs.isEmpty) return null;
      return $className.fromJson(docs.first.withRefs());
    }

    // fallback: return entire document
    final doc = await coll.findOne(where.eq(r'_id', id));
    return doc == null ? null : $className.fromJson(doc.withRefs());
  }

''';
  }
}

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mongo_document/mongo_document.dart';
import 'package:mongo_document_generator/mongo_document_generator.dart';
import 'package:mongo_document_generator/src/utils/templates.dart';
import 'package:source_gen/source_gen.dart';

const _jsonKeyChecker = TypeChecker.fromRuntime(JsonKey);
const _jsonSerializableChecker = TypeChecker.fromRuntime(JsonSerializable);

class MongoDocumentGenerator extends GeneratorForAnnotation<MongoDocument> {
  final _formatter = DartFormatter();

  String _buildUpdateParams(List<ParameterElement> params) {
    return params.map((p) {
      final base = p.type.getDisplayString();
      final suffix = (base != 'dynamic' &&
              p.type.nullabilitySuffix == NullabilitySuffix.none)
          ? '?'
          : '';
      final name = p.name;
      return '    $base$suffix $name,';
    }).join('\n');
  }

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) return '';
    FieldRename? fieldRename = getFieldRenamePolicy(
      _jsonSerializableChecker,
      element,
    );
    final className = element.name;
    final collection = annotation.peek('collection')!.stringValue;
    final params = element.unnamedConstructor?.parameters ?? [];
    final nestedCollectionMap = getNestedCollectionMap(params);
    final nestedCollectionProjectionClasses =
        buildNestedCollectionProjectionClasses(
      _jsonSerializableChecker,
      _jsonKeyChecker,
      nestedCollectionMap,
      params,
    );
    final nestedCollectionMapLiteral = buildNestedCollectiontionsMapLiteral(
      nestedCollectionMap,
    );
    final queryClasses = buildQueryClasses(
      _jsonKeyChecker,
      className,
      fieldRename,
      params,
    );

    final template = '''
$nestedCollectionProjectionClasses
$nestedCollectionMapLiteral
$queryClasses

extension \$${className}Extension on $className {
  static String get _collection => '$collection';

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
   
  Future<bool> delete() async {
    if (id == null) return false;
    final res = await (await MongoConnection.getDb())
      .collection(_collection)
      .deleteOne(where.eq(r'_id', id));
    return res.isSuccess;
  }
}

class ${className}s {
  
  static String get _collection => '$collection';
  
   /// Type‑safe insertMany
  static Future<List<$className?>> insertMany(
    List<$className> docs,
  ) async {
    if (docs.isEmpty) return <$className>[];
    final raw = docs.map((d) => d.toJson()..remove('_id')).toList();
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

  /// Type-safe findById
  static Future<$className?> findById(dynamic id) async {
    if (id == null) return null;
    if (id is String) {
      id = ObjectId.fromHexString(id);
    }
    if (id is! ObjectId) {
      throw ArgumentError('Invalid id type: \${id.runtimeType}');
    }
    final doc = await (await MongoConnection.getDb())
        .collection(_collection)
        .findOne(where.eq(r'_id', id));
    return doc == null ? null : $className.fromJson(doc);
  }

  /// Type-safe findOne
  static Future<$className?> findOne(
   Expression Function(Q$className q) predicate
  ) async {
    final selectorBuilder = predicate(Q$className()).toSelectorBuilder();
    final selectorMap = selectorBuilder.map;

    final allKeys = <String>{};
      collectKeys(selectorMap, allKeys);
      final roots =
          allKeys
              .where((k) => k.contains('.'))
              .map((k) => k.split('.').first)
              .toSet();

    if (roots.isNotEmpty) {
      var builder = AggregationPipelineBuilder();
      for (final root in roots) {
        if (!_nestedCollections.containsKey(root)) {
            continue;
        }
        final foreignColl = _nestedCollections[root]!;
        builder = builder
          .addStage(Lookup(from: foreignColl,
                           localField: root,
                           foreignField: '_id',
                           as: root))
          .addStage(Unwind(Field(root)));
      }
      builder = builder.addStage(Match(selectorMap));
      final stream = (await MongoConnection.getDb())
          .collection(_collection)
          .modernAggregate(builder.build());
      final doc = await stream.first;  
      return $className.fromJson(doc);
    }
  
    // fallback to simple findOne
    final doc = await (await MongoConnection.getDb())
        .collection(_collection)
        .findOne(selectorMap);
    return doc == null ? null : $className.fromJson(doc);

  }

  /// Type‑safe findMany
  static Future<List<$className>> findMany(
    Expression Function(Q$className q) predicate, {
    int? skip, int? limit,
    List<BaseProjections>? project,
  }) async {

    var selectorBuilder = predicate(Q$className()).toSelectorBuilder();
    if (skip != null) selectorBuilder = selectorBuilder.skip(skip);
    if (limit != null) selectorBuilder = selectorBuilder.limit(limit);
    final selectorMap = selectorBuilder.map;
  
    final allKeys = <String>{};
    collectKeys(selectorMap, allKeys);
    final roots = allKeys
        .where((k) => k.contains('.'))
        .map((k) => k.split('.').first)
        .toSet();
  
    if (roots.isNotEmpty) {
      var builder = AggregationPipelineBuilder();
      for (final root in roots) {
        if (!_nestedCollections.containsKey(root)) continue;
        builder = builder
          .addStage(Lookup(
            from: _nestedCollections[root]!,
            localField: root,
            foreignField: '_id',
            as: root,
          ))
          .addStage(Unwind(Field(root)));
      }
      builder = builder.addStage(Match(selectorMap));
    
      if (skip != null) builder = builder.addStage(Skip(skip));
      if (limit != null) builder = builder.addStage(Limit(limit));

      final docs = await (await MongoConnection.getDb())
          .collection(_collection)
          .modernAggregate(builder.build())
          .toList();
      return docs.map((e) => $className.fromJson(e)).toList();
    }
  
    final docs = await (await MongoConnection.getDb())
      .collection(_collection)
      .find(selectorMap).toList();
    return docs.map((e) => $className.fromJson(e)).toList();
 }

  /// Type-safe deleteOne
  static Future<bool> deleteOne(
    Expression Function(Q$className q) predicate
  ) async {
    final expr = predicate(Q$className());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
      .collection(_collection)
      .deleteOne(selector.map);
    return result.isSuccess;
  }
  
  /// Type-safe deleteMany
  static Future<bool> deleteMany(
    Expression Function(Q$className q) predicate
  ) async {
    final expr = predicate(Q$className());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
      .collection(_collection)
      .deleteMany(selector.map);
    return result.isSuccess;
  }

  /// Type-safe updateOne
  static Future<bool> updateOne(
    Expression Function(Q$className q) predicate, {
${_buildUpdateParams(params)}
  }) async {
    final modifier = _buildModifier({
      ${params.map((p) {
      final key = getParameterKey(_jsonKeyChecker, p, fieldRename);
      final hasDefault =
          _jsonKeyChecker.firstAnnotationOf(p)?.getField('defaultValue') !=
              null;
      final name = p.name;
      if (isNonNullable(p) || hasDefault) {
        return "'$key': $name,";
      } else {
        return "if ($name != null) '$key': $name,";
      }
    }).join('\n    ')}
    });
    final expr = predicate(Q$className());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
      .collection(_collection)
      .updateOne(selector.map, modifier);
    return result.isSuccess;
  }

  /// Type-safe updateMany
  static Future<bool> updateMany(
    Expression Function(Q$className q) predicate, {
${_buildUpdateParams(params)}
  }) async {
    final modifier = _buildModifier({
      ${params.map((p) {
      final key = getParameterKey(_jsonKeyChecker, p, fieldRename);
      final hasDefault =
          _jsonKeyChecker.firstAnnotationOf(p)?.getField('defaultValue') !=
              null;
      final name = p.name;
      if (isNonNullable(p) || hasDefault) {
        return "'$key': $name,";
      } else {
        return "if ($name != null) '$key': $name,";
      }
    }).join('\n    ')}
    });
    final expr = predicate(Q$className());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
      .collection(_collection)
      .updateMany(selector.map, modifier);
    return result.isSuccess;
  }

  static ModifierBuilder _buildModifier(Map<String, dynamic> updateMap) {
    final now = DateTime.now().toUtc();
    var modifier = modify.set('updated_at', now);
    updateMap.forEach((k, v) => modifier = modifier.set(k, v));
    return modifier;
  }
  
   /// Use `updateOne` directly whenever possible for better performance and clarity.
  /// This method is a fallback for cases requiring additional logic or dynamic update maps.
  static Future<$className?> updateOneFromMap(
    ObjectId id, 
    Map<String, dynamic> updateMap,
  ) async {
    final conn = await MongoConnection.getDb();
    final coll = conn.collection(_collection);
    final result = await coll.updateOne({'_id':id},{'\\\$set':updateMap});
    if(!result.isSuccess) return null;
    final updatedDoc = await coll.findOne({
      '_id': id
    });
    return updatedDoc == null?null:$className.fromJson(updatedDoc);
  }

  static Future<int> count(
    Expression Function(Q$className q) predicate
  ) async {
    final selectorMap = predicate(Q$className())
        .toSelectorBuilder()
        .map;
    return (await MongoConnection.getDb())
        .collection(_collection)
        .count(selectorMap);
  }

}
''';
    return _formatter.format(template);
  }
}

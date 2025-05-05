import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mongo_document/mongo_document_annotation.dart';
import 'package:mongo_document_generator/mongo_document_generator.dart';
import 'package:source_gen/source_gen.dart';

const _jsonKeyChecker = TypeChecker.fromRuntime(JsonKey);
const _jsonSerializableChecker = TypeChecker.fromRuntime(JsonSerializable);

class MongoDocumentGenerator extends GeneratorForAnnotation<MongoDocument> {
  final _formatter = DartFormatter();

  bool _isMapStringDynamic(ParameterElement p) {
    final t = p.type;
    if (t is InterfaceType && t.element.name == 'Map') {
      final args = t.typeArguments;
      return args.length == 2 &&
          args[0].getDisplayString(withNullability: false) == 'String' &&
          args[1].getDisplayString(withNullability: false) == 'dynamic';
    }
    return false;
  }

  bool _isListOrSet(ParameterElement p) {
    final t = p.type;
    if (t is InterfaceType) {
      final name = t.element.name;
      return (name == 'List' || name == 'Set') && t.typeArguments.length == 1;
    }
    return false;
  }

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) return '';

    var jsAnn = _jsonSerializableChecker.firstAnnotationOf(element);
    if (jsAnn == null && element.unnamedConstructor != null) {
      jsAnn = _jsonSerializableChecker.firstAnnotationOf(
        element.unnamedConstructor!,
      );
    }
    FieldRename? fieldRename;
    if (jsAnn != null) {
      final idx =
          jsAnn.getField('fieldRename')?.getField('index')?.toIntValue();
      if (idx != null) fieldRename = FieldRename.values[idx];
    }

    final className = element.name;
    final collection = annotation.peek('collection')!.stringValue;
    final params = element.unnamedConstructor?.parameters ?? [];

    final nestedCollectionMap = <String, String>{};

    for (final p in params) {
      final pType = p.type;
      if (pType is InterfaceType) {
        final nestedClassElem = pType.element;
        final mongoAnn = TypeChecker.fromRuntime(
          MongoDocument,
        ).firstAnnotationOf(nestedClassElem);
        if (mongoAnn != null) {
          final collName = mongoAnn.getField('collection')!.toStringValue()!;
          nestedCollectionMap[p.name] = collName;
        }
      }
    }

    final mapEntries = nestedCollectionMap.entries
        .map((e) => "'${e.key}': '${e.value}'")
        .join(', ');
    final nestedMapLiteral =
        'const _nestedCollections = <String,String>{ $mapEntries };';

    final qFields = params
        .map((p) {
          final dartType = p.type.getDisplayString(withNullability: true);
          final key = getFieldKey(_jsonKeyChecker, p, fieldRename);
          final name = p.name;
          // nested MongoDocument?
          if (p.type is InterfaceType &&
              (p.type as InterfaceType).element.metadata.any((md) {
                return md.computeConstantValue()?.type?.getDisplayString(
                      withNullability: false,
                    ) ==
                    'MongoDocument';
              })) {
            final nested = (p.type as InterfaceType).element.name;
            return '''
  Q$nested get $name => Q$nested(_key('$key'));
''';
          } else if (_isMapStringDynamic(p)) {
            return '''
  QMap<dynamic> get $name => QMap<dynamic>(_key('$key'));
''';
          } else if (_isListOrSet(p)) {
            final itemType = (p.type as InterfaceType).typeArguments.first
                .getDisplayString(withNullability: true);
            return """
  QList<$itemType> get $name => QList<$itemType>(_key('$key'));
""";
          } else {
            return '''
  QueryField<$dartType> get $name => QueryField<$dartType>(_key('$key'));
''';
          }
        })
        .join('\n');

    isNonNullable(param) =>
        !param.type.nullabilitySuffix.toString().contains('question');

    final qClass = '''
class Q$className {
final String _prefix;
  Q$className([this._prefix = '']);

  String _key(String field) =>
    _prefix.isEmpty ? field : '\$_prefix.\$field';

$qFields
}
''';

    // Generate extension + Query class
    final template = '''
$nestedMapLiteral

$qClass

extension \$${className}Extension on $className {
  static String get _collection => '$collection';

  Future<$className?> save() async {
    final coll = (await MongoConnection.getDb()).collection(_collection);
    final now = DateTime.now().toUtc();
    if (id == null) {
      final doc = toJson()..remove('_id');
      doc.update('created_at', (v) => v ?? now, ifAbsent: () => now);
      final result = await coll.insertOne(doc);
      if (result.isSuccess) return copyWith(id: result.id);
      return null;
    }
    final updateMap = toJson()..remove('_id');
    updateMap.update('created_at', (v) => v ?? now, ifAbsent: () => now);
    updateMap.update('updated_at', (v) => v ?? now, ifAbsent: () => now);
    var modifier = modify;
    updateMap.forEach((k, v) => modifier = modifier.set(k, v));
    final res = await coll.updateOne(where.eq(r'_id', id), modifier);
    return res.isSuccess ? this : null;
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
  
   /// Type‑safe DSL insertMany
  static Future<List<$className>> insertMany(
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
          return doc.copyWith(id: id as ObjectId?);
        })
        .toList();
  }

  /// Type-safe DSL findOne
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
        .findOne(selectorBuilder);
    return doc == null ? null : $className.fromJson(doc);

  }

  /// Type‑safe DSL findMany
  static Future<List<$className>> findMany(
    Expression Function(Q$className q) predicate, {
    int? skip, int? limit
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
      .find(selectorBuilder).toList();
    return docs.map((e) => $className.fromJson(e)).toList();
 }

  /// Type-safe DSL deleteOne
  static Future<bool> deleteOne(
    Expression Function(Q$className q) predicate
  ) async {
    final expr = predicate(Q$className());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
      .collection(_collection)
      .deleteOne(selector);
    return result.isSuccess;
  }
  
  /// Type-safe DSL deleteMany
  static Future<bool> deleteMany(
    Expression Function(Q$className q) predicate
  ) async {
    final expr = predicate(Q$className());
    final selector = expr.toSelectorBuilder();
    final result = await (await MongoConnection.getDb())
      .collection(_collection)
      .deleteMany(selector);
    return result.isSuccess;
  }
  
  static Future<bool> updateOne(
    Expression Function(Q$className q) predicate, {
${params.map((p) {
      final type = p.type.getDisplayString(withNullability: true);
      final name = p.name;
      var defaultVal = getDefaultValue(p);
      return defaultVal != null ? '$type $name = $defaultVal,' : '$type $name,';
    }).join('\n  ')}
  }) async {
    final modifier = _buildModifier({
      ${params.map((p) {
      final key = getFieldKey(_jsonKeyChecker, p, fieldRename);
      final hasDefault = _jsonKeyChecker.firstAnnotationOf(p)?.getField('defaultValue') != null;
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
      .updateOne(selector, modifier);
    return result.isSuccess;
  }

  /// Type-safe DSL updateMany
  static Future<bool> updateMany(
    Expression Function(Q$className q) predicate, {
${params.map((p) {
      final type = p.type.getDisplayString(withNullability: true);
      final name = p.name;
      final defaultVal = getDefaultValue(p);
      return defaultVal != null ? '$type $name = $defaultVal,' : '$type $name,';
    }).join('\n  ')}
  }) async {
    final modifier = _buildModifier({
      ${params.map((p) {
      final key = getFieldKey(_jsonKeyChecker, p, fieldRename);
      final hasDefault = _jsonKeyChecker.firstAnnotationOf(p)?.getField('defaultValue') != null;
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
      .updateMany(selector, modifier);
    return result.isSuccess;
  }

  static ModifierBuilder _buildModifier(Map<String, dynamic> updateMap) {
    final now = DateTime.now().toUtc();
    var modifier = modify.set('updated_at', now);
    updateMap.forEach((k, v) => modifier = modifier.set(k, v));
    return modifier;
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

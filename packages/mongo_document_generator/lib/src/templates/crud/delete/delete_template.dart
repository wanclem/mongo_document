import 'package:analyzer/dart/element/element.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mongo_document/src/templates/parameter_template.dart';
import 'package:source_gen/source_gen.dart';

class DeleteTemplates {
  static delete(String className) {
    return '''
  Future<bool> delete({Db? db}) async {
    if (id == null) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final res = await coll.deleteOne(where.eq(r'_id', id));
    return res.isSuccess;
  }
''';
  }

  static deleteOne(String className) {
    return '''
  static Future<bool> deleteOne(
    Expression Function(Q$className ${className[0].toLowerCase()}) predicate,
    {Db? db}
  ) async {
    final database = db ?? await MongoDbConnection.instance;
    final expr = predicate(Q$className());
    final selector = expr.toSelectorBuilder();
    final coll = await database.collection(_collection);
    final result = await coll.deleteOne(selector.map.cleaned());
    return result.isSuccess;
  }''';
  }

  static String deleteMany(String className) {
    return '''
  /// Type-safe deleteMany
  static Future<bool> deleteMany(
    Expression Function(Q$className ${className[0].toLowerCase()}) predicate,
    {Db? db}
  ) async {
    final database = db ?? await MongoDbConnection.instance;
    final expr = predicate(Q$className());
    final selector = expr.toSelectorBuilder();
    final coll = await database.collection(_collection);
    final result = await coll.deleteMany(selector.map.cleaned());
    return result.isSuccess;
  }
''';
  }

  static deleteOneByNamed(
    String className,
    TypeChecker typeChecker,
    List<ParameterElement> params,
    FieldRename? fieldRename,
    Map<String, dynamic> nestedCollectionMap,
  ) {
    return '''
  /// Type-safe deleteOne by named arguments
  static Future<bool> deleteOneByNamed(
  {${ParameterTemplates.buildNullableParams(params, fieldRename)}Db?db}
  ) async {
  final selector = <String, dynamic>{};
  ${params.map((p) {
      final paramName = p.name;
      final key =
          ParameterTemplates.getParameterKey(typeChecker, p, fieldRename);
      return '''if ($paramName != null) selector['$key'] = ${nestedCollectionMap.containsKey(key) ? "$paramName.id" : paramName};''';
    }).join('\n')}
    if (selector.isEmpty) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final result = await coll.deleteOne(selector);
    return result.isSuccess;
  }
''';
  }

  static deleteManyByNamed(
    String className,
    TypeChecker typeChecker,
    List<ParameterElement> params,
    FieldRename? fieldRename,
    Map<String, dynamic> nestedCollectionMap,
  ) {
    return '''
  /// Type-safe deleteMany by named arguments
  static Future<bool> deleteManyByNamed(
  {${ParameterTemplates.buildNullableParams(params, fieldRename)}Db?db}
  ) async {
  final selector = <String, dynamic>{};
  ${params.map((p) {
      final paramName = p.name;
      final key =
          ParameterTemplates.getParameterKey(typeChecker, p, fieldRename);
      return '''if ($paramName != null) selector['$key'] = ${nestedCollectionMap.containsKey(key) ? "$paramName.id" : paramName};''';
    }).join('\n')}
    if (selector.isEmpty) return false;
    final database = db ?? await MongoDbConnection.instance;
    final coll = await database.collection(_collection);
    final result = await coll.deleteMany(selector);
    return result.isSuccess;
  }
''';
  }
}

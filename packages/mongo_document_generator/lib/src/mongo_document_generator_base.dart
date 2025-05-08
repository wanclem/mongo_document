import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mongo_document/mongo_document_generator.dart';
import 'package:mongo_document/src/templates/crud/create/create_template.dart';
import 'package:mongo_document/src/templates/crud/delete/delete_template.dart';
import 'package:mongo_document/src/templates/crud/read/query_templates.dart';
import 'package:mongo_document/src/templates/crud/read/read_templates.dart';
import 'package:mongo_document/src/templates/crud/update/update_templates.dart';
import 'package:mongo_document/src/templates/object_references/object_references.dart';
import 'package:mongo_document/src/templates/parameter_template.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';
import 'package:source_gen/source_gen.dart';

const _jsonKeyChecker = TypeChecker.fromRuntime(JsonKey);
const _jsonSerializableChecker = TypeChecker.fromRuntime(JsonSerializable);

class MongoDocumentGenerator extends GeneratorForAnnotation<MongoDocument> {
  final _formatter = DartFormatter();

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
    final nestedCollectionMap =
        ParameterTemplates.getNestedCollectionMap(params);

    final template = '''
${ObjectReferences.buildNestedCollectiontionsMapLiteral(
      nestedCollectionMap,
    )}
${ObjectReferences.buildNestedCollectionProjectionClasses(
      _jsonSerializableChecker,
      _jsonKeyChecker,
      nestedCollectionMap,
      params,
    )}
${QueryTemplates.buildQueryClass(
      _jsonKeyChecker,
      className,
      fieldRename,
      params,
    )}

extension \$${className}Extension on $className {
  static String get _collection => '$collection';

  ${CreateTemplates.save(className)}
  ${DeleteTemplates.delete(className)}
  
}

class ${className}s {
  
  static String get _collection => '$collection';
  ${CreateTemplates.saveMany(className)}
  ${ReadTemplates.findById(className)}
  ${ReadTemplates.findOne(className)}
  ${ReadTemplates.findOneByNamed(_jsonKeyChecker, fieldRename, params, className)}
  ${ReadTemplates.findMany(className)}
  ${ReadTemplates.findManyByNamed(_jsonKeyChecker, fieldRename, params, className)}
  ${DeleteTemplates.deleteOne(className)}
  ${DeleteTemplates.deleteOneByNamed(className, _jsonKeyChecker, params, fieldRename)}
  ${DeleteTemplates.deleteMany(className)}
  ${UpdateTemplates.updateOne(className, _jsonKeyChecker, params, fieldRename)}
  ${UpdateTemplates.buildModifier()}
  ${UpdateTemplates.updateOneFromMap(className)}
  ${ReadTemplates.count(className)}
}
''';
    return _formatter.format(template);
  }
}

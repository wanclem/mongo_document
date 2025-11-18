import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mongo_document/mongo_document_generator.dart';
import 'package:mongo_document/src/checkers/annotation_checker.dart';
import 'package:mongo_document/src/checkers/default_annotation_checker.dart';
import 'package:mongo_document/src/templates/class_projection/class_projection.dart';
import 'package:mongo_document/src/templates/crud/create/create_template.dart';
import 'package:mongo_document/src/templates/crud/delete/delete_template.dart';
import 'package:mongo_document/src/templates/crud/read/query_templates.dart';
import 'package:mongo_document/src/templates/crud/read/read_templates.dart';
import 'package:mongo_document/src/templates/crud/update/update_templates.dart';
import 'package:mongo_document/src/templates/object_references/object_references.dart';
import 'package:mongo_document/src/templates/parameter_template.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';
import 'package:source_gen/source_gen.dart';
import 'package:pub_semver/pub_semver.dart';

const _jsonKeyChecker = TypeChecker.typeNamed(JsonKey);
const _jsonSerializableChecker = TypeChecker.typeNamed(JsonSerializable);

class MongoDocumentGenerator extends GeneratorForAnnotation<MongoDocument> {
  final _formatter = DartFormatter(languageVersion: Version.parse('3.0.0'));
  final AnnotationChecker checker;

  MongoDocumentGenerator({AnnotationChecker? checker})
    : checker = checker ?? DefaultAnnotationChecker();

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) return '';
    final ctor = element.unnamedConstructor!;
    final idParam = ctor.formalParameters.firstWhere(
      (p) => p.name == 'id',
      orElse:
          () =>
              throw InvalidGenerationSourceError(
                'Missing required `id` parameter…',
                element: element,
              ),
    );

    if (!checker.hasObjectIdConverter(idParam) ||
        !checker.hasJsonKeyWithId(idParam)) {
      throw InvalidGenerationSourceError(
        'The `id` parameter must be annotated with '
        '`@ObjectIdConverter()` and `@JsonKey(name: \'_id\')`.',
        element: element,
      );
    }

    FieldRename? fieldRename = getFieldRenamePolicy(
      _jsonSerializableChecker,
      element,
    );
    final className = element.name ?? '';
    final collection = annotation.peek('collection')!.stringValue;
    final params = element.unnamedConstructor?.formalParameters ?? [];
    final nestedCollectionMap = ParameterTemplates.getNestedCollectionMap(
      params,
      _jsonKeyChecker,
      fieldRename,
    );
    final template = '''
${ClassProjection.buildClassProjection(className, _jsonSerializableChecker, _jsonKeyChecker, params, fieldRename, nestedCollectionMap)}
${ObjectReferences.buildNestedCollectiontionsMapLiteral(nestedCollectionMap)}
${ObjectReferences.buildNestedCollectionProjectionClasses(className, _jsonSerializableChecker, _jsonKeyChecker, nestedCollectionMap, params, fieldRename)}
${QueryTemplates.buildQueryClass(_jsonKeyChecker, className, fieldRename, params)}

extension \$${className}Extension on $className {
  static String get _collection => '$collection';

  ${CreateTemplates.save(className)}
  ${DeleteTemplates.delete(className)}
  
}

class ${className}s {
  
  static String get _collection => '$collection';
  static String get collection => _collection;

  ${CreateTemplates.saveMany(className)}
  ${ReadTemplates.findById(className)}
  ${ReadTemplates.findOne(className)}
  ${ReadTemplates.findOneByNamed(_jsonKeyChecker, fieldRename, params, className, nestedCollectionMap)}
  ${ReadTemplates.findMany(className)}
  ${ReadTemplates.findManyByNamed(_jsonKeyChecker, fieldRename, params, className, nestedCollectionMap)}
  ${DeleteTemplates.deleteOne(className)}
  ${DeleteTemplates.deleteOneByNamed(className, _jsonKeyChecker, params, fieldRename, nestedCollectionMap)}
  ${DeleteTemplates.deleteMany(className)}
  ${DeleteTemplates.deleteManyByNamed(className, _jsonKeyChecker, params, fieldRename, nestedCollectionMap)}
  ${UpdateTemplates.updateOne(className, nestedCollectionMap, _jsonKeyChecker, params, fieldRename)}
  ${UpdateTemplates.updateMany(className, nestedCollectionMap, _jsonKeyChecker, params, fieldRename)}
  ${UpdateTemplates.buildModifier()}
  ${UpdateTemplates.updateOneFromMap(className)}
  ${ReadTemplates.count(className)}
}
''';
    return _formatter.format(template);
  }
}

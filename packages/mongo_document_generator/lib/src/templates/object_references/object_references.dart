import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:mongo_document/src/templates/parameter_template.dart';
import 'package:mongo_document/src/utils/field_manipulators.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

class ObjectReferences {
  static String buildNestedCollectionProjectionClasses(
    TypeChecker jsonSerializableChecker,
    TypeChecker jsonKeyChecker,
    Map<String, String> nestedCollectionMap,
    List<ParameterElement> params,
  ) {
    final projectionTemplate = '''
${nestedCollectionMap.keys.map((root) {
      final param = params.firstWhere((p) => p.name == root);
      final rc = ReCase(param.name);
      final typeName = rc.pascalCase;
      final enumName = '${typeName}Fields';
      final projName = '${typeName}Projections';
      final nestedClass = (param.type as InterfaceType).element as ClassElement;
      FieldRename? nestedRename =
          getFieldRenamePolicy(jsonSerializableChecker, nestedClass);
      var nestedClassParams = nestedClass.unnamedConstructor?.parameters ?? [];
      final entries = nestedClassParams.map((p) {
        final jsonKey =
            ParameterTemplates.getParameterKey(jsonKeyChecker, p, nestedRename);
        return "'$root.$jsonKey': 1";
      }).join(', ');
      final enumValues = nestedClassParams.map((f) => f.name).join(', ');
      final mappingEntries = nestedClassParams.map((p) {
        final jsonKey =
            ParameterTemplates.getParameterKey(jsonKeyChecker, p, nestedRename);
        return '    "${p.name}": "$root.$jsonKey"';
      }).join(',\n');

      return '''
enum $enumName { $enumValues }

class $projName implements BaseProjections {
  @override
  final List<$enumName>? fields;
  @override
  final Map<String, dynamic> fieldMappings = const {$mappingEntries};
  const $projName([this.fields]);

  @override
  Map<String,int> toProjection() {
    return {
      $entries
    };
  }
}
''';
    }).join()}
''';
    return projectionTemplate;
  }

  static String buildNestedCollectiontionsMapLiteral(
      Map<String, dynamic> nestedCollectionMap) {
    final nestedCollectionMapEntries = nestedCollectionMap.entries
        .map((e) => "'${e.key}': '${e.value}'")
        .join(', ');
    return 'const _nestedCollections = <String,String>{ $nestedCollectionMapEntries };';
  }

}

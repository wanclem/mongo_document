import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mongo_document/src/templates/parameter_template.dart';
import 'package:mongo_document/src/utils/field_manipulators.dart';
import 'package:recase/recase.dart';
import 'package:source_gen/source_gen.dart';

class ObjectReferences {
  static String buildNestedCollectionProjectionClasses(
    String className,
    TypeChecker jsonSerializableChecker,
    TypeChecker jsonKeyChecker,
    Map<String, String> nestedCollectionMap,
    List<ParameterElement> params,
    FieldRename? fieldRename,
  ) {
    final projectionTemplate = '''
${nestedCollectionMap.keys.map((root) {
      final param = params.firstWhere((p) =>
          ParameterTemplates.getParameterKey(
            jsonKeyChecker,
            p,
            fieldRename,
          ) ==
          root);
      final paramRC = ReCase(param.name).pascalCase;
      final classRC = ReCase(className).pascalCase;
      final typeName = "$classRC$paramRC";
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
  final List<$enumName>? inclusions;
  final List<$enumName>? exclusions;
  @override
  final Map<String, dynamic> fieldMappings = const {$mappingEntries};
  const $projName({this.inclusions,this.exclusions});

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
    Map<String, dynamic> nestedCollectionMap,
  ) {
    if (nestedCollectionMap.isEmpty) {
      return r"""const _nestedCollections = <String, String>{};""";
    }
    final nestedCollectionMapEntries = nestedCollectionMap.entries
        .map((e) => "'${e.key}': '${e.value}'")
        .join(', ');
    return 'const _nestedCollections = <String,String>{ $nestedCollectionMapEntries };';
  }
}

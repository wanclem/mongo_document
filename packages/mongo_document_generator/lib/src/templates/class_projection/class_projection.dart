import 'package:analyzer/dart/element/element.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mongo_document/src/templates/parameter_template.dart';
import 'package:source_gen/source_gen.dart';

class ClassProjection {
  static String buildClassProjection(
    String className,
    TypeChecker jsonSerializableChecker,
    TypeChecker jsonKeyChecker,
    List<FormalParameterElement> params,
    FieldRename? fieldRename,
    Map<String, String> nestedCollectionMap,
  ) {
    final enumName = '${className}Fields';
    final projectName = '${className}Projections';
    final validParams = params.where((p) {
      final key =
          ParameterTemplates.getParameterKey(jsonKeyChecker, p, fieldRename);
      return !nestedCollectionMap.containsKey(key);
    }).toList();
    final enumValues = validParams.map((f) => f.name).join(', ');
    final entries = validParams.map((p) {
      final jsonKey =
          ParameterTemplates.getParameterKey(jsonKeyChecker, p, fieldRename);
      return "'$jsonKey': 1";
    }).join(', ');
    final fieldMappings = validParams.map((p) {
      final jsonKey =
          ParameterTemplates.getParameterKey(jsonKeyChecker, p, fieldRename);
      return '    "${p.name}": "$jsonKey"';
    }).join(',\n');
    return '''
enum $enumName { $enumValues }

class $projectName implements BaseProjections {
  @override
  final List<$enumName>? inclusions;
  final List<$enumName>? exclusions;
  @override
  final Map<String, dynamic> fieldMappings = const {$fieldMappings};
  const $projectName({this.inclusions,this.exclusions});

  @override
  Map<String,int> toProjection() {
    return {
      $entries
    };
  }
}
''';
  }
}

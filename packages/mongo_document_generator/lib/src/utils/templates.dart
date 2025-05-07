import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mongo_document_generator/mongo_document_generator.dart';
import 'package:source_gen/source_gen.dart';

String buildNestedCollectionProjectionClasses(
  TypeChecker jsonSerializableChecker,
  TypeChecker jsonKeyChecker,
  Map<String, String> nestedCollectionMap,
  List<ParameterElement> params,
) {
  final projectionTemplate = '''
${nestedCollectionMap.keys.map((root) {
    final param = params.firstWhere((p) => p.name == root);
    final typeName = (param.type as InterfaceType).element.name;
    final enumName = '${typeName}Fields';
    final projName = '${typeName}Projections';
    final nestedClass = (param.type as InterfaceType).element as ClassElement;
    FieldRename? nestedRename =
        getFieldRenamePolicy(jsonSerializableChecker, nestedClass);
    var nestedClassParams = nestedClass.unnamedConstructor?.parameters ?? [];
    final entries = nestedClassParams.map((p) {
      final jsonKey = getParameterKey(jsonKeyChecker, p, nestedRename);
      return "'$root.$jsonKey': 1";
    }).join(', ');
    final enumValues = nestedClassParams.map((f) => f.name).join(', ');
    return '''
enum $enumName { $enumValues }

class $projName implements BaseProjections {
  final List<$enumName>? fields;
  const $projName([this.fields]);

  @override
  Map<String,int>? toProjection() {
    if (fields == null || fields!.isEmpty) return null;
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

String buildNestedCollectiontionsMapLiteral(Map<String, dynamic> nestedCollectionMap) {
  final nestedCollectionMapEntries = nestedCollectionMap.entries
      .map((e) => "'${e.key}': '${e.value}'")
      .join(', ');
  return 'const _nestedCollections = <String,String>{ $nestedCollectionMapEntries };';
}

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

bool isNonNullable(ParameterElement param) =>
    !param.type.nullabilitySuffix.toString().contains('question');

String buildQueryClasses(
  TypeChecker jsonKeyChecker,
  String className,
  FieldRename? fieldRename,
  List<ParameterElement> params,
) {
  final qFields = params.map((p) {
    // ignore: deprecated_member_use
    final dartType = p.type.getDisplayString(withNullability: true);
    final key = getParameterKey(jsonKeyChecker, p, fieldRename);
    final name = p.name;
    if (p.type is InterfaceType &&
        (p.type as InterfaceType).element.metadata.any((md) {
          return md.computeConstantValue()?.type?.getDisplayString(
                    // ignore: deprecated_member_use
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
      final itemType = (p.type as InterfaceType)
          .typeArguments
          .first
          // ignore: deprecated_member_use
          .getDisplayString(withNullability: true);
      return """
  QList<$itemType> get $name => QList<$itemType>(_key('$key'));
""";
    } else {
      return '''
  QueryField<$dartType> get $name => QueryField<$dartType>(_key('$key'));
''';
    }
  }).join('\n');

  final qClass = '''
class Q$className {
final String _prefix;
  Q$className([this._prefix = '']);

  String _key(String field) =>
    _prefix.isEmpty ? field : '\$_prefix.\$field';

$qFields
}
''';
  return qClass;
}

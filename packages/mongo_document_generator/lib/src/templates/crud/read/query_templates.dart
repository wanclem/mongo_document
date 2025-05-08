import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:mongo_document/src/templates/parameter_template.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';
import 'package:source_gen/source_gen.dart';

class QueryTemplates {
  static String buildQueryClasses(
    TypeChecker jsonKeyChecker,
    String className,
    FieldRename? fieldRename,
    List<ParameterElement> params,
  ) {
    final qFields = params.map((p) {
      // ignore: deprecated_member_use
      final dartType = p.type.getDisplayString(withNullability: true);
      final key =
          ParameterTemplates.getParameterKey(jsonKeyChecker, p, fieldRename);
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

  static bool _isMapStringDynamic(ParameterElement p) {
    final t = p.type;
    if (t is InterfaceType && t.element.name == 'Map') {
      final args = t.typeArguments;
      return args.length == 2 &&
          // ignore: deprecated_member_use
          args[0].getDisplayString(withNullability: false) == 'String' &&
          // ignore: deprecated_member_use
          args[1].getDisplayString(withNullability: false) == 'dynamic';
    }
    return false;
  }

  static bool _isListOrSet(ParameterElement p) {
    final t = p.type;
    if (t is InterfaceType) {
      final name = t.element.name;
      return (name == 'List' || name == 'Set') && t.typeArguments.length == 1;
    }
    return false;
  }
}

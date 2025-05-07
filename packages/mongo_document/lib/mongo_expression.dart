import 'package:mongo_dart/mongo_dart.dart';

abstract class Expression {
  SelectorBuilder toSelectorBuilder();

  Expression operator |(Expression other);

  Expression operator &(Expression other);
}

class Comparison implements Expression {
  final String field;
  final String op;
  final dynamic value;

  Comparison(this.field, this.op, this.value);

  @override
  SelectorBuilder toSelectorBuilder() {
    if (field.contains('.')) {
      final parts = field.split('.');
      final nestedField = parts.last;
      final embeddedPath = parts.sublist(0, parts.length - 1).join('.');
      switch (op) {
        case r'$eq':
          return where.eq('$embeddedPath.$nestedField', value);
        case r'$ne':
          return where.ne('$embeddedPath.$nestedField', value);
        case r'$lt':
          return where.lt('$embeddedPath.$nestedField', value);
        case r'$lte':
          return where.lte('$embeddedPath.$nestedField', value);
        case r'$gt':
          return where.gt('$embeddedPath.$nestedField', value);
        case r'$gte':
          return where.gte('$embeddedPath.$nestedField', value);
        default:
          throw ArgumentError('Unsupported comparison operator: $op');
      }
    } else {
      switch (op) {
        case r'$eq':
          return where.eq(field, value);
        case r'$ne':
          return where.ne(field, value);
        case r'$lt':
          return where.lt(field, value);
        case r'$lte':
          return where.lte(field, value);
        case r'$gt':
          return where.gt(field, value);
        case r'$gte':
          return where.gte(field, value);
        default:
          throw ArgumentError('Unsupported comparison operator: $op');
      }
    }
  }

  @override
  Expression operator &(Expression other) {
    return Logical(this, '&', other);
  }

  @override
  Expression operator |(Expression other) {
    return Logical(this, '|', other);
  }
}

class MethodCall implements Expression {
  final String field;
  final String method;
  final String value;

  MethodCall(this.field, this.method, this.value);

  @override
  SelectorBuilder toSelectorBuilder() {
    final pattern = method == 'startsWith'
        ? '^\${RegExp.escape(value)}'
        : method == 'endsWith'
            ? '\${RegExp.escape(value)}\$'
            : method == 'contains'
                ? RegExp.escape(value)
                : RegExp.escape(value);
    if (field.contains('.')) {
      final parts = field.split('.');
      final nestedField = parts.last;
      final embeddedPath = parts.sublist(0, parts.length - 1).join('.');
      return where.match(
        '$embeddedPath.$nestedField',
        pattern,
        caseInsensitive: true,
      );
    } else {
      return where.match(field, pattern, caseInsensitive: true);
    }
  }

  @override
  Expression operator &(Expression other) {
    return Logical(this, '&', other);
  }

  @override
  Expression operator |(Expression other) {
    return Logical(this, '|', other);
  }
}

class Logical implements Expression {
  final Expression left;
  final String op;
  final Expression right;

  Logical(this.left, this.op, this.right);

  @override
  SelectorBuilder toSelectorBuilder() {
    final leftMap = left.toSelectorBuilder().map;
    final rightMap = right.toSelectorBuilder().map;
    if (op == '&') {
      return SelectorBuilder()
        ..raw({
          r'$and': [leftMap, rightMap],
        });
    } else {
      return SelectorBuilder()
        ..raw({
          r'$or': [leftMap, rightMap],
        });
    }
  }

  @override
  Expression operator &(Expression other) {
    return Logical(this, '&', other);
  }

  @override
  Expression operator |(Expression other) {
    return Logical(this, '|', other);
  }
}

class QueryField<T> {
  final String name;

  QueryField(this.name);

  Expression eq(T v) => Comparison(name, r'$eq', v);

  Expression ne(T v) => Comparison(name, r'$ne', v);

  Expression lt(num v) => Comparison(name, r'$lt', v);

  Expression lte(num v) => Comparison(name, r'$lte', v);

  Expression gt(num v) => Comparison(name, r'$gt', v);

  Expression gte(num v) => Comparison(name, r'$gte', v);

  Expression startsWith(String v) => MethodCall(name, 'startsWith', v);

  Expression endsWith(String v) => MethodCall(name, 'endsWith', v);

  Expression contains(String v) => MethodCall(name, 'contains', v);
}

void collectKeys(dynamic node, Set<String> out) {
  if (node is Map<String, dynamic>) {
    node.forEach((k, v) {
      if (!k.startsWith(r'$')) out.add(k);
      collectKeys(v, out);
    });
  } else if (node is Iterable) {
    for (final item in node) {
      collectKeys(item, out);
    }
  }
}

class QMap<T> {
  final String _prefix;

  QMap(this._prefix);

  QueryField<T> key<V>(String k) => QueryField<T>('$_prefix.$k');

  QueryField<T> operator [](String k) => key<T>(k);
}

class QList<T> {
  final String _prefix;

  QList(this._prefix);

  Expression contains(T value) => _RawExpression({
        _prefix: {
          r'$in': [value],
        },
      });

  Expression elemMatch(Expression Function(QueryField<T> f) exprBuilder) {
    final expr = exprBuilder(QueryField<T>(_prefix));
    return _RawExpression({
      _prefix: {r'$elemMatch': expr.toSelectorBuilder().map},
    });
  }
}

class _RawExpression implements Expression {
  final Map<String, dynamic> _map;

  _RawExpression(this._map);

  @override
  SelectorBuilder toSelectorBuilder() => SelectorBuilder()..raw(_map);

  @override
  Expression operator |(Expression other) => Logical(this, '|', other);

  @override
  Expression operator &(Expression other) => Logical(this, '&', other);
}

/// Marker interface for all projections
abstract class BaseProjections {
  /// Return a map of "path":1 entries (or empty to include all)
  Map<String, int>? toProjection();
}

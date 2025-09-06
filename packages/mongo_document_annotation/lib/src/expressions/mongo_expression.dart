import 'package:mongo_dart/mongo_dart.dart';

dynamic processedValue(dynamic v) {
  if (v is Enum) {
    return v.name;
  }
  return v;
}

mixin MoreExMixin {
  String get _key;

  Expression exists([bool doesExist = true]) => RawExpression({
    _key: {r'$exists': doesExist},
  });

  Expression isIn(dynamic value) => RawExpression({
    _key: {r'$in': processedValue(value)},
  });

  Expression notIn(dynamic value) => RawExpression({
    _key: {r'$nin': processedValue(value)},
  });

  Expression containsAllOf(dynamic value) => RawExpression({
    _key: {r'$all': processedValue(value)},
  });

  Expression mod(dynamic value) => RawExpression({
    _key: {r'$mod': processedValue(value)},
  });

  Expression isBetween(dynamic min, dynamic max) => RawExpression({
    _key: {r'$gte': processedValue(min), r'$lte': processedValue(max)},
  });

  Expression near(var value, [double? maxDistance]) => RawExpression({
    _key: {
      r'$near': processedValue(value),
      if (maxDistance != null) r'$maxDistance': maxDistance,
    },
  });

  /// Only support $geometry shape operator
  /// Available ShapeOperator instances: Box , Center, CenterSphere, Geometry
  Expression geoWithin(ShapeOperator shape) => RawExpression({
    _key: {r'$geoWithin': shape.build()},
  });

  /// Only supports geometry points
  Expression nearSphere(
    String fieldName,
    Geometry point, {
    double? maxDistance,
    double? minDistance,
  }) => RawExpression({
    _key: {
      r'$nearSphere': <String, dynamic>{
        if (minDistance != null) '\$minDistance': minDistance,
        if (maxDistance != null) '\$maxDistance': maxDistance,
      }..addAll(point.build()),
    },
  });
}

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
    final safeValue = processedValue(value);
    if (field.contains('.')) {
      final parts = field.split('.');
      final nestedField = parts.last;
      final embeddedPath = parts.sublist(0, parts.length - 1).join('.');
      switch (op) {
        case r'$eq':
          return where.eq('$embeddedPath.$nestedField', safeValue);
        case r'$ne':
          return where.ne('$embeddedPath.$nestedField', safeValue);
        case r'$lt':
          return where.lt('$embeddedPath.$nestedField', safeValue);
        case r'$lte':
          return where.lte('$embeddedPath.$nestedField', safeValue);
        case r'$gt':
          return where.gt('$embeddedPath.$nestedField', safeValue);
        case r'$gte':
          return where.gte('$embeddedPath.$nestedField', safeValue);
        default:
          throw ArgumentError('Unsupported comparison operator: $op');
      }
    } else {
      switch (op) {
        case r'$eq':
          return where.eq(field, safeValue);
        case r'$ne':
          return where.ne(field, safeValue);
        case r'$lt':
          return where.lt(field, safeValue);
        case r'$lte':
          return where.lte(field, safeValue);
        case r'$gt':
          return where.gt(field, safeValue);
        case r'$gte':
          return where.gte(field, safeValue);
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
    final safeValue = processedValue(value);
    final pattern =
        method == 'startsWith'
            ? RegExp.escape(safeValue)
            : method == 'endsWith'
            ? '${RegExp.escape(safeValue)}\$'
            : method == 'contains'
            ? RegExp.escape(safeValue)
            : RegExp.escape(safeValue);
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

  List<Map<String, dynamic>> _unwrap(String key, Map<String, dynamic> m) {
    if (m.length == 1 && m.containsKey(key) && m[key] is List) {
      final rawList = m[key] as List;
      return rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [m];
  }

  @override
  SelectorBuilder toSelectorBuilder() {
    final leftBuilder = left.toSelectorBuilder();
    final rightBuilder = right.toSelectorBuilder();
    final leftMap = leftBuilder.map;
    final rightMap = rightBuilder.map;
    if (op == '&') {
      final clauses = [
        ..._unwrap(r'$and', leftMap),
        ..._unwrap(r'$and', rightMap),
      ];
      return SelectorBuilder()..raw({r'$and': clauses});
    } else {
      final clauses = [
        ..._unwrap(r'$or', leftMap),
        ..._unwrap(r'$or', rightMap),
      ];
      return SelectorBuilder()..raw({r'$or': clauses});
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

class QueryField<T> with MoreExMixin {
  final String name;

  QueryField(this.name);

  @override
  String get _key => name;

  Expression eq(T v) => Comparison(name, r'$eq', v);

  Expression ne(T v) => Comparison(name, r'$ne', v);

  Expression lt(T v) => Comparison(name, r'$lt', v);

  Expression lte(T v) => Comparison(name, r'$lte', v);

  Expression gt(T v) => Comparison(name, r'$gt', v);

  Expression gte(T v) => Comparison(name, r'$gte', v);

  Expression startsWith(String v) => MethodCall(name, 'startsWith', v);

  Expression endsWith(String v) => MethodCall(name, 'endsWith', v);

  Expression contains(String v) => MethodCall(name, 'contains', v);

  QueryField<V> field<V>(String fieldName) => QueryField<V>('$name.$fieldName');

  QueryField operator [](String fieldName) => QueryField('$name.$fieldName');
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

class QMap<T> with MoreExMixin {
  final String _prefix;

  QMap(this._prefix);

  @override
  String get _key => _prefix;

  QueryField<T> key<V>(String k) => QueryField<T>('$_prefix.$k');

  QueryField<T> operator [](String k) => key<T>(k);
}

class QList<T> with MoreExMixin {
  final String _prefix;

  QList(this._prefix);

  @override
  String get _key => _prefix;

  ///Check if the list contains a value
  Expression contains(T value) => RawExpression({
    _prefix: {
      r'$in': [value],
    },
  });

  ///Check if the list contains a value that matches the given expression
  Expression elemMatch(T value) => RawExpression({
    _prefix: {r'$elemMatch': value},
  });
}

class QueryLink<T> {
  final Expression _previous;
  final String _fieldName;

  QueryLink(this._previous, this._fieldName);

  QueryField<T> get _current => QueryField<T>(_fieldName);

  QueryField<String> get _currentString => QueryField<String>(_fieldName);

  Expression eq(T v) => _previous & _current.eq(v);

  Expression ne(T v) => _previous & _current.ne(v);

  Expression lt(T v) => _previous & _current.lt(v);

  Expression lte(T v) => _previous & _current.lte(v);

  Expression gt(T v) => _previous & _current.gt(v);

  Expression gte(T v) => _previous & _current.gte(v);

  Expression startsWith(String v) => _previous & _currentString.startsWith(v);

  Expression endsWith(String v) => _previous & _currentString.endsWith(v);

  Expression contains(String v) => _previous & _currentString.contains(v);
}

extension ChainedQuery on Expression {
  /// Chains an AND condition for the given [fieldName].
  ///
  /// **Warning:** This method forces the user to provide the database field name
  /// as a raw string. This can be error-prone, as the provided `fieldName` is
  /// not checked at compile-time and may become inconsistent with the structure
  /// of your data model if field names are refactored. ⚠️
  ///
  /// Where possible, you should refrain from using this method. For better type
  /// safety and maintainability, it is strongly recommended to use the `&`
  /// operator with predefined `QueryField` instances instead.
  ///
  /// ```dart
  /// // Safer: Uses predefined, strongly-typed QueryField instances.
  /// // A change in the 'age' field name only needs to be updated in one place.
  /// final saferQuery = Posts.findMany((p)=>p.author.id(id) & p.createdAt.eq(DateTime.now()));
  /// ```
  ///
  /// ```dart
  /// // Risky: The string 'created_at' is not checked. A typo or a
  /// // database schema change would lead to a runtime error.
  /// final riskyQuery = Posts.findMany((p)=>p.author.id(id).and('created_at').eq(DateTime.now()));
  /// ```
  ///
  QueryLink<T> and<T>(String fieldName) {
    return QueryLink<T>(this, fieldName);
  }
}

class RawExpression implements Expression {
  final Map<String, dynamic> _map;

  RawExpression(this._map);

  @override
  SelectorBuilder toSelectorBuilder() => SelectorBuilder()..raw(_map);

  @override
  Expression operator |(Expression other) => Logical(this, '|', other);

  @override
  Expression operator &(Expression other) => Logical(this, '&', other);
}

/// Marker interface for all projections
abstract class BaseProjections<E> {
  List<E>? get inclusions;

  List<E>? get exclusions;

  Map<String, dynamic> get fieldMappings;

  Map<String, int> toProjection();
}

import 'package:mongo_document_annotation/mongo_document_annotation.dart';
import 'package:test/test.dart';

void main() {
  group('text query expressions', () {
    test('startsWith anchors the escaped pattern at the beginning', () {
      final regex = _regexFor(
        QueryField<String>('name').startsWith('a.b'),
        'name',
      );

      expect(regex.pattern, r'^a\.b');
    });

    test('endsWith anchors the escaped pattern at the end', () {
      final regex = _regexFor(
        QueryField<String>('name').endsWith('a.b'),
        'name',
      );

      expect(regex.pattern, r'a\.b$');
    });

    test('contains leaves the escaped pattern unanchored', () {
      final regex = _regexFor(
        QueryField<String>('name').contains('a.b'),
        'name',
      );

      expect(regex.pattern, r'a\.b');
    });
  });
}

RegExp _regexFor(Expression expression, String field) {
  final query = expression.toSelectorBuilder().map[r'$query'] as Map;
  final fieldQuery = query[field] as Map;
  return fieldQuery[r'$regex'] as RegExp;
}

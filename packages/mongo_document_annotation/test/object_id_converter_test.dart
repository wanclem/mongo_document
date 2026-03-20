import 'package:mongo_document_annotation/mongo_document_annotation.dart';
import 'package:test/test.dart';

void main() {
  const converter = ObjectIdConverter();

  group('ObjectIdConverter.fromJson', () {
    test('returns null for null input', () {
      expect(converter.fromJson(null), isNull);
    });

    test('parses raw ObjectId values', () {
      final id = ObjectId.fromHexString('507f1f77bcf86cd799439011');
      expect(converter.fromJson(id), id);
    });

    test('parses raw hex strings', () {
      expect(
        converter.fromJson('507f1f77bcf86cd799439011'),
        ObjectId.fromHexString('507f1f77bcf86cd799439011'),
      );
    });

    test('parses map refs with _id values', () {
      expect(
        converter.fromJson({'_id': '507f1f77bcf86cd799439011'}),
        ObjectId.fromHexString('507f1f77bcf86cd799439011'),
      );
    });

    test('parses Mongo extended json maps', () {
      expect(
        converter.fromJson({r'$oid': '507f1f77bcf86cd799439011'}),
        ObjectId.fromHexString('507f1f77bcf86cd799439011'),
      );
    });

    test(r'parses nested _id -> $oid shapes', () {
      expect(
        converter.fromJson({
          '_id': {r'$oid': '507f1f77bcf86cd799439011'},
        }),
        ObjectId.fromHexString('507f1f77bcf86cd799439011'),
      );
    });

    test('throws ArgumentError for invalid input', () {
      expect(
        () => converter.fromJson('not-an-object-id'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => converter.fromJson({'_id': 'not-an-object-id'}),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('ObjectIdConverter.toJson', () {
    test('returns ObjectId unchanged', () {
      final id = ObjectId.fromHexString('507f1f77bcf86cd799439011');
      expect(converter.toJson(id), id);
    });
  });
}

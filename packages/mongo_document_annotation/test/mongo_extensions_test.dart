import 'package:mongo_document_annotation/mongo_document_annotation.dart';
import 'package:test/test.dart';

void main() {
  group('withRefs', () {
    test('legacy heuristic behavior is preserved without schema hints', () {
      final authorId = ObjectId.fromHexString('507f1f77bcf86cd799439011');
      final wrapped = {
        'author': authorId,
        'token': '507f1f77bcf86cd799439012',
      }.withRefs();

      expect(wrapped['author'], {'_id': authorId});
      expect(
        wrapped['token'],
        {'_id': ObjectId.fromHexString('507f1f77bcf86cd799439012')},
      );
    });

    test('schema-aware mode wraps refs but preserves plain ObjectId fields', () {
      final ownerId = ObjectId.fromHexString('507f1f77bcf86cd799439013');
      final authorId = ObjectId.fromHexString('507f1f77bcf86cd799439014');

      final wrapped = {
        'owner': ownerId,
        'author': authorId,
        'token': '507f1f77bcf86cd799439015',
      }.withRefs(refFields: {'author'}, objectIdFields: {'owner'});

      expect(wrapped['owner'], ownerId);
      expect(wrapped['author'], {'_id': authorId});
      expect(wrapped['token'], '507f1f77bcf86cd799439015');
    });

    test('schema-aware mode understands Mongo extended json refs', () {
      final wrapped = {
        'author': {r'$oid': '507f1f77bcf86cd799439019'},
        'owner': {r'$oid': '507f1f77bcf86cd799439020'},
      }.withRefs(refFields: {'author'}, objectIdFields: {'owner'});

      expect(wrapped['author'], {
        '_id': ObjectId.fromHexString('507f1f77bcf86cd799439019'),
      });
      expect(
        wrapped['owner'],
        ObjectId.fromHexString('507f1f77bcf86cd799439020'),
      );
    });
  });

  group('withValidObjectReferences', () {
    test(
      'schema-aware mode converts plain ObjectId fields without touching hex strings',
      () {
        final converted = {
          'owner': '507f1f77bcf86cd799439016',
          'author': {'_id': '507f1f77bcf86cd799439017'},
          'token': '507f1f77bcf86cd799439018',
        }.withValidObjectReferences(
          refFields: {'author'},
          objectIdFields: {'owner'},
        );

        expect(
          converted['owner'],
          ObjectId.fromHexString('507f1f77bcf86cd799439016'),
        );
        expect(
          converted['author'],
          ObjectId.fromHexString('507f1f77bcf86cd799439017'),
        );
        expect(converted['token'], '507f1f77bcf86cd799439018');
      },
    );

    test('schema-aware mode converts Mongo extended json object ids', () {
      final converted = {
        'owner': {r'$oid': '507f1f77bcf86cd799439021'},
        'author': {
          '_id': {r'$oid': '507f1f77bcf86cd799439022'},
        },
      }.withValidObjectReferences(
        refFields: {'author'},
        objectIdFields: {'owner'},
      );

      expect(
        converted['owner'],
        ObjectId.fromHexString('507f1f77bcf86cd799439021'),
      );
      expect(
        converted['author'],
        ObjectId.fromHexString('507f1f77bcf86cd799439022'),
      );
    });
  });
}

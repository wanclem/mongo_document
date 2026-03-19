import 'package:mongo_document_annotation/mongo_document_annotation.dart';
import 'package:test/test.dart';

void main() {
  group('mongo document snapshots', () {
    const collection = 'posts';

    test('stores and returns deep-cloned snapshots by collection and id', () {
      final id = ObjectId.fromHexString('507f1f77bcf86cd799439011');

      rememberMongoDocumentSnapshot(collection, {
        '_id': id,
        'body': 'Hello world',
        'tags': ['dart'],
        'author': {'_id': ObjectId.fromHexString('507f1f77bcf86cd799439012')},
      });

      final firstSnapshot = mongoDocumentSnapshot(collection, id);
      expect(firstSnapshot, isNotNull);
      expect(firstSnapshot!['body'], 'Hello world');

      (firstSnapshot['tags'] as List).add('mongodb');
      (firstSnapshot['author'] as Map<String, dynamic>)['role'] = 'admin';

      final secondSnapshot = mongoDocumentSnapshot(collection, id);
      expect(secondSnapshot!['tags'], ['dart']);
      expect(
        (secondSnapshot['author'] as Map<String, dynamic>).containsKey('role'),
        isFalse,
      );

      forgetMongoDocumentSnapshot(collection, id);
      expect(mongoDocumentSnapshot(collection, id), isNull);
    });

    test('bounds per-collection snapshot growth and keeps recent entries', () {
      const snapshotCount = 1005;
      const boundedCollection = 'bounded_posts';
      final ids = List.generate(
        snapshotCount,
        (index) => ObjectId.fromHexString(
          (index + 1).toRadixString(16).padLeft(24, '0'),
        ),
      );

      for (final id in ids) {
        rememberMongoDocumentSnapshot(boundedCollection, {
          '_id': id,
          'body': 'Post ${id.oid}',
        });
      }

      expect(
        mongoDocumentSnapshot(boundedCollection, ids.first),
        isNull,
      );
      expect(
        mongoDocumentSnapshot(boundedCollection, ids.last),
        isNotNull,
      );

      for (final id in ids.skip(snapshotCount - 1000)) {
        forgetMongoDocumentSnapshot(boundedCollection, id);
      }
    });
  });

  group('buildMongoUpdateMapFromSnapshot', () {
    test('updates changed tracked fields and ignores unchanged ones', () {
      final updateMap = buildMongoUpdateMapFromSnapshot(
        current: {
          '_id': ObjectId.fromHexString('507f1f77bcf86cd799439011'),
          'body': 'Updated body',
          'status': 'draft',
          'updated_at': DateTime.utc(2026, 3, 19),
        },
        snapshot: {
          '_id': ObjectId.fromHexString('507f1f77bcf86cd799439011'),
          'body': 'Original body',
          'status': 'draft',
        },
        trackedKeys: const ['body', 'status', 'updated_at'],
      );

      expect(updateMap, {'body': 'Updated body'});
    });

    test('does not wipe fields missing from a projected snapshot', () {
      final updateMap = buildMongoUpdateMapFromSnapshot(
        current: {
          'body': null,
          'status': 'draft',
        },
        snapshot: {
          'status': 'draft',
        },
        trackedKeys: const ['body', 'status'],
      );

      expect(updateMap, isEmpty);
    });

    test('allows setting previously-unloaded fields when the new value is non-null', () {
      final updateMap = buildMongoUpdateMapFromSnapshot(
        current: {
          'body': 'Updated body',
          'status': 'draft',
        },
        snapshot: {
          'status': 'draft',
        },
        trackedKeys: const ['body', 'status'],
      );

      expect(updateMap, {'body': 'Updated body'});
    });

    test('can clear a tracked field that existed in the snapshot', () {
      final updateMap = buildMongoUpdateMapFromSnapshot(
        current: {
          'body': null,
        },
        snapshot: {
          'body': 'Existing body',
        },
        trackedKeys: const ['body'],
      );

      expect(updateMap, {'body': null});
    });
  });
}

import 'package:mongo_document_db_driver/mongo_document_db_driver.dart';
import 'package:test/test.dart';

void main() {
  group('DbCollection.modernFindOne resilience', () {
    test('falls back to legacy findOne for simple filter-only reads', () async {
      final db = _openLegacyDb();
      final collection = _SpyCollection(db, 'posts');

      final result = await collection.modernFindOne(filter: {'_id': 42});

      expect(result, {'_id': 42, 'source': 'legacy'});
      expect(collection.legacyFindOneCalls, 1);
      expect(collection.lastLegacySelector, {'_id': 42});
    });

    test('reports db state errors before capability errors', () async {
      final db = Db('mongodb://127.0.0.1:27017/test-mongo-dart');
      db.debugSetState(State.closed);
      final collection = DbCollection(db, 'posts');

      await expectLater(
        () => collection.modernFindOne(filter: {'_id': 42}),
        throwsA(
          isA<MongoDartError>().having(
            (error) => error.message,
            'message',
            'Db is in the wrong state: State.CLOSED',
          ),
        ),
      );
    });

    test('keeps explicit capability errors for modern-only options', () async {
      final db = _openLegacyDb();
      final collection = DbCollection(db, 'posts');

      await expectLater(
        () => collection.modernFindOne(
          filter: {'_id': 42},
          sort: {'created_at': -1},
        ),
        throwsA(
          isA<MongoDartError>().having(
            (error) => error.message,
            'message',
            'findOne with the requested options requires an active MongoDB 3.6+ OP_MSG-capable connection',
          ),
        ),
      );
    });
  });
}

Db _openLegacyDb() {
  final db = Db('mongodb://127.0.0.1:27017/test-mongo-dart');
  db.debugSetState(State.open);
  final manager = ConnectionManager(db);
  db.debugAttachConnectionManager(manager);
  manager.debugSetMasterConnection(_LegacyConnection(manager));
  return db;
}

class _LegacyConnection extends Connection {
  _LegacyConnection(ConnectionManager manager)
    : super(manager, ServerConfig(host: '127.0.0.1', port: 27017)) {
    connected = true;
    isMaster = true;
    serverCapabilities.supportsOpMsg = false;
  }
}

class _SpyCollection extends DbCollection {
  _SpyCollection(super.db, super.collectionName);

  int legacyFindOneCalls = 0;
  dynamic lastLegacySelector;

  @override
  Future<Map<String, dynamic>?> legacyFindOne([dynamic selector]) async {
    legacyFindOneCalls++;
    lastLegacySelector = selector;
    return {
      '_id': (selector as Map<String, dynamic>)['_id'],
      'source': 'legacy',
    };
  }
}

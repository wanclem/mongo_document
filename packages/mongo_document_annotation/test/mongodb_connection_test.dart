import 'package:mongo_document_annotation/mongo_document_annotation.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() {
    MongoDbConnection.debugReset();
  });

  test(
    'reuses the same Db object when reopening a closed connection',
    () async {
      final db = _FakeDb();
      var factoryCalls = 0;
      MongoDbConnection.debugSetDbFactory((_) async {
        factoryCalls++;
        return db;
      });

      await MongoDbConnection.initialize('mongodb://example.com/test');

      expect(factoryCalls, equals(1));
      expect(db.openCalls, equals(1));

      await db.close();

      final reopened = await MongoDbConnection.instance;

      expect(reopened, same(db));
      expect(factoryCalls, equals(1));
      expect(db.openCalls, equals(2));
    },
  );

  test('shares the same in-flight connect attempt across callers', () async {
    final db = _FakeDb();
    final factoryCompleter = Completer<Db>();
    var factoryCalls = 0;
    MongoDbConnection.debugSetDbFactory((_) async {
      factoryCalls++;
      return factoryCompleter.future;
    });

    final initializeFuture = MongoDbConnection.initialize(
      'mongodb://example.com/test',
    );
    final secondCaller = MongoDbConnection.instance;

    expect(factoryCalls, equals(1));

    factoryCompleter.complete(db);

    await initializeFuture;
    final resolved = await secondCaller;

    expect(resolved, same(db));
    expect(factoryCalls, equals(1));
    expect(db.openCalls, equals(1));
  });

  test(
    'shutdown prevents a stale in-flight connect from re-registering',
    () async {
      final staleDb = _FakeDb();
      final freshDb = _FakeDb();
      final factoryCompleter = Completer<Db>();
      var factoryCalls = 0;
      MongoDbConnection.debugSetDbFactory((_) async {
        factoryCalls++;
        if (factoryCalls == 1) {
          return factoryCompleter.future;
        }
        return freshDb;
      });

      final initializeFuture = MongoDbConnection.initialize(
        'mongodb://example.com/test',
      );
      final initializeFailure = expectLater(initializeFuture, throwsStateError);

      await Future<void>.delayed(Duration.zero);
      final shutdownFuture = MongoDbConnection.shutdownDb();

      factoryCompleter.complete(staleDb);

      await shutdownFuture;
      await initializeFailure;
      expect(staleDb.closeCalls, equals(1));

      final reopened = await MongoDbConnection.instance;

      expect(reopened, same(freshDb));
      expect(factoryCalls, equals(2));
      expect(freshDb.openCalls, equals(1));
    },
  );

  test(
    'returns the existing Db immediately while reconnecting in the background',
    () async {
      final db = _FakeDb();
      MongoDbConnection.debugSetDbFactory((_) async => db);

      await MongoDbConnection.initialize('mongodb://example.com/test');

      final reopenCompleter = Completer<void>();
      db.nextOpenCompleter = reopenCompleter;
      db.markTransientlyClosed();

      final first = await MongoDbConnection.instance.timeout(
        const Duration(milliseconds: 50),
      );
      final second = await MongoDbConnection.instance.timeout(
        const Duration(milliseconds: 50),
      );

      expect(first, same(db));
      expect(second, same(db));
      expect(db.openCalls, equals(2));
      expect(db.state, equals(State.closed));
      expect(db.isExplicitlyClosed, isFalse);

      reopenCompleter.complete();
      await Future<void>.delayed(Duration.zero);

      expect(db.state, equals(State.open));
      expect(db.isExplicitlyClosed, isFalse);
    },
  );
}

class _FakeDb extends Db {
  _FakeDb() : super('mongodb://127.0.0.1:27017/test');

  int openCalls = 0;
  int closeCalls = 0;
  State _state = State.init;
  bool _isExplicitlyClosed = false;
  Completer<void>? nextOpenCompleter;

  @override
  State get state => _state;

  @override
  bool get isExplicitlyClosed => _isExplicitlyClosed;

  @override
  Future open({
    WriteConcern writeConcern = WriteConcern.acknowledged,
    bool secure = false,
  }) async {
    openCalls++;
    final completer = nextOpenCompleter;
    nextOpenCompleter = null;
    if (completer != null) {
      await completer.future;
    }
    _state = State.open;
    _isExplicitlyClosed = false;
  }

  @override
  Future close() async {
    closeCalls++;
    _state = State.closed;
    _isExplicitlyClosed = true;
  }

  void markTransientlyClosed() {
    _state = State.closed;
    _isExplicitlyClosed = false;
  }
}

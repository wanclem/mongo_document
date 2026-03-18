import 'package:meta/meta.dart';
import 'package:mongo_document_db_driver/mongo_document_db_driver.dart';

class MongoDbConnection {
  static Db? _instance;
  static Future<Db>? _connecting;
  static int _connectionGeneration = 0;
  static Future<Db> Function(String databaseUri) _dbFactory = Db.create;

  static String? _connectionUri;

  MongoDbConnection._();

  static Future<void> initialize(
    String databaseUri, {
    @Deprecated('Put TLS settings in the MongoDB connection string instead.')
    bool? secure,
  }) async {
    final normalizedUri = _normalizeDatabaseUri(
      databaseUri,
      secure: secure,
    );

    if (_connectionUri != null && _connectionUri != normalizedUri) {
      throw StateError(
        'MongoDbConnection is already initialized with a different connection string.',
      );
    }

    _connectionUri = normalizedUri;

    await instance;
  }

  static Future<Db> get instance async {
    if (_connectionUri == null) {
      throw StateError(
        'MongoDbConnection.initialize must be called before instance.',
      );
    }

    final connecting = _connecting;
    if (connecting != null) {
      return connecting;
    }

    var currentDb = _instance;
    if (currentDb != null) {
      if (currentDb.state != State.closed) {
        return currentDb;
      }
      final reopenTask = _openDb(currentDb, generation: _connectionGeneration);
      _connecting = reopenTask;
      try {
        return await reopenTask;
      } finally {
        if (identical(_connecting, reopenTask)) {
          _connecting = null;
        }
      }
    }

    final connectTask = _connect(generation: _connectionGeneration);
    _connecting = connectTask;
    try {
      return await connectTask;
    } finally {
      if (identical(_connecting, connectTask)) {
        _connecting = null;
      }
    }
  }

  static Future<Db> _connect({required int generation}) async {
    final newDb = await _dbFactory(_connectionUri!);
    return _openDb(newDb, generation: generation);
  }

  static Future<Db> _openDb(Db db, {required int generation}) async {
    await db.open();
    if (generation != _connectionGeneration) {
      await db.close();
      throw StateError(
        'MongoDbConnection was shut down while a connection attempt was in progress.',
      );
    }
    _instance = db;
    return db;
  }

  static Future<void> shutdownDb() async {
    _connectionGeneration++;
    final inProgress = _connecting;
    _connecting = null;

    Db? db = _instance;
    _instance = null;
    if (inProgress != null) {
      try {
        final pendingDb = await inProgress;
        if (!identical(pendingDb, db)) {
          await pendingDb.close();
        }
      } catch (_) {}
    }

    if (db != null) {
      try {
        await db.close();
      } catch (e) {
        print('Error during DB shutdown: $e');
      }
    }
  }

  @visibleForTesting
  static void debugSetDbFactory(
    Future<Db> Function(String databaseUri) factory,
  ) {
    _dbFactory = factory;
  }

  @visibleForTesting
  static void debugReset() {
    _instance = null;
    _connecting = null;
    _connectionGeneration = 0;
    _dbFactory = Db.create;
    _connectionUri = null;
  }

  static Future<DbCollection> getCollection(String collectionName) async {
    final db = await instance;
    return db.collection(collectionName);
  }

  static String _normalizeDatabaseUri(
    String databaseUri, {
    bool? secure,
  }) {
    if (secure == null) {
      return databaseUri;
    }

    final uri = Uri.parse(databaseUri);
    final queryParameters = Map<String, String>.from(uri.queryParameters);

    queryParameters['tls'] = secure.toString();

    return uri.replace(queryParameters: queryParameters).toString();
  }
}

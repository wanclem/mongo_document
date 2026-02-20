import 'package:mongo_document_db/mongo_document_db.dart';

class MongoDbConnection {
  static Db? _instance;
  static Future<Db>? _connecting;

  static String? _databaseUri;
  static bool? _secure;
  static bool? _tlsAllowInvalidCertificates;
  static String? _tlsCAFile;
  static String? _tlsCertificateKeyFile;
  static String? _tlsCertificateKeyFilePassword;

  MongoDbConnection._();

  static Future<void> initialize(
    String databaseUri, {
    bool secure = true,
    bool tlsAllowInvalidCertificates = false,
    String? tlsCAFile,
    String? tlsCertificateKeyFile,
    String? tlsCertificateKeyFilePassword,
  }) async {
    if (_databaseUri != null &&
        (_databaseUri != databaseUri ||
            _secure != secure ||
            _tlsAllowInvalidCertificates != tlsAllowInvalidCertificates ||
            _tlsCAFile != tlsCAFile ||
            _tlsCertificateKeyFile != tlsCertificateKeyFile ||
            _tlsCertificateKeyFilePassword != tlsCertificateKeyFilePassword)) {
      throw StateError(
        'MongoDbConnection is already initialized with different settings.',
      );
    }

    _databaseUri = databaseUri;
    _secure = secure;
    _tlsAllowInvalidCertificates = tlsAllowInvalidCertificates;
    _tlsCAFile = tlsCAFile;
    _tlsCertificateKeyFile = tlsCertificateKeyFile;
    _tlsCertificateKeyFilePassword = tlsCertificateKeyFilePassword;

    await instance;
  }

  static Future<Db> get instance async {
    if (_databaseUri == null) {
      throw StateError(
        'MongoDbConnection.initialize must be called before instance.',
      );
    }

    var currentDb = _instance;
    if (currentDb != null) {
      // Do not brute-force recreate the Db on transient socket drops.
      // The local driver now performs internal reconnect/recovery.
      if (currentDb.state != State.closed) {
        return currentDb;
      }
      _instance = null;
      currentDb = null;
    }

    final connecting = _connecting;
    if (connecting != null) {
      return connecting;
    }

    final connectTask = _connect();
    _connecting = connectTask;
    try {
      return await connectTask;
    } finally {
      if (identical(_connecting, connectTask)) {
        _connecting = null;
      }
    }
  }

  static Future<Db> _connect() async {
    final newDb = await Db.create(_databaseUri!);
    await newDb.open(
      secure: _secure ?? true,
      tlsAllowInvalidCertificates: _tlsAllowInvalidCertificates ?? false,
      tlsCAFile: _tlsCAFile,
      tlsCertificateKeyFile: _tlsCertificateKeyFile,
      tlsCertificateKeyFilePassword: _tlsCertificateKeyFilePassword,
    );
    _instance = newDb;
    return newDb;
  }

  static Future<void> shutdownDb() async {
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

  static Future<DbCollection> getCollection(String collectionName) async {
    final db = await instance;
    return db.collection(collectionName);
  }
}

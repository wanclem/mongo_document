import 'package:mongo_dart/mongo_dart.dart';

class MongoDbConnection {
  static Db? _instance;

  static late final String _databaseUri;
  static late final bool _secure;
  static late final bool _tlsAllowInvalidCertificates;
  static late final String? _tlsCAFile;
  static late final String? _tlsCertificateKeyFile;
  static late final String? _tlsCertificateKeyFilePassword;

  MongoDbConnection._();

  static Future<void> initialize(
    String databaseUri, {
    bool secure = true,
    bool tlsAllowInvalidCertificates = false,
    String? tlsCAFile,
    String? tlsCertificateKeyFile,
    String? tlsCertificateKeyFilePassword,
  }) async {
    if (_instance != null) return;

    _databaseUri = _withSafeAtlas(databaseUri);
    _secure = secure;
    _tlsAllowInvalidCertificates = tlsAllowInvalidCertificates;
    _tlsCAFile = tlsCAFile;
    _tlsCertificateKeyFile = tlsCertificateKeyFile;
    _tlsCertificateKeyFilePassword = tlsCertificateKeyFilePassword;

    await instance;
  }

  static Future<Db> get instance async {
    final currentDb = _instance;
    if (currentDb != null && currentDb.isConnected) {
      return currentDb;
    }

    final newDb = await Db.create(_databaseUri);
    await newDb.open(
      secure: _secure,
      tlsAllowInvalidCertificates: _tlsAllowInvalidCertificates,
      tlsCAFile: _tlsCAFile,
      tlsCertificateKeyFile: _tlsCertificateKeyFile,
      tlsCertificateKeyFilePassword: _tlsCertificateKeyFilePassword,
    );
    _instance = newDb;
    return newDb;
  }

  static Future<void> shutdownDb() async {
    final db = _instance;
    _instance = null;
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

  static String _withSafeAtlas(String databaseUri) {
    if (databaseUri.contains('safeAtlas=')) {
      return databaseUri;
    }
    final separator = databaseUri.contains('?') ? '&' : '?';
    return '$databaseUri${separator}safeAtlas=true';
  }
}

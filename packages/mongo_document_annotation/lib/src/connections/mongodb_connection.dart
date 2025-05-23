import 'package:mongo_dart/mongo_dart.dart';

class MongoDbConnection {
  static Db? _instance;

  static late final bool _secure;
  static late final bool _tlsAllowInvalidCertificates;
  static late final String? _tlsCAFile;
  static late final String? _tlsCertificateKeyFile;
  static late final String? _tlsCertificateKeyFilePassword;

  MongoDbConnection._();

  /// Must be called once at app startup.
  static Future<void> initialize(
    String databaseUri, {
    bool secure = true,
    bool tlsAllowInvalidCertificates = false,
    String? tlsCAFile,
    String? tlsCertificateKeyFile,
    String? tlsCertificateKeyFilePassword,
  }) async {
    if (_instance != null) {
      throw Exception("Database already initialized.");
    }

    _secure = secure;
    _tlsAllowInvalidCertificates = tlsAllowInvalidCertificates;
    _tlsCAFile = tlsCAFile;
    _tlsCertificateKeyFile = tlsCertificateKeyFile;
    _tlsCertificateKeyFilePassword = tlsCertificateKeyFilePassword;

    _instance = databaseUri.startsWith('mongodb+srv://')
        ? await Db.create(databaseUri)
        : Db(databaseUri);

    await _instance!.open(
      secure: _secure,
      tlsAllowInvalidCertificates: _tlsAllowInvalidCertificates,
      tlsCAFile: _tlsCAFile,
      tlsCertificateKeyFile: _tlsCertificateKeyFile,
      tlsCertificateKeyFilePassword: _tlsCertificateKeyFilePassword,
    );

    print('✅ MongoDB connected');
  }

  static Future<Db> get instance async {
    if (_instance == null) {
      throw Exception(
        "Database not initialized. Please call initialize() first.",
      );
    }

    if (!_instance!.isConnected) {
      await _instance!.open(
        secure: _secure,
        tlsAllowInvalidCertificates: _tlsAllowInvalidCertificates,
        tlsCAFile: _tlsCAFile,
        tlsCertificateKeyFile: _tlsCertificateKeyFile,
        tlsCertificateKeyFilePassword: _tlsCertificateKeyFilePassword,
      );
      print('🔄 MongoDB reconnected');
    }

    return _instance!;
  }

  static Future<void> shutdownDb() async {
    final db = await instance;
    await db.close();
    print('🛑 MongoDB connection closed');
  }

  static Future<DbCollection> getCollection(String collectionName) async {
    final db = await instance;
    return db.collection(collectionName);
  }
}

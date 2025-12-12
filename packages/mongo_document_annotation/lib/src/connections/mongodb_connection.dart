import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';

class MongoDbConnection {
  static Db? _instance;
  static Completer<void>? _connectionCompleter;
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
    if (_instance != null) {
      throw Exception("Database already initialized.");
    }

    _databaseUri = databaseUri;
    _secure = secure;
    _tlsAllowInvalidCertificates = tlsAllowInvalidCertificates;
    _tlsCAFile = tlsCAFile;
    _tlsCertificateKeyFile = tlsCertificateKeyFile;
    _tlsCertificateKeyFilePassword = tlsCertificateKeyFilePassword;

    await _connect();
    print('MongoDB connected');
  }

  static Future<void> _connect() async {
    if (_instance != null) {
      await _instance!.close().catchError((_) {});
    }

    _instance = await Db.create(_databaseUri);

    await _instance!.open(
      secure: _secure,
      tlsAllowInvalidCertificates: _tlsAllowInvalidCertificates,
      tlsCAFile: _tlsCAFile,
      tlsCertificateKeyFile: _tlsCertificateKeyFile,
      tlsCertificateKeyFilePassword: _tlsCertificateKeyFilePassword,
    );
  }

  static Future<Db> get instance async {
    if (_instance == null) {
      throw Exception(
        "Database not initialized. Please call initialize() first.",
      );
    }

    if (_instance!.isConnected) {
      return _instance!;
    }

    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      await _connectionCompleter!.future;
      return _instance!;
    }

    _connectionCompleter = Completer<void>();
    print('MongoDB disconnected, attempting to reconnect...');

    int maxRetries = 3;
    int retryDelay = 2;

    try {
      for (int i = 0; i < maxRetries; i++) {
        try {
          await _connect();

          if (_instance!.isConnected) {
            print('MongoDB reconnected successfully');
            _connectionCompleter!.complete();
            return _instance!;
          }
        } catch (e) {
          print('Reconnection attempt ${i + 1}/$maxRetries failed: $e');
          if (i < maxRetries - 1) {
            await Future.delayed(Duration(seconds: retryDelay * (i + 1)));
          }
        }
      }

      throw Exception('All reconnection attempts exhausted');
    } catch (e) {
      _connectionCompleter!.completeError(e);
      rethrow;
    } finally {
      _connectionCompleter = null;
    }
  }

  static Future<void> shutdownDb() async {
    if (_instance != null && _instance!.isConnected) {
      await _instance!.close();
      print('MongoDB connection closed');
    }
  }

  static Future<DbCollection> getCollection(String collectionName) async {
    final db = await instance;
    return db.collection(collectionName);
  }
}

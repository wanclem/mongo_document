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

  static Timer? _heartbeatTimer;
  static const Duration _heartbeatInterval = Duration(seconds: 15);
  static const int _maxReconnectAttempts = 5;

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

    _databaseUri = databaseUri;
    _secure = secure;
    _tlsAllowInvalidCertificates = tlsAllowInvalidCertificates;
    _tlsCAFile = tlsCAFile;
    _tlsCertificateKeyFile = tlsCertificateKeyFile;
    _tlsCertificateKeyFilePassword = tlsCertificateKeyFilePassword;

    await instance;
    _startHeartbeat();
  }

  static Future<void> _connect() async {
    final oldInstance = _instance;
    if (oldInstance != null) {
      try {
        await oldInstance.close();
      } catch (_) {}
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
  }

  static Future<void> _connectWithBackoff([int attempt = 0]) async {
    try {
      await _connect();
      final db = _instance;
      if (db == null) throw Exception("Failed to assign instance");
      await db.pingCommand().timeout(const Duration(seconds: 5));
      print('MongoDB connected/reconnected successfully.');
    } catch (e) {
      print('Connection attempt ${attempt + 1} failed: $e');
      if (attempt + 1 < _maxReconnectAttempts) {
        final delay = Duration(seconds: (1 << attempt) * 2);
        await Future.delayed(delay);
        return _connectWithBackoff(attempt + 1);
      }
      rethrow;
    }
  }

  static Future<Db> get instance async {
    final completer = _connectionCompleter;
    if (completer != null && !completer.isCompleted) {
      await completer.future;
      final db = _instance;
      if (db != null) return db;
    }
    final currentDb = _instance;
    if (currentDb != null && currentDb.isConnected) {
      try {
        await currentDb.pingCommand().timeout(const Duration(seconds: 2));
        return currentDb;
      } catch (e) {
        print('MongoDB connection lost (ping failed). Reconnecting...');
      }
    }

    _connectionCompleter = Completer<void>();
    try {
      await _connectWithBackoff();
      final db = _instance;
      if (db == null) {
        throw Exception("MongoDB instance is null after connection.");
      }
      _connectionCompleter?.complete();
      return db;
    } catch (e) {
      _connectionCompleter?.completeError(e);
      rethrow;
    } finally {
      _connectionCompleter = null;
    }
  }

  static Future<void> shutdownDb() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
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

  static void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) async {
      try {
        await instance;
      } catch (e) {
        print('Heartbeat check failed: $e');
      }
    });
  }
}

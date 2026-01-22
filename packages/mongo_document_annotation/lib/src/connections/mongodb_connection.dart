import 'dart:async';
import 'dart:io';
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

    print('MongoDB Initialized');

    _startHeartbeat();
  }

  static Future<void> _connect() async {
    if (_instance != null) {
      try {
        await _instance!.close();
      } catch (_) {}
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

  static Future<void> _connectWithBackoff([int attempt = 0]) async {
    try {
      await _connect();
      await _instance!.pingCommand().timeout(const Duration(seconds: 5));
      return;
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
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      await _connectionCompleter!.future;
      return _instance!;
    }

    if (_instance != null && _instance!.isConnected) {
      try {
        await _instance!.pingCommand().timeout(const Duration(seconds: 2));
        return _instance!;
      } catch (e) {
        print('Existing MongoDB connection stale/dropped. Reconnecting...');
      }
    }

    _connectionCompleter = Completer<void>();
    try {
      await _connectWithBackoff();
      _connectionCompleter!.complete();
      return _instance!;
    } catch (e) {
      _connectionCompleter!.completeError(e);
      _connectionCompleter = null;
      rethrow;
    } finally {
      _connectionCompleter = null;
    }
  }

  static Future<void> shutdownDb() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    if (_instance != null) {
      try {
        await _instance!.close();
      } catch (e) {
        print('Error closing DB: $e');
      } finally {
        _instance = null;
      }
    }
  }

  static Future<DbCollection> getCollection(String collectionName) async {
    final db = await instance;
    return db.collection(collectionName);
  }

  static Future<T> runWithRetry<T>(
    Future<T> Function() operation, {
    int retries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await operation();
      } catch (e) {
        if (_isTransientError(e) && attempt < retries) {
          attempt++;
          print('DB transient error (attempt $attempt/$retries): $e');
          await Future.delayed(retryDelay * attempt);
          continue;
        }
        rethrow;
      }
    }
  }

  static bool _isTransientError(dynamic e) {
    final msg = e?.toString().toLowerCase() ?? '';
    return e is SocketException ||
        e is TimeoutException ||
        msg.contains('closed') ||
        msg.contains('reset by peer') ||
        msg.contains('broken pipe') ||
        msg.contains('master') ||
        msg.contains('selection');
  }

  static void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) async {
      if (_instance == null) return;
      try {
        await instance;
      } catch (e) {
        print('Heartbeat connection check failed: $e');
      }
    });
  }
}

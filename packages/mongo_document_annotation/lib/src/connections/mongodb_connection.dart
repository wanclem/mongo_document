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
    final int max = _maxReconnectAttempts;
    final delaySeconds = (1 << attempt) * 2;
    try {
      await _connect();
      if (_instance!.isConnected) {
        print('MongoDB reconnected successfully (attempt ${attempt + 1})');
        return;
      }
    } catch (e) {
      print('Reconnect attempt ${attempt + 1} failed: $e');
    }
    if (attempt + 1 < max) {
      await Future.delayed(Duration(seconds: delaySeconds));
      return _connectWithBackoff(attempt + 1);
    }
    throw Exception('All reconnection attempts exhausted after $max tries');
  }

  static Future<Db> get instance async {
    if (_instance == null) {
      throw Exception(
        "Database not initialized. Please call initialize() first.",
      );
    }

    if (_instance!.isConnected) {
      await _instance!.pingCommand().timeout(Duration(seconds: 5));
      return _instance!;
    }

    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      await _connectionCompleter!.future;
      return _instance!;
    }

    _connectionCompleter = Completer<void>();
    print('MongoDB disconnected, attempting to reconnect...');

    try {
      await _connectWithBackoff();
      if (_instance!.isConnected) {
        _connectionCompleter!.complete();
        return _instance!;
      } else {
        throw Exception('Reconnection failed');
      }
    } catch (e) {
      _connectionCompleter!.completeError(e);
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
    print('MongoDB connection closed');
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
          print('DB op transient error (attempt $attempt/$retries): $e');
          try {
            await _connectWithBackoff(0);
          } catch (reconnectError) {
            print('Reconnect during retry failed: $reconnectError');
          }
          await Future.delayed(retryDelay * attempt);
          continue;
        }
        rethrow;
      }
    }
  }

  static bool _isTransientError(dynamic e) {
    final msg = e?.toString() ?? '';
    if (e is SocketException ||
        e is TimeoutException ||
        msg.contains('No master connection') ||
        msg.contains('SocketException') ||
        msg.contains('Server selection') ||
        msg.contains('connection closed')) {
      return true;
    }
    if (e is MongoDartError) {
      return true;
    }
    return false;
  }

  static void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) async {
      if (_instance == null) return;
      try {
        await _instance!.pingCommand();
      } catch (e) {
        print('MongoDB heartbeat failed: $e -- attempting reconnect');
        try {
          await _connectWithBackoff(0);
        } catch (re) {
          print('Heartbeat-triggered reconnect failed: $re');
        }
      }
    });
  }
}

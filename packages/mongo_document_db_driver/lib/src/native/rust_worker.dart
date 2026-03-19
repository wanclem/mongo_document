import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as pkg_ffi;
import 'package:mongo_document_db_driver/mongo_document_db_driver.dart';
import 'package:mongo_document_db_driver/src/database/utils/recoverable_error_classifier.dart';

import 'rust_bindings.dart';

class RustWorkerCursorHandle {
  const RustWorkerCursorHandle({required this.worker, required this.cursorId});

  final RustWorkerClient worker;
  final int cursorId;
}

class RustWorkerPool {
  RustWorkerPool._(this._workers);

  final List<RustWorkerClient> _workers;
  int _nextWorkerIndex = 0;
  bool _closed = false;
  Future<void>? _warmupFuture;

  static Future<RustWorkerPool> open({
    required String connectionString,
    required String databaseName,
    Duration? connectTimeout,
    Duration? serverSelectionTimeout,
    required int workerCount,
  }) async {
    final resolvedWorkerCount = workerCount < 1 ? 1 : workerCount;
    final perWorkerConnectionString = _perWorkerConnectionString(
      connectionString,
      workerCount: resolvedWorkerCount,
    );
    final primaryWorker = await debugRetryTransientWorkerStartupOperation(
      operation: () => RustWorkerClient.spawn(
        connectionString: perWorkerConnectionString,
        databaseName: databaseName,
        logContext: _workerLogContext(
          workerNumber: 1,
          workerCount: resolvedWorkerCount,
        ),
        connectTimeout: connectTimeout,
        serverSelectionTimeout: serverSelectionTimeout,
      ),
    );
    final pool = RustWorkerPool._(<RustWorkerClient>[primaryWorker]);
    if (resolvedWorkerCount > 1) {
      pool._warmupFuture = pool._warmAdditionalWorkers(
        additionalWorkers: resolvedWorkerCount - 1,
        connectionString: perWorkerConnectionString,
        databaseName: databaseName,
        connectTimeout: connectTimeout,
        serverSelectionTimeout: serverSelectionTimeout,
      );
    }
    return pool;
  }

  bool get hasHealthyWorker =>
      !_closed && _workers.any((worker) => worker.isHealthy);

  String? get lastError {
    for (final worker in _workers) {
      if (worker.lastError case final error?) {
        return error;
      }
    }
    return null;
  }

  RustWorkerClient selectWorker() {
    if (_closed || _workers.isEmpty) {
      throw const ConnectionException('Rust worker pool is closed.');
    }
    for (var offset = 0; offset < _workers.length; offset++) {
      final index = (_nextWorkerIndex + offset) % _workers.length;
      final worker = _workers[index];
      if (!worker.isHealthy) {
        continue;
      }
      _nextWorkerIndex = (index + 1) % _workers.length;
      return worker;
    }
    throw ConnectionException(lastError ?? 'Rust worker pool is unavailable.');
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    try {
      await _warmupFuture?.timeout(const Duration(seconds: 1));
    } catch (_) {
      // Best-effort only.
    }
    await Future.wait(
      _workers.map((worker) => worker.close()),
      eagerError: false,
    );
  }

  Future<void> _warmAdditionalWorkers({
    required int additionalWorkers,
    required String connectionString,
    required String databaseName,
    Duration? connectTimeout,
    Duration? serverSelectionTimeout,
  }) async {
    for (var i = 0; i < additionalWorkers; i++) {
      if (_closed) {
        return;
      }
      try {
        final worker = await RustWorkerClient.spawn(
          connectionString: connectionString,
          databaseName: databaseName,
          logContext: _workerLogContext(
            workerNumber: i + 2,
            workerCount: additionalWorkers + 1,
          ),
          connectTimeout: connectTimeout,
          serverSelectionTimeout: serverSelectionTimeout,
        );
        if (_closed) {
          await worker.close();
          return;
        }
        _workers.add(worker);
      } catch (_) {
        // Keep the pool usable with the workers we already have.
        return;
      }
    }
  }

  static String _perWorkerConnectionString(
    String connectionString, {
    required int workerCount,
  }) {
    if (workerCount <= 1) {
      return connectionString;
    }
    final parts = connectionString.split('?');
    if (parts.length == 1) {
      return connectionString;
    }
    final base = parts.first;
    final query = parts.sublist(1).join('?');
    final queryParameters = Map<String, String>.from(
      Uri.splitQueryString(query),
    );
    _dividePoolOption(queryParameters, 'maxPoolSize', workerCount);
    _dividePoolOption(queryParameters, 'minPoolSize', workerCount);
    queryParameters.remove('maxConnecting');
    final rebuiltQuery = Uri(queryParameters: queryParameters).query;
    return rebuiltQuery.isEmpty ? base : '$base?$rebuiltQuery';
  }

  static String _workerLogContext({
    required int workerNumber,
    required int workerCount,
  }) {
    if (workerNumber <= 1) {
      return 'worker pool primary 1/$workerCount';
    }
    return 'worker pool warmup $workerNumber/$workerCount';
  }

  static void _dividePoolOption(
    Map<String, String> queryParameters,
    String key,
    int workerCount,
  ) {
    final rawValue = queryParameters[key];
    final parsedValue = int.tryParse(rawValue ?? '');
    if (parsedValue == null || parsedValue <= 0) {
      return;
    }
    final perWorkerValue = (parsedValue / workerCount).ceil();
    queryParameters[key] = perWorkerValue.clamp(1, parsedValue).toString();
  }
}

Future<T> debugRetryTransientWorkerStartupOperation<T>({
  required Future<T> Function() operation,
  int maxAttempts = 3,
}) async {
  if (maxAttempts < 1) {
    throw ArgumentError.value(
      maxAttempts,
      'maxAttempts',
      'Must be at least 1.',
    );
  }

  Object? lastError;
  StackTrace? lastStackTrace;

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await operation();
    } catch (error, stackTrace) {
      lastError = error;
      lastStackTrace = stackTrace;
      if (!_isRetryableWorkerStartupError(error) || attempt >= maxAttempts) {
        rethrow;
      }
      await Future<void>.delayed(_workerStartupRetryDelay(attempt));
    }
  }

  Error.throwWithStackTrace(lastError!, lastStackTrace!);
}

class RustWorkerClient {
  RustWorkerClient._({
    required Isolate isolate,
    required SendPort commandPort,
    required ReceivePort responsePort,
    required ReceivePort exitPort,
    required ReceivePort errorPort,
  }) : _isolate = isolate,
       _commandPort = commandPort,
       _responsePort = responsePort,
       _exitPort = exitPort,
       _errorPort = errorPort {
    _responseSubscription = _responsePort.listen(_handleResponse);
    _exitSubscription = _exitPort.listen((_) {
      if (_closing) {
        _markClosed(_lastError ?? 'Rust worker closed.');
      } else {
        _markClosed('Rust worker exited unexpectedly.');
      }
    });
    _errorSubscription = _errorPort.listen((dynamic payload) {
      final message = switch (payload) {
        List list when list.isNotEmpty => list.first.toString(),
        _ => 'Rust worker isolate failed.',
      };
      _markClosed(message);
    });
  }

  final Isolate _isolate;
  final SendPort _commandPort;
  final ReceivePort _responsePort;
  final ReceivePort _exitPort;
  final ReceivePort _errorPort;
  final Map<int, Completer<Map<String, Object?>>> _pending =
      <int, Completer<Map<String, Object?>>>{};
  StreamSubscription? _responseSubscription;
  StreamSubscription? _exitSubscription;
  StreamSubscription? _errorSubscription;
  int _nextRequestId = 1;
  bool _healthy = true;
  bool _closing = false;
  bool _closed = false;
  String? _lastError;

  bool get isHealthy => !_closed && _healthy;

  String? get lastError => _lastError;

  static Future<RustWorkerClient> spawn({
    required String connectionString,
    required String databaseName,
    required String logContext,
    Duration? connectTimeout,
    Duration? serverSelectionTimeout,
  }) async {
    final readyPort = ReceivePort();
    final responsePort = ReceivePort();
    final exitPort = ReceivePort();
    final errorPort = ReceivePort();

    final isolate = await Isolate.spawn<Map<String, Object?>>(
      _mongoRustWorkerMain,
      <String, Object?>{
        'readyPort': readyPort.sendPort,
        'responsePort': responsePort.sendPort,
        'connectionString': connectionString,
        'databaseName': databaseName,
        'logContext': logContext,
        'connectTimeoutMs': connectTimeout?.inMilliseconds ?? 0,
        'serverSelectionTimeoutMs': serverSelectionTimeout?.inMilliseconds ?? 0,
      },
      onExit: exitPort.sendPort,
      onError: errorPort.sendPort,
      errorsAreFatal: true,
    );

    final readyMessage = await readyPort.first as Map;
    readyPort.close();

    if (readyMessage['ok'] != true) {
      isolate.kill(priority: Isolate.immediate);
      responsePort.close();
      exitPort.close();
      errorPort.close();
      final message =
          readyMessage['error']?.toString() ??
          'Rust worker failed to initialize.';
      if (_isConnectionRelatedErrorMessage(message)) {
        throw ConnectionException(message);
      }
      throw MongoDartError(message);
    }

    return RustWorkerClient._(
      isolate: isolate,
      commandPort: readyMessage['commandPort'] as SendPort,
      responsePort: responsePort,
      exitPort: exitPort,
      errorPort: errorPort,
    );
  }

  Future<Map<String, Object?>> runCommand(Uint8List requestBytes) {
    return _sendRequest('runCommand', requestBytes: requestBytes);
  }

  Future<Map<String, Object?>> executeCollectionAction(Uint8List requestBytes) {
    return _sendRequest('executeCollectionAction', requestBytes: requestBytes);
  }

  Future<Map<String, Object?>> runCursorCommand(Uint8List requestBytes) {
    return _sendRequest('runCursorCommand', requestBytes: requestBytes);
  }

  Future<Map<String, Object?>> findOne(Uint8List requestBytes) {
    return _sendRequest('findOne', requestBytes: requestBytes);
  }

  Future<RustWorkerCursorHandle> openFindCursor(Uint8List requestBytes) async {
    final result = await _sendRequest(
      'findCursorOpen',
      requestBytes: requestBytes,
    );
    return RustWorkerCursorHandle(
      worker: this,
      cursorId: result['cursorId'] as int,
    );
  }

  Future<RustWorkerCursorHandle> openAggregateCursor(
    Uint8List requestBytes,
  ) async {
    final result = await _sendRequest(
      'aggregateCursorOpen',
      requestBytes: requestBytes,
    );
    return RustWorkerCursorHandle(
      worker: this,
      cursorId: result['cursorId'] as int,
    );
  }

  Future<Map<String, Object?>> nextCursorBatch(int cursorId) {
    return _sendRequest('cursorNextBatch', cursorId: cursorId);
  }

  Future<void> closeCursor(int cursorId) async {
    await _sendRequest(
      'cursorClose',
      cursorId: cursorId,
      allowClosedWorker: true,
    );
  }

  Future<void> ping() async {
    await _sendRequest('ping');
  }

  Future<Map<String, Object?>> _sendRequest(
    String operation, {
    Uint8List? requestBytes,
    int? cursorId,
    bool allowClosedWorker = false,
  }) {
    if ((_closed || !_healthy) && !allowClosedWorker) {
      throw ConnectionException(_lastError ?? 'Rust worker is unavailable.');
    }
    final requestId = _nextRequestId++;
    final completer = Completer<Map<String, Object?>>();
    _pending[requestId] = completer;
    _commandPort.send(<String, Object?>{
      'id': requestId,
      'op': operation,
      if (requestBytes != null)
        'requestData': TransferableTypedData.fromList(<Uint8List>[
          requestBytes,
        ]),
      'cursorId': ?cursorId,
    });
    return completer.future;
  }

  void _handleResponse(dynamic payload) {
    if (payload is! Map) {
      return;
    }
    final response = Map<String, Object?>.from(payload);
    final requestId = response['id'] as int?;
    if (requestId == null) {
      return;
    }
    final completer = _pending.remove(requestId);
    if (completer == null || completer.isCompleted) {
      return;
    }
    if (response['ok'] == true) {
      completer.complete(response);
      return;
    }
    final message =
        response['error']?.toString() ?? 'Rust worker request failed.';
    final connectionError = response['connectionError'] == true;
    if (connectionError) {
      _healthy = false;
      _lastError = message;
      completer.completeError(ConnectionException(message));
      return;
    }
    completer.completeError(MongoDartError(message));
  }

  Future<void> close() async {
    if (_closed || _closing) {
      return;
    }
    _closing = true;
    try {
      await _sendRequest(
        'close',
        allowClosedWorker: true,
      ).timeout(const Duration(seconds: 1));
    } catch (_) {
      // Best-effort shutdown.
    } finally {
      _markClosed(_lastError ?? 'Rust worker closed.');
      _isolate.kill(priority: Isolate.immediate);
      await _responseSubscription?.cancel();
      await _exitSubscription?.cancel();
      await _errorSubscription?.cancel();
      _responsePort.close();
      _exitPort.close();
      _errorPort.close();
    }
  }

  void _markClosed(String message) {
    if (_closed) {
      return;
    }
    _closed = true;
    _healthy = false;
    _lastError = message;
    final error = ConnectionException(message);
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }
    _pending.clear();
  }
}

@pragma('vm:entry-point')
Future<void> _mongoRustWorkerMain(Map<String, Object?> message) async {
  final readyPort = message['readyPort'] as SendPort;
  final responsePort = message['responsePort'] as SendPort;
  final connectionString = message['connectionString'] as String;
  final databaseName = message['databaseName'] as String;
  final logContext = message['logContext'] as String? ?? 'worker pool';
  final connectTimeoutMs = message['connectTimeoutMs'] as int? ?? 0;
  final serverSelectionTimeoutMs =
      message['serverSelectionTimeoutMs'] as int? ?? 0;

  final bindings = MongoRustBindings.open();
  final commandPort = ReceivePort();
  final cursors = <int, Pointer<RustCursorHandle>>{};
  var nextCursorId = 1;
  Pointer<RustClientHandle> client = Pointer<RustClientHandle>.fromAddress(0);

  try {
    client = _workerClientOpen(
      bindings,
      connectionString: connectionString,
      databaseName: databaseName,
      logContext: logContext,
      connectTimeoutMs: connectTimeoutMs,
      serverSelectionTimeoutMs: serverSelectionTimeoutMs,
    );
    readyPort.send(<String, Object?>{
      'ok': true,
      'commandPort': commandPort.sendPort,
    });

    await for (final dynamic rawMessage in commandPort) {
      if (rawMessage is! Map) {
        continue;
      }
      final request = Map<String, Object?>.from(rawMessage);
      final requestId = request['id'] as int;
      final operation = request['op'] as String;
      try {
        switch (operation) {
          case 'ping':
            _workerPing(bindings, client);
            responsePort.send(<String, Object?>{'id': requestId, 'ok': true});
          case 'runCommand':
            final resultBytes = _workerRunCommand(
              bindings,
              client,
              _materializeRequestBytes(request['requestData']),
            );
            responsePort.send(<String, Object?>{
              'id': requestId,
              'ok': true,
              'resultData': TransferableTypedData.fromList(<Uint8List>[
                resultBytes,
              ]),
            });
          case 'executeCollectionAction':
            final resultBytes = _workerExecuteCollectionAction(
              bindings,
              client,
              _materializeRequestBytes(request['requestData']),
            );
            responsePort.send(<String, Object?>{
              'id': requestId,
              'ok': true,
              'resultData': TransferableTypedData.fromList(<Uint8List>[
                resultBytes,
              ]),
            });
          case 'runCursorCommand':
            final resultBytes = _workerRunCursorCommand(
              bindings,
              client,
              _materializeRequestBytes(request['requestData']),
            );
            responsePort.send(<String, Object?>{
              'id': requestId,
              'ok': true,
              'resultData': TransferableTypedData.fromList(<Uint8List>[
                resultBytes,
              ]),
            });
          case 'findOne':
            final result = _workerFindOne(
              bindings,
              client,
              _materializeRequestBytes(request['requestData']),
            );
            responsePort.send(<String, Object?>{
              'id': requestId,
              'ok': true,
              'found': result != null,
              if (result != null)
                'resultData': TransferableTypedData.fromList(<Uint8List>[
                  result,
                ]),
            });
          case 'findCursorOpen':
            final cursor = _workerOpenFindCursor(
              bindings,
              client,
              _materializeRequestBytes(request['requestData']),
            );
            final cursorId = nextCursorId++;
            cursors[cursorId] = cursor;
            responsePort.send(<String, Object?>{
              'id': requestId,
              'ok': true,
              'cursorId': cursorId,
            });
          case 'aggregateCursorOpen':
            final cursor = _workerOpenAggregateCursor(
              bindings,
              client,
              _materializeRequestBytes(request['requestData']),
            );
            final cursorId = nextCursorId++;
            cursors[cursorId] = cursor;
            responsePort.send(<String, Object?>{
              'id': requestId,
              'ok': true,
              'cursorId': cursorId,
            });
          case 'cursorNextBatch':
            final cursorId = request['cursorId'] as int;
            final cursor = cursors[cursorId];
            if (cursor == null) {
              throw const ConnectionException(
                'Rust worker cursor handle was missing.',
              );
            }
            final result = _workerCursorNextBatch(bindings, cursor);
            if (result.exhausted) {
              final removedCursor = cursors.remove(cursorId);
              if (removedCursor != null) {
                bindings.cursorClose(removedCursor);
              }
            }
            responsePort.send(<String, Object?>{
              'id': requestId,
              'ok': true,
              'exhausted': result.exhausted,
              if (result.bytes != null)
                'resultData': TransferableTypedData.fromList(<Uint8List>[
                  result.bytes!,
                ]),
            });
          case 'cursorClose':
            final cursorId = request['cursorId'] as int;
            final cursor = cursors.remove(cursorId);
            if (cursor != null) {
              bindings.cursorClose(cursor);
            }
            responsePort.send(<String, Object?>{'id': requestId, 'ok': true});
          case 'close':
            responsePort.send(<String, Object?>{'id': requestId, 'ok': true});
            break;
          default:
            throw MongoDartError(
              'Unsupported Rust worker operation: $operation',
            );
        }
        if (operation == 'close') {
          break;
        }
      } catch (error) {
        final message = switch (error) {
          ConnectionException exception => exception.message,
          MongoDartError mongoError => mongoError.message,
          _ => error.toString(),
        };
        responsePort.send(<String, Object?>{
          'id': requestId,
          'ok': false,
          'error': message,
          'connectionError': _isConnectionRelatedErrorMessage(message),
        });
      }
    }
  } catch (error) {
    final message = switch (error) {
      ConnectionException exception => exception.message,
      MongoDartError mongoError => mongoError.message,
      _ => error.toString(),
    };
    readyPort.send(<String, Object?>{'ok': false, 'error': message});
  } finally {
    for (final cursor in cursors.values) {
      bindings.cursorClose(cursor);
    }
    cursors.clear();
    if (client.address != 0) {
      bindings.clientClose(client);
    }
    commandPort.close();
  }
}

final class _WorkerCursorBatchResponse {
  const _WorkerCursorBatchResponse({
    required this.bytes,
    required this.exhausted,
  });

  final Uint8List? bytes;
  final bool exhausted;
}

Pointer<RustClientHandle> _workerClientOpen(
  MongoRustBindings bindings, {
  required String connectionString,
  required String databaseName,
  required String logContext,
  required int connectTimeoutMs,
  required int serverSelectionTimeoutMs,
}) {
  return pkg_ffi.using((arena) {
    final errorOut = arena<Pointer<pkg_ffi.Utf8>>()
      ..value = Pointer<pkg_ffi.Utf8>.fromAddress(0);
    final client = bindings.clientOpen(
      connectionString.toNativeUtf8(allocator: arena),
      databaseName.toNativeUtf8(allocator: arena),
      logContext.toNativeUtf8(allocator: arena),
      connectTimeoutMs,
      serverSelectionTimeoutMs,
      errorOut,
    );
    _workerThrowIfRustError(bindings, errorOut.value);
    if (client.address == 0) {
      throw const ConnectionException(
        'Rust backend returned a null client handle.',
      );
    }
    return client;
  });
}

void _workerPing(MongoRustBindings bindings, Pointer<RustClientHandle> client) {
  pkg_ffi.using((arena) {
    final errorOut = arena<Pointer<pkg_ffi.Utf8>>()
      ..value = Pointer<pkg_ffi.Utf8>.fromAddress(0);
    final ok = bindings.clientPing(client, errorOut);
    _workerThrowIfRustError(bindings, errorOut.value);
    if (ok == 0) {
      throw const ConnectionException('Rust backend ping failed.');
    }
  });
}

Uint8List _workerRunCommand(
  MongoRustBindings bindings,
  Pointer<RustClientHandle> client,
  Uint8List requestBytes,
) {
  return pkg_ffi.using((arena) {
    final requestPtr = arena<Uint8>(requestBytes.length);
    requestPtr.asTypedList(requestBytes.length).setAll(0, requestBytes);
    final resultBytesOut = arena<Pointer<Uint8>>()
      ..value = Pointer<Uint8>.fromAddress(0);
    final resultLengthOut = arena<Int32>()..value = 0;
    final errorOut = arena<Pointer<pkg_ffi.Utf8>>()
      ..value = Pointer<pkg_ffi.Utf8>.fromAddress(0);

    final ok = bindings.clientRunCommandBson(
      client,
      requestPtr,
      requestBytes.length,
      resultBytesOut,
      resultLengthOut,
      errorOut,
    );
    _workerThrowIfRustError(bindings, errorOut.value);
    if (ok == 0) {
      throw const ConnectionException('Rust backend command failed.');
    }
    return _copyNativeBytes(
      bindings,
      resultBytesOut.value,
      resultLengthOut.value,
    );
  });
}

Uint8List _workerExecuteCollectionAction(
  MongoRustBindings bindings,
  Pointer<RustClientHandle> client,
  Uint8List requestBytes,
) {
  return pkg_ffi.using((arena) {
    final requestPtr = arena<Uint8>(requestBytes.length);
    requestPtr.asTypedList(requestBytes.length).setAll(0, requestBytes);
    final resultBytesOut = arena<Pointer<Uint8>>()
      ..value = Pointer<Uint8>.fromAddress(0);
    final resultLengthOut = arena<Int32>()..value = 0;
    final errorOut = arena<Pointer<pkg_ffi.Utf8>>()
      ..value = Pointer<pkg_ffi.Utf8>.fromAddress(0);

    final ok = bindings.clientExecuteCollectionActionBson(
      client,
      requestPtr,
      requestBytes.length,
      resultBytesOut,
      resultLengthOut,
      errorOut,
    );
    _workerThrowIfRustError(bindings, errorOut.value);
    if (ok == 0) {
      throw const ConnectionException('Rust backend collection action failed.');
    }
    return _copyNativeBytes(
      bindings,
      resultBytesOut.value,
      resultLengthOut.value,
    );
  });
}

Uint8List _workerRunCursorCommand(
  MongoRustBindings bindings,
  Pointer<RustClientHandle> client,
  Uint8List requestBytes,
) {
  return pkg_ffi.using((arena) {
    final requestPtr = arena<Uint8>(requestBytes.length);
    requestPtr.asTypedList(requestBytes.length).setAll(0, requestBytes);
    final resultBytesOut = arena<Pointer<Uint8>>()
      ..value = Pointer<Uint8>.fromAddress(0);
    final resultLengthOut = arena<Int32>()..value = 0;
    final errorOut = arena<Pointer<pkg_ffi.Utf8>>()
      ..value = Pointer<pkg_ffi.Utf8>.fromAddress(0);

    final ok = bindings.clientRunCursorCommandBson(
      client,
      requestPtr,
      requestBytes.length,
      resultBytesOut,
      resultLengthOut,
      errorOut,
    );
    _workerThrowIfRustError(bindings, errorOut.value);
    if (ok == 0) {
      throw const ConnectionException('Rust backend cursor command failed.');
    }
    return _copyNativeBytes(
      bindings,
      resultBytesOut.value,
      resultLengthOut.value,
    );
  });
}

Uint8List? _workerFindOne(
  MongoRustBindings bindings,
  Pointer<RustClientHandle> client,
  Uint8List requestBytes,
) {
  return pkg_ffi.using((arena) {
    final requestPtr = arena<Uint8>(requestBytes.length);
    requestPtr.asTypedList(requestBytes.length).setAll(0, requestBytes);
    final resultBytesOut = arena<Pointer<Uint8>>()
      ..value = Pointer<Uint8>.fromAddress(0);
    final resultLengthOut = arena<Int32>()..value = 0;
    final foundOut = arena<Uint8>()..value = 0;
    final errorOut = arena<Pointer<pkg_ffi.Utf8>>()
      ..value = Pointer<pkg_ffi.Utf8>.fromAddress(0);

    final ok = bindings.clientFindOneBson(
      client,
      requestPtr,
      requestBytes.length,
      resultBytesOut,
      resultLengthOut,
      foundOut,
      errorOut,
    );
    _workerThrowIfRustError(bindings, errorOut.value);
    if (ok == 0) {
      throw const ConnectionException('Rust backend findOne failed.');
    }
    if (foundOut.value == 0) {
      return null;
    }
    return _copyNativeBytes(
      bindings,
      resultBytesOut.value,
      resultLengthOut.value,
    );
  });
}

Pointer<RustCursorHandle> _workerOpenFindCursor(
  MongoRustBindings bindings,
  Pointer<RustClientHandle> client,
  Uint8List requestBytes,
) {
  return pkg_ffi.using((arena) {
    final requestPtr = arena<Uint8>(requestBytes.length);
    requestPtr.asTypedList(requestBytes.length).setAll(0, requestBytes);
    final errorOut = arena<Pointer<pkg_ffi.Utf8>>()
      ..value = Pointer<pkg_ffi.Utf8>.fromAddress(0);

    final cursor = bindings.clientFindCursorOpenBson(
      client,
      requestPtr,
      requestBytes.length,
      errorOut,
    );
    _workerThrowIfRustError(bindings, errorOut.value);
    if (cursor.address == 0) {
      throw const ConnectionException('Rust backend cursor open failed.');
    }
    return cursor;
  });
}

Pointer<RustCursorHandle> _workerOpenAggregateCursor(
  MongoRustBindings bindings,
  Pointer<RustClientHandle> client,
  Uint8List requestBytes,
) {
  return pkg_ffi.using((arena) {
    final requestPtr = arena<Uint8>(requestBytes.length);
    requestPtr.asTypedList(requestBytes.length).setAll(0, requestBytes);
    final errorOut = arena<Pointer<pkg_ffi.Utf8>>()
      ..value = Pointer<pkg_ffi.Utf8>.fromAddress(0);

    final cursor = bindings.clientAggregateCursorOpenBson(
      client,
      requestPtr,
      requestBytes.length,
      errorOut,
    );
    _workerThrowIfRustError(bindings, errorOut.value);
    if (cursor.address == 0) {
      throw const ConnectionException('Rust backend cursor open failed.');
    }
    return cursor;
  });
}

_WorkerCursorBatchResponse _workerCursorNextBatch(
  MongoRustBindings bindings,
  Pointer<RustCursorHandle> cursor,
) {
  return pkg_ffi.using((arena) {
    final resultBytesOut = arena<Pointer<Uint8>>()
      ..value = Pointer<Uint8>.fromAddress(0);
    final resultLengthOut = arena<Int32>()..value = 0;
    final exhaustedOut = arena<Uint8>()..value = 0;
    final errorOut = arena<Pointer<pkg_ffi.Utf8>>()
      ..value = Pointer<pkg_ffi.Utf8>.fromAddress(0);

    final ok = bindings.cursorNextBatchBson(
      cursor,
      resultBytesOut,
      resultLengthOut,
      exhaustedOut,
      errorOut,
    );
    _workerThrowIfRustError(bindings, errorOut.value);
    if (ok == 0) {
      throw const ConnectionException('Rust backend cursor batch failed.');
    }
    final resultBytes = _copyNativeBytes(
      bindings,
      resultBytesOut.value,
      resultLengthOut.value,
    );
    return _WorkerCursorBatchResponse(
      bytes: resultBytes.isEmpty ? null : resultBytes,
      exhausted: exhaustedOut.value != 0,
    );
  });
}

Uint8List _copyNativeBytes(
  MongoRustBindings bindings,
  Pointer<Uint8> resultPtr,
  int resultLength,
) {
  if (resultPtr.address == 0 || resultLength <= 0) {
    return Uint8List(0);
  }
  final bytes = Uint8List.fromList(resultPtr.asTypedList(resultLength));
  bindings.bytesFree(resultPtr, resultLength);
  return bytes;
}

Uint8List _materializeRequestBytes(Object? payload) {
  if (payload is! TransferableTypedData) {
    return Uint8List(0);
  }
  return payload.materialize().asUint8List();
}

void _workerThrowIfRustError(
  MongoRustBindings bindings,
  Pointer<pkg_ffi.Utf8> errorPtr,
) {
  if (errorPtr.address == 0) {
    return;
  }
  final message = errorPtr.toDartString();
  bindings.stringFree(errorPtr);
  if (_isConnectionRelatedErrorMessage(message)) {
    throw ConnectionException(message);
  }
  throw MongoDartError(message);
}

bool _isConnectionRelatedErrorMessage(String message) {
  final normalized = message.toUpperCase();
  return normalized.contains('SERVER SELECTION') ||
      normalized.contains('NO SUITABLE SERVERS') ||
      normalized.contains('CONNECTION REFUSED') ||
      normalized.contains('POOL CLEARED') ||
      normalized.contains('NETWORK') ||
      normalized.contains('TIMEOUT') ||
      normalized.contains('TIMED OUT') ||
      normalized.contains('TOPOLOGY') ||
      normalized.contains('BROKEN PIPE') ||
      normalized.contains('CONNECTION CLOSED') ||
      normalized.contains('EOF') ||
      normalized.contains('NOT MASTER') ||
      normalized.contains('PRIMARY STEPPED DOWN') ||
      normalized.contains('SOCKET') ||
      normalized.contains('AUTHENTICATION REQUIRED');
}

bool _isRetryableWorkerStartupError(Object error) {
  if (error is! ConnectionException) {
    return false;
  }

  final message = error.message;
  if (RecoverableErrorClassifier.isAuthenticationRequiredMessage(message)) {
    return false;
  }

  if (RecoverableErrorClassifier.isPrimaryRoutingFailureMessage(message) ||
      RecoverableErrorClassifier.isConnectionLifecycleFailureMessage(message)) {
    return true;
  }

  final normalized = message.toUpperCase();
  return normalized.contains('TIMED OUT') ||
      normalized.contains('TIMEOUT') ||
      normalized.contains('I/O ERROR') ||
      normalized.contains('SERVER SELECTION') ||
      normalized.contains('NO SUITABLE SERVERS') ||
      normalized.contains('POOL CLEARED') ||
      normalized.contains('RETRYABLEWRITEERROR') ||
      normalized.contains('NETWORK');
}

Duration _workerStartupRetryDelay(int completedAttempt) {
  final attempt = completedAttempt < 1 ? 1 : completedAttempt;
  return Duration(milliseconds: 250 * attempt);
}

import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'mongoc_bindings.dart';
import 'mongoc_exception.dart';
import 'native/bundled_library.dart';

final class MongocClient {
  MongocClient._(this._isolate, this._sendPort);

  final Isolate _isolate;
  final SendPort _sendPort;
  var _closed = false;

  static Future<MongocClient> connect(
    String uri, {
    String? nativeLibraryPath,
  }) async {
    final dylibPath = nativeLibraryPath ??
        Platform.environment['MONGO_DOCUMENT_DB_MONGOC_LIB'] ??
        await BundledMongocLibrary.resolveBundledLibraryPath();

    final readyPort = ReceivePort();
    final isolate = await Isolate.spawn<_MongocIsolateInit>(
      _mongocIsolateMain,
      _MongocIsolateInit(
        readyPort.sendPort,
        dylibPath,
        uri,
      ),
      debugName: 'mongo_document_db_mongoc',
    );

    final first = await readyPort.first;
    readyPort.close();

    if (first is _MongocIsolateReady) {
      return MongocClient._(isolate, first.sendPort);
    }

    isolate.kill(priority: Isolate.immediate);
    if (first is _MongocIsolateError) {
      throw MongocException(first.message);
    }
    throw StateError('Unexpected isolate init message: $first');
  }

  Future<String> ping() => _call<String>(_MongocOp.ping);

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _call<void>(_MongocOp.close);
    _isolate.kill(priority: Isolate.immediate);
  }

  Future<T> _call<T>(_MongocOp op) async {
    if (_closed && op != _MongocOp.close) {
      throw StateError('Client already closed');
    }

    final rp = ReceivePort();
    _sendPort.send(_MongocRequest(op, rp.sendPort));
    final msg = await rp.first;
    rp.close();

    if (msg is _MongocResponseOk) return msg.value as T;
    if (msg is _MongocResponseError) throw MongocException(msg.message);
    throw StateError('Unexpected response: $msg');
  }
}

enum _MongocOp { ping, close }

final class _MongocIsolateInit {
  const _MongocIsolateInit(
    this.readyPort,
    this.nativeLibraryPath,
    this.uri,
  );
  final SendPort readyPort;
  final String nativeLibraryPath;
  final String uri;
}

final class _MongocIsolateReady {
  const _MongocIsolateReady(this.sendPort);
  final SendPort sendPort;
}

final class _MongocIsolateError {
  const _MongocIsolateError(this.message);
  final String message;
}

final class _MongocRequest {
  const _MongocRequest(this.op, this.replyTo);
  final _MongocOp op;
  final SendPort replyTo;
}

sealed class _MongocResponse {
  const _MongocResponse();
}

final class _MongocResponseOk extends _MongocResponse {
  const _MongocResponseOk(this.value);
  final Object? value;
}

final class _MongocResponseError extends _MongocResponse {
  const _MongocResponseError(this.message);
  final String message;
}

void _mongocIsolateMain(_MongocIsolateInit init) {
  final lib = DynamicLibrary.open(init.nativeLibraryPath);
  final bindings = MongocBindings(lib);
  bindings.init();

  final errorOut = calloc<Pointer<Utf8>>();
  try {
    final uriUtf8 = init.uri.toNativeUtf8();
    final client = bindings.clientNew(uriUtf8, errorOut);
    malloc.free(uriUtf8);
    if (client == nullptr) {
      final message = _takeCString(bindings, errorOut.value) ??
          'mongoc_client_new returned null';
      init.readyPort.send(_MongocIsolateError(message));
      return;
    }

    final commandPort = ReceivePort();
    init.readyPort.send(_MongocIsolateReady(commandPort.sendPort));

    commandPort.listen((message) {
      if (message is! _MongocRequest) return;

      try {
        switch (message.op) {
          case _MongocOp.ping:
            final replyJsonOut = calloc<Pointer<Utf8>>();
            final errorOut = calloc<Pointer<Utf8>>();
            try {
              final ok = bindings.ping(client, replyJsonOut, errorOut) == 1;
              if (!ok) {
                final err = _takeCString(bindings, errorOut.value) ??
                    'ping failed (unknown error)';
                message.replyTo.send(_MongocResponseError(err));
                return;
              }

              final reply = _takeCString(bindings, replyJsonOut.value) ?? '{}';
              message.replyTo.send(_MongocResponseOk(reply));
            } finally {
              calloc.free(replyJsonOut);
              calloc.free(errorOut);
            }
            break;
          case _MongocOp.close:
            bindings.clientDestroy(client);
            bindings.cleanup();
            message.replyTo.send(const _MongocResponseOk(null));
            commandPort.close();
            break;
        }
      } catch (e) {
        message.replyTo.send(_MongocResponseError(e.toString()));
      }
    });
  } finally {
    calloc.free(errorOut);
  }
}

String? _takeCString(MongocBindings bindings, Pointer<Utf8> cString) {
  if (cString == nullptr) return null;
  try {
    return cString.toDartString();
  } finally {
    bindings.stringFree(cString);
  }
}

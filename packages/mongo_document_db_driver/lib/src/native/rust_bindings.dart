import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'rust_library.dart';

final class RustClientHandle extends Opaque {}
final class RustCursorHandle extends Opaque {}

typedef _RustAbiVersionNative = Int32 Function();
typedef _RustAbiVersionDart = int Function();

typedef _RustClientOpenNative =
    Pointer<RustClientHandle> Function(
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
      Int64,
      Int64,
      Pointer<Pointer<Utf8>>,
    );
typedef _RustClientOpenDart =
    Pointer<RustClientHandle> Function(
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
      int,
      int,
      Pointer<Pointer<Utf8>>,
    );

typedef _RustClientCloseNative = Void Function(Pointer<RustClientHandle>);
typedef _RustClientCloseDart = void Function(Pointer<RustClientHandle>);

typedef _RustClientPingNative =
    Uint8 Function(Pointer<RustClientHandle>, Pointer<Pointer<Utf8>>);
typedef _RustClientPingDart =
    int Function(Pointer<RustClientHandle>, Pointer<Pointer<Utf8>>);

typedef _RustClientRunBsonNative =
    Uint8 Function(
      Pointer<RustClientHandle>,
      Pointer<Uint8>,
      Int32,
      Pointer<Pointer<Uint8>>,
      Pointer<Int32>,
      Pointer<Pointer<Utf8>>,
    );
typedef _RustClientRunBsonDart =
    int Function(
      Pointer<RustClientHandle>,
      Pointer<Uint8>,
      int,
      Pointer<Pointer<Uint8>>,
      Pointer<Int32>,
      Pointer<Pointer<Utf8>>,
    );

typedef _RustClientCollectionActionBsonNative =
    Uint8 Function(
      Pointer<RustClientHandle>,
      Pointer<Uint8>,
      Int32,
      Pointer<Pointer<Uint8>>,
      Pointer<Int32>,
      Pointer<Pointer<Utf8>>,
    );
typedef _RustClientCollectionActionBsonDart =
    int Function(
      Pointer<RustClientHandle>,
      Pointer<Uint8>,
      int,
      Pointer<Pointer<Uint8>>,
      Pointer<Int32>,
      Pointer<Pointer<Utf8>>,
    );

typedef _RustClientFindOneBsonNative =
    Uint8 Function(
      Pointer<RustClientHandle>,
      Pointer<Uint8>,
      Int32,
      Pointer<Pointer<Uint8>>,
      Pointer<Int32>,
      Pointer<Uint8>,
      Pointer<Pointer<Utf8>>,
    );
typedef _RustClientFindOneBsonDart =
    int Function(
      Pointer<RustClientHandle>,
      Pointer<Uint8>,
      int,
      Pointer<Pointer<Uint8>>,
      Pointer<Int32>,
      Pointer<Uint8>,
      Pointer<Pointer<Utf8>>,
    );

typedef _RustClientOpenCursorBsonNative =
    Pointer<RustCursorHandle> Function(
      Pointer<RustClientHandle>,
      Pointer<Uint8>,
      Int32,
      Pointer<Pointer<Utf8>>,
    );
typedef _RustClientOpenCursorBsonDart =
    Pointer<RustCursorHandle> Function(
      Pointer<RustClientHandle>,
      Pointer<Uint8>,
      int,
      Pointer<Pointer<Utf8>>,
    );

typedef _RustCursorNextBatchBsonNative =
    Uint8 Function(
      Pointer<RustCursorHandle>,
      Pointer<Pointer<Uint8>>,
      Pointer<Int32>,
      Pointer<Uint8>,
      Pointer<Pointer<Utf8>>,
    );
typedef _RustCursorNextBatchBsonDart =
    int Function(
      Pointer<RustCursorHandle>,
      Pointer<Pointer<Uint8>>,
      Pointer<Int32>,
      Pointer<Uint8>,
      Pointer<Pointer<Utf8>>,
    );

typedef _RustCursorCloseNative = Void Function(Pointer<RustCursorHandle>);
typedef _RustCursorCloseDart = void Function(Pointer<RustCursorHandle>);

typedef _RustStringFreeNative = Void Function(Pointer<Utf8>);
typedef _RustStringFreeDart = void Function(Pointer<Utf8>);

typedef _RustBytesFreeNative = Void Function(Pointer<Uint8>, Int32);
typedef _RustBytesFreeDart = void Function(Pointer<Uint8>, int);

class MongoRustBindings {
  static const currentAbiVersion = 3;
  static MongoRustBindings? _defaultInstance;

  final DynamicLibrary library;
  final int Function() abiVersion;
  final Pointer<RustClientHandle> Function(
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    int,
    int,
    Pointer<Pointer<Utf8>>
  )
  clientOpen;
  final void Function(Pointer<RustClientHandle>) clientClose;
  final int Function(Pointer<RustClientHandle>, Pointer<Pointer<Utf8>>) clientPing;
  final int Function(
    Pointer<RustClientHandle>,
    Pointer<Uint8>,
    int,
    Pointer<Pointer<Uint8>>,
    Pointer<Int32>,
    Pointer<Pointer<Utf8>>
  )
  clientRunCommandBson;
  final int Function(
    Pointer<RustClientHandle>,
    Pointer<Uint8>,
    int,
    Pointer<Pointer<Uint8>>,
    Pointer<Int32>,
    Pointer<Pointer<Utf8>>
  )
  clientExecuteCollectionActionBson;
  final int Function(
    Pointer<RustClientHandle>,
    Pointer<Uint8>,
    int,
    Pointer<Pointer<Uint8>>,
    Pointer<Int32>,
    Pointer<Pointer<Utf8>>
  )
  clientRunCursorCommandBson;
  final int Function(
    Pointer<RustClientHandle>,
    Pointer<Uint8>,
    int,
    Pointer<Pointer<Uint8>>,
    Pointer<Int32>,
    Pointer<Uint8>,
    Pointer<Pointer<Utf8>>
  )
  clientFindOneBson;
  final Pointer<RustCursorHandle> Function(
    Pointer<RustClientHandle>,
    Pointer<Uint8>,
    int,
    Pointer<Pointer<Utf8>>
  )
  clientFindCursorOpenBson;
  final Pointer<RustCursorHandle> Function(
    Pointer<RustClientHandle>,
    Pointer<Uint8>,
    int,
    Pointer<Pointer<Utf8>>
  )
  clientAggregateCursorOpenBson;
  final int Function(
    Pointer<RustClientHandle>,
    Pointer<Uint8>,
    int,
    Pointer<Pointer<Uint8>>,
    Pointer<Int32>,
    Pointer<Pointer<Utf8>>
  )
  clientAggregateBson;
  final int Function(
    Pointer<RustCursorHandle>,
    Pointer<Pointer<Uint8>>,
    Pointer<Int32>,
    Pointer<Uint8>,
    Pointer<Pointer<Utf8>>
  )
  cursorNextBatchBson;
  final void Function(Pointer<RustCursorHandle>) cursorClose;
  final void Function(Pointer<Utf8>) stringFree;
  final void Function(Pointer<Uint8>, int) bytesFree;

  MongoRustBindings._(
    this.library, {
    required this.abiVersion,
    required this.clientOpen,
    required this.clientClose,
    required this.clientPing,
    required this.clientRunCommandBson,
    required this.clientExecuteCollectionActionBson,
    required this.clientRunCursorCommandBson,
    required this.clientFindOneBson,
    required this.clientFindCursorOpenBson,
    required this.clientAggregateCursorOpenBson,
    required this.clientAggregateBson,
    required this.cursorNextBatchBson,
    required this.cursorClose,
    required this.stringFree,
    required this.bytesFree,
  });

  static MongoRustBindings get defaultInstance =>
      _defaultInstance ??= MongoRustBindings.open();

  factory MongoRustBindings.open({
    String? libraryPath,
    String? packageRoot,
    Abi? abi,
  }) {
    final library = MongoRustLibrary.open(
      libraryPath: libraryPath,
      packageRoot: packageRoot,
      abi: abi,
    );
    return MongoRustBindings._(
      library,
      abiVersion: library.lookupFunction<_RustAbiVersionNative, _RustAbiVersionDart>(
        'mdd_rust_abi_version',
      ),
      clientOpen:
          library.lookupFunction<_RustClientOpenNative, _RustClientOpenDart>(
            'mdd_rust_client_open',
          ),
      clientClose:
          library.lookupFunction<_RustClientCloseNative, _RustClientCloseDart>(
            'mdd_rust_client_close',
          ),
      clientPing:
          library.lookupFunction<_RustClientPingNative, _RustClientPingDart>(
            'mdd_rust_client_ping',
          ),
      clientRunCommandBson:
          library.lookupFunction<_RustClientRunBsonNative, _RustClientRunBsonDart>(
            'mdd_rust_client_run_command_bson',
          ),
      clientExecuteCollectionActionBson:
          library.lookupFunction<
            _RustClientCollectionActionBsonNative,
            _RustClientCollectionActionBsonDart
          >(
            'mdd_rust_client_execute_collection_action_bson',
          ),
      clientRunCursorCommandBson:
          library.lookupFunction<_RustClientRunBsonNative, _RustClientRunBsonDart>(
            'mdd_rust_client_run_cursor_command_bson',
          ),
      clientFindOneBson:
          library.lookupFunction<
            _RustClientFindOneBsonNative,
            _RustClientFindOneBsonDart
          >(
            'mdd_rust_client_find_one_bson',
          ),
      clientFindCursorOpenBson:
          library.lookupFunction<
            _RustClientOpenCursorBsonNative,
            _RustClientOpenCursorBsonDart
          >(
            'mdd_rust_client_find_cursor_open_bson',
          ),
      clientAggregateCursorOpenBson:
          library.lookupFunction<
            _RustClientOpenCursorBsonNative,
            _RustClientOpenCursorBsonDart
          >(
            'mdd_rust_client_aggregate_cursor_open_bson',
          ),
      clientAggregateBson:
          library.lookupFunction<_RustClientRunBsonNative, _RustClientRunBsonDart>(
            'mdd_rust_client_aggregate_bson',
          ),
      cursorNextBatchBson:
          library.lookupFunction<
            _RustCursorNextBatchBsonNative,
            _RustCursorNextBatchBsonDart
          >(
            'mdd_rust_cursor_next_batch_bson',
          ),
      cursorClose:
          library.lookupFunction<_RustCursorCloseNative, _RustCursorCloseDart>(
            'mdd_rust_cursor_close',
          ),
      stringFree:
          library.lookupFunction<_RustStringFreeNative, _RustStringFreeDart>(
            'mdd_rust_string_free',
          ),
      bytesFree:
          library.lookupFunction<_RustBytesFreeNative, _RustBytesFreeDart>(
            'mdd_rust_bytes_free',
          ),
    );
  }

  static bool isAvailable({
    String? libraryPath,
    String? packageRoot,
    Abi? abi,
  }) {
    try {
      return MongoRustBindings.open(
            libraryPath: libraryPath,
            packageRoot: packageRoot,
            abi: abi,
          ).abiVersion() ==
          currentAbiVersion;
    } catch (_) {
      return false;
    }
  }
}

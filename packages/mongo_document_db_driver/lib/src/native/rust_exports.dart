@DefaultAsset('package:mongo_document_db_driver/src/native/rust_exports.dart')
library;

import 'dart:ffi';

import 'package:ffi/ffi.dart';

final class RustClientHandle extends Opaque {}
final class RustCursorHandle extends Opaque {}

@Native<Int32 Function()>(symbol: 'mdd_rust_abi_version')
external int mddRustAbiVersion();

@Native<Void Function(Pointer<Utf8>)>(symbol: 'mdd_rust_string_free')
external void mddRustStringFree(Pointer<Utf8> value);

@Native<Void Function(Pointer<Uint8>, Int32)>(symbol: 'mdd_rust_bytes_free')
external void mddRustBytesFree(Pointer<Uint8> value, int length);

@Native<
  Pointer<RustClientHandle> Function(
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Int64,
    Int64,
    Pointer<Pointer<Utf8>>,
  )
>(symbol: 'mdd_rust_client_open')
external Pointer<RustClientHandle> mddRustClientOpen(
  Pointer<Utf8> uri,
  Pointer<Utf8> databaseName,
  Pointer<Utf8> logContext,
  int connectTimeoutMs,
  int serverSelectionTimeoutMs,
  Pointer<Pointer<Utf8>> errorOut,
);

@Native<Void Function(Pointer<RustClientHandle>)>(symbol: 'mdd_rust_client_close')
external void mddRustClientClose(Pointer<RustClientHandle> client);

@Native<
  Uint8 Function(Pointer<RustClientHandle>, Pointer<Pointer<Utf8>>)
>(symbol: 'mdd_rust_client_ping')
external int mddRustClientPing(
  Pointer<RustClientHandle> client,
  Pointer<Pointer<Utf8>> errorOut,
);

@Native<
  Uint8 Function(
    Pointer<RustClientHandle>,
    Pointer<Uint8>,
    Int32,
    Pointer<Pointer<Uint8>>,
    Pointer<Int32>,
    Pointer<Pointer<Utf8>>,
  )
>(symbol: 'mdd_rust_client_run_command_bson')
external int mddRustClientRunCommandBson(
  Pointer<RustClientHandle> client,
  Pointer<Uint8> requestBytes,
  int requestLength,
  Pointer<Pointer<Uint8>> resultBytesOut,
  Pointer<Int32> resultLengthOut,
  Pointer<Pointer<Utf8>> errorOut,
);

@Native<
  Uint8 Function(
    Pointer<RustClientHandle>,
    Pointer<Uint8>,
    Int32,
    Pointer<Pointer<Uint8>>,
    Pointer<Int32>,
    Pointer<Pointer<Utf8>>,
  )
>(symbol: 'mdd_rust_client_execute_collection_action_bson')
external int mddRustClientExecuteCollectionActionBson(
  Pointer<RustClientHandle> client,
  Pointer<Uint8> requestBytes,
  int requestLength,
  Pointer<Pointer<Uint8>> resultBytesOut,
  Pointer<Int32> resultLengthOut,
  Pointer<Pointer<Utf8>> errorOut,
);

@Native<
  Uint8 Function(
    Pointer<RustClientHandle>,
    Pointer<Uint8>,
    Int32,
    Pointer<Pointer<Uint8>>,
    Pointer<Int32>,
    Pointer<Pointer<Utf8>>,
  )
>(symbol: 'mdd_rust_client_run_cursor_command_bson')
external int mddRustClientRunCursorCommandBson(
  Pointer<RustClientHandle> client,
  Pointer<Uint8> requestBytes,
  int requestLength,
  Pointer<Pointer<Uint8>> resultBytesOut,
  Pointer<Int32> resultLengthOut,
  Pointer<Pointer<Utf8>> errorOut,
);

@Native<
  Uint8 Function(
    Pointer<RustClientHandle>,
    Pointer<Uint8>,
    Int32,
    Pointer<Pointer<Uint8>>,
    Pointer<Int32>,
    Pointer<Uint8>,
    Pointer<Pointer<Utf8>>,
  )
>(symbol: 'mdd_rust_client_find_one_bson')
external int mddRustClientFindOneBson(
  Pointer<RustClientHandle> client,
  Pointer<Uint8> requestBytes,
  int requestLength,
  Pointer<Pointer<Uint8>> resultBytesOut,
  Pointer<Int32> resultLengthOut,
  Pointer<Uint8> foundOut,
  Pointer<Pointer<Utf8>> errorOut,
);

@Native<
  Pointer<RustCursorHandle> Function(
    Pointer<RustClientHandle>,
    Pointer<Uint8>,
    Int32,
    Pointer<Pointer<Utf8>>,
  )
>(symbol: 'mdd_rust_client_find_cursor_open_bson')
external Pointer<RustCursorHandle> mddRustClientFindCursorOpenBson(
  Pointer<RustClientHandle> client,
  Pointer<Uint8> requestBytes,
  int requestLength,
  Pointer<Pointer<Utf8>> errorOut,
);

@Native<
  Pointer<RustCursorHandle> Function(
    Pointer<RustClientHandle>,
    Pointer<Uint8>,
    Int32,
    Pointer<Pointer<Utf8>>,
  )
>(symbol: 'mdd_rust_client_aggregate_cursor_open_bson')
external Pointer<RustCursorHandle> mddRustClientAggregateCursorOpenBson(
  Pointer<RustClientHandle> client,
  Pointer<Uint8> requestBytes,
  int requestLength,
  Pointer<Pointer<Utf8>> errorOut,
);

@Native<
  Uint8 Function(
    Pointer<RustClientHandle>,
    Pointer<Uint8>,
    Int32,
    Pointer<Pointer<Uint8>>,
    Pointer<Int32>,
    Pointer<Pointer<Utf8>>,
  )
>(symbol: 'mdd_rust_client_aggregate_bson')
external int mddRustClientAggregateBson(
  Pointer<RustClientHandle> client,
  Pointer<Uint8> requestBytes,
  int requestLength,
  Pointer<Pointer<Uint8>> resultBytesOut,
  Pointer<Int32> resultLengthOut,
  Pointer<Pointer<Utf8>> errorOut,
);

@Native<
  Uint8 Function(
    Pointer<RustCursorHandle>,
    Pointer<Pointer<Uint8>>,
    Pointer<Int32>,
    Pointer<Uint8>,
    Pointer<Pointer<Utf8>>,
  )
>(symbol: 'mdd_rust_cursor_next_batch_bson')
external int mddRustCursorNextBatchBson(
  Pointer<RustCursorHandle> cursor,
  Pointer<Pointer<Uint8>> resultBytesOut,
  Pointer<Int32> resultLengthOut,
  Pointer<Uint8> exhaustedOut,
  Pointer<Pointer<Utf8>> errorOut,
);

@Native<Void Function(Pointer<RustCursorHandle>)>(symbol: 'mdd_rust_cursor_close')
external void mddRustCursorClose(Pointer<RustCursorHandle> cursor);

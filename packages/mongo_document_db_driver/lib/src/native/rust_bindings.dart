import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'rust_exports.dart';

export 'rust_exports.dart' show RustClientHandle, RustCursorHandle;

class MongoRustBindings {
  static const currentAbiVersion = 3;
  static MongoRustBindings? _defaultInstance;

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

  MongoRustBindings._({
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

  factory MongoRustBindings.open() {
    final instance = MongoRustBindings._(
      abiVersion: mddRustAbiVersion,
      clientOpen: mddRustClientOpen,
      clientClose: mddRustClientClose,
      clientPing: mddRustClientPing,
      clientRunCommandBson: mddRustClientRunCommandBson,
      clientExecuteCollectionActionBson: mddRustClientExecuteCollectionActionBson,
      clientRunCursorCommandBson: mddRustClientRunCursorCommandBson,
      clientFindOneBson: mddRustClientFindOneBson,
      clientFindCursorOpenBson: mddRustClientFindCursorOpenBson,
      clientAggregateCursorOpenBson: mddRustClientAggregateCursorOpenBson,
      clientAggregateBson: mddRustClientAggregateBson,
      cursorNextBatchBson: mddRustCursorNextBatchBson,
      cursorClose: mddRustCursorClose,
      stringFree: mddRustStringFree,
      bytesFree: mddRustBytesFree,
    );

    final abiVersion = instance.abiVersion();
    if (abiVersion != currentAbiVersion) {
      throw StateError(
        'Rust runtime ABI mismatch. Expected $currentAbiVersion, found $abiVersion.',
      );
    }
    return instance;
  }

  static bool isAvailable() {
    try {
      return MongoRustBindings.open().abiVersion() == currentAbiVersion;
    } catch (_) {
      return false;
    }
  }
}

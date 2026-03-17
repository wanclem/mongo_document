import 'dart:ffi';

import 'package:ffi/ffi.dart';

final class MongocBindings {
  MongocBindings(DynamicLibrary lib)
      : init = lib.lookupFunction<Int32 Function(), int Function()>(
          'mdd_mongoc_init',
        ),
        cleanup = lib.lookupFunction<Void Function(), void Function()>(
          'mdd_mongoc_cleanup',
        ),
        clientNew = lib.lookupFunction<
            Pointer<Void> Function(Pointer<Utf8>, Pointer<Pointer<Utf8>>),
            Pointer<Void> Function(
          Pointer<Utf8>,
          Pointer<Pointer<Utf8>>,
        )>('mdd_mongoc_client_new'),
        clientDestroy = lib.lookupFunction<Void Function(Pointer<Void>),
            void Function(Pointer<Void>)>('mdd_mongoc_client_destroy'),
        ping = lib.lookupFunction<
            Int32 Function(
              Pointer<Void>,
              Pointer<Pointer<Utf8>>,
              Pointer<Pointer<Utf8>>,
            ),
            int Function(
              Pointer<Void>,
              Pointer<Pointer<Utf8>>,
              Pointer<Pointer<Utf8>>,
            )>('mdd_mongoc_ping'),
        stringFree = lib.lookupFunction<Void Function(Pointer<Utf8>),
            void Function(Pointer<Utf8>)>('mdd_mongoc_string_free');

  final int Function() init;
  final void Function() cleanup;

  final Pointer<Void> Function(
    Pointer<Utf8> uri,
    Pointer<Pointer<Utf8>> errorOut,
  ) clientNew;
  final void Function(Pointer<Void> client) clientDestroy;

  final int Function(
    Pointer<Void> client,
    Pointer<Pointer<Utf8>> replyJsonOut,
    Pointer<Pointer<Utf8>> errorOut,
  ) ping;

  final void Function(Pointer<Utf8> s) stringFree;
}

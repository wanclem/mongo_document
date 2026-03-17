# mongo_document_db_mongoc

Server-side MongoDB driver experiment for Dart that calls the official MongoDB C Driver
(`libmongoc` / `libbson`) via `dart:ffi`.

## Why this exists

`libmongoc` is maintained by MongoDB and has a battle-tested implementation for:

- Connection management and pooling
- TLS/auth (SCRAM, X.509, etc.)
- CRUD, aggregation, change streams, transactions (replica sets / sharded clusters)

This package is intentionally kept separate from `mongo_document_db` while the approach is validated.

## Status

This is an early scaffold:

- C shim (`native/`) exposes a tiny API surface to keep Dart bindings stable
- Dart spawns an isolate to run blocking libmongoc calls off the main isolate

## Building native binaries (local dev)

You need `libmongoc` installed on your machine for local builds.

```bash
cd packages/mongo_document_db_mongoc
bash tool/build_native.sh
```

The script builds the shim and copies the output into `lib/src/native/<abi>/`.

You can also point Dart to a custom library path:

- `MONGO_DOCUMENT_DB_MONGOC_LIB=/absolute/path/to/libmongo_document_db_mongoc.(so|dylib|dll)`

## CI: prebuilt binaries

This repo includes a GitHub Actions workflow that builds the native shim and uploads artifacts
per target ABI. See `.github/workflows/build-mongo_document_db_mongoc-native.yml`.

At runtime, Dart loads the correct binary automatically based on `Abi.current()` and the host OS.

## Usage (smoke test)

```dart
import 'dart:io';
import 'package:mongo_document_db_mongoc/mongo_document_db_mongoc.dart';

Future<void> main() async {
  final uri = Platform.environment['MONGODB_URI']!;
  final client = await MongocClient.connect(uri);
  final reply = await client.ping();
  stdout.writeln(reply);
  await client.close();
}
```

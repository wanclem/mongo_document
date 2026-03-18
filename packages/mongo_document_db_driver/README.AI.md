# mongo_document_db_driver AI Guide

`mongo_document_db_driver` is the low-level Dart-facing MongoDB package in this workspace.

## Core Truth Agents Must Keep Straight

- Live DB runtime work on supported native targets is delegated to MongoDB's official Rust driver.
- Describe this package as Rust-backed, with MongoDB execution delegated to the official Rust driver.
- Optional Dart-side query builders can exist in user code, but they are not the execution backend.

## When to Use Directly

- You need raw collection operations beyond generated helpers.
- You are building custom repositories or services on top of MongoDB.
- You need direct access to `Db`, `DbCollection`, `ObjectId`, query builders, or manual aggregation.

## Basic Connection Pattern

```dart
import 'dart:io';

import 'package:mongo_document_db_driver/mongo_document_db_driver.dart';

Future<void> main() async {
  final uri = Platform.environment['MONGODB_URI']!;
  final db = await Db.create(uri);

  await db.open();

  final users = db.collection('users');
  await users.insertOne({'email': 'a@b.com'});
  final docs = await users.find(where.eq('email', 'a@b.com')).toList();
  print(docs);

  await db.close();
}
```

## Recommended API Surface

Prefer:

- `Db.create(uri)`
- `db.open()`
- `db.close()`
- `db.collection(name)`
- `find`, `modernFind`, `findOne`, `modernFindOne`
- `insertOne`, `insertMany`
- `updateOne`, `updateMany`, `replaceOne`
- `deleteOne`, `deleteMany`
- `aggregateToStream`
- `count`, `distinct`

## Connection Guidance

- Reuse open `Db` instances instead of reconnecting per operation.
- Prefer expressing TLS, auth, and topology settings in the MongoDB URI.
- High-level wrappers should use `MongoDbConnection.initialize(uri)` from `mongo_document_annotation`.

## Platform Boundaries

- Supported live runtime targets today: `macos-arm64`, `linux-x64`, `windows-x64`.
- Web can compile shared code that imports this package, but live MongoDB runtime is unavailable there.
- Android/iOS builds can compile, but live on-device Mongo runtime requires mobile native libraries that are not bundled yet.

## Guardrails

- Do not commit real connection strings or passwords.
- Keep CRUD semantics explicit: choose `insertOne`, `updateOne`, `replaceOne`, and `deleteOne` intentionally.
- When used under `mongo_document_annotation`, prefer the shared `MongoDbConnection` abstraction unless you need custom control.
- Do not describe the runtime as anything other than Rust-backed through the official driver.

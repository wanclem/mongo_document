# mongo_document_db AI Guide

`mongo_document_db` is the low-level MongoDB driver used by `mongo_document_annotation` and generated code.

## When to Use Directly

- You need raw collection operations beyond generated helpers.
- You are building custom repositories/services on top of MongoDB.
- You need direct control over connection and driver options.

## Basic Connection Pattern

```dart
import 'dart:io';
import 'package:mongo_document_db/mongo_document_db.dart';

Future<void> main() async {
  final uri = Platform.environment['MONGODB_URI']!;
  final db = await Db.create(uri);

  final secure = uri.startsWith('mongodb+srv://') ||
      uri.contains('tls=true') ||
      uri.contains('ssl=true');

  await db.open(secure: secure);

  final users = db.collection('users');
  await users.insertOne({'email': 'a@b.com'});
  final docs = await users.find(where.eq('email', 'a@b.com')).toList();
  print(docs);

  await db.close();
}
```

## Connection Guidance

- Reuse open `Db` instances instead of reconnecting per operation.
- Prefer TLS for remote clusters (`mongodb+srv://` typically implies TLS).
- Close gracefully on shutdown to avoid socket/resource leaks.

## Atlas and Production Notes

- Keep credentials out of source control.
- Use environment variables or secret managers for URI/auth data.
- Avoid adding workaround URI flags that serialize all operations unless absolutely required.

## Core APIs Agents Should Know

- `Db.create(uri)`
- `db.open(...)`
- `db.close()`
- `db.collection(name)`
- `DbCollection.find(...)`, `findOne(...)`
- `insertOne`, `insertMany`, `updateOne`, `updateMany`, `replaceOne`, `deleteOne`, `deleteMany`
- Query/modify helpers exported from driver (e.g. `where`, `modify`)

## Guardrails

- Do not commit real connection strings or passwords.
- Keep CRUD semantics explicit: choose `insertOne`/`updateOne`/`replaceOne` intentionally.
- When used under `mongo_document_annotation`, prefer the shared `MongoDbConnection` abstraction unless you need custom control.

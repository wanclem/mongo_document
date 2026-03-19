# mongo_document_db_driver

[![pub package](https://img.shields.io/pub/v/mongo_document_db_driver.svg)](https://pub.dev/packages/mongo_document_db_driver)
[![license](https://img.shields.io/badge/license-MIT-green)](../../LICENSE)

`mongo_document_db_driver` is the low-level MongoDB driver package underneath `mongo_document_annotation` and generated `mongo_document` APIs.

Most app teams will work through generated models like `Post.save()` and `Posts.findMany(...)`. This package is for the lower-level cases where you want direct access to `Db`, `DbCollection`, filters, modifiers, commands, or aggregation pipelines.

## Install

```yaml
dependencies:
  mongo_document_db_driver: ^2.1.0
```

```bash
dart pub get
```

## Basic Usage

```dart
import 'package:mongo_document_db_driver/mongo_document_db_driver.dart';

Future<void> main() async {
  final db = await Db.create(
    'mongodb+srv://<user>:<password>@<cluster>/<database>?retryWrites=true&w=majority',
  );

  await db.open();

  final users = db.collection('users');

  await users.insertOne({
    'email': 'a@b.com',
    'active': true,
  });

  final user = await users.modernFindOne(
    filter: {'email': 'a@b.com'},
    projection: {'_id': 1, 'email': 1},
  );

  print(user);

  await db.close();
}
```

## Read

Use plain Mongo filter maps when that is the clearest fit:

```dart
final docs = await users.modernFind(
  filter: {
    'active': true,
    'rating': {r'$gt': 10},
  },
  sort: {'created_at': -1},
  limit: 20,
).toList();
```

You can also use the exported DSL:

```dart
final docs = await users
    .find(where.eq('active', true).gt('rating', 10).sortBy('created_at'))
    .toList();
```

When you need projection, sort, skip, and limit as separate arguments, prefer `modernFind` and `modernFindOne`:

```dart
final latest = await users.modernFindOne(
  filter: {'active': true},
  projection: {'_id': 1, 'email': 1},
  sort: {'created_at': -1},
);
```

## Create

```dart
await users.insertOne({
  'email': 'john@doe.com',
  'name': 'John Doe',
});

await users.insertMany([
  {'email': 'a@b.com'},
  {'email': 'c@d.com'},
]);
```

## Update

```dart
await users.updateOne(
  {'email': 'john@doe.com'},
  modify.set('name', 'John D.'),
);

await users.updateMany(
  {'active': false},
  modify.set('archived', true),
);

await users.replaceOne(
  {'email': 'john@doe.com'},
  {
    'email': 'john@doe.com',
    'name': 'John D.',
    'active': true,
  },
);
```

## Delete

```dart
await users.deleteOne({'email': 'john@doe.com'});
await users.deleteMany({'archived': true});
```

## Aggregation

```dart
final result = await users.aggregateToStream([
  {
    r'$match': {'active': true},
  },
  {
    r'$group': {
      '_id': null,
      'count': {r'$sum': 1},
    },
  },
]).toList();
```

## Connection Strings

For most applications, the connection string is all you need:

- `mongodb+srv://...`
- `retryWrites=true`
- `w=majority`
- `authSource=...`
- `tls=true`

High-level wrappers such as `MongoDbConnection.initialize(...)` in `mongo_document_annotation` expect just the URI.

## Platform Notes

- Dart VM / server / CLI / desktop: supported on bundled native targets `macos-arm64`, `linux-x64`, and `windows-x64`
- Web: shared-code compilation is supported, but opening a live MongoDB connection in the browser is not
- Android / iOS: Flutter apps compile, but live on-device runtime still requires mobile native libraries to be bundled

The package ships the native runtime for supported bundled targets, so consumers do not need Rust installed locally.

## Recommended Surface Area

If you are writing new code against this package directly, the main path is:

- `Db.create(uri)`
- `db.open()`
- `db.collection(name)`
- `modernFind`, `modernFindOne`
- `insertOne`, `insertMany`
- `updateOne`, `updateMany`, `replaceOne`
- `deleteOne`, `deleteMany`
- `aggregateToStream`
- `count`, `distinct`

## Troubleshooting

If you see:

```text
mongo_document_db_driver requires the bundled Rust runtime
```

it usually means one of these:

- you are running on an unsupported runtime target
- the matching bundled native library is missing
- the runtime is trying to perform live DB access on a platform where only shared-code compilation is supported

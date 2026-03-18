# mongo_document_db_driver

[![pub package](https://img.shields.io/pub/v/mongo_document_db_driver.svg)](https://pub.dev/packages/mongo_document_db_driver)
[![license](https://img.shields.io/badge/license-MIT-green)](../../LICENSE)

`mongo_document_db_driver` is the low-level Dart-facing MongoDB driver used by `mongo_document_annotation` and generated `mongo_document` code.

## Runtime Architecture

`mongo_document_db_driver` gives Dart applications a familiar MongoDB API while delegating live database execution to MongoDB's official Rust driver on supported native targets.

Rather than reimplementing a production MongoDB runtime in Dart, the package relies on MongoDB's officially maintained driver for:

- connection establishment
- topology discovery and server selection
- pooling and reconnect behavior
- CRUD operations
- aggregation
- command execution
- cursor iteration and `getMore`
- change streams

The Dart side provides:

- the public API (`Db`, `DbCollection`, `ObjectId`, and friends)
- BSON helpers and model-friendly value conversion
- query builders such as `where` and `modify`
- integration points used by `mongo_document_annotation` and generated code

Optional Dart-side query builders are available as a convenience DSL. They shape requests in Dart, while execution happens in the official Rust driver.

## What This Means Practically

- Live database execution is handled by MongoDB's official Rust driver.
- Consumers on shipped native targets do not need Rust installed locally.
- The package keeps a familiar Dart API while the official Rust driver handles core MongoDB work.

## Platform Support

| Target | Status |
| --- | --- |
| Dart VM / server / CLI / desktop | Supported on bundled native targets: `macos-arm64`, `linux-x64`, `windows-x64` |
| Web | The package can compile into shared/browser code, but opening a live MongoDB connection in the browser is unsupported |
| Android / iOS | Flutter apps compile, but live MongoDB runtime on-device requires mobile native libraries, which are not bundled yet |

## Installation

```yaml
dependencies:
  mongo_document_db_driver: ^2.0.0
```

Then:

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

## Querying

You can use plain MongoDB filter maps:

```dart
final docs = await users.find({
  'active': true,
  'rating': {r'$gt': 10},
}).toList();
```

Or keep using the exported query DSL:

```dart
final docs = await users
    .find(where.eq('active', true).gt('rating', 10).sortBy('created_at'))
    .toList();
```

The query builder is a Dart-side convenience layer. Execution happens through the Rust backend on supported runtimes.

If you want to pass options like projection, limit, skip, and sort separately, prefer `modernFind` / `modernFindOne`.

```dart
final latest = await users.modernFindOne(
  filter: {'active': true},
  projection: {'_id': 1, 'email': 1},
  sort: {'created_at': -1},
);
```

## CRUD Examples

### Insert

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

### Update

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

### Delete

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

## Connection Strings and TLS

Prefer putting TLS and auth options in the MongoDB connection string itself:

- `mongodb+srv://...`
- `tls=true`
- `authSource=...`
- `replicaSet=...`

For most applications, the connection string is all you need. High-level wrappers such as `MongoDbConnection.initialize(...)` in `mongo_document_annotation` now expect just the URI.

## Bundled Native Runtime

The package ships prebuilt native libraries for supported runtime targets. On those targets, consumers do not need Rust installed.

See:

- [native/prebuilt/README.md](native/prebuilt/README.md)
- [native/rust/README.md](native/rust/README.md)

## Recommended API Surface

Prefer the current CRUD and command APIs:

- `Db.create(uri)`
- `db.open()`
- `db.collection(name)`
- `find`, `modernFind`, `findOne`, `modernFindOne`
- `insertOne`, `insertMany`
- `updateOne`, `updateMany`, `replaceOne`
- `deleteOne`, `deleteMany`
- `aggregateToStream`
- `count`, `distinct`

The package also exposes a broader surface area, but the modern CRUD and aggregation APIs are the primary path.

## Troubleshooting

If you see:

```text
mongo_document_db_driver requires the bundled Rust runtime
```

then one of these is usually true:

- you are running on an unsupported runtime target
- the matching native library is missing
- the runtime is trying to perform live DB access on a platform where only shared-code compilation is supported

## Contributing

Contributions are welcome. See the repository root for development and release context.

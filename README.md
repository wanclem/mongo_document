# mongo_document

[![mongo_document](https://img.shields.io/pub/v/mongo_document.svg)](https://pub.dev/packages/mongo_document)
[![mongo_document_annotation](https://img.shields.io/pub/v/mongo_document_annotation.svg)](https://pub.dev/packages/mongo_document_annotation)
[![mongo_document_db_driver](https://img.shields.io/pub/v/mongo_document_db_driver.svg)](https://pub.dev/packages/mongo_document_db_driver)
[![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

`mongo_document` is a family of Dart packages for generating type-safe MongoDB APIs with a Rust-backed MongoDB runtime.

On supported native targets, live MongoDB execution is delegated to MongoDB's official Rust driver. Dart stays focused on the developer-facing API, code generation, BSON/converter support, and ergonomic query composition.

## Package Map

| Package | Purpose | Add As |
| --- | --- | --- |
| `mongo_document` | Code generator that emits `*.mongo_document.dart` files | `dev_dependencies` |
| `mongo_document_annotation` | Annotations, converters, runtime helpers, and the shared `MongoDbConnection` wrapper | `dependencies` |
| `mongo_document_db_driver` | Low-level Dart-facing driver backed by MongoDB's official Rust driver | direct dependency only if you want manual driver access |

## What Runs In Rust

On supported native runtimes, the official Rust driver handles:

- connection establishment
- server selection and topology handling
- pooling and reconnection
- CRUD operations
- aggregation
- cursors and `getMore`
- change streams

Dart provides:

- the public API surface
- model generation
- converters and BSON-friendly model helpers
- optional Dart-side query builders and generated helpers

That means you keep familiar Dart ergonomics while MongoDB operations run through an officially maintained driver.

## Platform Support

| Target | Status |
| --- | --- |
| Dart VM / server / CLI / desktop | Supported on currently shipped native targets: `macos-arm64`, `linux-x64`, `windows-x64` |
| Web | Compile-safe for shared code, generated models, converters, and `ObjectId`; live MongoDB runtime is not available in the browser |
| Android / iOS | Flutter apps compile successfully; live MongoDB runtime requires bundled mobile native libraries, which are not shipped yet |

Consumers on shipped native targets do not need Rust installed locally. The package loads the bundled native library directly.

## Installation

Add this to your app package:

```yaml
dependencies:
  mongo_document_annotation: ^2.0.0
  json_annotation: ^4.9.0
  freezed_annotation: ">=2.4.4 <4.0.0" # optional

dev_dependencies:
  mongo_document: ^2.0.0
  build_runner: ^2.10.3
  json_serializable: ^6.9.3
  freezed: ">=2.5.8 <4.0.0" # optional
```

Then run:

```bash
dart pub get
```

## Initialize Once

Configure MongoDB one time during app startup:

```dart
import 'dart:io';

import 'package:mongo_document_annotation/mongo_document_annotation.dart';

Future<void> main() async {
  final uri = Platform.environment['MONGODB_URI']!;
  await MongoDbConnection.initialize(uri);

  ProcessSignal.sigint.watch().listen((_) async {
    await MongoDbConnection.shutdownDb();
    exit(0);
  });

  ProcessSignal.sigterm.watch().listen((_) async {
    await MongoDbConnection.shutdownDb();
    exit(0);
  });
}
```

For low-level manual driver usage, see [packages/mongo_document_db_driver/README.md](packages/mongo_document_db_driver/README.md).

## Model Example

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';

part 'post.freezed.dart';
part 'post.g.dart';
part 'post.mongo_document.dart';

@MongoDocument(collection: 'posts')
@freezed
abstract class Post with _$Post {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory Post({
    @ObjectIdConverter() @JsonKey(name: '_id') ObjectId? id,
    String? body,
    @DateTimeConverter() DateTime? createdAt,
    @DateTimeConverter() DateTime? updatedAt,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}
```

## Generated CRUD Example

```dart
final post = await Post(body: 'Hello world').save();

final latest = await Posts.findOne(
  (q) => q.body.eq('Hello world'),
);

await Posts.updateOne(
  (q) => q.id.eq(post?.id),
  body: 'Updated body',
);

await Posts.deleteOne((q) => q.id.eq(post?.id));
```

## Lookups and Projections

```dart
final posts = await Posts.findMany(
  (q) => q.body.contains('Hello'),
  lookups: [
    Lookup(
      from: Comments.collection,
      as: 'comments',
      localField: '_id',
      foreignField: 'post',
      limit: 3,
    ),
  ],
  projections: [
    PostAuthorProjections(),
    PostProjection(),
  ],
);
```

## Conventions

- Annotate `_id` with `@ObjectIdConverter()` and `@JsonKey(name: '_id')`.
- Use `@JsonSerializable(fieldRename: FieldRename.snake)` if your MongoDB schema uses `snake_case`.
- Do not edit generated `*.mongo_document.dart` files by hand; regenerate them.

## Troubleshooting

If you see annotation-target warnings, add this to `analysis_options.yaml`:

```yaml
analyzer:
  errors:
    invalid_annotation_target: ignore
```

If you see an error like `mongo_document_db_driver requires the bundled Rust runtime`, it usually means:

- you are trying to open a DB on an unsupported runtime target, or
- the matching native library is missing for that target

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).

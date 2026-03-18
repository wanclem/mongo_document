# mongo_document AI Guide

This guide is for coding agents and automation tools integrating the `mongo_document` packages in Dart backends and shared Dart/Flutter projects.

## Package Map

| Package | Purpose | Add As |
| --- | --- | --- |
| `mongo_document_annotation` | Runtime helpers, annotations, converters, query/projection support, and `MongoDbConnection` | `dependencies` |
| `mongo_document` | Code generator (`source_gen` builder) that emits `.mongo_document.dart` files | `dev_dependencies` |
| `mongo_document_db_driver` | Low-level Dart-facing MongoDB driver backed by MongoDB's official Rust driver on supported native targets | transitively via annotation, or direct dependency for manual driver usage |

## Architecture Rules Agents Must Respect

- Describe `mongo_document_db_driver` as a Dart-facing package backed by MongoDB's official Rust driver.
- On supported native targets, live DB execution goes through the official Rust driver backend.
- Optional Dart-side query builders can appear in user code, but execution belongs to the Rust driver.

## Standard Integration Flow

1. Add dependencies.
2. Annotate models with `@MongoDocument(collection: '...')`.
3. Add `part` declarations, including `.mongo_document.dart`.
4. Run build runner.
5. Initialize Mongo once at startup with `MongoDbConnection.initialize(uri)`.
6. Use generated helpers like `Model.save()`, `Models.findMany(...)`, projections, and lookups.
7. Close cleanly on shutdown with `MongoDbConnection.shutdownDb()`.

## Recommended Dependency Setup

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

## Generation Commands

```bash
dart run build_runner build --delete-conflicting-outputs
```

Watch mode:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## Minimal Model Template

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

## Startup and Shutdown Contract

```dart
import 'dart:io';

import 'package:mongo_document_annotation/mongo_document_annotation.dart';

Future<void> bootstrapDb() async {
  final uri = Platform.environment['MONGODB_URI']!;
  await MongoDbConnection.initialize(uri);
}

Future<void> shutdownDb() => MongoDbConnection.shutdownDb();
```

Put TLS and auth settings in the MongoDB URI itself.

## Generated API Shape Agents Should Expect

For `Post`, the generator commonly emits:

- `extension $PostExtension on Post`
  - `Future<Post?> save({Db? db})`
  - `Future<bool> delete({Db? db})`
- `class Posts`
  - `saveMany`, `findById`, `findOne`, `findMany`, update helpers, delete helpers
- typed query helpers such as `QPost`
- projection helpers such as `PostProjections`

## Platform Boundaries

- Server/CLI/desktop Dart VM: live DB runtime supported on the shipped native targets.
- Web: compile-safe for shared types and generated code, but live Mongo runtime unsupported.
- Android/iOS: Flutter compilation is fine, but live on-device Mongo runtime requires mobile native libraries that are not bundled yet.

## Operational Rules for Agents

- Never edit generated `.mongo_document.dart` files directly.
- Regenerate instead of hand-fixing generated code.
- Initialize the DB once; do not repeatedly initialize with different URIs.
- Use optional `{Db? db}` parameters in generated methods for explicit orchestration when needed.
- Keep MongoDB credentials out of source code; use environment variables or secret managers.

## Troubleshooting

- `StateError: MongoDbConnection.initialize must be called before instance.`
  - Ensure startup initializes Mongo before any CRUD call.
- `mongo_document_db_driver requires the bundled Rust runtime`
  - The current runtime target is unsupported for live DB access, or the matching native library is missing.
- Missing generated methods:
  - Confirm `part 'model.mongo_document.dart';` exists and rerun build runner.

## AI Entrypoints

- Root guide: `README.AI.md`
- Driver guide: `packages/mongo_document_db_driver/README.AI.md`
- Annotation/runtime guide: `packages/mongo_document_annotation/README.AI.md`
- Generator guide: `packages/mongo_document_generator/README.AI.md`

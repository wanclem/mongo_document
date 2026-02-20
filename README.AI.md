# mongo_document AI Guide

This guide is for coding agents and automation tools integrating `mongo_document` packages in Dart backends.

## Package Map

| Package | Purpose | Add As |
|---|---|---|
| `mongo_document_annotation` | Runtime helpers, annotations, query DSL, connection helper | `dependencies` |
| `mongo_document` | Code generator (`source_gen` builder) that emits `.mongo_document.dart` files | `dev_dependencies` |
| `mongo_document_db` | Low-level MongoDB Dart driver used by generated/runtime code | transitively via annotation, or direct dependency for manual driver usage |

## Standard Integration Flow

1. Add dependencies.
2. Annotate your models with `@MongoDocument(collection: '...')`.
3. Add `part` declarations (including `.mongo_document.dart`).
4. Run build runner to generate code.
5. Initialize the DB once at app startup with `MongoDbConnection.initialize(...)`.
6. Use generated helpers (`Model.save()`, `Models.findMany(...)`, projections, lookups).
7. Close DB cleanly on shutdown using `MongoDbConnection.shutdownDb()`.

## Recommended Dependency Setup

```yaml
dependencies:
  mongo_document_annotation: ^1.7.14
  json_annotation: ^4.9.0
  freezed_annotation: ">=2.4.4 <4.0.0" # if using freezed

dev_dependencies:
  mongo_document: ^1.7.14
  build_runner: ^2.10.3
  json_serializable: ^6.9.3
  freezed: ">=2.5.8 <4.0.0" # if using freezed
```

## Generation Commands

Run from the package containing your model files:

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
  await MongoDbConnection.initialize(uri, secure: true);
}

Future<void> shutdownDb() => MongoDbConnection.shutdownDb();
```

## Generated API Shape (What Agents Should Expect)

For `Post`, generator commonly emits:

- `extension $PostExtension on Post`:
  - `Future<Post?> save({Db? db})`
  - `Future<bool> delete({Db? db})`
- `class Posts`:
  - `saveMany`, `findById`, `findOne`, `findMany`, `updateOne`, `updateMany`, delete variants
- Query DSL:
  - `QPost` with typed fields (e.g., `q.body.eq(...)`)
- Projections:
  - `PostProjections`, nested projections when references exist

## Operational Rules for Agents

- Never edit generated `.mongo_document.dart` files directly.
- Regenerate instead of hand-fixing generated code.
- Initialize DB once; do not call `MongoDbConnection.initialize` repeatedly with different settings.
- Use optional `{Db? db}` parameters in generated methods for explicit context/isolate flows.
- Keep MongoDB credentials out of source code; use environment variables.

## Troubleshooting

- `StateError: MongoDbConnection.initialize must be called before instance.`
  - Ensure startup calls `MongoDbConnection.initialize(...)` before any CRUD call.
- Missing generated methods:
  - Confirm `part 'model.mongo_document.dart';` exists and rerun build runner.
- Annotation warnings:
  - Add `invalid_annotation_target: ignore` in `analysis_options.yaml` when needed.

## AI Entrypoints

- Root guide: `README.AI.md`
- Driver guide: `packages/mongo_document_db/README.AI.md`
- Annotation/runtime guide: `packages/mongo_document_annotation/README.AI.md`
- Generator guide: `packages/mongo_document_generator/README.AI.md`

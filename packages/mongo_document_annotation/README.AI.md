# mongo_document_annotation AI Guide

`mongo_document_annotation` provides:

- `@MongoDocument` annotations used by the generator
- converters and runtime helpers used by generated code
- query/projection support types
- the shared `MongoDbConnection` lifecycle wrapper

## Runtime Reality

Generated code that uses this package ultimately routes live MongoDB work into `mongo_document_db_driver`, whose supported native runtime path is backed by MongoDB's official Rust driver.

## Install

```yaml
dependencies:
  mongo_document_annotation: ^2.0.0
  json_annotation: ^4.9.0
  freezed_annotation: ">=2.4.4 <4.0.0" # optional
```

Generator package is also required:

```yaml
dev_dependencies:
  mongo_document: ^2.0.0
  build_runner: ^2.10.3
```

## Connection Lifecycle

Use exactly one initialization in app startup:

```dart
await MongoDbConnection.initialize(uri);
```

Access DB later:

```dart
final db = await MongoDbConnection.instance;
```

Shutdown:

```dart
await MongoDbConnection.shutdownDb();
```

Put TLS and auth settings in the URI. Prefer URI-based examples.

## Model Contract

Required in each model:

- `@MongoDocument(collection: 'collection_name')`
- `part 'model.mongo_document.dart';`
- `_id` should usually use:
  - `@ObjectIdConverter()`
  - `@JsonKey(name: '_id')`

Freezed example:

```dart
@MongoDocument(collection: 'posts')
@freezed
abstract class Post with _$Post {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory Post({
    @ObjectIdConverter() @JsonKey(name: '_id') ObjectId? id,
    String? body,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}
```

## Generated API Expectations

For `Post`:

- `Post.save({Db? db})`
- `Post.delete({Db? db})`
- `Posts.saveMany(...)`
- `Posts.findById(...)`
- `Posts.findOne(...)`
- `Posts.findMany(...)`
- update and delete helper variants
- query type: `QPost`
- projections: `PostProjections`

## Common Agent Tasks

- Add a new document model and rerun generation.
- Use `lookups` and `projections` in `findMany(...)` for relational-style reads.
- Pass explicit `db` when orchestrating multiple operations in one context.

## Guardrails

- Do not modify generated `.mongo_document.dart` manually.
- Regenerate after model/schema changes.
- Keep connection URIs in env vars or secret managers.
- Do not imply that web or mobile on-device live Mongo runtime is fully supported unless the native runtime artifacts exist for that target.

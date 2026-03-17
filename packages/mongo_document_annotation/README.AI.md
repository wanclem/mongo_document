# mongo_document_annotation AI Guide

`mongo_document_annotation` provides:

- `@MongoDocument` annotation used by the generator
- Runtime helpers used by generated code
- Query DSL and projection helpers
- Shared DB connection manager (`MongoDbConnection`)

## Install

```yaml
dependencies:
  mongo_document_annotation: ^1.7.29
  json_annotation: ^4.9.0
  freezed_annotation: ">=2.4.4 <4.0.0" # optional, if using freezed
```

Generator package is also required:

```yaml
dev_dependencies:
  mongo_document: ^1.7.29
  build_runner: ^2.10.3
```

## Connection Lifecycle

Use exactly one initialization in app startup:

```dart
await MongoDbConnection.initialize(
  uri,
  secure: true,
  tlsAllowInvalidCertificates: false,
);
```

Access db later:

```dart
final db = await MongoDbConnection.instance;
```

Shutdown:

```dart
await MongoDbConnection.shutdownDb();
```

## Model Contract

Required in each model:

- `@MongoDocument(collection: 'collection_name')`
- `part 'model.mongo_document.dart';`
- `_id` field should usually use:
  - `@ObjectIdConverter()`
  - `@JsonKey(name: '_id')`

Freezed model example:

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

## Generated API (Expected)

For `Post`:

- `Post.save({Db? db})`
- `Post.delete({Db? db})`
- `Posts.saveMany(...)`
- `Posts.findById(...)`
- `Posts.findOne(...)`
- `Posts.findMany(...)`
- update and delete helper variants
- query type: `QPost`
- projections: `PostProjections`, nested projection classes when references are present

## Common Agent Tasks

- Add new document model and run generator.
- Use `lookups` + `projections` in `findMany(...)` for relational-style reads.
- Pass explicit `db` when orchestrating multiple operations in one context.

## Guardrails

- Do not modify generated `.mongo_document.dart` manually.
- Regenerate after model/schema changes.
- Keep connection URI in env vars, not source code.

[![pub package](https://img.shields.io/pub/v/mongo_document_annotation.svg)](https://pub.dev/packages/mongo_document_annotation)
[![license](https://img.shields.io/badge/license-MIT-green)](../../LICENSE)

# mongo_document_annotation

`mongo_document_annotation` provides the annotations, converters, runtime helpers, and shared connection wrapper used by generated `mongo_document` model APIs.

`mongo_document_annotation` pairs with `mongo_document_db_driver`, a Rust-backed driver that delegates live MongoDB execution to MongoDB's official Rust driver on supported native targets.

## What This Package Gives You

- `@MongoDocument(...)` annotations
- `ObjectId`, date, and nested model converters
- `MongoDbConnection` shared connection wrapper
- query/projection helper types used by generated code

## Installation

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

Then:

```bash
dart pub get
```

## Initialize the Shared Connection

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
}
```

Put TLS and auth settings in the connection string itself. The connection helper is intentionally URI-first now.

## Freezed Example

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

## Regular Class Example

```dart
import 'package:json_annotation/json_annotation.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';

part 'post.mongo_document.dart';

@MongoDocument(collection: 'posts')
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Post {
  Post({
    @ObjectIdConverter() @JsonKey(name: '_id') this.id,
    this.body,
  });

  final ObjectId? id;
  final String? body;

  Post copyWith({ObjectId? id, String? body}) {
    return Post(
      id: id ?? this.id,
      body: body ?? this.body,
    );
  }

  factory Post.fromJson(Map<String, dynamic> json) =>
      throw UnimplementedError();

  Map<String, dynamic> toJson() => throw UnimplementedError();
}
```

## Generated CRUD Example

```dart
final saved = await Post(body: 'Hello world').save();

final latest = await Posts.findOne(
  (q) => q.body.eq('Hello world'),
);

await Posts.updateOne(
  (q) => q.id.eq(saved?.id),
  body: 'Updated',
);
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

## Platform Notes

- This package can safely live in shared Dart/Flutter codebases.
- On web, shared types and converters compile, but live MongoDB runtime access is unsupported.
- On Android/iOS, Flutter apps compile, but live MongoDB runtime requires mobile native Rust libraries that are not bundled yet.
- On supported native server/desktop targets, the actual DB execution path is Rust-backed.

## Conventions

- Annotate `_id` with `@ObjectIdConverter()` and `@JsonKey(name: '_id')`.
- Use `@JsonSerializable(fieldRename: FieldRename.snake)` when your MongoDB documents use `snake_case`.
- Do not manually edit generated `*.mongo_document.dart` files.

## Troubleshooting

If you need to silence annotation-target warnings:

```yaml
analyzer:
  errors:
    invalid_annotation_target: ignore
```

## License

MIT — see [LICENSE](../../LICENSE).

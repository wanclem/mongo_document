[![pub package](https://img.shields.io/pub/v/mongo_document.svg)](https://pub.dev/packages/mongo_document)
[![license](https://img.shields.io/badge/license-MIT-green)](../../LICENSE)

# mongo_document

`mongo_document` is the code generator package in the `mongo_document` workspace.

It scans annotated model files and emits `*.mongo_document.dart` helpers for:

- typed CRUD methods
- query field builders
- projections
- lookup helpers
- collection-level helper classes

The generated runtime path targets `mongo_document_annotation`, which in turn uses `mongo_document_db_driver`. On supported native runtimes, database execution behind those generated helpers is delegated to MongoDB's official Rust driver.

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

## Minimal Model

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
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}
```

## Generate Code

From the package containing your models:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Watch mode:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## What Gets Generated

For a model like `Post`, you can expect output such as:

- a typed query helper like `QPost`
- projection helpers such as `PostProjections`
- instance helpers like `save()` and `delete()`
- collection helpers like `Posts.findOne(...)`, `Posts.findMany(...)`, `Posts.updateOne(...)`, and `Posts.deleteMany(...)`

## Runtime Example

```dart
final saved = await Post(body: 'Hello world').save();

final latest = await Posts.findOne(
  (q) => q.body.eq('Hello world'),
);

await Posts.updateOne(
  (q) => q.id.eq(saved?.id),
  body: 'Updated body',
);
```

## Important Notes

- Do not manually edit generated `*.mongo_document.dart` files.
- Change the source model, then regenerate.
- The generated APIs can still compile into shared Flutter/web projects, but live DB runtime depends on `mongo_document_db_driver` support for the target platform.

## Troubleshooting

If you need to suppress annotation-target warnings:

```yaml
analyzer:
  errors:
    invalid_annotation_target: ignore
```

## License

MIT — see [LICENSE](../../LICENSE).

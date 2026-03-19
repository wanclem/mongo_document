# mongo_document example

This package is a generator, so the real output shows up in your annotated models after running `build_runner`.

Typical setup:

```yaml
dependencies:
  mongo_document_annotation: ^2.1.0
  json_annotation: ^4.9.0
  freezed_annotation: ">=2.4.4 <4.0.0" # optional

dev_dependencies:
  mongo_document: ^2.1.0
  build_runner: ^2.10.3
  json_serializable: ^6.9.3
  freezed: ">=2.5.8 <4.0.0" # optional
```

Example model:

```dart
@MongoDocument(collection: 'posts')
@freezed
abstract class Post with _$Post {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory Post({
    @ObjectIdConverter() @JsonKey(name: '_id') ObjectId? id,
    String? body,
    String? status,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}
```

Generate:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Then use the generated API:

```dart
final post = await Post(body: 'Hello world').save();

final updated = await post.copyWith(
  body: 'Updated body',
).save();

final drafts = await Posts.findMany(
  (q) => q.status.eq('draft'),
);
```

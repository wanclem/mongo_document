# Plain Dart Models

Freezed is common, but plain Dart classes work too.

```dart
@MongoDocument(collection: 'posts')
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Post {
  Post({
    @ObjectIdConverter() @JsonKey(name: '_id') this.id,
    this.body,
    this.status,
  });

  final ObjectId? id;
  final String? body;
  final String? status;

  Post copyWith({
    ObjectId? id,
    String? body,
    String? status,
  }) {
    return Post(
      id: id ?? this.id,
      body: body ?? this.body,
      status: status ?? this.status,
    );
  }

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);
}
```

You still get generated CRUD like:

```dart
final post = await Post(body: 'Hello world').save();
```

# Generated API Mental Model

This guide explains how to think about the generated API.

## What You Write

You define a model:

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

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);
}
```

Then you run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## What Gets Generated

For `Post`, generation usually gives you:

- `Posts`
- `QPost`
- `PostFields`
- `PostProjections`
- nested projection classes like `PostAuthorProjections`
- instance methods like `save()`, `saveChanges()`, and `delete()`

## How To Think About Each Piece

### `Post`

Your model.

### `Posts`

The collection-facing API.

Use it for:

- `findById`
- `findOne`
- `findMany`
- `saveMany`
- `updateOne`
- `updateMany`
- `deleteOne`
- `deleteMany`
- `count`

### `QPost`

The typed query builder.

Example:

```dart
final drafts = await Posts.findMany(
  (q) => q.status.eq('draft'),
);
```

### `PostFields`

Field enums/constants used by projections and some generated helpers.

### `PostProjections`

Top-level field trimming for reads.

### Nested projection classes

These trim fields inside nested model properties.

Example:

```dart
PostAuthorProjections(
  inclusions: [
    PostAuthorFields.id,
    PostAuthorFields.firstName,
  ],
)
```

## Save Flow

### Create

```dart
final post = await Post(body: 'Hello world').save();
```

### Immutable update

```dart
final updated = await post.copyWith(
  body: 'Updated body',
).save();
```

or:

```dart
final updated = await post.copyWith(
  body: 'Updated body',
).saveChanges();
```

When the original document came from the generated API, the package keeps enough snapshot information to update only changed fields.

### Dynamic patch

Use collection-level updates when the patch is not known at compile time:

```dart
await Posts.updateOneFromMap(
  postId,
  {'status': 'archived'},
);
```

## Read Flow

### By id

```dart
final post = await Posts.findById(postId);
```

### First match

```dart
final post = await Posts.findOne(
  (q) => q.status.eq('published'),
);
```

### Many

```dart
final posts = await Posts.findMany(
  (q) => q.status.eq('published'),
  limit: 20,
);
```

Named reads like `findOneByNamed(...)` and `findManyByNamed(...)` use the same lookup/projection path as predicate-based reads.

## Connection Model

Generated helpers use the shared connection you initialized with:

```dart
await MongoDbConnection.initialize(uri);
```

That shared connection is exposed as:

```dart
MongoDbConnection.instance
```

If needed, every CRUD helper can also target a specific `Db`.

## Field Mapping Model

Generated helpers operate in Dart field names first.

If Mongo stores:

```json
{ "user_id": ... }
```

but Dart exposes:

```dart
Account? user
```

then the generated API still uses `user` and maps it to the stored key behind the scenes.

This applies to:

- CRUD
- query builders
- lookups
- projections

## Typed Object References

A field like:

```dart
Account? author
```

is still stored in Mongo as an `ObjectId`.

The field stays `author` in Dart across:

- queries
- saves
- reads
- lookups
- projections

See [object-references.md](object-references.md).

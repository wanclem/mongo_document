# mongo\_document

[![pub package](https://img.shields.io/pub/v/mongo_document.svg)](https://pub.dev/packages/mongo_document)
[![build status](https://github.com/wannclem/mongo_document/actions/workflows/dart.yml/badge.svg)](https://github.com/wannclem/mongo_document/actions)
[![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

## 📦 mongo\_document

A simple annotation that lets you perform CRUD on MongoDB using native Dart types.
> ⚠️ Work in Progress: This package is still under active development. Many features are experimental or not yet implemented. Expect breaking changes and missing functionality.
## Motivation
While `mongo_dart` provides low-level MongoDB access, it requires you to manually manage collections, types, field names, and query logic. This can easily lead to mismatches, especially when your Dart model fields use different names from the database schema (e.g., `postAuthor` vs. `post_author`).

`@MongoDocument` bridges this gap by generating type-safe CRUD operations and query builders based on your annotated `freezed` classes. This saves you from writing raw queries or worrying about field mapping errors. Behind the scenes, your Dart native types are translated into formats compatible for use by `mongo_dart`.


---

## 🚀 Features

* **Zero‑boilerplate CRUD** — `.save()`, `.delete()`, `.insertMany()` on your model instance
* **Rich Query API** — type‑safe DSL: `.findOne()`, `.findMany(skip:limit:)`, `.deleteOne()`, `.deleteMany()`, `.updateOne()`, `.updateMany()`, `.count()`
* **Nested joins** — automatic `$lookup` + `$unwind` when querying referenced `@MongoDocument` fields
* **Array support** — `QList<T>` with `.contains()`, `.inList()`, `.elemMatch()` for List/Set fields
* **Map support** — `QMap<V>` with sub‑key queries e.g `p.misc['key'].eq(value)`
* **Field renaming** — honors `@JsonSerializable(fieldRename: …)`
* **Timestamps** — auto‑manages `_id`, `createdAt`, `updatedAt`

---

## 🛠️ Getting Started

### 1. Add dependencies

In your `pubspec.yaml`:

```yaml
dependencies:
  json_annotation: ^4.9.0
  mongo_document: ^0.0.1

dev_dependencies:
  build_runner: ^2.4.14
  freezed: ">=2.5.8 <4.0.0"
  json_serializable: ^6.9.3
  mongo_document_generator: ^0.0.1
```

```bash
dart pub get
```

### 2. Initialize the MongoDB connection

Call once before using any generated APIs (e.g. in `main()`):

```dart
import 'package:mongo_document/mongo_connection.dart';

Future<void> main() async {
  await MongoConnection.init('mongodb://localhost:27017/mydb');
  // Now generated .save(), .findOne(), etc. will work
}
```

### 3. Define & annotate your models

Use `freezed` + `@MongoDocument`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mongo_document/mongo_document.dart';

part 'post.freezed.dart';
part 'post.g.dart';
part 'post.mongo_document.dart';

@freezed
@MongoDocument(collection: 'posts')
abstract class Post with _$Post {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory Post({
    @ObjectIdConverter() @JsonKey(name: '_id') ObjectId? id,
    User? author,
    String? body,
    @Default(<String>[]) List<String> tags,
    @DateTimeConverter() DateTime? createdAt,
    @DateTimeConverter() DateTime? updatedAt,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}
```

### 4. Generate the code

```bash
dart run build_runner build --delete-conflicting-outputs
```

This produces `post.mongo_document.dart`, adding:

* `Post.save()`, `Post.delete()`, `Posts.insertMany()`, `Posts.findOne()`, `Posts.findMany()`, `Posts.deleteOne()`, `Posts.deleteMany()`, `Posts.updateOne()`, `Posts.updateMany()`, `Posts.count()`
* `QPost` with `QueryField`, `QMap`, `QList` getters
* Automatic nested‐join logic and skip/limit handling

---

## 💡 Usage Examples

### Create / Insert

```dart
// single insert
final newPost = Post(author: user, tags: ['news'], body: 'Hello');
await newPost.save();

// Update a single post
var post = await Posts.findOne((p) => p.body.contains("Hello World"));
post = post?.copyWith(body: 'new post body');
await post?.save();

// bulk insertMany
final p1 = Post(author: user, tags: ['news'], body: 'Hello');
final p2 = Post(author: user, tags: ['tech'], body: 'World');
final inserted = await Posts.insertMany([p1, p2]);
print(inserted.map((p) => p.id));
```

### findOne

```dart
// find a single post whose tags include 'general' and body equals 'hello world'
final post = await Posts.findOne(
  (p) => p.tags.contains('general') & p.body.eq('hello world')
);
```

### findMany

```dart
// load first 10 posts with author populated
final posts = await Posts.findMany(
  (p) => p.author.firstName.startsWith('A'),
  skip: 0,
  limit: 10,
);
```

### Array element match

```dart
// find posts with any tag starting with 'gen'
final genPosts = await Posts.findMany(
  (p) => p.tags.elemMatch((t) => t.startsWith('gen'))
);

// find posts with tags contain 'awesome' in the tag list
final awesomePosts = await Posts.findMany(
(p) => p.tags.contains('awesome')
);
```

### Map key query

```dart
// find posts where analytics['views'] > 100
final hot = await Posts.findMany(
  (p) => p.analytics['views'].gt(100)
);
```

### count

```dart
final countAll = await Posts.count((p) => p.body.ne(null));
```

---

## ⚙️ Troubleshooting

If you encounter the warning `@JsonSerializable can only be used on classes`:
  add the following to your `analysis_options.yaml` to suppress it

  ```yaml
  analyzer:
    errors:
      invalid_annotation_target: ignore
  ```

---
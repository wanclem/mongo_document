[![pub package](https://img.shields.io/pub/v/mongo_document.svg)](https://pub.dev/packages/mongo_document)  [![build status](https://github.com/wannclem/mongo_document/actions/workflows/dart.yml/badge.svg)](https://github.com/wannclem/mongo_document/actions)  [![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

<!-- TOC -->

## Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Getting Started](#getting-started)

   * [Prerequisites](#prerequisites)
   * [Installation](#installation)
   * [Initialization](#initialization)
4. [Usage](#usage)

   * [Defining Models](#defining-models)
   * [Generating Code](#generating-code)
   * [CRUD Examples](#crud-examples)
   * [Advanced Queries](#advanced-queries)
5. [Configuration & Conventions](#configuration--conventions)
6. [Troubleshooting](#troubleshooting)
7. [Contributing](#contributing)
8. [License](#license)

<!-- /TOC -->

## Overview

**mongo\_document** bridges Dart `freezed` models and MongoDB via `mongo_dart`, generating zero‑boilerplate, type‑safe CRUD and query builders that respect your Dart-native naming conventions (e.g. camelCase) while serializing to your DB schema (e.g. snake\_case).

> ⚠️ *Work in Progress*: Experimental features may change. Your feedback and contributions are welcome.

## Features

* **Document References & Propagation** — support for referencing other `@MongoDocument` models (e.g. `User? author` in `Post`), storing an `ObjectId` behind the scenes and automatically propagating `.save()` calls to nested documents

* **Zero‑Boilerplate CRUD** — instance methods: `.save()`, `.delete()`, static helpers: `.insertMany()`

* **Zero‑Boilerplate CRUD** — instance methods: `.save()`, `.delete()`, static helpers: `.insertMany()`

* **Type‑Safe Query DSL** — `.findOne()`, `.findMany()`, `.updateOne()`, `.deleteMany()`, `.count()`

* **Nested Joins** — automatic `$lookup` + `$unwind` for referenced `@MongoDocument` relations

* **Array & Map Support** — `QList<T>` (.contains(), .elemMatch()), `QMap<V>` (sub-key queries)

* **Field Renaming** — honors `@JsonSerializable(fieldRename: …)` settings without manual mapping

* **Timestamps & IDs** — auto-manages `_id`, `created_at`, `updated_at`

## Getting Started

### Prerequisites

* Dart SDK ≥ 2.18

* A running MongoDB instance (local or remote)

* **MongoDB server version ≥ 3.6** (this library does not support older MongoDB releases)


### Installation

Add to your `pubspec.yaml`:

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

Then:

```bash
dart pub get
```

### Initialization

In your application entrypoint (e.g. `main()`), configure the MongoDB connection once:

```dart
import 'package:mongo_document/mongo_connection.dart';

Future<void> main() async {
  await MongoConnection.init('mongodb://localhost:27017/mydb');
  // Now you can use generated .save(), .findOne(), etc.
}
```

## Usage

### Defining Models

**⚠️ Requirement:** Every `@MongoDocument` class **must** include an `ObjectId` field in its primary constructor annotated with `@JsonKey(name: '_id')`. This ensures a valid MongoDB `_id` is always present.

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

### Generating Code

Run build\_runner to generate `.mongo_document.dart` helpers:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This creates:

* Model instance methods: `.save()`, `.delete()`
* Static APIs: `Posts.findOne()`, `Posts.findMany()`, etc.
* Query builder `QPost` with typed fields, lists, maps.

### CRUD Examples

```dart
// Create & save
final newPost = Post(body: 'Hello world', tags: ['intro']);
await newPost.save();

// Read
final post = await Posts.findOne((p) => p.body.eq('Hello world'));

// Update
post = post?.copyWith(body: 'Updated');
await post?.save();

// Delete
await post?.delete();
```

### Advanced Queries

```dart
// Find posts whose tags array contain "viral"
final viralPosts = await Posts.findMany(
  (p) => p.tags.contains("viral")
);

// Map key query: analytics['views'] > 100
final hot = await Posts.findMany(
  (p) => p.analytics['views'].gt(100)
);

// Count documents
final total = await Posts.count((p) => p.body.ne(null));
```

### References & Propagation

You can reference other MongoDocument models and have nested saves propagate automatically. Behind the scenes, a reference field stores the related document's `ObjectId`, and invoking `.save()` on the parent will also persist changes in the referenced document.

```dart
// Load and modify a referenced User
User? author = await Users.findById(authorId);
author = author?.copyWith(firstName: 'newName');

// Load a Post, update its author reference, then save both
Post? post = await Posts.findById(postId);
post = post?.copyWith(author: author);
await post?.save(); // changes to `author` propagate to the users collection
```

## Configuration & Conventions

* Customize converters via `@ObjectIdConverter()` and `@DateTimeConverter()`.
* Collection name comes from `@MongoDocument(collection: ...)`.

## Troubleshooting

**Warning**: `@JsonSerializable can only be used on classes`
Add to your `analysis_options.yaml`:

```yaml
analyzer:
  errors:
    invalid_annotation_target: ignore
```

## Contributing

Contributions, issues, and feature requests are welcome!
Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

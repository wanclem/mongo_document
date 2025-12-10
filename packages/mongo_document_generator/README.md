[![pub package](https://img.shields.io/pub/v/mongo_document.svg)](https://pub.dev/packages/mongo_document) [![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

<!-- TOC -->

## Table of Contents

1. [Overview](#overview)
2. [Getting Started](#getting-started)

   * [Prerequisites](#prerequisites)
   * [Installation](#installation)
   * [Initialization](#initialization)
3. [Usage](#usage)

   * [Using Freezed Classes](#using-freezed-classes)
   * [Using Regular Classes](#using-regular-classes)
   * [CRUD Examples](#crud-examples)
   * [Lookups & Projections](#lookups--projections)
4. [Configuration & Conventions](#configuration--conventions)
5. [Troubleshooting](#troubleshooting)
6. [Contributing](#contributing)
7. [License](#license)

<!-- /TOC -->

## Overview

**mongo_document** simplifies interaction between Dart classes and MongoDB using `mongo_dart`. It generates zero-boilerplate, type-safe CRUD methods, query builders, and supports cross-collection lookups and projections. It works seamlessly with both `freezed` and plain Dart classes.

This package allows you to:

* Perform type-safe CRUD operations directly from your Dart classes.
* Respect Dart naming conventions (e.g., camelCase) while mapping to your MongoDB schema (e.g., snake_case).
* Define complex queries, projections, and cross-collection lookups with minimal boilerplate.

## Getting Started

### Prerequisites

* Dart SDK ≥ 3.0
* A running MongoDB instance (local or remote)
* MongoDB server version ≥ 3.6

### Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  freezed_annotation: ">=2.4.4 <4.0.0"
  json_annotation: ^4.9.0
  mongo_document_annotation: ^1.7.0

dev_dependencies:
  build_runner: ^2.4.14
  freezed: ">=2.5.8 <4.0.0"
  json_serializable: ^6.9.3
  mongo_document: ^1.7.0
```

Then:

```bash
dart pub get
```

### Initialization

Configure your MongoDB connection once in your application entrypoint:

```dart
import 'package:mongo_document_annotation/mongo_document_annotation.dart';

Future<void> main() async {
  await MongoConnection.initialize('mongodb://localhost:27017/mydb');

  // Graceful shutdown
  ProcessSignal.sigint.watch().listen((_) async {
    await MongoDbConnection.shutdown();
    exit(0);
  });
  ProcessSignal.sigterm.watch().listen((_) async {
    await MongoDbConnection.shutdown();
    exit(0);
  });
}
```

## Usage

### Using Freezed Classes

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
    User? author,
    @DateTimeConverter() DateTime? createdAt,
    @DateTimeConverter() DateTime? updatedAt,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}
```

### Using Regular Classes (No Freezed)

```dart
import 'package:json_annotation/json_annotation.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';

part 'post.mongo_document.dart';

/// Post (Regular Class)
/// This class shows how to use mongo_document without freezed.
/// The user must implement copyWith(), fromJson(), and toJson().
@MongoDocument(collection: 'posts')
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Post {
  final String? body;
  final User? author;
  final ObjectId? id;

  Post({
    @ObjectIdConverter() @JsonKey(name: '_id') this.id,
    this.body,
    this.author,
  });

  Post copyWith({ObjectId? id, String? body, User? author}) {
    return Post(
      id: id ?? this.id,
      body: body ?? this.body,
      author: author ?? this.author,
    );
  }

  factory Post.fromJson(Map<String, dynamic> json) => throw UnimplementedError();

  Map<String, dynamic> toJson() => throw UnimplementedError();
}
```

### CRUD Examples

```dart
// Create & Save
final post = await Post(body: 'Hello world').save();

// Batch Save
await Posts.saveMany([Post(body: 'A'), Post(body: 'B')]);

// Update via copyWith then save
await post?.copyWith(body: 'Updated').save();

// Targeted updateOne
await Posts.updateOne(
  (p) => p.body.eq('Hello world'),
  body: 'Updated via updateOne'
);
```

### Lookups & Projections

**Cross-collection lookup example:** fetch posts with the latest 3 comments each.

```dart
final posts = await Posts.findMany(
  (p) => p.body.contains("Hello"),
  lookups: [
    Lookup(
      from: Comments.collection,
      as: "comments",
      limit: 3,
      localField: "_id",
      foreignField: "post",
    ),
  ],
);
```

**Projecting fields of related documents:** fetch posts with author details.

```dart
final posts = await Posts.findMany(
  (p) => p.body.contains("Hello"),
  projections: [PostAuthorProjections()]
);
```

**Combining lookups and projections:**

```dart
final posts = await Posts.findMany(
  (p) => p.body.contains("Hello"),
  lookups: [
    Lookup(
      from: Comments.collection,
      as: "comments",
      limit: 3,
      localField: "_id",
      foreignField: "post",
    ),
  ],
  projections: [PostAuthorProjections(), PostProjection()]
);
```

This fetches each post, includes the author information, and the latest 3 comments.

## Configuration & Conventions

* Ensure `_id` is annotated with `@ObjectIdConverter()` and `@JsonKey(name: '_id')`.
* Use `@JsonSerializable(fieldRename: FieldRename.snake)` to map camelCase fields to MongoDB style.
* Nested `@MongoDocument` types generate projection helpers automatically.

## Troubleshooting

Add to `analysis_options.yaml`:

```yaml
analyzer:
  errors:
    invalid_annotation_target: ignore
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License — see [LICENSE](LICENSE).

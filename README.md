[![pub package](https://img.shields.io/pub/v/mongo_document.svg)](https://pub.dev/packages/mongo_document_annotation) [![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

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
   * [Advanced Queries & Projections](#advanced-queries--projections)
   * [Named-Argument Queries & Projections](#named-argument-queries--projections)
   * [Nested-Document Queries & Projections](#nested-document-queries--projections)

5. [Configuration & Conventions](#configuration--conventions)

6. [Troubleshooting](#troubleshooting)

7. [Contributing](#contributing)

8. [License](#license)

<!-- /TOC -->

## Overview

**mongo\_document** bridges Dart `freezed` models and MongoDB via `mongo_dart`, generating zero‑boilerplate, type‑safe CRUD and query builders that respect your Dart-native naming conventions (e.g. camelCase) while serializing to and from your DB schema (e.g. snake\_case).

> ⚠️ *Work in Progress*: Experimental features may change. Your feedback and contributions are welcome.

## Motivation

When your Dart models use camelCase, but your database schema uses a different naming style (e.g. snake\_case or any other convention), manual mapping between the two becomes tedious and error-prone. **mongo\_document** removes that friction—letting you CRUD directly from your Dart model definitions, regardless of how you choose to name fields in MongoDB.

## Features

* **Zero‑Boilerplate CRUD & Queries**: `.save()`, `.delete()`, `.findOne()`, `.findMany()`, `.findOneByNamed()`, `.findManyByNamed()`, `.findById()`
* **Batch Operations**: `.saveMany(List<T> documents)` for bulk inserts; `.updateOne(predicate, namedArgumentsOfUpdates)` for targeted updates
* **Type-Safe DSL & Named Filters**: Lambda-based predicates (`p => p.field.eq(...)`) or named-argument filters matching your model
* **Automatic Field Mapping**: Honors `@JsonSerializable(fieldRename)`—camelCase in Dart, snake\_case in MongoDB—and respects explicit `@JsonKey(name)` overrides
* **Nested References & Projections**: Generates `*Projections` helper classes for each nested `@MongoDocument` type
* **Joins, Arrays & Maps**: Built-in `$lookup` for references; `QList` and `QMap` support array/map operations
* **Timestamps & IDs**: Auto-manage `_id`, `created_at`, and `updated_at`

## Getting Started

### Prerequisites

* Dart SDK ≥ 3.0
* A running MongoDB instance (local or remote)
* **MongoDB server version ≥ 3.6**

### Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  freezed_annotation: ">=2.4.4 <4.0.0"
  json_annotation: ^4.9.0
  mongo_document_annotation: ^1.4.1

dev_dependencies:
  build_runner: ^2.4.14
  freezed: ">=2.5.8 <4.0.0"
  json_serializable: ^6.9.3
  mongo_document: ^1.4.1
```

Then:

```bash
dart pub get
```

### Initialization

In your application entrypoint (e.g. `main()`), configure the MongoDB connection once:

```dart
import 'package:mongo_document_annotation/mongo_document_annotation.dart';

Future<void> main() async {
  await MongoConnection.initialize('mongodb://localhost:27017/mydb');
  // Now you can use generated .save(), .findOne(), etc.

  // Handle graceful shutdown
  ProcessSignal.sigint.watch().listen((_) async {
    print('SIGINT received. Shutting down gracefully...');
    await MongoDbConnection.shutdown();
    exit(0);
  });

  ProcessSignal.sigterm.watch().listen((_) async {
    print('SIGTERM received. Shutting down gracefully...');
    await MongoDbConnection.shutdown();
    exit(0);
  });
}
```

## Usage

### Defining Models

**⚠️ Requirement:** Every `@MongoDocument` class **must** include an `ObjectId` field in its primary constructor annotated with `@ObjectIdConverter()` and `@JsonKey(name: '_id')`. This ensures a valid MongoDB `_id` is always present.

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
    User? author,
    String? body,
    @JsonKey(name:'post_note') String? postNote,
    @Default(<String>[]) List<String> tags,
    @DateTimeConverter() DateTime? createdAt,
    @DateTimeConverter() DateTime? updatedAt,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}
```

### Generating Code

Run build\_runner:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates:

* Instance methods: `.save()`, `.delete()`,
* Static APIs: `Posts.saveMany()`, `Posts.findOne()`, `Posts.findMany()`, `Posts.findById()`, `Posts.findOneByNamed()`, `Posts.findManyByNamed()`,`Posts.updateOne(...)`
* Query builder `QPost` with typed fields

### CRUD Examples

```dart
// Create & Save
final post = await Post(body: 'Hello world', tags: ['intro']).save();

// Batch Save
await Posts.saveMany([
  Post(body: 'Batch A'),
  Post(body: 'Batch B')
]);

// Update via copyWith and finally save()
await post?.copyWith(body: 'Updated').save();

// Targeted updateOne
await Posts.updateOne(
  (p) => p.body.eq('Hello world'),
  body: 'Updated via updateOne'
);
```

### Advanced Queries & Projections

All query methods—including `.findOne()`, `.findMany()`, `.findOneByNamed()` and `.findManyByNamed()`—support an optional `projections` parameter. Projection helper classes are generated for each nested `@MongoDocument` type in your model (e.g. for a `User? author` field you get `PostAuthorProjections`). Use these with the corresponding `*Fields` enums to include or exclude fields.

```dart
// Named-argument single query with exclusions
final result = await Posts.findOneByNamed(
  body: 'Secret Post',
  projections: [
    PostAuthorProjections(exclusions: [PostAuthorFields.password])
  ]
);

// DSL query with inclusions
Post? postWithAuthorNames = await Posts.findOne(
  (p) => p.body.eq('Hello'),
  projections: [
    PostAuthorProjections(inclusions: [PostAuthorFields.firstName, PostAuthorFields.lastName])
  ]
);
```

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

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

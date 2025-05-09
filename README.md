[![pub package](https://img.shields.io/pub/v/mongo_document.svg)](https://pub.dev/packages/mongo_document) [![build status](https://github.com/wannclem/mongo_document/actions/workflows/dart.yml/badge.svg)](https://github.com/wannclem/mongo_document/actions) [![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

<!-- TOC -->

## Table of Contents

1. [Overview](#overview)

2. [Features](#features)

3. [Getting Started](#getting-started)

   - [Prerequisites](#prerequisites)
   - [Installation](#installation)
   - [Initialization](#initialization)

4. [Usage](#usage)

   - [Defining Models](#defining-models)
   - [Generating Code](#generating-code)
   - [CRUD Examples](#crud-examples)
   - [Advanced Queries](#advanced-queries)
   - [Named-Argument Queries & Projections](#named-argument-queries--projections)

5. [Configuration & Conventions](#configuration--conventions)

6. [Troubleshooting](#troubleshooting)

7. [Contributing](#contributing)

8. [License](#license)

<!-- /TOC -->

## Overview

**mongo_document** bridges Dart `freezed` models and MongoDB via `mongo_dart`, generating zero‑boilerplate, type‑safe CRUD and query builders that respect your Dart-native naming conventions (e.g. camelCase) while serializing to and from your DB schema (e.g. snake_case).

> ⚠️ _Work in Progress_: Experimental features may change. Your feedback and contributions are welcome.

## Motivation

When your Dart models use camelCase, but your database schema uses a different naming style (e.g. snake_case or any other convention), manual mapping between the two becomes tedious and error-prone. **mongo_document** removes that friction—letting you CRUD and query directly from your Dart model definitions, regardless of how you choose to name fields in MongoDB.

## Features

- **Zero‑Boilerplate CRUD & Queries**: `.save()`, `.delete()`, `.findOne()`, `.findMany()`, `.findOneByNamed()`, `.findManyByNamed()`, `.findById()`
- **Batch Operations**: `.saveMany(List<T> documents)` for bulk inserts; `.updateOne(predicate, namedArgumentsOfUpdates)` for targeted updates
- **Type-Safe DSL & Named Filters**: Lambda-based predicates (`p => p.field.eq(...)`) or named-argument filters matching your model
- **Automatic Field Mapping**: Honors `@JsonSerializable(fieldRename)`—camelCase in Dart, snake_case in MongoDB—and respects explicit `@JsonKey(name)` overrides
- **Nested References & Projections**: Generates `*Projections` helper classes for each nested `@MongoDocument` type
- **Joins, Arrays & Maps**: Built-in `$lookup` for references; `QList` and `QMap` support array/map operations
- **Timestamps & IDs**: Auto-manage `_id`, `created_at`, and `updated_at`

## Getting Started

### Prerequisites

- Dart SDK ≥ 2.12 (null safety)
- A running MongoDB instance (local or remote)
- **MongoDB server version ≥ 3.6**

### Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  json_annotation: ^4.9.0
  mongo_document_annotation: ^0.0.9

dev_dependencies:
  build_runner: ^2.4.14
  freezed: ">=2.5.8 <4.0.0"
  json_serializable: ^6.9.3
  mongo_document: ^0.0.9
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
  await MongoConnection.init('mongodb://localhost:27017/mydb');
  // Now you can use generated .save(), .findOne(), etc.
}
```

## Usage

### Defining Models

**⚠️ Requirement:** Every `@MongoDocument` class **must** include an `ObjectId` field in its primary constructor annotated with `@ObjectIdConverter()` and `@JsonKey(name: '_id')`. This ensures a valid MongoDB `_id` is always present.

```dart
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

Run build_runner:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates:

- Instance methods: `.save()`, `.delete()`, `.saveMany()`, `.updateOne(...)`
- Static APIs: `Posts.findOne()`, `Posts.findMany()`, `Posts.findById()`, `Posts.findOneByNamed()`, `Posts.findManyByNamed()`
- Query builder `QPost` with typed fields `QPost` with typed fields

### Create|Update

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

### Queries

```dart
// DSL filter single
final post = await Posts.findOne((p) => p.body.eq('Hello world'));

// DSL filter many
List<Post> viralPosts = await Posts.findMany((p) => p.tags.contains('viral'));

// Named-argument single
Post? special = await Posts.findOneByNamed(body: 'Special Update', author: userAuthor);

// Named-argument many
List<Post> intros = await Posts.findManyByNamed(body: 'Welcome', tags: ['intro']);

// Read by ID
final samePost = await Posts.findById(post?.id);

//// Compound DSL queries ///

// AND Query
Post? awesomePost = await Posts.findOne((p) => p.body.eq("Hello world") & p.tags.contains("awesome"));

// OR Query
Post? viralPost = await Posts.findOne((p) => p.body.eq("Viral") | p.tags.contains("viral"));

```

### Delete

```dart
// Delete
await viralPost?.delete();

// Targeted deleteOne
await Posts.deleteOne((p) => p.body.eq('Hello world'));

// Targetd deleteOneByNamed
await Posts.deleteOneByNamed(body:"Hello World");

// Targeted deleteMany
await Posts.deleteMany((p) => p.body.startsWith('Hello'));

// Targeted deleteManyByNamed
await Posts.deleteManyByNamed(body:"Hello World");
```

### Advanced Queries & Projections

All query methods—including `.findOne()`, `.findMany()`, `.findOneByNamed()`, `.findManyByNamed()`, and `.findOne()` supports an optional `projections` parameter. Projection helper classes are generated for each nested `@MongoDocument` type in your model (e.g. for a `User? author` field you get `AuthorProjections`). Use these with the corresponding `*Fields` enums to include or exclude fields.

```dart
// Named-argument query with exclusions
await Posts.findManyByNamed(
  body: 'Secret Post',
  projections: [
    AuthorProjections(exclusions: [AuthorFields.password])
  ]
);

// DSL query with inclusions
Post? postWithAuthorNames = await Posts.findOne(
  (p) => p.body.eq('Hello'),
  projections: [
    AuthorProjections(inclusions: [AuthorFields.firstName, AuthorFields.lastName])
  ]
);

await Posts.findManyByNamed(
  body: 'Secret Post',
  projections: [
    AuthorProjections(exclusions: [AuthorFields.password])
  ]
);
```

### Sample Projection Result

```json
{
  "_id": "605c5f2e8a7c2e1a4c3d9b7f",
  "body": "Hello",
  "tags": ["intro"],
  "author": { "first_name": "Jane", "last_name": "Doe" }
}
```

Explanation: Because we used an inclusion projection (`inclusions: [AuthorFields.firstName, AuthorFields.lastName]`), only the specified `author` subfields (`firstName`, `lastName`) appear in the result. If you provide an empty inclusion and exclusion arrays you will get back only the `ObjectId` as `{_id:ObjectId("605c5f2e8a7c2e1a4c3d9b7f)}` mapped to the `author` reference.

## Configuration & Conventions

- Converters: `@ObjectIdConverter()`, `@DateTimeConverter()`
- Collection name from `@MongoDocument(collection: ...)`

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

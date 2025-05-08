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

When your Dart models use camelCase, but your database schema uses a different naming style (e.g. snake_case or any other convention), manual mapping between the two becomes tedious. **mongo_document** removes that friction—letting you CRUD and query directly from your Dart model definitions, regardless of how you choose to name fields in MongoDB.

## Features

- **Zero‑Boilerplate CRUD & Queries**: `.save()`, `.delete()`, `.saveMany()`, `.findOne()`, `.findMany()`, `.findOneByNamed()`, `.findManyByNamed()`

- **Type-Safe DSL & Named Filters**: Choose between lambda-based predicates (`p => p.field.eq(...)`) or simple named arguments matching your model

- **Automatic Field Mapping**: Honors `@JsonSerializable(fieldRename)`—camelCase in Dart, snake_case in MongoDB—and respects explicit `@JsonKey(name)` overrides, transparently mapping between your Dart model and database schema.

- **Nested References & Projections** — for each nested `@MongoDocument` type found in your model (e.g. `User? author`), the generator creates a corresponding `*Projections` helper class (named after the parameter) so you can include or exclude its fields in any query.

- **Joins, Arrays & Maps**: Built-in `$lookup` for references; `QList` and `QMap` support common array/map operations

- **Timestamps & IDs**: Auto-manage `_id`, `created_at`, and `updated_at`

## Getting Started

### Prerequisites

- Dart SDK ≥ 2.12 (null safety)
- A running MongoDB instance (local or remote)
- **MongoDB server version ≥ 3.6**

### Installation

To use **mongo_document**, you'll need the standard Dart code-generation setup with `build_runner`.
First, add `build_runner`, `freezed`, `json_serializable`, and `mongo_document_annotation` (and the runtime `mongo_document`) to your `pubspec.yaml` under `dev_dependencies` and `dependencies` as shown below.

Add to your `pubspec.yaml`:

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
import 'package:mongo_document/mongo_connection.dart';

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

@freezed
@MongoDocument(collection: 'posts')
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

Run build_runner to generate `.mongo_document.dart` helpers:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This creates:

- Model instance methods: `.save()`, `.delete()`
- Static APIs: `Posts.findOne()`, `Posts.findMany()`, etc.
- Query builder `QPost` with typed fields, lists, maps.

### CRUD Examples

```dart
// Create & save
final newPost = await Post(body: 'Hello world', tags: ['intro']).save();

// Read
final post = await Posts.findOne((p) => p.body.eq('Hello world'));

// Update
post = await post?.copyWith(body: 'Updated').save();

// Delete
await post?.delete();
```

### Queries

Examples of each query method:

```dart
// 1) DSL filter: findOne
Post? helloPost = await Posts.findOne((p) => p.body.eq("Hello world"));

// 2) DSL filter many: findMany
List<Post> viralPosts = await Posts.findMany((p) => p.tags.contains("viral"));

// 3) Named-argument single: findOneByNamed
Post? special = await Posts.findOneByNamed(body: "Special Update", author: userAuthor);

// 4) Named-argument many: findManyByNamed
List<Post> intros = await Posts.findManyByNamed(body: "Welcome", tags: ["intro"]);
```

Use the style that best fits your needs—DSL predicates or named-argument—to retrieve one or multiple documents. In DSL predicates you can combine conditions using `&` (AND) and `|` (OR), for example:

```dart
//DSL And Query
Post? awesomePost = await Posts.findOne((p) => p.body.eq("Hello world") & p.tags.contains("awesome"));

//DSL OR Query
Post? viralPost = await Posts.findOne((p) => p.body.eq("Viral") | p.tags.contains("viral"));
```

### Queries & Projections

All query methods—including `.findOne()`, `.findMany()`, `.findOneByNamed()`, and `.findManyByNamed()`—support an optional `projections` parameter. Projection helper classes are generated only for nested `@MongoDocument` types in your model (e.g. for a `User? author` field you get `AuthorProjections`). Use these `*Projections` helper classes with the corresponding `*Fields` enums to include or exclude nested fields on any query.

```dart
// Standard query with projections
Post? postWithAuthorNames = await Posts.findOne(
  (p) => p.body.eq("Hello"),
  projections: [
    AuthorProjections(inclusions: [AuthorFields.firstName, AuthorFields.lastName])
  ]
);

// Named-argument query with exclusions
List<Post> postsWithoutPasswords = await Posts.findManyByNamed(
  body: "Secret Post",
  projections: [
    AuthorProjections(exclusions: [AuthorFields.password])
  ]
);
```

- **projections**: A list of generated `*Projections` instances (e.g. `AuthorProjections`) specifying field inclusions or exclusions.
- Projection classes are only generated when you have a nested `@MongoDocument` in your model.
- Works with any query method: standard DSL or named-argument variants.

## Configuration & Conventions

- Customize converters via e.g `@ObjectIdConverter()` and `@DateTimeConverter()`.
- Collection name comes from `@MongoDocument(collection: ...)`.

## Troubleshooting

**Warning**: `@JsonSerializable can only be used on classes` — Add to your `analysis_options.yaml`:

```yaml
analyzer:
  errors:
    invalid_annotation_target: ignore
```

## Contributing

Contributions, issues, and feature requests are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

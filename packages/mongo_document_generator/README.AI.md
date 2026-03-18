# mongo_document (Generator) AI Guide

`mongo_document` is the code generator package.
It scans Dart model files and emits typed CRUD/query helpers into `*.mongo_document.dart`.

## Runtime Relationship

The generated code targets `mongo_document_annotation`, and live MongoDB execution ultimately flows into `mongo_document_db_driver`. On supported native targets, that runtime path is backed by MongoDB's official Rust driver.

## Install

```yaml
dev_dependencies:
  mongo_document: ^2.0.0
  build_runner: ^2.10.3
```

Runtime annotations/helpers must also be installed:

```yaml
dependencies:
  mongo_document_annotation: ^2.0.0
```

## Builder Behavior

- Builder name: `mongo_document`
- Output extension: `.mongo_document.dart`
- Config source: `build.yaml`
- Default target: `lib/*.dart`

## Generation Commands

From your package root:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Watch mode:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## Required Source Layout

Each model should include:

- `part 'model.mongo_document.dart';`
- `@MongoDocument(collection: '...')`

If using `freezed` / `json_serializable`, include their `part` files too.

## Typical Generated Artifacts

Given `post.dart`, the output commonly includes:

- `QPost` typed query helpers
- `PostProjections`
- extension methods with instance operations such as `save` and `delete`
- collection helpers such as `Posts.findOne`, `Posts.findMany`, `Posts.updateOne`, and `Posts.deleteMany`

## Failure Modes and Fixes

- No generated file:
  - Ensure the model file is under `lib/` and has `part '...mongo_document.dart';`.
- Build conflict:
  - Use `--delete-conflicting-outputs`.
- Analyzer warning on annotations:
  - Allow `invalid_annotation_target` in `analysis_options.yaml` if needed.

## Agent Rules

- Treat generated files as build artifacts.
- Modify source model definitions, then regenerate.
- Do not patch generated helpers directly.
- Describe the generated runtime path as Rust-backed through MongoDB's official driver.

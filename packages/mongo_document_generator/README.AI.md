# mongo_document (Generator) AI Guide

`mongo_document` is the code generator package.
It scans Dart model files and emits typed CRUD/query helpers into `*.mongo_document.dart`.

## Install

```yaml
dev_dependencies:
  mongo_document: ^1.7.14
  build_runner: ^2.10.3
```

Runtime annotations/helpers must also be installed:

```yaml
dependencies:
  mongo_document_annotation: ^1.7.14
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

If using freezed/json_serializable, include their `part` files too.

## Typical Generated Artifacts

Given `post.dart`, output includes:

- `enum PostFields`
- `class QPost` (typed query fields)
- `class PostProjections` (+ nested projection helpers)
- extension with instance operations (`save`, `delete`)
- static collection class (`Posts`) with query/update/delete helpers

## Failure Modes and Fixes

- No generated file:
  - Ensure model file is under `lib/` and has `part '...mongo_document.dart';`.
- Build conflict:
  - Use `--delete-conflicting-outputs`.
- Analyzer warning on annotations:
  - Allow `invalid_annotation_target` in `analysis_options.yaml` if needed.

## Agent Rules

- Treat generated files as build artifacts.
- Modify source model definitions, then regenerate.
- Do not patch generated helpers directly.

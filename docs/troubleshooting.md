# Troubleshooting

## I changed my model, but the generated API still looks old

Regenerate:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Run this after changing:

- fields
- `@JsonKey(...)`
- `fieldRename`
- lookups
- projections
- nested refs

## A projected field came back as `null`

Projected models still deserialize into the same Dart type, but fields you did not ask for should be treated as unloaded.

That usually means:

- the field was not included in the projection
- or it was intentionally trimmed by a nested projection

## My lookup is not matching the stored Mongo field

In lookup definitions, write Dart field names like:

```dart
localField: 'user'
```

not stored Mongo keys like:

```dart
localField: 'user_id'
```

The package remaps Dart names to stored Mongo keys using your JSON annotations.

## `copyWith(...).save()` updated more or less than I expected

`copyWith(...).save()` and `copyWith(...).saveChanges()` can do partial immutable updates when the document originally came from the generated API, because the package keeps a snapshot of the loaded document.

If you build a brand-new model from scratch without a generated read first, the package may not have enough prior state to infer a minimal diff.

For truly dynamic updates, prefer:

```dart
await Posts.updateOneFromMap(postId, patch);
```

## I got a bad ObjectId error

Make sure the id string is a valid Mongo `ObjectId`.

The generated code now throws cleaner argument errors for bad id parsing in common read paths, but the root cause is still an invalid id string.

## I only wanted to trim nested fields

Use a nested projection.

You do not need an explicit lookup if:

- the related field is already present in the document
- or you just want the normal typed-ref materialization with fewer nested fields

Use an explicit lookup only when you need custom join behavior such as:

- `unsetFields`
- `where`
- nested lookups
- boolean/count/array shape

## I need a different database for one operation

Generated helpers use `MongoDbConnection.instance` by default.

If you need a different `Db`, pass it explicitly:

```dart
final archiveDb = await Db.create(archiveUri);
await archiveDb.open();

final post = await Posts.findById(postId, db: archiveDb);
```

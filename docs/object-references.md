# Object References

Typed object references are one of the most important patterns in this package.

## The Recommended Style

Prefer:

```dart
Account? author
```

instead of:

```dart
ObjectId? authorId
```

## Why

It keeps your Dart code clearer:

```dart
final posts = await CrossPosts.findMany(
  (p) => p.author.id.eq(currentUser.id),
);
```

That reads naturally and still maps correctly to Mongo storage.

## What Gets Stored

Even though the Dart field is a model reference, Mongo still stores a plain `ObjectId` for that field.

So:

```dart
CrossPost(author: someAccount)
```

stores roughly as:

```json
{ "author": ObjectId("...") }
```

## What Comes Back On Reads

### Normal reads

The field comes back as the typed Dart shape again, usually with just enough data for the reference.

### Richer reads

When projections or lookups materialize more of the related document, the same field can hydrate into a fuller nested model.

The field name stays:

```dart
author
```

not `authorId`.

## Save Flow

This is valid:

```dart
final post = await Posts.findById(postId);
if (post == null) return;

final updated = await post.copyWith(
  author: anotherAuthor,
).save();
```

The package still reduces `author` to its `_id` behind the scenes when writing.

## Lookups And Projections

Object refs become especially useful here.

### Projection-only typed ref materialization

```dart
final posts = await CrossPosts.findMany(
  (p) => p.workspace.id.eq(currentWorkspace.id),
  projections: [
    CrossPostAuthorProjections(
      inclusions: [
        CrossPostAuthorFields.id,
        CrossPostAuthorFields.firstName,
      ],
    ),
  ],
);
```

### Explicit lookup when you need custom behavior

```dart
final posts = await CrossPosts.findMany(
  (p) => p.workspace.id.eq(currentWorkspace.id),
  lookups: [
    Lookup.single(
      from: Accounts.collection,
      localField: 'author',
      foreignField: '_id',
      as: 'author',
      unsetFields: ['email', 'password', 'sessions'],
    ),
  ],
);
```

## Important Rule

Use the Dart field name in your query code and lookups.

If Mongo stores a different key, the package maps it for you.

That means:

- query builders use `author`
- lookups use `author`
- projections use `author`
- Mongo may still store a different underlying key if your JSON annotations say so

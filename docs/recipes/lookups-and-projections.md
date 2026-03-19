# Lookups And Projections

Projection-only:

```dart
final posts = await Posts.findMany(
  (q) => q.status.eq('published'),
  projections: [
    PostProjections(
      inclusions: [PostFields.id, PostFields.body],
    ),
  ],
);
```

Lookup-only:

```dart
final posts = await Posts.findMany(
  (q) => q.status.eq('published'),
  lookups: [
    Lookup.single(
      from: Users.collection,
      localField: 'author',
      foreignField: '_id',
      as: 'author',
    ),
  ],
);
```

Lookup + projection:

```dart
final posts = await Posts.findMany(
  (q) => q.status.eq('published'),
  lookups: [
    Lookup.single(
      from: Users.collection,
      localField: 'author',
      foreignField: '_id',
      as: 'author',
      unsetFields: ['email', 'password'],
    ),
  ],
  projections: [
    PostProjections(
      inclusions: [PostFields.id, PostFields.body],
    ),
    PostAuthorProjections(
      inclusions: [
        PostAuthorFields.id,
        PostAuthorFields.firstName,
      ],
    ),
  ],
);
```

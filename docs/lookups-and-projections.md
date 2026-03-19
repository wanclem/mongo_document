# Lookups And Projections

Lookups and projections are often used together, but they solve different problems.

## The Short Version

- **Lookup**: fetch related data
- **Projection**: trim returned fields

## Decision Table

| Need | Use |
| --- | --- |
| Only part of the base document | base projection |
| Only part of a nested model field | nested projection |
| Related data returned in the same read | lookup |
| One related document | `Lookup.single(...)` |
| Related list | `Lookup.array(...)` |
| Boolean relationship | `Lookup.boolean(...)` |
| Count of related documents | `Lookup.count(...)` |
| Custom join behavior like `unsetFields` or nested lookups | explicit lookup |
| Typed ref with normal related-data materialization and trimmed nested fields | nested projection is often enough |

## Use A Projection When You Only Need Part Of The Result

### Base projection

```dart
final posts = await Posts.findMany(
  (q) => q.status.eq('published'),
  projections: [
    PostProjections(
      inclusions: [
        PostFields.id,
        PostFields.body,
        PostFields.createdAt,
      ],
    ),
  ],
);
```

### Nested projection

```dart
final member = await WorkspaceMembers.findOne(
  (wm) =>
      wm.user.id.eq(authenticatedUser.id) &
      wm.workspace.id.eq(workspaceId),
  projections: [
    WorkspaceMemberWorkspaceProjections(),
  ],
);
```

Nested projections do **not** throw away the base fields the outer model still needs.

## Use A Lookup When Mongo Should Fetch Related Data

### One related document

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

### Related list

```dart
final posts = await Posts.findMany(
  (q) => q.status.eq('published'),
  lookups: [
    Lookup.array(
      from: Comments.collection,
      localField: '_id',
      foreignField: 'post',
      as: 'recentComments',
      sort: {'created_at': -1},
      limit: 3,
    ),
  ],
);
```

### Boolean relationship

```dart
final posts = await Posts.findMany(
  (q) => q.status.eq('published'),
  lookups: [
    Lookup.boolean(
      from: Followers.collection,
      localField: 'author',
      foreignField: 'leader',
      as: 'youFollow',
      where: {'follower': caller.id!},
    ),
  ],
);
```

### Count

```dart
final posts = await Posts.findMany(
  (q) => q.status.eq('published'),
  lookups: [
    Lookup.count(
      from: Comments.collection,
      localField: '_id',
      foreignField: 'post',
      as: 'commentCount',
    ),
  ],
);
```

## Typed Refs: Projection-Only vs Explicit Lookup

For typed object references like:

```dart
Account? author
```

a nested projection is often enough if you only want the normal related-data materialization for that field:

```dart
final posts = await CrossPosts.findMany(
  (p) => p.workspace.id.eq(currentWorkspace.id),
  projections: [
    CrossPostProjections(
      inclusions: [CrossPostFields.id, CrossPostFields.text],
    ),
    CrossPostAuthorProjections(
      inclusions: [
        CrossPostAuthorFields.id,
        CrossPostAuthorFields.firstName,
      ],
    ),
  ],
);
```

Use an explicit lookup when you need custom join behavior:

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
  projections: [
    CrossPostProjections(
      inclusions: [CrossPostFields.id, CrossPostFields.text],
    ),
    CrossPostAuthorProjections(
      inclusions: [
        CrossPostAuthorFields.id,
        CrossPostAuthorFields.firstName,
      ],
    ),
  ],
);
```

These are not duplicates:

- the lookup controls how `author` is fetched
- the nested projection trims which `author` fields survive

If both target the same field, the package merges them into one lookup pipeline instead of creating duplicate `$lookup` stages.

## Always Use Dart Field Names In Lookups

If a model field is:

```dart
Account? user
```

but Mongo stores it as `user_id`, still write:

```dart
Lookup.single(
  from: Accounts.collection,
  localField: 'user',
  foreignField: '_id',
  as: 'user',
)
```

The package remaps Dart names to stored Mongo keys using your `@JsonKey(...)` and `fieldRename` rules.

## Typical Aggregation Shape

For a read with predicate + lookup + projection, the generated pipeline is usually shaped like:

```text
$match
$sort (if requested)
$skip (if requested)
$limit (if requested)
$lookup
$unwind or $addFields (depending on lookup shape)
$project
```

The important guarantee is that projection-driven nested materialization and explicit lookups should not duplicate each other.

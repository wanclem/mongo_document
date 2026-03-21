[![pub package](https://img.shields.io/pub/v/mongo_document_annotation.svg)](https://pub.dev/packages/mongo_document_annotation)
[![license](https://img.shields.io/badge/license-MIT-green)](../../LICENSE)

# mongo_document_annotation

`mongo_document_annotation` is the runtime package you usually import in your models and startup code.

This is the package that defines the annotations and shared runtime pieces.

It is not the generator itself.

It also carries the shared `MongoDbConnection` surface used by generated CRUD helpers, so this package sits on the runtime path where connection lifecycle and recovery behavior matter in real applications.

Use it when you want:

- `@MongoDocument(...)` on a model
- `MongoDbConnection.initialize(...)` during startup
- converters such as `@ObjectIdConverter()` and `@DateTimeConverter()`
- lookup and projection types used by generated queries

It provides:

- `@MongoDocument(...)`
- `MongoDbConnection.initialize(...)`
- converters like `@ObjectIdConverter()` and `@DateTimeConverter()`
- lookup types
- projection types
- the shared helpers used by generated CRUD code

If `mongo_document` gives you `Post.save()` and `Posts.findMany(...)`, this package gives the annotations, mapping rules, and query-shaping tools those generated helpers depend on.

The usual setup is:

- add `mongo_document_annotation` to `dependencies`
- add `mongo_document` to `dev_dependencies`
- run `build_runner`

## Install

```yaml
dependencies:
  mongo_document_annotation: ^2.1.5
  json_annotation: ^4.9.0
  freezed_annotation: ">=2.4.4 <4.0.0" # optional

dev_dependencies:
  mongo_document: ^2.1.5
  build_runner: ^2.10.3
  json_serializable: ^6.9.3
  freezed: ">=2.5.8 <4.0.0" # optional
```

```bash
dart pub get
```

## When To Import This Package Directly

Import `mongo_document_annotation` directly when you are:

- defining a MongoDB-backed model
- configuring the shared MongoDB connection
- writing custom converters or annotations
- using low-level lookup / projection types in hand-written query helpers

If what you want is the generated CRUD API such as `findOne`, `findMany`, `save`, or `delete`, that comes from the generated output produced by `mongo_document`.

## Initialize MongoDB

Do this once during startup:

```dart
import 'dart:io';

import 'package:mongo_document_annotation/mongo_document_annotation.dart';

Future<void> main() async {
  final uri = Platform.environment['MONGODB_URI']!;
  await MongoDbConnection.initialize(uri);

  ProcessSignal.sigterm.watch().listen((_) async {
    await MongoDbConnection.shutdownDb();
    exit(0);
  });
}
```

That shared connection is what the generated CRUD helpers use by default.

Generated helpers default to `MongoDbConnection.instance`, which is the shared connection you initialized with `MongoDbConnection.initialize(...)` at startup. Every CRUD helper can still target a specific `Db` when you want a different database:

```dart
final archiveDb = await Db.create(archiveMongoUri);
await archiveDb.open();

final archivedPost = await Posts.findById(postId, db: archiveDb);
await archivedPost?.copyWith(status: 'restored').save(db: archiveDb);
```

## Annotate A Model

```dart
import 'package:json_annotation/json_annotation.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';

part 'post.g.dart';
part 'post.mongo_document.dart';

@MongoDocument(collection: 'posts')
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Post {
  Post({
    @ObjectIdConverter() @JsonKey(name: '_id') this.id,
    this.body,
    this.status,
    @DateTimeConverter() this.createdAt,
    @DateTimeConverter() this.updatedAt,
  });

  final ObjectId? id;
  final String? body;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);
}
```

From there, `mongo_document` generation builds the typed CRUD API around this model.

## Dart Field Names Stay Clean

This package respects:

- `@JsonKey(name: ...)`
- `@JsonSerializable(fieldRename: ...)`

That means your Dart API can stay readable even if Mongo uses a different stored name.

```dart
@MongoDocument(collection: 'workspace_members')
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class WorkspaceMember {
  WorkspaceMember({
    @ObjectIdConverter() @JsonKey(name: '_id') this.id,
    @JsonKey(name: 'work_space') this.workspace,
    this.role,
  });

  final ObjectId? id;
  final Workspace? workspace;
  final String? role;

  factory WorkspaceMember.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceMemberFromJson(json);
  Map<String, dynamic> toJson() => _$WorkspaceMemberToJson(this);
}
```

So your query code still reads like normal Dart:

```dart
final member = await WorkspaceMembers.findOne(
  (wm) => wm.workspace.id.eq(workspaceId),
);
```

and the package still maps that correctly to the Mongo field path.

## Typed Object References

A reference field does not have to be modeled as `ObjectId? authorId`.

You can model it as the related Dart type:

```dart
@MongoDocument(collection: 'posts')
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CrossPost {
  CrossPost({
    @ObjectIdConverter() @JsonKey(name: '_id') this.id,
    this.author,
    @JsonKey(name: 'workSpace') this.workspace,
    this.text,
  });

  final ObjectId? id;
  final Account? author;
  final Workspace? workspace;
  final String? text;

  factory CrossPost.fromJson(Map<String, dynamic> json) =>
      _$CrossPostFromJson(json);
  Map<String, dynamic> toJson() => _$CrossPostToJson(this);
}
```

This keeps the field meaningful in Dart:

```dart
final posts = await CrossPosts.findMany(
  (p) => p.author.id.eq(authenticatedUser.id),
);
```

instead of forcing everything into an `authorId` naming style.

Behind the scenes, the shared helpers in this package handle the reference conversion:

- on writes, nested model references are reduced to `_id` values for MongoDB storage
- on reads, stored reference ids are rewrapped into the shape your Dart model expects
- if a lookup populates the reference, the same field can deserialize into a fuller nested model without changing the field name or type
- query builders can still target `author.id`, `workspace.id`, and similar paths while the stored field remains the Mongo reference itself

That is why the same field can work well across normal saves, reads, projections, and lookups.

The internal helpers that make this work are used automatically by generated code. Most app code does not need to call `withRefs()` or `withValidObjectReferences()` directly, but those are the shared normalization helpers that keep typed references ergonomic on both the read and write paths.

That same typed field also stays consistent when you project or look it up:

```dart
final posts = await CrossPosts.findMany(
  (p) => p.workspace.id.eq(workspaceId),
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

That still works on `post.author`, not `post.authorId`, while the stored Mongo value remains a plain `ObjectId`.

## When To Use Lookups

Use a lookup when the read should return related data in the same trip to MongoDB.

Lookups and projections are related, but they are not the same thing:

- a lookup decides whether related data should be fetched at all
- a lookup decides the shape of the related result, such as one object, many objects, a boolean, or a count
- a projection decides which fields survive in the final payload
- for typed object references, a nested projection can already trigger the default related-data materialization for that field
- add an explicit lookup when you need more control, such as `unsetFields`, `where`, nested lookups, or a different result shape
- explicit lookups use Dart field names like `author` or `user`, and the package remaps them to stored Mongo keys using `@JsonKey(...)` and `fieldRename`

So `Lookup.single(as: 'author', ...)` and `PostAuthorProjections(...)` are not duplicates. The lookup loads `author` as a single nested object. The nested projection trims the fields on that nested object. If you pass both for the same field, the package merges them into one lookup pipeline instead of creating duplicate lookups.

Typical examples:

- a post with its author
- a workspace member with its workspace
- a `youFollow` boolean
- a `commentCount`

### One nested document: `Lookup.single(...)`

```dart
Lookup.single(
  from: Users.collection,
  localField: 'author',
  foreignField: '_id',
  as: 'author',
)
```

### A nested list: `Lookup.array(...)`

```dart
Lookup.array(
  from: Comments.collection,
  localField: '_id',
  foreignField: 'post',
  as: 'recentComments',
  sort: {'created_at': -1},
  limit: 3,
)
```

### A yes/no relationship flag: `Lookup.boolean(...)`

```dart
Lookup.boolean(
  from: Followers.collection,
  localField: 'author',
  foreignField: 'leader',
  as: 'youFollow',
  where: {'follower': caller.id!},
)
```

### A related count: `Lookup.count(...)`

```dart
Lookup.count(
  from: Comments.collection,
  localField: '_id',
  foreignField: 'post',
  as: 'commentCount',
)
```

### A full lookup example

```dart
final posts = await Posts.findMany(
  (q) => q.status.eq('published'),
  lookups: [
    Lookup.single(
      from: Users.collection,
      localField: 'author',
      foreignField: '_id',
      as: 'author',
      unsetFields: ['email', 'password', 'sessions'],
    ),
    Lookup.count(
      from: Comments.collection,
      localField: '_id',
      foreignField: 'post',
      as: 'commentCount',
    ),
  ],
);
```

Use lookups when the endpoint genuinely needs related data back from the same read. If the base document already has the only foreign key you need, a lookup is usually unnecessary.

### Lookup only

If the endpoint needs the related document and you are fine returning the full nested payload, a lookup alone is enough:

```dart
final posts = await Posts.findMany(
  (q) => q.status.eq('published'),
  lookups: [
    Lookup.single(
      from: Users.collection,
      localField: 'author',
      foreignField: '_id',
      as: 'author',
      unsetFields: ['email', 'password', 'sessions'],
    ),
  ],
);
```

If the Dart field is stored under a different Mongo key, still use the Dart field name:

```dart
final member = await WorkspaceMembers.findOne(
  (wm) => wm.user.id.eq(authenticatedUser.id),
  lookups: [
    Lookup.single(
      from: Accounts.collection,
      localField: 'user',
      foreignField: '_id',
      as: 'user',
      unsetFields: ['password'],
    ),
  ],
);
```

If that field is stored as `user_id` in Mongo, the package remaps it behind the scenes.

## When To Use Projections

Use projections when you only need part of a document.

Typical cases:

- card/list pages
- dashboard summaries
- permission checks
- nested documents where only a few fields should be loaded

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

Nested projection classes are for nested model fields. Sometimes that nested data is already stored inside the main document. Sometimes it is coming back from a lookup. In both cases, the nested projection lets you keep only the fields you need from that nested object while the base fields required to deserialize the main model are still kept automatically. So if you only pass `WorkspaceMemberWorkspaceProjections()`, the package still preserves the base fields needed to deserialize `WorkspaceMember` itself.

For typed object references, a nested projection can also be enough to trigger the default related-data materialization for that field. You do not need an explicit lookup if you only want the normal related document on the same field with fewer nested fields.

Projected models still deserialize into the same Dart type. Fields you did not ask for should be treated as unloaded and may come back as `null` in that projected model instance.

### Projection + lookup together

```dart
final posts = await Posts.findMany(
  (q) => q.status.eq('published'),
  lookups: [
    Lookup.single(
      from: Users.collection,
      localField: 'author',
      foreignField: '_id',
      as: 'author',
      unsetFields: ['email', 'password', 'sessions'],
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

That pattern is useful when the parent document and the joined document both need to stay lean.

In that example:

- `Lookup.single(...)` fetches `author` and turns the joined result into one object instead of a list
- `unsetFields` on the lookup trims sensitive fields before the final projection runs
- `PostProjections(...)` trims the parent document
- `PostAuthorProjections(...)` trims the nested joined `author`

Typed object references fit especially well here:

```dart
final posts = await CrossPosts.findMany(
  (p) => p.workspace.id.eq(workspaceId),
  lookups: [
    Lookup.single(
      from: Accounts.collection,
      localField: 'author',
      foreignField: '_id',
      as: 'author',
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

The field still stays `author` in Dart, even though the stored Mongo value is a reference and the looked-up value is a fuller nested document.

## Shared Helpers Behind `save()` And `saveChanges()`

This package also provides the shared helper layer used by generated immutable update flows:

```dart
final post = await Posts.findById(postId);
if (post == null) return;

final updated = await post.copyWith(body: 'Updated body').save();
```

or:

```dart
final updated = await post.copyWith(body: 'Updated body').saveChanges();
```

You do not pass `previous`.

## Most Apps Import This Package Directly For

- `MongoDbConnection.initialize(...)`
- `@MongoDocument(...)`
- `@ObjectIdConverter()`
- `@DateTimeConverter()`
- lookup and projection types in query code

The generated CRUD surface itself comes from `mongo_document`.

<p align="center">
  <img src="https://raw.githubusercontent.com/wanclem/mongo_document/main/assets/logo/logo.png" width="160" alt="mongo_document logo" />
</p>

# mongo_document

[![mongo_document](https://img.shields.io/pub/v/mongo_document.svg)](https://pub.dev/packages/mongo_document)
[![mongo_document_annotation](https://img.shields.io/pub/v/mongo_document_annotation.svg)](https://pub.dev/packages/mongo_document_annotation)
[![mongo_document_db_driver](https://img.shields.io/pub/v/mongo_document_db_driver.svg)](https://pub.dev/packages/mongo_document_db_driver)
[![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

`mongo_document` helps you talk to MongoDB in a Dart-native way.

Define a model once, run generation, and write code like:

```dart
final post = await Post(body: 'Hello world').save();

final updated = await post.copyWith(
  body: 'Updated body',
  status: 'published',
).save();

final drafts = await Posts.findMany(
  (q) => q.status.eq('draft'),
  limit: 20,
);
```

Instead of hand-writing collection wrappers, raw update maps, field-name translation, reference conversion, and aggregation glue over and over, you stay close to normal Dart models and normal Dart code.

## Package Map

Most apps only need these two packages:

| Package | Add As | Use It For |
| --- | --- | --- |
| `mongo_document_annotation` | `dependencies` | annotations, converters, `MongoDbConnection`, lookup/projection types, shared helpers |
| `mongo_document` | `dev_dependencies` | code generation for `save()`, `findById()`, `findMany()`, query builders, projections, and lookups |

`mongo_document_db_driver` is the low-level driver package underneath. Most app code never needs to import it directly.

## Install

```yaml
dependencies:
  mongo_document_annotation: ^2.1.0
  json_annotation: ^4.9.0
  freezed_annotation: ">=2.4.4 <4.0.0" # optional

dev_dependencies:
  mongo_document: ^2.1.0
  build_runner: ^2.10.3
  json_serializable: ^6.9.3
  freezed: ">=2.5.8 <4.0.0" # optional
```

```bash
dart pub get
```

## Initialize MongoDB Once

Initialize the shared connection during startup, then let the generated API use it everywhere else.

```dart
import 'dart:io';

import 'package:mongo_document_annotation/mongo_document_annotation.dart';

Future<void> main() async {
  final uri = Platform.environment['MONGODB_URI']!;

  await MongoDbConnection.initialize(uri);

  ProcessSignal.sigint.watch().listen((_) async {
    await MongoDbConnection.shutdownDb();
    exit(0);
  });

  ProcessSignal.sigterm.watch().listen((_) async {
    await MongoDbConnection.shutdownDb();
    exit(0);
  });
}
```

## Define A Model

If you already use Freezed, it is a very natural fit here because `copyWith()`, immutability, JSON generation, and value equality all play nicely with generated CRUD helpers.

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
    String? body,
    String? status,
    @DateTimeConverter() DateTime? createdAt,
    @DateTimeConverter() DateTime? updatedAt,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}
```

Plain Dart classes work too. The important parts are `fromJson`, `toJson`, the generated `part` file, and ideally a `copyWith()` if you want the same immutable update flow.

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

  Post copyWith({
    ObjectId? id,
    String? body,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Post(
      id: id ?? this.id,
      body: body ?? this.body,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);
}
```

Generate helpers any time model shape or mapping changes, for example after changing fields, `@JsonKey(...)`, `fieldRename`, lookups, or nested references:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Or keep generation running while you work:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

For a model like `Post`, generation gives you:

- `Posts`
- `QPost`
- `PostFields`
- `PostProjections`
- nested projection classes like `PostAuthorProjections` for targeting specific fields inside nested model properties
- instance helpers like `save()`, `saveChanges()`, and `delete()`

## Everyday CRUD

### Create

`save()` inserts when the document has no id and returns the saved model.

```dart
final post = await Post(
  body: 'Hello world',
  status: 'draft',
).save();
```

You can also save many at once:

```dart
final savedPosts = await Posts.saveMany([
  Post(body: 'One'),
  Post(body: 'Two'),
]);
```

### Read

```dart
final byId = await Posts.findById(postId);

final firstDraft = await Posts.findOne(
  (q) => q.status.eq('draft'),
);

final drafts = await Posts.findMany(
  (q) => q.status.eq('draft'),
  sort: ('created_at', -1),
  limit: 20, // findMany defaults to 10 if you do not pass a limit.
);
```

This style scales well in service classes too:

```dart
class AccountService {
  static Future<Account?> findOne(
    Expression Function(QAccount q) predicate, {
    List<BaseProjections> projections = const [],
    List<Lookup> lookups = const [],
  }) {
    return Accounts.findOne(
      predicate,
      projections: projections,
      lookups: lookups,
    );
  }
}
```

Generated helpers default to `MongoDbConnection.instance`, which is the shared connection you initialized with `MongoDbConnection.initialize(...)` at startup. Every CRUD helper can still target a specific `Db` when you want a different database:

```dart
final analyticsDb = await Db.create(analyticsMongoUri);
await analyticsDb.open();

final draft = await Posts.findById(postId, db: analyticsDb);

await Post(body: 'Stored in analytics too').save(db: analyticsDb);
```

### Update With `copyWith()`

This is one of the nicest flows in the package:

```dart
final post = await Posts.findById(postId);
if (post == null) return;

final updated = await post.copyWith(
  body: 'Updated body',
  status: 'published',
).save();
```

Or, if you want the call site to read explicitly as an update:

```dart
final updated = await post.copyWith(
  body: 'Updated body',
).saveChanges();
```

No `previous:` argument is needed.

When the document came from the generated API, the package keeps enough snapshot information to update only the fields that actually changed. That means `copyWith(...).save()` stays ergonomic without always pushing the entire serialized document back to MongoDB.

### Update With A Direct Patch

When you already know the patch fields and do not need `copyWith()`, use the collection helpers directly:

```dart
final updated = await Posts.updateOne(
  (q) => q.id.eq(postId),
  body: 'Updated body',
  status: 'published',
);
```

If the patch shape is dynamic, use a map:

```dart
final updated = await Posts.updateOneFromMap(
  postId,
  {
    'status': 'archived',
    'published_at': DateTime.now().toUtc(),
  },
);
```

### Delete

```dart
await post.delete();
await Posts.deleteOne((q) => q.id.eq(postId));
await Posts.deleteMany((q) => q.status.eq('deleted'));
```

## Dart Names Stay Dart-First

You write queries with Dart field names, even if Mongo stores those fields differently.

```dart
final member = await WorkspaceMembers.findOne(
  (wm) =>
      wm.user.id.eq(authenticatedUser.id) &
      wm.workspace.id.eq(workspaceId),
);
```

That stays clean because the package respects both:

- `@JsonKey(name: ...)`
- `@JsonSerializable(fieldRename: ...)`

Example:

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

So you still write:

```dart
wm.workspace.id.eq(workspaceId)
```

and Mongo still receives the correct field path under the hood.

## Model References Instead Of `authorId`

One of the nicest patterns in `mongo_document` is that you can model Mongo references with the related Dart model type instead of forcing everything to become `ObjectId? authorId`.

For example, a model can be written like this:

```dart
@MongoDocument(collection: 'posts')
@freezed
abstract class CrossPost with _$CrossPost {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory CrossPost({
    @ObjectIdConverter() @JsonKey(name: '_id') ObjectId? id,
    Account? author,
    @JsonKey(name: 'workSpace') Workspace? workspace,
    String? text,
  }) = _CrossPost;

  factory CrossPost.fromJson(Map<String, dynamic> json) =>
      _$CrossPostFromJson(json);
}
```

That keeps your Dart API expressive:

```dart
final post = await CrossPost(
  author: authenticatedUser,
  workspace: currentWorkspace,
  text: 'Hello world',
).save();
```

and your query code stays readable too:

```dart
final posts = await CrossPosts.findMany(
  (p) => p.author.id.eq(authenticatedUser.id),
);
```

Behind the scenes, the package still stores Mongo references the way Mongo expects them.

- In Dart, the field stays `Account? author`, not `ObjectId? authorId`.
- On save, the generated helpers reduce `author` to its `_id` and store that bare `ObjectId` in Mongo.
- On a normal read without a lookup, the same field comes back as the typed Dart shape again, usually as a lightweight `Account` with only its `id` populated.
- On a lookup or richer projection, that same `author` field can hydrate into a fuller `Account` object without changing the field name or field type in your model.
- In query builders, `p.author.id.eq(...)` still maps cleanly to the stored Mongo field behind the scenes.

So `Account? author` gives you a much nicer API than `ObjectId? authorId`, while still storing a proper reference in MongoDB.

This becomes especially useful once you start projecting or looking up related data, because the field name stays the same all the way through.

If you only need a small slice of the related document, a nested projection by itself is often enough:

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

That keeps the API on `post.author`, not `post.authorId`, and the package still stores a plain `ObjectId` in Mongo behind the scenes.

Add an explicit lookup only when you want to control how the related document is fetched, for example to unset sensitive fields, apply nested lookups, or change the result shape:

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

The lookup and the nested projection are not duplicates:

- the lookup decides how `author` should be loaded
- the nested projection decides which `author` fields survive in the final payload
- if you pass both, the package merges them into one lookup pipeline instead of creating duplicate lookups

## When To Use Projections

Use projections when the page or endpoint does not need the full document.

Typical cases:

- card/list screens
- light auth/permission checks
- nested data where only a few fields are needed
- places where payload size matters

If a page only needs a post card, keep the payload lean:

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

If you only care about a nested object, project that nested object directly:

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

Nested projection classes are for nested model fields. That nested data might already live inside the document, or it might be populated through a lookup. In both cases, the nested projection lets you keep just the fields you need from that nested object while the base fields required to deserialize `WorkspaceMember` are still preserved automatically. That means a call like `WorkspaceMemberWorkspaceProjections()` can stay focused on `workspace` without accidentally stripping the base fields the main model still needs.

For typed object references like `Account? author` or `Workspace? workspace`, a nested projection alone can already trigger the default reference materialization for that field. You do not need an explicit lookup if you only want the normal related document on the same field with fewer nested fields.

Projected models still deserialize into the same Dart type. Fields you did not ask for should be treated as unloaded and may come back as `null` in that projected model instance.

## Lookups And Projections Solve Different Problems

These two features are often used together, but they do different jobs:

- A lookup decides whether MongoDB should fetch related data at all.
- A lookup also decides the shape of that related result, for example one object, many objects, a boolean, or a count.
- A projection decides which fields should survive in the final payload.
- A nested projection does not replace a lookup. It only trims the fields of a nested object that is already present, whether that nested object came from the stored document or from a lookup.
- For typed object references, a nested projection can be enough to trigger the default reference materialization for that field.
- Add an explicit lookup when you want more control over how that related data is fetched, for example `unsetFields`, `where`, nested lookups, boolean/count results, or a non-default result shape.
- In explicit lookups, write Dart field names like `author` or `user`. The package remaps them to stored Mongo keys using your `@JsonKey(...)` and `fieldRename` rules.

For example:

- `Lookup.single(as: 'author', ...)` means "load `author` and return it as one object instead of a list."
- `PostAuthorProjections(...)` means "once `author` is present, only keep the author fields I asked for."

## When To Use Lookups

Use lookups when you want related data to come back in the same read instead of manually loading and stitching it yourself.

Common examples:

- a post with its author
- a workspace member with its workspace
- a `youFollow` boolean
- a `commentCount`

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

If you only need the foreign id that is already stored on the base document, you usually do not need a lookup. Use a lookup when the read becomes cleaner because the related data should already be there when the document is returned.

### Lookup Only

If the endpoint truly needs the related document and you are fine returning all of it, a lookup by itself is enough:

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

That says: fetch `author` and return it as one nested object.

If your model stores the field under a different Mongo key, still write the Dart field name in the lookup:

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

If `user` is stored as `user_id` in Mongo, the package remaps that lookup for you.

## Projections And Lookups Together

It is common to use both together when the endpoint needs joined data, but not the full joined payload:

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

That is a good pattern when the screen needs related data, but only a small slice of both the parent and nested documents.

In that example:

- `Lookup.single(...)` says `author` should be loaded from another collection and returned as one object.
- `unsetFields` on the lookup trims or removes sensitive fields before the final payload is even shaped.
- `PostProjections(...)` trims the top-level `Post` fields.
- `PostAuthorProjections(...)` trims the nested `author` fields that are still left.

So the lookup and the nested projection are not duplicates. One fetches the relationship. The other trims the relationship.

## Rule Of Thumb

- Use `save()` when you want one method for create and update.
- Use `saveChanges()` when you want update intent to be obvious at the call site.
- Use lookups when related data should come back in the same read.
- Use projections when the full document is unnecessary.
- Use `updateOneFromMap()` only when the patch is truly dynamic.

## Where To Go Next

- [mongo_document_annotation](packages/mongo_document_annotation/README.md) for annotations, converters, lookups, projections, and connection setup
- [mongo_document](packages/mongo_document_generator/README.md) for the generator itself
- [mongo_document_db_driver](packages/mongo_document_db_driver/README.md) for low-level driver access
- [docs/generated-api-mental-model.md](docs/generated-api-mental-model.md) for how the generated surface fits together
- [docs/lookups-and-projections.md](docs/lookups-and-projections.md) for when to use each and how they combine
- [docs/object-references.md](docs/object-references.md) for typed model refs like `Account? author`
- [docs/troubleshooting.md](docs/troubleshooting.md) for common mistakes and recovery steps
- [docs/recipes/README.md](docs/recipes/README.md) for copy-pasteable focused examples

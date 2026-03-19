[![pub package](https://img.shields.io/pub/v/mongo_document.svg)](https://pub.dev/packages/mongo_document)
[![license](https://img.shields.io/badge/license-MIT-green)](../../LICENSE)

# mongo_document

`mongo_document` is the code generator that turns your annotated MongoDB models into a Dart-native API.

After generation, your app code reads like this:

```dart
final post = await Post(body: 'Hello world').save();

final updated = await post.copyWith(
  body: 'Updated body',
).save();

final drafts = await Posts.findMany(
  (q) => q.status.eq('draft'),
  limit: 20,
);
```

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

The generated helpers use the shared connection from `mongo_document_annotation`.

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

## Define A Model

Freezed is a great fit when you want immutable `copyWith()` flows:

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

Plain Dart classes work too as long as they expose `fromJson`, `toJson`, and the generated `part` file:

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
  });

  final ObjectId? id;
  final String? body;
  final String? status;

  Post copyWith({
    ObjectId? id,
    String? body,
    String? status,
  }) {
    return Post(
      id: id ?? this.id,
      body: body ?? this.body,
      status: status ?? this.status,
    );
  }

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);
}
```

Generate helpers whenever model shape or mapping changes:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Or keep it running:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## What Gets Generated

For each annotated model, the generator gives you:

- instance helpers like `save()`, `saveChanges()`, and `delete()`
- collection helpers like `findById`, `findOne`, `findMany`, `updateOne`, `updateMany`, `deleteOne`, `deleteMany`, and `count`
- typed query builders like `QPost`
- field enums like `PostFields`
- projection classes like `PostProjections`
- nested projection classes like `PostAuthorProjections` for selecting only the fields you need inside nested model properties

## Everyday Flow

### Create

```dart
final post = await Post(
  body: 'Hello world',
  status: 'draft',
).save();
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
  limit: 20, // defaults to 10 when omitted
);
```

Generated helpers default to `MongoDbConnection.instance`, which is the shared connection you initialized with `MongoDbConnection.initialize(...)` at startup. Every CRUD helper can still target a specific `Db` when you want a different database:

```dart
final reportingDb = await Db.create(reportingMongoUri);
await reportingDb.open();

final account = await Accounts.findById(accountId, db: reportingDb);
await account?.copyWith(status: 'active').save(db: reportingDb);
```

### Update With `copyWith()`

```dart
final post = await Posts.findById(postId);
if (post == null) return;

final updated = await post.copyWith(
  body: 'Updated body',
  status: 'published',
).save();
```

Or:

```dart
final updated = await post.copyWith(
  body: 'Updated body',
).saveChanges();
```

Both flows work without passing `previous`.

When a document came from the generated API, the generator-backed helpers keep enough snapshot information to update only the fields that changed.

### Update Without `copyWith()`

```dart
final updated = await Posts.updateOne(
  (q) => q.id.eq(postId),
  body: 'Updated body',
  status: 'published',
);
```

For dynamic patch payloads:

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
```

## Queries Stay Close To Your Model

The generated query builders let you express filters with your Dart model structure:

```dart
final member = await WorkspaceMembers.findOne(
  (wm) =>
      wm.user.id.eq(authenticatedUser.id) &
      wm.workspace.id.eq(workspaceId),
);
```

That stays Dart-first even when Mongo stores those fields under different names.

## Model References Stay Typed

You do not have to name every reference field `authorId`, `workspaceId`, or `userId` in your Dart models.

You can model references with the related Dart type itself:

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

That means your app code reads naturally:

```dart
final post = await CrossPost(
  author: authenticatedUser,
  workspace: currentWorkspace,
  text: 'Hello world',
).save();

final posts = await CrossPosts.findMany(
  (p) => p.author.id.eq(authenticatedUser.id),
);
```

The generated helpers still store the reference correctly in MongoDB by reducing those nested model references to their `_id` values when writing, then rehydrating them back into the typed Dart field shape on reads.

The same field then works cleanly across the whole lifecycle:

- on save, `author` is reduced to its `_id` for Mongo storage
- on a regular read, `author` comes back as the typed Dart field again
- on a lookup, `author` can hydrate into a fuller `Account`
- in queries, `p.author.id.eq(...)` still reads naturally

That is why this becomes especially useful once you add projections or lookups, because the field stays `author` all the way through.

If you only need a trimmed version of the related document, a nested projection alone is often enough:

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

Add an explicit lookup only when you need custom join behavior such as `unsetFields`, nested lookups, or a boolean/count/array result shape.

## Use Lookups When Related Data Should Come Back In One Read

Lookups and projections solve different problems:

- a lookup decides whether related data should be fetched at all
- a lookup decides the shape of that related result, such as one object, many objects, a boolean, or a count
- a projection decides which fields should survive in the final payload
- for typed object references, a nested projection can already trigger the default related-data materialization for that field
- add an explicit lookup when you want more control, such as `unsetFields`, `where`, nested lookups, or a different result shape
- explicit lookups still use Dart field names like `author` or `user`; the package remaps them to stored Mongo keys for you

So `Lookup.single(as: 'author', ...)` and `PostAuthorProjections(...)` are not duplicates. The lookup loads `author` as one object. The nested projection trims which author fields are returned. If you pass both, the package merges them into one lookup pipeline instead of duplicating the join.

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
    Lookup.count(
      from: Comments.collection,
      localField: '_id',
      foreignField: 'post',
      as: 'commentCount',
    ),
  ],
);
```

Use lookups when you want the read itself to return joined data like author details, counts, or relationship flags.

## Use Projections When You Only Need Part Of The Document

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

Nested-only projections work cleanly too:

```dart
final members = await WorkspaceMembers.findMany(
  (q) => q.workspace.id.eq(workspaceId),
  projections: [
    WorkspaceMemberWorkspaceProjections(),
  ],
);
```

Nested projection classes are for nested model fields. Sometimes that nested object is already part of the stored document. Sometimes it is being populated through a lookup. Either way, the nested projection lets you keep that nested payload lean without stripping away the base model fields required to deserialize `WorkspaceMember`. If you only pass `WorkspaceMemberWorkspaceProjections()`, the generator still preserves the base fields the outer model needs.

If a related field is already stored on the document and you only want to trim it, a nested projection alone is enough. For typed object references, that same nested projection can also trigger the default related-data materialization for that field. If the related field must be loaded with custom join behavior, use an explicit lookup first, then optionally add a nested projection to keep that looked-up payload lean.

Projected models still deserialize into the same Dart type. Fields you did not ask for should be treated as unloaded and may come back as `null` in that projected model instance.

## A Nice Service-Layer Pattern

Many apps wrap the generated collections in service classes:

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

That keeps your domain-specific logic in one place while still benefiting from the generated API.

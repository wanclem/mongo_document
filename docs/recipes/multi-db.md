# Multi-Database Usage

Generated helpers default to the shared connection created by `MongoDbConnection.initialize(...)`.

For a specific database:

```dart
final reportingDb = await Db.create(reportingMongoUri);
await reportingDb.open();

final post = await Posts.findById(postId, db: reportingDb);
await post?.copyWith(status: 'archived').save(db: reportingDb);
```

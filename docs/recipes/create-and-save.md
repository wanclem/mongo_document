# Create And Save

```dart
final post = await Post(
  body: 'Hello world',
  status: 'draft',
).save();
```

`save()` inserts when the model has no id and returns the saved model.

Bulk save:

```dart
final saved = await Posts.saveMany([
  Post(body: 'One'),
  Post(body: 'Two'),
]);
```

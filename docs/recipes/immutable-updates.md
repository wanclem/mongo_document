# Immutable Updates With `copyWith()`

```dart
final post = await Posts.findById(postId);
if (post == null) return;

final updated = await post.copyWith(
  body: 'Updated body',
).save();
```

Or:

```dart
final updated = await post.copyWith(
  body: 'Updated body',
).saveChanges();
```

When the original document came from the generated API, these flows can update only changed fields.

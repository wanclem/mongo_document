# Typed Object References

Prefer:

```dart
Account? author
```

instead of:

```dart
ObjectId? authorId
```

Query it naturally:

```dart
final posts = await CrossPosts.findMany(
  (p) => p.author.id.eq(currentUser.id),
);
```

The package still stores a plain `ObjectId` in Mongo behind the scenes.

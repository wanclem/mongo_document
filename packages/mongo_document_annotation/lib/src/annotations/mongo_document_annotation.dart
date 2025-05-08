import 'package:freezed_annotation/freezed_annotation.dart';

/// Marks a class as a MongoDB document, giving its collection name.
@immutable
class MongoDocument {
  final String collection;

  const MongoDocument({required this.collection});
}

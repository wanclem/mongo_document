/// ------------------------------------------------------------
/// VanillaUser (Non-Freezed Example)
/// ------------------------------------------------------------
/// This class demonstrates how to use `mongo_document` without `freezed`.
///
/// Key Points:
/// 1. `mongo_document` will still generate all the CRUD helpers
///    (e.g., `.save()`, `.delete()`, `.findOne()`, `.findMany()`),
///    and query builders (`QVanillaUser`) from this class.
/// 2. Since this is not a `freezed` class:
///    - You must implement `copyWith()` manually if you need it.
///    - You must implement `fromJson()` and `toJson()` manually
///      (or use `json_serializable` with the correct converters).
/// 3. The `_id` field is required for MongoDB and must be annotated
///    with `@ObjectIdConverter()` and `@JsonKey(name: '_id')`
///    on the constructor parameter.
///
/// Example Usage:
/// ```dart
/// final user = VanillaUser(firstName: 'Alice', lastName: 'Smith');
/// final updatedUser = user.copyWith(firstName: 'Bob');
/// await updatedUser.save();
/// ```

import 'package:json_annotation/json_annotation.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';

part 'vanilla_user.mongo_document.dart';

@MongoDocument(collection: 'vanilla_users')
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class VanillaUser {
  final String? firstName;
  final String? lastName;

  @ObjectIdConverter()
  final ObjectId? id;

  VanillaUser({
    @ObjectIdConverter() @JsonKey(name: '_id') this.id,
    this.firstName,
    this.lastName,
  });

  VanillaUser copyWith({ObjectId? id, String? firstName, String? lastName}) {
    return VanillaUser(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
    );
  }

  factory VanillaUser.fromJson(Map<String, dynamic> json) =>
      throw UnimplementedError();

  Map<String, dynamic> toJson() => throw UnimplementedError();
}

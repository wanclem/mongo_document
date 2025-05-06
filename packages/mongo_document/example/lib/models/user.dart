import 'package:mongo_document/mongo_document.dart';

part 'user.freezed.dart';

part 'user.g.dart';

part 'user.mongo_document.dart';

@freezed
@MongoDocument(collection: "users")
abstract class User with _$User {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory User({
    @ObjectIdConverter() @JsonKey(name: '_id') ObjectId? id,
    String? firstName,
    String? lastName,
    String? email,
    @Default(18) int age,
    @DateTimeConverter() DateTime? createdAt,
    @DateTimeConverter() DateTime? updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

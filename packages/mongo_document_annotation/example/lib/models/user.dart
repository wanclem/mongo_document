import 'package:mongo_document_annotation/mongo_document_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'user.freezed.dart';
part 'user.g.dart';
part 'user.mongo_document.dart';

@MongoDocument(collection: 'accounts')
@freezed
abstract class User with _$User {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory User({
    @ObjectIdConverter() @JsonKey(name: '_id') ObjectId? id,
    String? firstName,
    String? lastName,
    String? email,
    String? password,
    @DateTimeConverter() DateTime? createdAt,
    @DateTimeConverter() DateTime? updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

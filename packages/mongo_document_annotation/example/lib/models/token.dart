import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';

part 'token.freezed.dart';

part 'token.g.dart';

part 'token.mongo_document.dart';

@MongoDocument(collection: 'tokens')
@freezed
abstract class Token with _$Token {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory Token({
    @ObjectIdConverter() @JsonKey(name: '_id') ObjectId? id,
    String? ownerEmail,
    String? token,
    Map<String, dynamic>? data,
    String? reason,
    String? description,
    int? numberOfUpdates,
    @DateTimeConverter() DateTime? expireAt,
    @DateTimeConverter() DateTime? createdAt,
    @DateTimeConverter() DateTime? updatedAt,
  }) = _Token;

  factory Token.fromJson(Map<String, dynamic> json) => _$TokenFromJson(json);
}

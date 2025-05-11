import 'package:example/models/user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';

part 'organization.freezed.dart';

part 'organization.g.dart';

part 'organization.mongo_document.dart';

@MongoDocument(collection: 'organizations')
@freezed
abstract class Organization with _$Organization {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory Organization({
    @ObjectIdConverter() @JsonKey(name: '_id') ObjectId? id,
    String? tempId,
    User? owner,
    String? name,
    dynamic avatar,
    @Default({}) Map<String, dynamic> ephemeralData,
    @Default(false) bool active,
    @DateTimeConverter() DateTime? createdAt,
    @DateTimeConverter() DateTime? updatedAt,
  }) = _Organization;

  factory Organization.fromJson(Map<String, dynamic> json) =>
      _$OrganizationFromJson(json);
}

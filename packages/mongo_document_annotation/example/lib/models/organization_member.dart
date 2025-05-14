import 'dart:convert';

import 'package:example/models/organization.dart';
import 'package:example/models/user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';

part 'organization_member.freezed.dart';

part 'organization_member.g.dart';

part 'organization_member.mongo_document.dart';

@MongoDocument(collection: 'organizationmembers')
@freezed
abstract class OrganizationMember with _$OrganizationMember {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory OrganizationMember({
    @ObjectIdConverter() @JsonKey(name: '_id') ObjectId? id,
    @JsonKey(name: 'user_id') User? user,
    Organization? organization,
    String? occupation,
    String? role,
    String? title,
    @DateTimeConverter() DateTime? createdAt,
    @DateTimeConverter() DateTime? updatedAt,
  }) = _OrganizationMember;

  factory OrganizationMember.fromJson(Map<String, dynamic> json) =>
      _$OrganizationMemberFromJson(json);
}

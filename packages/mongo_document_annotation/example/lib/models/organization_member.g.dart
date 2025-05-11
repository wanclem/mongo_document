// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OrganizationMember _$OrganizationMemberFromJson(Map<String, dynamic> json) =>
    _OrganizationMember(
      id: const ObjectIdConverter().fromJson(json['_id']),
      user:
          json['user_id'] == null
              ? null
              : User.fromJson(json['user_id'] as Map<String, dynamic>),
      organization:
          json['organization'] == null
              ? null
              : Organization.fromJson(
                json['organization'] as Map<String, dynamic>,
              ),
      occupation: json['occupation'] as String?,
      role: json['role'] as String?,
      title: json['title'] as String?,
      createdAt: const DateTimeConverter().fromJson(json['created_at']),
      updatedAt: const DateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$OrganizationMemberToJson(_OrganizationMember instance) =>
    <String, dynamic>{
      '_id': const ObjectIdConverter().toJson(instance.id),
      'user_id': instance.user?.toJson(),
      'organization': instance.organization?.toJson(),
      'occupation': instance.occupation,
      'role': instance.role,
      'title': instance.title,
      'created_at': const DateTimeConverter().toJson(instance.createdAt),
      'updated_at': const DateTimeConverter().toJson(instance.updatedAt),
    };

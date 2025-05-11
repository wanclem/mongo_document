// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Organization _$OrganizationFromJson(Map<String, dynamic> json) =>
    _Organization(
      id: const ObjectIdConverter().fromJson(json['_id']),
      tempId: json['temp_id'] as String?,
      owner:
          json['owner'] == null
              ? null
              : User.fromJson(json['owner'] as Map<String, dynamic>),
      name: json['name'] as String?,
      avatar: json['avatar'],
      ephemeralData:
          json['ephemeral_data'] as Map<String, dynamic>? ?? const {},
      active: json['active'] as bool? ?? false,
      createdAt: const DateTimeConverter().fromJson(json['created_at']),
      updatedAt: const DateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$OrganizationToJson(_Organization instance) =>
    <String, dynamic>{
      '_id': const ObjectIdConverter().toJson(instance.id),
      'temp_id': instance.tempId,
      'owner': instance.owner?.toJson(),
      'name': instance.name,
      'avatar': instance.avatar,
      'ephemeral_data': instance.ephemeralData,
      'active': instance.active,
      'created_at': const DateTimeConverter().toJson(instance.createdAt),
      'updated_at': const DateTimeConverter().toJson(instance.updatedAt),
    };

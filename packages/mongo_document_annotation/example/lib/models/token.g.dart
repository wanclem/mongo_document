// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Token _$TokenFromJson(Map<String, dynamic> json) => _Token(
  id: const ObjectIdConverter().fromJson(json['_id']),
  ownerEmail: json['owner_email'] as String?,
  token: json['token'] as String?,
  data: json['data'] as Map<String, dynamic>?,
  reason: json['reason'] as String?,
  description: json['description'] as String?,
  numberOfUpdates: (json['number_of_updates'] as num?)?.toInt(),
  expireAt: const DateTimeConverter().fromJson(json['expire_at']),
  createdAt: const DateTimeConverter().fromJson(json['created_at']),
  updatedAt: const DateTimeConverter().fromJson(json['updated_at']),
);

Map<String, dynamic> _$TokenToJson(_Token instance) => <String, dynamic>{
  '_id': const ObjectIdConverter().toJson(instance.id),
  'owner_email': instance.ownerEmail,
  'token': instance.token,
  'data': instance.data,
  'reason': instance.reason,
  'description': instance.description,
  'number_of_updates': instance.numberOfUpdates,
  'expire_at': const DateTimeConverter().toJson(instance.expireAt),
  'created_at': const DateTimeConverter().toJson(instance.createdAt),
  'updated_at': const DateTimeConverter().toJson(instance.updatedAt),
};

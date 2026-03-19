// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vanilla_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VanillaUser _$VanillaUserFromJson(Map<String, dynamic> json) => VanillaUser(
  id: const ObjectIdConverter().fromJson(json['_id']),
  firstName: json['first_name'] as String?,
  lastName: json['last_name'] as String?,
);

Map<String, dynamic> _$VanillaUserToJson(VanillaUser instance) =>
    <String, dynamic>{
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      '_id': const ObjectIdConverter().toJson(instance.id),
    };

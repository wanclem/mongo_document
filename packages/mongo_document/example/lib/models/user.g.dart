// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
      id: const ObjectIdConverter().fromJson(json['_id']),
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      age: (json['age'] as num?)?.toInt() ?? 18,
      createdAt: const DateTimeConverter().fromJson(json['created_at']),
      updatedAt: const DateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
      '_id': const ObjectIdConverter().toJson(instance.id),
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'email': instance.email,
      'age': instance.age,
      'created_at': const DateTimeConverter().toJson(instance.createdAt),
      'updated_at': const DateTimeConverter().toJson(instance.updatedAt),
    };

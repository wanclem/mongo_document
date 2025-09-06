// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Post _$PostFromJson(Map<String, dynamic> json) => _Post(
  id: const ObjectIdConverter().fromJson(json['_id']),
  body: json['body'] as String?,
  postNote: json['post_note'] as String?,
  author:
      json['author'] == null
          ? null
          : User.fromJson(json['author'] as Map<String, dynamic>),
  schedule:
      json['schedule'] == null
          ? null
          : Schedule.fromJson(json['schedule'] as Map<String, dynamic>),
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  createdAt: const DateTimeConverter().fromJson(json['created_at']),
  updatedAt: const DateTimeConverter().fromJson(json['updated_at']),
);

Map<String, dynamic> _$PostToJson(_Post instance) => <String, dynamic>{
  '_id': const ObjectIdConverter().toJson(instance.id),
  'body': instance.body,
  'post_note': instance.postNote,
  'author': instance.author?.toJson(),
  'schedule': instance.schedule?.toJson(),
  'tags': instance.tags,
  'created_at': const DateTimeConverter().toJson(instance.createdAt),
  'updated_at': const DateTimeConverter().toJson(instance.updatedAt),
};

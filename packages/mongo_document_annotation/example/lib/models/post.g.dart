// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Post _$PostFromJson(Map<String, dynamic> json) => _Post(
  id: const ObjectIdConverter().fromJson(json['_id']),
  body: json['body'] as String?,
  postNote: json['post_note'] as String?,
  author: const ObjectIdConverter().fromJson(json['author']),
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
  'author': const ObjectIdConverter().toJson(instance.author),
  'tags': instance.tags,
  'created_at': const DateTimeConverter().toJson(instance.createdAt),
  'updated_at': const DateTimeConverter().toJson(instance.updatedAt),
};

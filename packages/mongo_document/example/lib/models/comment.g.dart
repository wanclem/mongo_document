// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Comment _$CommentFromJson(Map<String, dynamic> json) => _Comment(
      id: const ObjectIdConverter().fromJson(json['_id']),
      post: json['post'] == null
          ? null
          : Post.fromJson(json['post'] as Map<String, dynamic>),
      text: json['text'] as String?,
      age: (json['age'] as num?)?.toInt() ?? 18,
      createdAt: const DateTimeConverter().fromJson(json['created_at']),
      updatedAt: const DateTimeConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$CommentToJson(_Comment instance) => <String, dynamic>{
      '_id': const ObjectIdConverter().toJson(instance.id),
      'post': instance.post?.toJson(),
      'text': instance.text,
      'age': instance.age,
      'created_at': const DateTimeConverter().toJson(instance.createdAt),
      'updated_at': const DateTimeConverter().toJson(instance.updatedAt),
    };

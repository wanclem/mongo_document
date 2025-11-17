// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Post {

@ObjectIdConverter()@JsonKey(name: '_id') ObjectId? get id; String? get body; String? get postNote; User? get author; Schedule? get schedule; bool get authorFollowsYou; List<dynamic> get targetPlatforms; List<String> get tags;@DateTimeConverter() DateTime? get createdAt;@DateTimeConverter() DateTime? get updatedAt;
/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostCopyWith<Post> get copyWith => _$PostCopyWithImpl<Post>(this as Post, _$identity);

  /// Serializes this Post to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Post&&(identical(other.id, id) || other.id == id)&&(identical(other.body, body) || other.body == body)&&(identical(other.postNote, postNote) || other.postNote == postNote)&&(identical(other.author, author) || other.author == author)&&(identical(other.schedule, schedule) || other.schedule == schedule)&&(identical(other.authorFollowsYou, authorFollowsYou) || other.authorFollowsYou == authorFollowsYou)&&const DeepCollectionEquality().equals(other.targetPlatforms, targetPlatforms)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,body,postNote,author,schedule,authorFollowsYou,const DeepCollectionEquality().hash(targetPlatforms),const DeepCollectionEquality().hash(tags),createdAt,updatedAt);

@override
String toString() {
  return 'Post(id: $id, body: $body, postNote: $postNote, author: $author, schedule: $schedule, authorFollowsYou: $authorFollowsYou, targetPlatforms: $targetPlatforms, tags: $tags, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PostCopyWith<$Res>  {
  factory $PostCopyWith(Post value, $Res Function(Post) _then) = _$PostCopyWithImpl;
@useResult
$Res call({
@ObjectIdConverter()@JsonKey(name: '_id') ObjectId? id, String? body, String? postNote, User? author, Schedule? schedule, bool authorFollowsYou, List<dynamic> targetPlatforms, List<String> tags,@DateTimeConverter() DateTime? createdAt,@DateTimeConverter() DateTime? updatedAt
});


$UserCopyWith<$Res>? get author;$ScheduleCopyWith<$Res>? get schedule;

}
/// @nodoc
class _$PostCopyWithImpl<$Res>
    implements $PostCopyWith<$Res> {
  _$PostCopyWithImpl(this._self, this._then);

  final Post _self;
  final $Res Function(Post) _then;

/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? body = freezed,Object? postNote = freezed,Object? author = freezed,Object? schedule = freezed,Object? authorFollowsYou = null,Object? targetPlatforms = null,Object? tags = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ObjectId?,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,postNote: freezed == postNote ? _self.postNote : postNote // ignore: cast_nullable_to_non_nullable
as String?,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as User?,schedule: freezed == schedule ? _self.schedule : schedule // ignore: cast_nullable_to_non_nullable
as Schedule?,authorFollowsYou: null == authorFollowsYou ? _self.authorFollowsYou : authorFollowsYou // ignore: cast_nullable_to_non_nullable
as bool,targetPlatforms: null == targetPlatforms ? _self.targetPlatforms : targetPlatforms // ignore: cast_nullable_to_non_nullable
as List<dynamic>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res>? get author {
    if (_self.author == null) {
    return null;
  }

  return $UserCopyWith<$Res>(_self.author!, (value) {
    return _then(_self.copyWith(author: value));
  });
}/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScheduleCopyWith<$Res>? get schedule {
    if (_self.schedule == null) {
    return null;
  }

  return $ScheduleCopyWith<$Res>(_self.schedule!, (value) {
    return _then(_self.copyWith(schedule: value));
  });
}
}


/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _Post implements Post {
  const _Post({@ObjectIdConverter()@JsonKey(name: '_id') this.id, this.body, this.postNote, this.author, this.schedule, this.authorFollowsYou = false, final  List<dynamic> targetPlatforms = const [], final  List<String> tags = const <String>[], @DateTimeConverter() this.createdAt, @DateTimeConverter() this.updatedAt}): _targetPlatforms = targetPlatforms,_tags = tags;
  factory _Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

@override@ObjectIdConverter()@JsonKey(name: '_id') final  ObjectId? id;
@override final  String? body;
@override final  String? postNote;
@override final  User? author;
@override final  Schedule? schedule;
@override@JsonKey() final  bool authorFollowsYou;
 final  List<dynamic> _targetPlatforms;
@override@JsonKey() List<dynamic> get targetPlatforms {
  if (_targetPlatforms is EqualUnmodifiableListView) return _targetPlatforms;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_targetPlatforms);
}

 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@DateTimeConverter() final  DateTime? createdAt;
@override@DateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostCopyWith<_Post> get copyWith => __$PostCopyWithImpl<_Post>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PostToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Post&&(identical(other.id, id) || other.id == id)&&(identical(other.body, body) || other.body == body)&&(identical(other.postNote, postNote) || other.postNote == postNote)&&(identical(other.author, author) || other.author == author)&&(identical(other.schedule, schedule) || other.schedule == schedule)&&(identical(other.authorFollowsYou, authorFollowsYou) || other.authorFollowsYou == authorFollowsYou)&&const DeepCollectionEquality().equals(other._targetPlatforms, _targetPlatforms)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,body,postNote,author,schedule,authorFollowsYou,const DeepCollectionEquality().hash(_targetPlatforms),const DeepCollectionEquality().hash(_tags),createdAt,updatedAt);

@override
String toString() {
  return 'Post(id: $id, body: $body, postNote: $postNote, author: $author, schedule: $schedule, authorFollowsYou: $authorFollowsYou, targetPlatforms: $targetPlatforms, tags: $tags, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PostCopyWith<$Res> implements $PostCopyWith<$Res> {
  factory _$PostCopyWith(_Post value, $Res Function(_Post) _then) = __$PostCopyWithImpl;
@override @useResult
$Res call({
@ObjectIdConverter()@JsonKey(name: '_id') ObjectId? id, String? body, String? postNote, User? author, Schedule? schedule, bool authorFollowsYou, List<dynamic> targetPlatforms, List<String> tags,@DateTimeConverter() DateTime? createdAt,@DateTimeConverter() DateTime? updatedAt
});


@override $UserCopyWith<$Res>? get author;@override $ScheduleCopyWith<$Res>? get schedule;

}
/// @nodoc
class __$PostCopyWithImpl<$Res>
    implements _$PostCopyWith<$Res> {
  __$PostCopyWithImpl(this._self, this._then);

  final _Post _self;
  final $Res Function(_Post) _then;

/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? body = freezed,Object? postNote = freezed,Object? author = freezed,Object? schedule = freezed,Object? authorFollowsYou = null,Object? targetPlatforms = null,Object? tags = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Post(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ObjectId?,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,postNote: freezed == postNote ? _self.postNote : postNote // ignore: cast_nullable_to_non_nullable
as String?,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as User?,schedule: freezed == schedule ? _self.schedule : schedule // ignore: cast_nullable_to_non_nullable
as Schedule?,authorFollowsYou: null == authorFollowsYou ? _self.authorFollowsYou : authorFollowsYou // ignore: cast_nullable_to_non_nullable
as bool,targetPlatforms: null == targetPlatforms ? _self._targetPlatforms : targetPlatforms // ignore: cast_nullable_to_non_nullable
as List<dynamic>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res>? get author {
    if (_self.author == null) {
    return null;
  }

  return $UserCopyWith<$Res>(_self.author!, (value) {
    return _then(_self.copyWith(author: value));
  });
}/// Create a copy of Post
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScheduleCopyWith<$Res>? get schedule {
    if (_self.schedule == null) {
    return null;
  }

  return $ScheduleCopyWith<$Res>(_self.schedule!, (value) {
    return _then(_self.copyWith(schedule: value));
  });
}
}

// dart format on

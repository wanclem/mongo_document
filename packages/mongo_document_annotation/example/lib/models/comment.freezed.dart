// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Comment {
  @ObjectIdConverter()
  @JsonKey(name: '_id')
  ObjectId? get id;
  Post? get post;
  String? get text;
  int get age;
  @DateTimeConverter()
  DateTime? get createdAt;
  @DateTimeConverter()
  DateTime? get updatedAt;

  /// Create a copy of Comment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CommentCopyWith<Comment> get copyWith =>
      _$CommentCopyWithImpl<Comment>(this as Comment, _$identity);

  /// Serializes this Comment to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Comment &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.post, post) || other.post == post) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.age, age) || other.age == age) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, post, text, age, createdAt, updatedAt);

  @override
  String toString() {
    return 'Comment(id: $id, post: $post, text: $text, age: $age, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $CommentCopyWith<$Res> {
  factory $CommentCopyWith(Comment value, $Res Function(Comment) _then) =
      _$CommentCopyWithImpl;
  @useResult
  $Res call(
      {@ObjectIdConverter() @JsonKey(name: '_id') ObjectId? id,
      Post? post,
      String? text,
      int age,
      @DateTimeConverter() DateTime? createdAt,
      @DateTimeConverter() DateTime? updatedAt});

  $PostCopyWith<$Res>? get post;
}

/// @nodoc
class _$CommentCopyWithImpl<$Res> implements $CommentCopyWith<$Res> {
  _$CommentCopyWithImpl(this._self, this._then);

  final Comment _self;
  final $Res Function(Comment) _then;

  /// Create a copy of Comment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? post = freezed,
    Object? text = freezed,
    Object? age = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_self.copyWith(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as ObjectId?,
      post: freezed == post
          ? _self.post
          : post // ignore: cast_nullable_to_non_nullable
              as Post?,
      text: freezed == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String?,
      age: null == age
          ? _self.age
          : age // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }

  /// Create a copy of Comment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PostCopyWith<$Res>? get post {
    if (_self.post == null) {
      return null;
    }

    return $PostCopyWith<$Res>(_self.post!, (value) {
      return _then(_self.copyWith(post: value));
    });
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _Comment implements Comment {
  const _Comment(
      {@ObjectIdConverter() @JsonKey(name: '_id') this.id,
      this.post,
      this.text,
      this.age = 18,
      @DateTimeConverter() this.createdAt,
      @DateTimeConverter() this.updatedAt});
  factory _Comment.fromJson(Map<String, dynamic> json) =>
      _$CommentFromJson(json);

  @override
  @ObjectIdConverter()
  @JsonKey(name: '_id')
  final ObjectId? id;
  @override
  final Post? post;
  @override
  final String? text;
  @override
  @JsonKey()
  final int age;
  @override
  @DateTimeConverter()
  final DateTime? createdAt;
  @override
  @DateTimeConverter()
  final DateTime? updatedAt;

  /// Create a copy of Comment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CommentCopyWith<_Comment> get copyWith =>
      __$CommentCopyWithImpl<_Comment>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CommentToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Comment &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.post, post) || other.post == post) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.age, age) || other.age == age) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, post, text, age, createdAt, updatedAt);

  @override
  String toString() {
    return 'Comment(id: $id, post: $post, text: $text, age: $age, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$CommentCopyWith<$Res> implements $CommentCopyWith<$Res> {
  factory _$CommentCopyWith(_Comment value, $Res Function(_Comment) _then) =
      __$CommentCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@ObjectIdConverter() @JsonKey(name: '_id') ObjectId? id,
      Post? post,
      String? text,
      int age,
      @DateTimeConverter() DateTime? createdAt,
      @DateTimeConverter() DateTime? updatedAt});

  @override
  $PostCopyWith<$Res>? get post;
}

/// @nodoc
class __$CommentCopyWithImpl<$Res> implements _$CommentCopyWith<$Res> {
  __$CommentCopyWithImpl(this._self, this._then);

  final _Comment _self;
  final $Res Function(_Comment) _then;

  /// Create a copy of Comment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = freezed,
    Object? post = freezed,
    Object? text = freezed,
    Object? age = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_Comment(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as ObjectId?,
      post: freezed == post
          ? _self.post
          : post // ignore: cast_nullable_to_non_nullable
              as Post?,
      text: freezed == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String?,
      age: null == age
          ? _self.age
          : age // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }

  /// Create a copy of Comment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PostCopyWith<$Res>? get post {
    if (_self.post == null) {
      return null;
    }

    return $PostCopyWith<$Res>(_self.post!, (value) {
      return _then(_self.copyWith(post: value));
    });
  }
}

// dart format on

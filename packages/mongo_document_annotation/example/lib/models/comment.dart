import 'package:example/models/post.dart';
import 'package:example/models/user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';

part 'comment.freezed.dart';

part 'comment.g.dart';

part 'comment.mongo_document.dart';

@MongoDocument(collection: "comments")
@freezed
abstract class Comment with _$Comment {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory Comment({
    @ObjectIdConverter() @JsonKey(name: '_id') ObjectId? id,
    User? author,
    Post? post,
    String? text,
    @Default(false) bool deleted,
    @DateTimeConverter() DateTime? createdAt,
    @DateTimeConverter() DateTime? updatedAt,
  }) = _Comment;

  factory Comment.fromJson(Map<String, dynamic> json) =>
      _$CommentFromJson(json);
}

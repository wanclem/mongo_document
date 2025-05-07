import 'package:example/models/post.dart';
import 'package:mongo_document/mongo_document.dart';

part 'comment.freezed.dart';

part 'comment.g.dart';

part 'comment.mongo_document.dart';

@freezed
@MongoDocument(collection: "comments")
abstract class Comment with _$Comment {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory Comment({
    @ObjectIdConverter() @JsonKey(name: '_id') ObjectId? id,
    Post? post,
    String? text,
    @Default(18) int age,
    @DateTimeConverter() DateTime? createdAt,
    @DateTimeConverter() DateTime? updatedAt,
  }) = _Comment;

  factory Comment.fromJson(Map<String, dynamic> json) =>
      _$CommentFromJson(json);
}

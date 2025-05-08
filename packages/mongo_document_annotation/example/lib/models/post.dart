import 'package:example/models/comment.dart';
import 'package:example/models/user.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';

part 'post.freezed.dart';

part 'post.g.dart';

part 'post.mongo_document.dart';

@freezed
@MongoDocument(collection: "posts")
abstract class Post with _$Post {
  @JsonSerializable(
    fieldRename: FieldRename.snake,
    explicitToJson: true,
  )
  const factory Post({
    @ObjectIdConverter() @JsonKey(name: '_id') ObjectId? id,
    User? author,
    Comment? lastComment,
    @Default([]) List<String> tags,
    String? body,
    @DateTimeConverter() DateTime? createdAt,
    @DateTimeConverter() DateTime? updatedAt,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}

import 'package:example/models/comment.dart';
import 'package:example/models/schedule.dart';
import 'package:example/models/user.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'post.freezed.dart';

part 'post.g.dart';

part 'post.mongo_document.dart';

@MongoDocument(collection: 'posts')
@freezed
abstract class Post with _$Post {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory Post({
    @ObjectIdConverter() @JsonKey(name: '_id') ObjectId? id,
    String? body,
    String? postNote,
    User? author,
    Schedule? schedule,
    @Default([]) List<Comment> comments,
    @Default(false) bool authorFollowsYou,
    @Default([]) List<dynamic> targetPlatforms,
    @Default(<String>[]) List<String> tags,
    @DateTimeConverter() DateTime? createdAt,
    @DateTimeConverter() DateTime? updatedAt,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}

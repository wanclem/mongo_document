import 'package:example/models/user.dart';
import 'package:mongo_document/mongo_document.dart';

part 'post.freezed.dart';

part 'post.g.dart';

part 'post.mongo_document.dart';
enum PlatformIdentifier {
  facebook,
  instagram,
  twitter,
  linkedin,
  x,
  googleMyBusiness,
  reddit,
  pinterest,
  youtube,
  tiktok,
  wordpress,
  rssFeed,
  blogger,
  threads,
  bluesky,
  telegram,
  none,
}

@freezed
@MongoDocument(collection: "posts")
abstract class Post with _$Post {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory Post({
    @ObjectIdConverter() @JsonKey(name: '_id') ObjectId? id,
    User? author,
    @Default([]) List<String> tags,
    String? body,
    @DateTimeConverter() DateTime? createdAt,
    @DateTimeConverter() DateTime? updatedAt,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}

import 'package:example/env/dump.dart';
import 'package:example/models/post.dart';
import 'package:example/models/user.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';

Future<void> main() async {
  Environment env = Environment();
  String mongoUri = env.get('MONGO_URI') ?? "";

  ///Initialize connection to the database once on application start
  await MongoDbConnection.initialize(mongoUri);

  // Create a new user
  User? newUser = await User(firstName: "John", lastName: "Doe").save();
  print("User Created: $newUser");

  // //Create a new post
  Post? post =
      await Post(
        author: newUser,
        body: "Hello World",
        tags: ['setup', 'init', 'starter'],
      ).save();

  print("Post Created: $post");

  final existingPost = await Posts.findById(post!.id);
  print(existingPost);
}

import 'package:example/env/dump.dart';
import 'package:example/models/post.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';

Future<void> main() async {
  Environment env = Environment();
  String mongoUri = env.get('MONGO_URI') ?? "";
  await MongoDbConnection.initialize(mongoUri);
  //Create a new user
  // User? newUser = await User(firstName: "John", lastName: "Doe").save();
  // print("User Created: $newUser");
  // //Create a new post
  // Post? post =
  //     await Post(
  //       author: newUser,
  //       body: "Setting up my post",
  //       tags: ['setup', 'init'],
  //     ).save();
  // print("Post Created: $post");
}

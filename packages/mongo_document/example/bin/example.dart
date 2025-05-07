import 'package:example/env/dump.dart';
import 'package:example/models/post.dart';
import 'package:example/models/user.dart';
import 'package:mongo_document/mongo_document.dart';

Future<void> main() async {
  var env = Environment();
  String? mongoUri = env.get('MONGO_URI') ?? "";

  /// Initialize the global MongoDB connection once.
  /// All generated .save(), .findOne(), .findMany(), etc. will reuse this.
  await MongoConnection.init(mongoUri);

  // Create a new post
  // Post? newPost = await Post(body: "Hey there!", tags: [
  //   "MongoDb",
  //   "Is",
  //   "The",
  //   "Best",
  //   "Database",
  //   "In",
  //   "The",
  //   "Entire",
  //   "World"
  // ]).save();
  // print("Post Created Successfully");

  // // Find the post by ID
  // Post? newlyCreatedPost = await Posts.findById(newPost?.id);
  // print("Newly Created Post $newlyCreatedPost");

  // //Find the first post whose tags array contains the element "MongoDb"
  // Post? p = await Posts.findOne((p) => p.tags.contains("MongoDb"));
  // print("Post with tags containing MongoDb element $p");
}

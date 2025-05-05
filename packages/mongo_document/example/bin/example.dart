import 'package:example/env/dump.dart';
import 'package:example/models/post.dart';
import 'package:mongo_document/mongo_connection.dart';

Future<void> main() async {
  var env = Environment();
  String? mongoUri = env.get('MONGO_URI') ?? "";

  /// Initialize the global MongoDB connection once.
  /// All generated .save(), .findOne(), .findMany(), etc. will reuse this.
  MongoConnection.init(mongoUri);

  /// Execute an asynchronous find‑one query against the `posts` collection.
  var post = await PostQuery.findOne((p) => p.body.contains("Hello World"));
  print(post);
}

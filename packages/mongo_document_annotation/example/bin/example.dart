import 'package:example/env/dump.dart';
import 'package:mongo_document_annotation/mongo_document_annotation.dart';

Future<void> main() async {
  Environment env = Environment();
  String mongoUri = env.get('MONGO_URI') ?? "";
  await MongoConnection.init(mongoUri);
  //TODO: Next item on the list is querying by nested objects as shown below:
  // Post? post = await Posts.findOne((p) => p.author.firstName.eq("Wan"));
  // print(post);
}
